import Foundation
import os
import Security

/// Keeps the signed-in session between launches.
public protocol FlickrTokenStore: Sendable {
    func load() throws(FlickrError) -> FlickrSession?
    func save(_ session: FlickrSession) throws(FlickrError)
    func delete() throws(FlickrError)
}

/// Stores the session as a generic password in the Keychain, readable after first unlock and
/// never synced or backed up to another device.
public struct KeychainTokenStore: FlickrTokenStore {

    public let service: String
    public let account: String

    public init(service: String = "com.devedup.flickrkit", account: String = "session") {
        self.service = service
        self.account = account
    }

    public func load() throws(FlickrError) -> FlickrSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw .tokenStore(status: status, description: "Couldn't read the Flickr session from the Keychain.")
        }
        do {
            return try JSONDecoder().decode(FlickrSession.self, from: data)
        } catch {
            throw .tokenStore(status: errSecDecode, description: "The stored Flickr session is unreadable: \(error)")
        }
    }

    public func save(_ session: FlickrSession) throws(FlickrError) {
        let data: Data
        do {
            data = try JSONEncoder().encode(session)
        } catch {
            throw .tokenStore(status: errSecParam, description: "Couldn't encode the Flickr session: \(error)")
        }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let item = baseQuery.merging(attributes) { _, new in new }
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw .tokenStore(status: status, description: "Couldn't save the Flickr session to the Keychain.")
        }
    }

    public func delete() throws(FlickrError) {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw .tokenStore(status: status, description: "Couldn't remove the Flickr session from the Keychain.")
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }
}

/// The `NSUserDefaults` keys FlickrKit 1.x stored the token and secret under, in plain text.
public enum FlickrLegacyTokenKeys {
    public static let token = "kFKStoredTokenKey"
    public static let secret = "kFKStoredTokenSecret"
}

extension FlickrTokenStore {

    /// Moves a FlickrKit 1.x token out of `defaults` into this store, once.
    ///
    /// Does nothing when the store already has a session or `defaults` has no token. The legacy keys
    /// are removed only after the save succeeds. Call ``FlickrClient/restoreSession()`` afterwards to
    /// fill in the user, which 1.x didn't store.
    ///
    /// - Returns: Whether a token was migrated.
    @discardableResult
    public func migrateLegacyToken(from defaults: UserDefaults = .standard) throws(FlickrError) -> Bool {
        guard try load() == nil,
              let token = defaults.string(forKey: FlickrLegacyTokenKeys.token),
              let secret = defaults.string(forKey: FlickrLegacyTokenKeys.secret) else {
            return false
        }
        try save(FlickrSession(accessToken: FlickrAccessToken(token: token, secret: secret), user: nil, permission: nil))
        defaults.removeObject(forKey: FlickrLegacyTokenKeys.token)
        defaults.removeObject(forKey: FlickrLegacyTokenKeys.secret)
        return true
    }
}

/// Keeps the session in memory only. For tests and previews.
public final class InMemoryTokenStore: FlickrTokenStore {

    private let storage: OSAllocatedUnfairLock<FlickrSession?>

    public init(session: FlickrSession? = nil) {
        storage = OSAllocatedUnfairLock(initialState: session)
    }

    public func load() throws(FlickrError) -> FlickrSession? {
        storage.withLock { $0 }
    }

    public func save(_ session: FlickrSession) throws(FlickrError) {
        storage.withLock { $0 = session }
    }

    public func delete() throws(FlickrError) {
        storage.withLock { $0 = nil }
    }
}

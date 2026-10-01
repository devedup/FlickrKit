import CryptoKit
import Foundation

/// Stores raw JSON responses so repeated calls within their max age don't hit the network.
public protocol FlickrResponseCache: Sendable {
    /// The data stored for `key` if it is no older than `maxAge`.
    func data(forKey key: String, maxAge: Duration) async -> Data?
    func store(_ data: Data, forKey key: String) async
    func remove(forKey key: String) async
    func removeAll() async
}

/// Cache keys for API calls.
public enum FlickrCacheKey {

    /// A SHA-256 hex digest of the scope, method and arguments, with the arguments sorted so the
    /// same call always gets the same key. `scope` is the signed-in user's NSID for signed calls,
    /// so one account never sees another's cached responses, and `nil` for anonymous ones.
    public static func make(method: String, arguments: [String: String], scope: String?) -> String {
        var text = (scope ?? "") + "|" + method
        for key in arguments.keys.sorted() {
            text += "|" + key + "=" + (arguments[key] ?? "")
        }
        return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Common max ages, matching the FlickrKit 1.x `FKDUMaxAge` values.
public enum FlickrCacheAge {
    public static let oneMinute: Duration = .seconds(60)
    public static let fiveMinutes: Duration = .seconds(5 * 60)
    public static let oneHour: Duration = .seconds(60 * 60)
    public static let halfDay: Duration = .seconds(12 * 60 * 60)
    public static let oneDay: Duration = .seconds(24 * 60 * 60)
}

extension Duration {
    var timeInterval: TimeInterval {
        let parts = components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}

/// A cache held in memory. For tests, previews, or apps that don't want responses on disk.
public actor InMemoryResponseCache: FlickrResponseCache {

    private var entries: [String: (data: Data, stored: Date)] = [:]
    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    public func data(forKey key: String, maxAge: Duration) -> Data? {
        guard let entry = entries[key], now().timeIntervalSince(entry.stored) <= maxAge.timeInterval else {
            return nil
        }
        return entry.data
    }

    public func store(_ data: Data, forKey key: String) {
        entries[key] = (data, now())
    }

    public func remove(forKey key: String) {
        entries[key] = nil
    }

    public func removeAll() {
        entries.removeAll()
    }

    public var count: Int { entries.count }
}

/// A cache of files in a directory, one per key, aged by modification date.
///
/// When the total size passes `byteLimit`, the least recently stored files are removed until it is
/// back under three quarters of the limit. The OS may also purge the Caches directory at any time.
public actor DiskResponseCache: FlickrResponseCache {

    public let directory: URL
    public let byteLimit: Int
    private let now: @Sendable () -> Date
    private let fileManager = FileManager()

    /// - Parameters:
    ///   - directory: Defaults to `Caches/FlickrKit/Responses`.
    ///   - byteLimit: Defaults to 50 MB.
    public init(directory: URL? = nil, byteLimit: Int = 50 * 1024 * 1024, now: @escaping @Sendable () -> Date = Date.init) {
        self.directory = directory ?? URL.cachesDirectory.appending(path: "FlickrKit/Responses", directoryHint: .isDirectory)
        self.byteLimit = byteLimit
        self.now = now
    }

    public func data(forKey key: String, maxAge: Duration) -> Data? {
        let url = fileURL(forKey: key)
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path(percentEncoded: false))
            guard let modified = attributes[.modificationDate] as? Date,
                  now().timeIntervalSince(modified) <= maxAge.timeInterval else {
                return nil
            }
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    public func store(_ data: Data, forKey key: String) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = fileURL(forKey: key)
            try data.write(to: url, options: .atomic)
            try fileManager.setAttributes([.modificationDate: now()], ofItemAtPath: url.path(percentEncoded: false))
            trimIfNeeded()
        } catch {
            // A failed cache write only costs a later network request.
        }
    }

    public func remove(forKey key: String) {
        do {
            try fileManager.removeItem(at: fileURL(forKey: key))
        } catch {
            // Already gone.
        }
    }

    public func removeAll() {
        do {
            try fileManager.removeItem(at: directory)
        } catch {
            // Already gone.
        }
    }

    private func fileURL(forKey key: String) -> URL {
        // Keys from FlickrCacheKey are hex digests; hash anything else so it is a safe file name.
        let isSafe = !key.isEmpty && key.count <= 128 && key.allSatisfy { $0.isHexDigit }
        let name = isSafe ? key : SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name, directoryHint: .notDirectory)
    }

    private func trimIfNeeded() {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let files: [URL]
        do {
            files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)
        } catch {
            return
        }
        var entries: [(url: URL, size: Int, modified: Date)] = []
        for file in files {
            do {
                let values = try file.resourceValues(forKeys: Set(keys))
                entries.append((file, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast))
            } catch {
                continue
            }
        }
        var total = entries.reduce(0) { $0 + $1.size }
        guard total > byteLimit else { return }
        for entry in entries.sorted(by: { $0.modified < $1.modified }) where total > byteLimit * 3 / 4 {
            do {
                try fileManager.removeItem(at: entry.url)
                total -= entry.size
            } catch {
                continue
            }
        }
    }
}

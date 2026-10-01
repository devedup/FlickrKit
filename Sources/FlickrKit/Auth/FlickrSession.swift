import Foundation

/// The access level a user grants the app on Flickr's authorize page. Ordered: `delete`
/// includes `write`, which includes `read`.
public enum FlickrPermission: String, Sendable, Codable, CaseIterable, Comparable {
    case read
    case write
    case delete

    public static func < (lhs: FlickrPermission, rhs: FlickrPermission) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .read: 0
        case .write: 1
        case .delete: 2
        }
    }
}

/// An OAuth access token and its secret.
public struct FlickrAccessToken: Sendable, Codable, Hashable {
    public var token: String
    public var secret: String

    public init(token: String, secret: String) {
        self.token = token
        self.secret = secret
    }
}

/// The signed-in Flickr account.
public struct FlickrUser: Sendable, Codable, Hashable, Identifiable {
    /// The NSID, e.g. `12037949754@N01`.
    public var nsid: String
    public var username: String
    public var fullName: String

    public var id: String { nsid }

    public init(nsid: String, username: String, fullName: String) {
        self.nsid = nsid
        self.username = username
        self.fullName = fullName
    }
}

/// What a ``FlickrTokenStore`` keeps between launches.
///
/// `user` and `permission` are optional so a token migrated from FlickrKit 1.x, which only stored
/// the token and secret, can be saved; ``FlickrClient/restoreSession()`` fills them in.
public struct FlickrSession: Sendable, Codable, Hashable {
    public var accessToken: FlickrAccessToken
    public var user: FlickrUser?
    public var permission: FlickrPermission?

    public init(accessToken: FlickrAccessToken, user: FlickrUser?, permission: FlickrPermission?) {
        self.accessToken = accessToken
        self.user = user
        self.permission = permission
    }
}

/// How a call is authenticated.
public enum FlickrAuthMode: Sendable, Hashable {
    /// Never signed: only `api_key` is sent, and the response is cached for everyone.
    case anonymous
    /// Signed when a user is signed in, so Flickr returns their private view (e.g. friends-only
    /// photos, `isfavorite`); anonymous otherwise.
    case ifSignedIn
    /// Fails with ``FlickrError/notSignedIn`` or ``FlickrError/insufficientPermission(required:granted:)``
    /// unless a user with at least this permission is signed in.
    case required(FlickrPermission)
}

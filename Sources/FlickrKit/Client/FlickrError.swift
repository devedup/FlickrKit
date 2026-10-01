import Foundation

/// Everything that can go wrong in a FlickrKit call.
public enum FlickrError: Error, Sendable, Equatable {

    /// Flickr answered `stat: fail`. `code` is Flickr's error code for the method.
    case api(code: Int, message: String)
    /// The stored token is no longer valid (Flickr codes 98 "Invalid auth token" and
    /// 99 "Insufficient permissions"/"User not logged in"). Sign the user out and ask them again.
    case invalidToken(code: Int, message: String)
    /// The call needs a signed-in user and nobody is signed in.
    case notSignedIn
    /// The call needs `required` access but the user granted only `granted`.
    case insufficientPermission(required: FlickrPermission, granted: FlickrPermission)
    /// The server answered with a non-2xx HTTP status, after any retries.
    case http(status: Int)
    /// The transport failed (offline, timed out, cancelled…). `code` is the `URLError` code
    /// when there is one.
    case transport(code: Int, description: String)
    /// Flickr answered 200 with no body.
    case emptyResponse
    /// The body wasn't JSON, or didn't decode into the type the caller asked for.
    case decoding(description: String)
    /// A sign-in step failed. `message` is what Flickr said, or a description of the failure.
    case signInFailed(message: String)
    /// The callback URL handed to ``FlickrClient/completeSignIn(callbackURL:)`` is missing
    /// `oauth_token` or `oauth_verifier`, or belongs to a different sign-in.
    case invalidSignInCallback(URL)
    /// ``FlickrClient/completeSignIn(callbackURL:)`` was called with no sign-in in progress.
    case noSignInInProgress
    /// The user closed the sign-in window.
    case signInCancelled
    /// The token store couldn't read or write. `status` is the Keychain `OSStatus` if any.
    case tokenStore(status: Int32, description: String)

    /// Whether the user has to sign in again before authenticated calls can work.
    public var requiresSignIn: Bool {
        switch self {
        case .invalidToken, .notSignedIn, .insufficientPermission: true
        default: false
        }
    }
}

extension FlickrError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .api(let code, let message): "Flickr error \(code): \(message)"
        case .invalidToken(_, let message): "Your Flickr sign-in has expired (\(message))."
        case .notSignedIn: "Sign in to Flickr to do this."
        case .insufficientPermission(let required, let granted):
            "This needs \(required.rawValue) access to your Flickr account, and only \(granted.rawValue) access was granted."
        case .http(let status): "Flickr returned HTTP \(status)."
        case .transport(_, let description): description
        case .emptyResponse: "Flickr returned an empty response."
        case .decoding(let description): "Couldn't read Flickr's response: \(description)"
        case .signInFailed(let message): "Couldn't sign in to Flickr: \(message)"
        case .invalidSignInCallback: "The sign-in callback from Flickr was incomplete."
        case .noSignInInProgress: "There is no Flickr sign-in in progress."
        case .signInCancelled: "Sign-in was cancelled."
        case .tokenStore(_, let description): description
        }
    }
}

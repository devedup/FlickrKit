#if canImport(AuthenticationServices)
import AuthenticationServices
import Foundation

/// Runs the whole Flickr sign-in in an `ASWebAuthenticationSession`: gets a request token, shows
/// Flickr's authorize page in a secure browser window (with the user's saved passwords), and
/// exchanges the callback for an access token.
///
/// ```swift
/// let authenticator = FlickrWebAuthenticator(client: client)
/// let user = try await authenticator.signIn(
///     callbackURL: URL(string: "myapp://flickr-auth")!,
///     permission: .write,
///     anchor: window
/// )
/// ```
@MainActor
public final class FlickrWebAuthenticator: NSObject {

    private let client: FlickrClient
    private var session: ASWebAuthenticationSession?
    private var anchor: ASPresentationAnchor?

    public init(client: FlickrClient) {
        self.client = client
    }

    /// Signs the user in and returns their account.
    ///
    /// - Parameters:
    ///   - callbackURL: The URL Flickr redirects to. Its scheme is what the session listens for,
    ///     so it doesn't need registering in the app's URL types.
    ///   - permission: The access to ask for.
    ///   - prefersEphemeralSession: `true` doesn't share cookies with Safari, so the user always
    ///     sees Flickr's login form. Defaults to `false`, which lets a user already signed in to
    ///     Flickr in Safari just tap OK.
    ///   - anchor: The window to present over.
    /// - Throws: ``FlickrError/signInCancelled`` if the user closes the window.
    public func signIn(
        callbackURL: URL,
        permission: FlickrPermission,
        prefersEphemeralSession: Bool = false,
        anchor: ASPresentationAnchor
    ) async throws(FlickrError) -> FlickrUser {
        guard let scheme = callbackURL.scheme else {
            throw .signInFailed(message: "The callback URL needs a scheme.")
        }
        let authorizeURL = try await client.beginSignIn(callbackURL: callbackURL, permission: permission)
        let redirect: URL
        do {
            redirect = try await present(authorizeURL, callbackScheme: scheme, ephemeral: prefersEphemeralSession, anchor: anchor)
        } catch {
            await client.cancelSignIn()
            throw error
        }
        return try await client.completeSignIn(callbackURL: redirect)
    }

    /// Closes the sign-in window if one is showing.
    public func cancel() {
        session?.cancel()
    }

    private func present(_ url: URL, callbackScheme: String, ephemeral: Bool, anchor: ASPresentationAnchor) async throws(FlickrError) -> URL {
        self.anchor = anchor
        defer {
            session = nil
            self.anchor = nil
        }
        let result: Result<URL, FlickrError> = await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: .success(callbackURL))
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(returning: .failure(.signInCancelled))
                } else {
                    let description = error?.localizedDescription ?? "The sign-in window closed without a result."
                    continuation.resume(returning: .failure(.signInFailed(message: description)))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = ephemeral
            self.session = session
            if !session.start() {
                continuation.resume(returning: .failure(.signInFailed(message: "Couldn't open the sign-in window.")))
            }
        }
        return try result.get()
    }
}

extension FlickrWebAuthenticator: ASWebAuthenticationPresentationContextProviding {
    public nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            anchor ?? ASPresentationAnchor()
        }
    }
}
#endif

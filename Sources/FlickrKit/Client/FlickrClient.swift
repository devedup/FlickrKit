import Foundation
import os

/// The entry point to the Flickr API: signs and sends calls, caches responses, and runs the
/// OAuth sign-in.
///
/// One client per app is the norm. Every dependency is injectable, so tests can drive it with a
/// stub transport, an in-memory cache and token store, and a sleep that returns at once.
public actor FlickrClient {

    public let apiKey: String
    private let signer: OAuthSigner
    private let tokenStore: any FlickrTokenStore
    private let transport: any FlickrTransport
    private let cache: any FlickrResponseCache
    private let retryPolicy: FlickrRetryPolicy
    private let semaphore: AsyncSemaphore
    private let sleep: @Sendable (Duration) async throws -> Void
    private let now: @Sendable () -> Date
    private let makeNonce: @Sendable () -> String
    private let logger = Logger(subsystem: "com.devedup.flickrkit", category: "FlickrClient")

    private var session: FlickrSession?
    private var pendingSignIn: PendingSignIn?

    private struct PendingSignIn {
        var token: String
        var secret: String
        var permission: FlickrPermission
    }

    /// - Parameters:
    ///   - apiKey: Your Flickr API key.
    ///   - sharedSecret: The secret that goes with it.
    ///   - tokenStore: Where the signed-in session is kept. Defaults to the Keychain.
    ///   - transport: Defaults to `URLSession.shared`.
    ///   - cache: Defaults to a ``DiskResponseCache`` in the Caches directory.
    ///   - retryPolicy: Back-off for 429 and 5xx responses.
    ///   - maxConcurrentRequests: Requests in flight at once; others wait their turn.
    ///   - sleep: Waits between retries. Tests pass one that returns immediately.
    ///   - now: The clock used for OAuth timestamps.
    ///   - makeNonce: OAuth nonces. Tests pass a fixed value.
    public init(
        apiKey: String,
        sharedSecret: String,
        tokenStore: any FlickrTokenStore = KeychainTokenStore(),
        transport: any FlickrTransport = URLSession.shared,
        cache: any FlickrResponseCache = DiskResponseCache(),
        retryPolicy: FlickrRetryPolicy = .default,
        maxConcurrentRequests: Int = 4,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        now: @escaping @Sendable () -> Date = Date.init,
        makeNonce: @escaping @Sendable () -> String = { UUID().uuidString.replacingOccurrences(of: "-", with: "") }
    ) {
        self.apiKey = apiKey
        self.signer = OAuthSigner(consumerKey: apiKey, consumerSecret: sharedSecret)
        self.tokenStore = tokenStore
        self.transport = transport
        self.cache = cache
        self.retryPolicy = retryPolicy
        self.semaphore = AsyncSemaphore(value: maxConcurrentRequests)
        self.sleep = sleep
        self.now = now
        self.makeNonce = makeNonce
        do {
            self.session = try tokenStore.load()
        } catch {
            self.session = nil
        }
    }

    // MARK: - Session

    /// The stored session, if a user is signed in. Its `user` may be `nil` until
    /// ``restoreSession()`` has run for a token migrated from FlickrKit 1.x.
    public var currentSession: FlickrSession? { session }

    public var currentUser: FlickrUser? { session?.user }

    public var isSignedIn: Bool { session != nil }

    // MARK: - Calls

    /// Calls `request.method` and decodes the response as `T`.
    public func call<T: Decodable & Sendable>(_ request: FlickrRequest, as type: T.Type = T.self) async throws(FlickrError) -> T {
        try await call(request.method, args: request.arguments, auth: request.auth, maxAge: request.maxAge)
    }

    /// Calls any Flickr API method and decodes the response as `T`.
    ///
    /// - Parameters:
    ///   - method: e.g. `flickr.photos.getInfo`.
    ///   - args: The method's arguments. `format`, `nojsoncallback`, `api_key` and the OAuth
    ///     parameters are added for you.
    ///   - auth: Whether to sign the call.
    ///   - maxAge: How long a cached response may be reused; `nil` never caches.
    public func call<T: Decodable & Sendable>(
        _ method: String,
        args: [String: String] = [:],
        auth: FlickrAuthMode = .ifSignedIn,
        maxAge: Duration? = nil
    ) async throws(FlickrError) -> T {
        let data = try await data(method, args: args, auth: auth, maxAge: maxAge)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw .decoding(description: String(describing: error))
        }
    }

    /// The raw JSON for `request`, after the `stat` check. Useful for recording fixtures.
    public func data(for request: FlickrRequest) async throws(FlickrError) -> Data {
        try await data(request.method, args: request.arguments, auth: request.auth, maxAge: request.maxAge)
    }

    /// The raw JSON for a call, after the `stat` check.
    public func data(
        _ method: String,
        args: [String: String] = [:],
        auth: FlickrAuthMode = .ifSignedIn,
        maxAge: Duration? = nil
    ) async throws(FlickrError) -> Data {
        let signing = try sessionForSigning(auth)
        return try await restData(method, args: args, signing: signing, maxAge: maxAge)
    }

    /// Removes every cached response, for example from a "Clear cache" setting.
    public func clearCache() async {
        await cache.removeAll()
    }

    private func restData(_ method: String, args: [String: String], signing: FlickrSession?, maxAge: Duration?) async throws(FlickrError) -> Data {
        let key = FlickrCacheKey.make(method: method, arguments: args, scope: signing.map(Self.cacheScope))
        if let maxAge {
            if let cached = await cache.data(forKey: key, maxAge: maxAge) {
                return cached
            }
        } else {
            await cache.remove(forKey: key)
        }

        let data = try await send { [self] in restRequest(method, args: args, signing: signing) }
        try Self.checkStatus(data)
        if maxAge != nil {
            await cache.store(data, forKey: key)
        }
        return data
    }

    private func sessionForSigning(_ auth: FlickrAuthMode) throws(FlickrError) -> FlickrSession? {
        switch auth {
        case .anonymous:
            return nil
        case .ifSignedIn:
            return session
        case .required(let permission):
            guard let session else {
                throw .notSignedIn
            }
            if let granted = session.permission, granted < permission {
                throw .insufficientPermission(required: permission, granted: granted)
            }
            return session
        }
    }

    /// Responses differ per account, so signed calls are cached per user. A token migrated from 1.x
    /// has no user yet, so its token stands in until ``restoreSession()`` fills the user in.
    private static func cacheScope(for session: FlickrSession) -> String {
        session.user?.nsid ?? "token:" + session.accessToken.token
    }

    private func restRequest(_ method: String, args: [String: String], signing: FlickrSession?) -> URLRequest {
        var parameters = args
        parameters["method"] = method
        parameters["format"] = "json"
        parameters["nojsoncallback"] = "1"
        if let signing {
            parameters = signedParameters(url: FlickrEndpoint.rest, parameters: parameters, token: signing.accessToken.token, tokenSecret: signing.accessToken.secret)
        } else {
            parameters["api_key"] = apiKey
        }
        return getRequest(FlickrEndpoint.rest, parameters: parameters)
    }

    private func signedParameters(url: URL, parameters: [String: String], token: String?, tokenSecret: String?) -> [String: String] {
        signer.signedParameters(
            httpMethod: "GET",
            url: url,
            parameters: parameters,
            token: token,
            tokenSecret: tokenSecret,
            nonce: makeNonce(),
            timestamp: Int(now().timeIntervalSince1970)
        )
    }

    private func getRequest(_ url: URL, parameters: [String: String]) -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = FormEncoding.query(from: parameters)
        var request = URLRequest(url: components?.url ?? url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    static func checkStatus(_ data: Data) throws(FlickrError) {
        let status: FlickrStatus
        do {
            status = try JSONDecoder().decode(FlickrStatus.self, from: data)
        } catch {
            throw .decoding(description: String(describing: error))
        }
        guard status.isFailure else { return }
        let code = status.code ?? 0
        let message = status.message ?? "Flickr returned error code \(code)"
        switch code {
        case 98, 99: throw .invalidToken(code: code, message: message)
        default: throw .api(code: code, message: message)
        }
    }

    /// Sends a request built fresh for each attempt (so OAuth nonces aren't reused), retrying
    /// rate limits, server errors and dropped connections with exponential back-off.
    private func send(_ makeRequest: () -> URLRequest) async throws(FlickrError) -> Data {
        var attempt = 0
        while true {
            let request = makeRequest()
            await semaphore.wait()
            let outcome: Result<(Data, HTTPURLResponse), any Error>
            do {
                outcome = .success(try await transport.send(request))
            } catch {
                outcome = .failure(error)
            }
            await semaphore.signal()

            let canRetry = attempt < retryPolicy.maxRetries
            switch outcome {
            case .success(let (data, response)):
                if (200..<300).contains(response.statusCode) {
                    guard !data.isEmpty else { throw .emptyResponse }
                    return data
                }
                guard canRetry, retryPolicy.retryableStatuses.contains(response.statusCode) else {
                    throw .http(status: response.statusCode)
                }
                let delay = retryPolicy.delay(beforeRetry: attempt, retryAfter: response.value(forHTTPHeaderField: "Retry-After"))
                logger.debug("\(request.url?.path() ?? "", privacy: .public) returned \(response.statusCode); retrying in \(delay)")
                try await wait(delay)
            case .failure(let error as URLError):
                guard canRetry, FlickrRetryPolicy.isRetryable(error) else {
                    throw .transport(code: error.errorCode, description: error.localizedDescription)
                }
                try await wait(retryPolicy.delay(beforeRetry: attempt, retryAfter: nil))
            case .failure(let error):
                if error is CancellationError {
                    throw .transport(code: URLError.cancelled.rawValue, description: "The request was cancelled.")
                }
                throw .transport(code: 0, description: error.localizedDescription)
            }
            attempt += 1
        }
    }

    private func wait(_ delay: Duration) async throws(FlickrError) {
        do {
            try await sleep(delay)
        } catch {
            throw .transport(code: URLError.cancelled.rawValue, description: "The request was cancelled.")
        }
    }

    // MARK: - Sign-in

    /// Step 1 of signing in: gets a request token and returns Flickr's authorize page to show
    /// the user, for example in an `ASWebAuthenticationSession` (see ``FlickrWebAuthenticator``).
    ///
    /// Each call starts a new sign-in and discards any earlier one that never completed.
    ///
    /// - Parameters:
    ///   - callbackURL: Where Flickr sends the browser after the user approves, e.g.
    ///     `myapp://flickr-auth`. It must use a scheme your app handles.
    ///   - permission: The access to ask for.
    public func beginSignIn(callbackURL: URL, permission: FlickrPermission) async throws(FlickrError) -> URL {
        pendingSignIn = nil
        let parameters = signedParameters(url: FlickrEndpoint.requestToken, parameters: ["oauth_callback": callbackURL.absoluteString], token: nil, tokenSecret: nil)
        let request = getRequest(FlickrEndpoint.requestToken, parameters: parameters)
        let body = try await sendForSignIn(request)
        let response = FormEncoding.parameters(fromQuery: body)
        guard let token = response["oauth_token"], let secret = response["oauth_token_secret"] else {
            throw .signInFailed(message: body.isEmpty ? "Flickr did not return a request token." : body)
        }
        pendingSignIn = PendingSignIn(token: token, secret: secret, permission: permission)
        return Self.authorizeURL(requestToken: token, permission: permission)
    }

    /// Step 2 of signing in: exchanges the callback Flickr redirected to for an access token,
    /// saves the session to the token store and returns the user.
    ///
    /// The pending sign-in is cleared whether this succeeds or fails, so a retry always starts
    /// again from ``beginSignIn(callbackURL:permission:)``.
    public func completeSignIn(callbackURL: URL) async throws(FlickrError) -> FlickrUser {
        guard let pending = pendingSignIn else {
            throw .noSignInInProgress
        }
        pendingSignIn = nil

        let callback = Self.callbackParameters(callbackURL)
        if let problem = callback["oauth_problem"] {
            throw .signInFailed(message: problem)
        }
        guard let token = callback["oauth_token"], let verifier = callback["oauth_verifier"], token == pending.token else {
            throw .invalidSignInCallback(callbackURL)
        }

        let parameters = signedParameters(url: FlickrEndpoint.accessToken, parameters: ["oauth_verifier": verifier], token: pending.token, tokenSecret: pending.secret)
        let body = try await sendForSignIn(getRequest(FlickrEndpoint.accessToken, parameters: parameters))
        let response = FormEncoding.parameters(fromQuery: body)
        if let problem = response["oauth_problem"] {
            throw .signInFailed(message: problem)
        }
        guard let accessToken = response["oauth_token"],
              let accessSecret = response["oauth_token_secret"],
              let nsid = response["user_nsid"],
              let username = response["username"] else {
            throw .signInFailed(message: body.isEmpty ? "Flickr did not return an access token." : body)
        }
        let user = FlickrUser(nsid: nsid, username: username, fullName: response["fullname"] ?? "")
        let newSession = FlickrSession(accessToken: FlickrAccessToken(token: accessToken, secret: accessSecret), user: user, permission: pending.permission)
        try tokenStore.save(newSession)
        session = newSession
        return user
    }

    /// Forgets a sign-in that was begun but never completed, e.g. because the user closed the
    /// sign-in window. A signed-in session is left alone.
    public func cancelSignIn() {
        pendingSignIn = nil
    }

    /// Signs out: forgets the session and removes it from the token store. Cached responses for
    /// the account are scoped to it and simply stop being used.
    public func signOut() throws(FlickrError) {
        session = nil
        pendingSignIn = nil
        try tokenStore.delete()
    }

    /// Checks the stored token with `flickr.auth.oauth.checkToken` at launch.
    ///
    /// - Returns: The user, or `nil` when nobody is signed in.
    /// - Throws: ``FlickrError/invalidToken(code:message:)`` after signing out, when Flickr no
    ///   longer accepts the token (revoked at flickr.com/services/auth). Any other error, such as
    ///   being offline, leaves the stored session in place so the app keeps working signed in.
    @discardableResult
    public func restoreSession() async throws(FlickrError) -> FlickrUser? {
        if session == nil {
            session = try tokenStore.load()
        }
        guard let stored = session else {
            return nil
        }
        let check: CheckTokenResponse
        do {
            let data = try await restData(FlickrMethod.Auth.checkTokenName, args: ["oauth_token": stored.accessToken.token], signing: stored, maxAge: nil)
            check = try JSONDecoder().decode(CheckTokenResponse.self, from: data)
        } catch let error as FlickrError {
            if case .invalidToken = error {
                try signOut()
            }
            throw error
        } catch {
            throw .decoding(description: String(describing: error))
        }
        let user = FlickrUser(nsid: check.oauth.user.nsid, username: check.oauth.user.username, fullName: check.oauth.user.fullname ?? "")
        let refreshed = FlickrSession(accessToken: stored.accessToken, user: user, permission: FlickrPermission(rawValue: check.oauth.perms.content) ?? stored.permission)
        if refreshed != stored {
            try tokenStore.save(refreshed)
        }
        session = refreshed
        return user
    }

    private func sendForSignIn(_ request: URLRequest) async throws(FlickrError) -> String {
        do {
            let data = try await send { request }
            return String(decoding: data, as: UTF8.self)
        } catch {
            if case .http(let status) = error {
                throw .signInFailed(message: "Flickr returned HTTP \(status).")
            }
            throw error
        }
    }

    private static func callbackParameters(_ url: URL) -> [String: String] {
        guard let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery else {
            return [:]
        }
        return FormEncoding.parameters(fromQuery: query)
    }

    /// Flickr's authorize page for a request token.
    public static func authorizeURL(requestToken: String, permission: FlickrPermission) -> URL {
        var components = URLComponents(url: FlickrEndpoint.authorize, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = FormEncoding.query(from: ["oauth_token": requestToken, "perms": permission.rawValue])
        return components?.url ?? FlickrEndpoint.authorize
    }
}

private struct CheckTokenResponse: Decodable {
    struct OAuth: Decodable {
        struct User: Decodable {
            var nsid: String
            var username: String
            var fullname: String?
        }
        var perms: FlickrContent<String>
        var user: User
    }
    var oauth: OAuth
}

/// Flickr's fixed URLs.
public enum FlickrEndpoint {
    public static let rest = url("https://api.flickr.com/services/rest/")
    public static let requestToken = url("https://www.flickr.com/services/oauth/request_token")
    public static let authorize = url("https://www.flickr.com/services/oauth/authorize")
    public static let accessToken = url("https://www.flickr.com/services/oauth/access_token")

    static func url(_ string: StaticString) -> URL {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid constant URL \(string)")
        }
        return url
    }
}

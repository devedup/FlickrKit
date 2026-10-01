import Foundation
import Testing
@testable import FlickrKit

struct SignInTests {

    private let callback = URL(string: "galleryr://flickr-auth")!

    /// A transport that plays Flickr's side of the OAuth exchange.
    private func flickr(accessTokenBody: String = "fullname=Dave%20C&oauth_token=access&oauth_token_secret=access-secret&user_nsid=12345%40N01&username=dave") -> StubTransport {
        StubTransport { request, _ in
            switch request.url?.path() {
            case "/services/oauth/request_token":
                (Data("oauth_callback_confirmed=true&oauth_token=request&oauth_token_secret=request-secret".utf8), 200, [:])
            case "/services/oauth/access_token":
                (Data(accessTokenBody.utf8), 200, [:])
            default:
                (Data(), 404, [:])
            }
        }
    }

    @Test func beginReturnsTheAuthorizePageWithThePermission() async throws {
        let transport = flickr()
        let client = Fixture.client(transport: transport)
        let url = try await client.beginSignIn(callbackURL: callback, permission: .write)

        #expect(url.absoluteString == "https://www.flickr.com/services/oauth/authorize?oauth_token=request&perms=write")
        let query = try #require(transport.requests.first).queryParameters
        #expect(query["oauth_callback"] == "galleryr://flickr-auth")
        #expect(query["oauth_token"] == nil)
        #expect(query["oauth_signature"] != nil)
    }

    @Test func completeExchangesTheVerifierAndSavesTheSession() async throws {
        let transport = flickr()
        let store = InMemoryTokenStore()
        let client = Fixture.client(transport: transport, tokenStore: store)
        _ = try await client.beginSignIn(callbackURL: callback, permission: .write)
        let user = try await client.completeSignIn(callbackURL: URL(string: "galleryr://flickr-auth?oauth_token=request&oauth_verifier=verifier")!)

        #expect(user == FlickrUser(nsid: "12345@N01", username: "dave", fullName: "Dave C"))
        #expect(await client.isSignedIn)
        let saved = try #require(try store.load())
        #expect(saved.accessToken == FlickrAccessToken(token: "access", secret: "access-secret"))
        #expect(saved.permission == .write)

        let exchange = try #require(transport.requests.last).queryParameters
        #expect(exchange["oauth_token"] == "request")
        #expect(exchange["oauth_verifier"] == "verifier")
    }

    @Test(arguments: [
        "galleryr://flickr-auth",
        "galleryr://flickr-auth?oauth_token=request",
        "galleryr://flickr-auth?oauth_verifier=verifier",
        "galleryr://flickr-auth?oauth_token=someone-else&oauth_verifier=verifier"
    ])
    func incompleteCallbacksThrowAndClearThePendingSignIn(callbackString: String) async throws {
        let client = Fixture.client(transport: flickr())
        _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        let url = URL(string: callbackString)!
        await #expect(throws: FlickrError.invalidSignInCallback(url)) {
            try await client.completeSignIn(callbackURL: url)
        }
        await #expect(throws: FlickrError.noSignInInProgress) {
            try await client.completeSignIn(callbackURL: URL(string: "galleryr://flickr-auth?oauth_token=request&oauth_verifier=v")!)
        }
    }

    @Test func oauthProblemFromFlickrIsReported() async throws {
        let client = Fixture.client(transport: flickr(accessTokenBody: "oauth_problem=token_rejected"))
        _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        await #expect(throws: FlickrError.signInFailed(message: "token_rejected")) {
            try await client.completeSignIn(callbackURL: URL(string: "galleryr://flickr-auth?oauth_token=request&oauth_verifier=v")!)
        }
        #expect(await client.isSignedIn == false)
    }

    @Test func incompleteAccessTokenResponseFails() async throws {
        let client = Fixture.client(transport: flickr(accessTokenBody: "oauth_token=access"))
        _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        await #expect(throws: FlickrError.signInFailed(message: "oauth_token=access")) {
            try await client.completeSignIn(callbackURL: URL(string: "galleryr://flickr-auth?oauth_token=request&oauth_verifier=v")!)
        }
    }

    @Test func cancelForgetsThePendingSignInSoTheNextBeginStartsFresh() async throws {
        let transport = flickr()
        let client = Fixture.client(transport: transport)
        _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        await client.cancelSignIn()
        await #expect(throws: FlickrError.noSignInInProgress) {
            try await client.completeSignIn(callbackURL: URL(string: "galleryr://flickr-auth?oauth_token=request&oauth_verifier=v")!)
        }
        _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        #expect(transport.requests.filter { $0.url?.path() == "/services/oauth/request_token" }.count == 2)
    }

    @Test func missingRequestTokenIsAnError() async {
        let transport = StubTransport { _, _ in (Data("oauth_problem=consumer_key_unknown".utf8), 200, [:]) }
        let client = Fixture.client(transport: transport)
        await #expect(throws: FlickrError.signInFailed(message: "oauth_problem=consumer_key_unknown")) {
            _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        }
    }

    @Test func httpFailureDuringSignInIsReportedAsSignInFailure() async {
        let transport = StubTransport { _, _ in (Data(), 401, [:]) }
        let client = Fixture.client(transport: transport)
        await #expect(throws: FlickrError.signInFailed(message: "Flickr returned HTTP 401.")) {
            _ = try await client.beginSignIn(callbackURL: callback, permission: .read)
        }
    }

    @Test func signOutForgetsAndDeletesTheSession() async throws {
        let store = InMemoryTokenStore(session: Fixture.session())
        let client = Fixture.client(transport: flickr(), tokenStore: store)
        #expect(await client.isSignedIn)
        try await client.signOut()
        #expect(await client.isSignedIn == false)
        #expect(try store.load() == nil)
    }
}

struct RestoreSessionTests {

    private let checkTokenOK = #"{"oauth":{"token":{"_content":"access-token"},"perms":{"_content":"delete"},"user":{"nsid":"12345@N01","username":"dave","fullname":"Dave C"}},"stat":"ok"}"#

    @Test func nobodySignedInReturnsNil() async throws {
        let transport = StubTransport(json: checkTokenOK)
        let client = Fixture.client(transport: transport)
        #expect(try await client.restoreSession() == nil)
        #expect(transport.requests.isEmpty)
    }

    @Test func validTokenFillsInTheUserAndPermission() async throws {
        let store = InMemoryTokenStore(session: Fixture.session(permission: nil, user: nil))
        let transport = StubTransport(json: checkTokenOK)
        let client = Fixture.client(transport: transport, tokenStore: store)
        let user = try await client.restoreSession()

        #expect(user == Fixture.signedInUser)
        #expect(try store.load()?.permission == .delete)
        #expect(try store.load()?.user == Fixture.signedInUser)
        let query = try #require(transport.requests.first).queryParameters
        #expect(query["method"] == "flickr.auth.oauth.checkToken")
        #expect(query["oauth_token"] == "access-token")
    }

    @Test func revokedTokenSignsOut() async throws {
        let store = InMemoryTokenStore(session: Fixture.session())
        let transport = StubTransport(json: #"{"stat":"fail","code":98,"message":"Invalid token"}"#)
        let client = Fixture.client(transport: transport, tokenStore: store)
        await #expect(throws: FlickrError.invalidToken(code: 98, message: "Invalid token")) {
            try await client.restoreSession()
        }
        #expect(await client.isSignedIn == false)
        #expect(try store.load() == nil)
    }

    @Test func offlineKeepsTheStoredSession() async throws {
        let store = InMemoryTokenStore(session: Fixture.session())
        let transport = StubTransport { _, _ in throw URLError(.notConnectedToInternet) }
        let client = Fixture.client(transport: transport, tokenStore: store)
        await #expect(throws: FlickrError.self) {
            try await client.restoreSession()
        }
        #expect(await client.isSignedIn)
        #expect(try store.load() != nil)
    }
}

struct LegacyTokenMigrationTests {

    private func defaults() -> UserDefaults {
        let name = "FlickrKitTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            Issue.record("Couldn't create a defaults suite")
            return .standard
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func movesThe1xTokenAndRemovesIt() throws {
        let defaults = defaults()
        defaults.set("old-token", forKey: FlickrLegacyTokenKeys.token)
        defaults.set("old-secret", forKey: FlickrLegacyTokenKeys.secret)
        let store = InMemoryTokenStore()

        #expect(try store.migrateLegacyToken(from: defaults))
        #expect(try store.load()?.accessToken == FlickrAccessToken(token: "old-token", secret: "old-secret"))
        #expect(defaults.string(forKey: FlickrLegacyTokenKeys.token) == nil)
        #expect(try store.migrateLegacyToken(from: defaults) == false)
    }

    @Test func leavesAnExistingSessionAlone() throws {
        let defaults = defaults()
        defaults.set("old-token", forKey: FlickrLegacyTokenKeys.token)
        defaults.set("old-secret", forKey: FlickrLegacyTokenKeys.secret)
        let store = InMemoryTokenStore(session: Fixture.session())

        #expect(try store.migrateLegacyToken(from: defaults) == false)
        #expect(try store.load()?.accessToken.token == "access-token")
    }
}

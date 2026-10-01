import Foundation
import os
import Testing
@testable import FlickrKit

private struct Echo: Decodable, Sendable {
    var stat: String
    var value: Int?
}

struct FlickrClientRequestTests {

    @Test func anonymousCallsSendTheAPIKeyAndNoOAuth() async throws {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, session: Fixture.session())
        let _: Echo = try await client.call("flickr.photos.getRecent", args: ["per_page": "10"], auth: .anonymous)

        let request = try #require(transport.requests.first)
        let query = request.queryParameters
        #expect(request.url?.host() == "api.flickr.com")
        #expect(request.httpMethod == "GET")
        #expect(query["method"] == "flickr.photos.getRecent")
        #expect(query["format"] == "json")
        #expect(query["nojsoncallback"] == "1")
        #expect(query["per_page"] == "10")
        #expect(query["api_key"] == "api-key")
        #expect(query["oauth_signature"] == nil)
    }

    @Test func signedCallsCarryAValidOAuthSignature() async throws {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, session: Fixture.session())
        let _: Echo = try await client.call("flickr.photos.search", args: ["text": "a+b c"], auth: .ifSignedIn)

        let query = try #require(transport.requests.first).queryParameters
        #expect(query["oauth_token"] == "access-token")
        #expect(query["oauth_consumer_key"] == "api-key")
        #expect(query["oauth_nonce"] == "nonce")
        #expect(query["oauth_timestamp"] == "1700000000")
        #expect(query["text"] == "a+b c")
        #expect(query["api_key"] == nil)

        var unsigned = query
        let signature = unsigned.removeValue(forKey: "oauth_signature")
        let base = OAuthSigner.signatureBaseString(httpMethod: "GET", url: FlickrEndpoint.rest, parameters: unsigned)
        #expect(signature == OAuthSigner.signature(baseString: base, consumerSecret: "shared-secret", tokenSecret: "access-secret"))
    }

    @Test func plusIsSentEncodedSoFlickrDoesNotReadASpace() async throws {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport)
        let _: Echo = try await client.call("flickr.photos.search", args: ["text": "c++"], auth: .anonymous)
        #expect(transport.requests.first?.url?.query(percentEncoded: true)?.contains("text=c%2B%2B") == true)
    }

    @Test func ifSignedInFallsBackToAnonymous() async throws {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport)
        let _: Echo = try await client.call("flickr.photos.getRecent", auth: .ifSignedIn)
        #expect(transport.requests.first?.queryParameters["api_key"] == "api-key")
    }

    @Test func requiredAuthWithoutASessionThrowsBeforeSending() async {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport)
        await #expect(throws: FlickrError.notSignedIn) {
            let _: Echo = try await client.call(FlickrMethod.Favorites.add(photoID: "1"))
        }
        #expect(transport.requests.isEmpty)
    }

    @Test func requiredAuthChecksTheGrantedPermission() async {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, session: Fixture.session(permission: .read))
        await #expect(throws: FlickrError.insufficientPermission(required: .write, granted: .read)) {
            let _: Echo = try await client.call(FlickrMethod.Photos.Comments.addComment(photoID: "1", text: "Nice"))
        }
    }

    @Test func unknownPermissionIsLetThroughForFlickrToJudge() async throws {
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, session: Fixture.session(permission: nil))
        let _: Echo = try await client.call(FlickrMethod.Favorites.add(photoID: "1"))
        #expect(transport.requests.count == 1)
    }
}

struct FlickrClientResponseTests {

    @Test func decodesTheRequestedType() async throws {
        let client = Fixture.client(transport: StubTransport(json: #"{"stat":"ok","value":7}"#))
        let echo: Echo = try await client.call("flickr.test.echo", auth: .anonymous)
        #expect(echo.value == 7)
    }

    @Test func statFailBecomesAnAPIError() async {
        let client = Fixture.client(transport: StubTransport(json: #"{"stat":"fail","code":1,"message":"Photo not found"}"#))
        await #expect(throws: FlickrError.api(code: 1, message: "Photo not found")) {
            let _: Echo = try await client.call("flickr.photos.getInfo", auth: .anonymous)
        }
    }

    @Test func codesAsStringsAreAccepted() async {
        let client = Fixture.client(transport: StubTransport(json: #"{"stat":"fail","code":"2","message":"Unknown user"}"#))
        await #expect(throws: FlickrError.api(code: 2, message: "Unknown user")) {
            let _: Echo = try await client.call("flickr.people.getInfo", auth: .anonymous)
        }
    }

    @Test(arguments: [98, 99])
    func authCodesBecomeInvalidToken(code: Int) async {
        let client = Fixture.client(transport: StubTransport(json: #"{"stat":"fail","code":\#(code),"message":"Invalid auth token"}"#), session: Fixture.session())
        do {
            let _: Echo = try await client.call("flickr.favorites.getList")
            Issue.record("Expected an error")
        } catch {
            #expect(error == .invalidToken(code: code, message: "Invalid auth token"))
            #expect(error.requiresSignIn)
        }
    }

    @Test func nonJSONIsADecodingError() async {
        let client = Fixture.client(transport: StubTransport(json: "<html>"))
        await #expect {
            let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        } throws: { error in
            if case .decoding = error as? FlickrError { true } else { false }
        }
    }

    @Test func wrongShapeIsADecodingError() async {
        let client = Fixture.client(transport: StubTransport(json: #"{"stat":"ok","value":"seven"}"#))
        await #expect {
            let _: Echo = try await client.call("flickr.test.echo", auth: .anonymous)
        } throws: { error in
            if case .decoding = error as? FlickrError { true } else { false }
        }
    }

    @Test func emptyBodyIsAnError() async {
        let client = Fixture.client(transport: StubTransport { _, _ in (Data(), 200, [:]) })
        await #expect(throws: FlickrError.emptyResponse) {
            let _: Echo = try await client.call("flickr.test.echo", auth: .anonymous)
        }
    }
}

struct FlickrClientRetryTests {

    @Test func serverErrorsAreRetriedWithExponentialBackOff() async throws {
        let transport = StubTransport { _, index in
            index < 2 ? (Data(), 503, [:]) : (Data(Fixture.ok.utf8), 200, [:])
        }
        let sleep = SleepRecorder()
        let client = Fixture.client(transport: transport, sleep: sleep)
        let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        #expect(transport.requests.count == 3)
        #expect(sleep.recorded == [.seconds(1), .seconds(2)])
    }

    @Test func retryAfterIsHonouredAndCapped() async throws {
        let transport = StubTransport { _, index in
            switch index {
            case 0: (Data(), 429, ["Retry-After": "5"])
            case 1: (Data(), 429, ["Retry-After": "600"])
            default: (Data(Fixture.ok.utf8), 200, [:])
            }
        }
        let sleep = SleepRecorder()
        let client = Fixture.client(transport: transport, sleep: sleep)
        let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        #expect(sleep.recorded == [.seconds(5), .seconds(30)])
    }

    @Test func givesUpAfterMaxRetries() async {
        let transport = StubTransport { _, _ in (Data(), 500, [:]) }
        let client = Fixture.client(transport: transport, retryPolicy: FlickrRetryPolicy(maxRetries: 2))
        await #expect(throws: FlickrError.http(status: 500)) {
            let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        }
        #expect(transport.requests.count == 3)
    }

    @Test func clientErrorsAreNotRetried() async {
        let transport = StubTransport { _, _ in (Data(), 404, [:]) }
        let client = Fixture.client(transport: transport)
        await #expect(throws: FlickrError.http(status: 404)) {
            let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        }
        #expect(transport.requests.count == 1)
    }

    @Test func droppedConnectionsAreRetriedAndOfflineIsNot() async {
        let dropped = StubTransport { _, index in
            if index == 0 { throw URLError(.networkConnectionLost) }
            return (Data(Fixture.ok.utf8), 200, [:])
        }
        let client = Fixture.client(transport: dropped)
        await #expect(throws: Never.self) {
            let _: Echo = try await client.call("flickr.photos.getRecent", auth: .anonymous)
        }

        let offline = StubTransport { _, _ in throw URLError(.notConnectedToInternet) }
        let offlineClient = Fixture.client(transport: offline)
        await #expect {
            let _: Echo = try await offlineClient.call("flickr.photos.getRecent", auth: .anonymous)
        } throws: { error in
            if case .transport(let code, _) = error as? FlickrError { code == URLError.notConnectedToInternet.rawValue } else { false }
        }
        #expect(offline.requests.count == 1)
    }

    @Test func eachRetryIsSignedAfresh() async throws {
        let nonces = NonceCounter()
        let transport = StubTransport { _, index in
            index == 0 ? (Data(), 502, [:]) : (Data(Fixture.ok.utf8), 200, [:])
        }
        let client = FlickrClient(
            apiKey: "k", sharedSecret: "s",
            tokenStore: InMemoryTokenStore(session: Fixture.session()),
            transport: transport, cache: InMemoryResponseCache(),
            sleep: SleepRecorder().sleep, makeNonce: { nonces.next() }
        )
        let _: Echo = try await client.call("flickr.favorites.getList")
        let sent = transport.requests.map { $0.queryParameters["oauth_nonce"] }
        #expect(sent == ["1", "2"])
    }

    @Test func noMoreThanTheConcurrencyCapAreInFlight() async throws {
        let transport = StubTransport { _, _ in
            try await Task.sleep(for: .milliseconds(20))
            return (Data(Fixture.ok.utf8), 200, [:])
        }
        let client = Fixture.client(transport: transport, maxConcurrentRequests: 4)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<12 {
                group.addTask {
                    let _: Echo = try await client.call("flickr.photos.getRecent", args: ["page": String(index)], auth: .anonymous)
                }
            }
            try await group.waitForAll()
        }
        #expect(transport.requests.count == 12)
        #expect(transport.maxInFlight <= 4)
        #expect(transport.maxInFlight > 1)
    }
}

private final class NonceCounter: Sendable {
    private let count = OSAllocatedUnfairLock(initialState: 0)
    func next() -> String { String(count.withLock { $0 += 1; return $0 }) }
}

struct FlickrClientCacheTests {

    @Test func aFreshCachedResponseSkipsTheNetwork() async throws {
        let transport = StubTransport(json: #"{"stat":"ok","value":1}"#)
        let client = Fixture.client(transport: transport)
        let request = FlickrMethod.Photos.getInfo(photoID: "42")
        let first: Echo = try await client.call(request)
        let second: Echo = try await client.call(request)
        #expect(first.value == 1 && second.value == 1)
        #expect(transport.requests.count == 1)
    }

    @Test func noMaxAgeAlwaysFetchesAndEvicts() async throws {
        let cache = InMemoryResponseCache()
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, cache: cache)
        let cached = FlickrMethod.Favorites.getList(userID: "1").maxAge(.seconds(60))
        let _: Echo = try await client.call(cached)
        #expect(await cache.count == 1)
        let _: Echo = try await client.call(cached.maxAge(nil))
        #expect(await cache.count == 0)
        #expect(transport.requests.count == 2)
    }

    @Test func failuresAreNotCached() async throws {
        let transport = StubTransport { _, index in
            index == 0
                ? (Data(#"{"stat":"fail","code":105,"message":"Service unavailable"}"#.utf8), 200, [:])
                : (Data(Fixture.ok.utf8), 200, [:])
        }
        let client = Fixture.client(transport: transport)
        let request = FlickrMethod.Photos.getRecent()
        await #expect(throws: FlickrError.self) {
            let _: Echo = try await client.call(request)
        }
        let _: Echo = try await client.call(request)
        #expect(transport.requests.count == 2)
    }

    @Test func signedResponsesAreCachedPerUser() async throws {
        let cache = InMemoryResponseCache()
        let store = InMemoryTokenStore(session: Fixture.session())
        let transport = StubTransport(json: Fixture.ok)
        let client = Fixture.client(transport: transport, cache: cache, tokenStore: store)
        let request = FlickrMethod.Photos.getInfo(photoID: "42")
        let _: Echo = try await client.call(request)

        let other = FlickrUser(nsid: "999@N01", username: "other", fullName: "")
        try store.save(Fixture.session(user: other))
        let otherClient = Fixture.client(transport: transport, cache: cache, tokenStore: store)
        let _: Echo = try await otherClient.call(request)
        #expect(transport.requests.count == 2)
    }

    @Test func cacheKeysIgnoreArgumentOrderAndRespectScope() {
        let a = FlickrCacheKey.make(method: "m", arguments: ["a": "1", "b": "2"], scope: nil)
        let b = FlickrCacheKey.make(method: "m", arguments: ["b": "2", "a": "1"], scope: nil)
        let scoped = FlickrCacheKey.make(method: "m", arguments: ["a": "1", "b": "2"], scope: "1@N01")
        #expect(a == b)
        #expect(a != scoped)
        #expect(a.count == 64)
    }

    @Test func inMemoryEntriesExpire() async {
        let clock = Clock()
        let cache = InMemoryResponseCache(now: { clock.now })
        await cache.store(Data("x".utf8), forKey: "k")
        #expect(await cache.data(forKey: "k", maxAge: .seconds(60)) != nil)
        clock.advance(by: 61)
        #expect(await cache.data(forKey: "k", maxAge: .seconds(60)) == nil)
    }

    @Test func diskCacheStoresExpiresAndTrims() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "FlickrKitTests-\(UUID().uuidString)")
        defer {
            do { try FileManager.default.removeItem(at: directory) } catch {}
        }
        let clock = Clock()
        let cache = DiskResponseCache(directory: directory, byteLimit: 1000, now: { clock.now })
        let key = FlickrCacheKey.make(method: "m", arguments: [:], scope: nil)
        await cache.store(Data("hello".utf8), forKey: key)
        #expect(await cache.data(forKey: key, maxAge: .seconds(60)) == Data("hello".utf8))
        clock.advance(by: 120)
        #expect(await cache.data(forKey: key, maxAge: .seconds(60)) == nil)

        await cache.store(Data("a/b key".utf8), forKey: "not/a hex key")
        #expect(await cache.data(forKey: "not/a hex key", maxAge: .seconds(60)) == Data("a/b key".utf8))

        for index in 0..<5 {
            clock.advance(by: 1)
            await cache.store(Data(repeating: 0, count: 300), forKey: String(format: "%064x", index))
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
        let total = try files.reduce(0) { sum, name in
            let size = try FileManager.default.attributesOfItem(atPath: directory.appending(path: name).path(percentEncoded: false))[.size] as? Int ?? 0
            return sum + size
        }
        #expect(total <= 1000)
        #expect(await cache.data(forKey: String(format: "%064x", 4), maxAge: .seconds(600)) != nil)

        await cache.removeAll()
        #expect(await cache.data(forKey: String(format: "%064x", 4), maxAge: .seconds(600)) == nil)
    }
}

/// A settable clock for cache tests.
final class Clock: Sendable {
    private let seconds = OSAllocatedUnfairLock<TimeInterval>(initialState: 1_700_000_000)
    var now: Date { Date(timeIntervalSince1970: seconds.withLock { $0 }) }
    func advance(by interval: TimeInterval) { seconds.withLock { $0 += interval } }
}

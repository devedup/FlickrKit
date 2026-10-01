import Foundation
import os
@testable import FlickrKit

/// A transport that answers from a handler and records every request.
final class StubTransport: FlickrTransport {

    typealias Handler = @Sendable (URLRequest, Int) async throws -> (Data, Int, [String: String])

    private let handler: Handler
    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var requests: [URLRequest] = []
        var inFlight = 0
        var maxInFlight = 0
    }

    /// `handler` gets the request and its 0-based index, and returns body, status and headers.
    init(handler: @escaping Handler) {
        self.handler = handler
    }

    /// Always answers with `json` and status 200.
    convenience init(json: String) {
        self.init { _, _ in (Data(json.utf8), 200, [:]) }
    }

    var requests: [URLRequest] { state.withLock { $0.requests } }
    var maxInFlight: Int { state.withLock { $0.maxInFlight } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let index = state.withLock { state in
            state.requests.append(request)
            state.inFlight += 1
            state.maxInFlight = max(state.maxInFlight, state.inFlight)
            return state.requests.count - 1
        }
        defer { state.withLock { $0.inFlight -= 1 } }
        let (data, status, headers) = try await handler(request, index)
        let url = request.url ?? URL(fileURLWithPath: "/")
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        return (data, response)
    }
}

/// Records the delays the client sleeps for, without sleeping.
final class SleepRecorder: Sendable {
    private let delays = OSAllocatedUnfairLock<[Duration]>(initialState: [])

    var recorded: [Duration] { delays.withLock { $0 } }

    var sleep: @Sendable (Duration) async throws -> Void {
        { [delays] duration in delays.withLock { $0.append(duration) } }
    }
}

extension URLRequest {
    /// The decoded query parameters.
    var queryParameters: [String: String] {
        guard let url, let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery else {
            return [:]
        }
        return FormEncoding.parameters(fromQuery: query)
    }
}

enum Fixture {
    static let signedInUser = FlickrUser(nsid: "12345@N01", username: "dave", fullName: "Dave C")

    static func session(permission: FlickrPermission? = .write, user: FlickrUser? = signedInUser) -> FlickrSession {
        FlickrSession(accessToken: FlickrAccessToken(token: "access-token", secret: "access-secret"), user: user, permission: permission)
    }

    static func client(
        transport: StubTransport,
        session: FlickrSession? = nil,
        cache: any FlickrResponseCache = InMemoryResponseCache(),
        tokenStore: InMemoryTokenStore? = nil,
        sleep: SleepRecorder = SleepRecorder(),
        retryPolicy: FlickrRetryPolicy = .default,
        maxConcurrentRequests: Int = 4
    ) -> FlickrClient {
        FlickrClient(
            apiKey: "api-key",
            sharedSecret: "shared-secret",
            tokenStore: tokenStore ?? InMemoryTokenStore(session: session),
            transport: transport,
            cache: cache,
            retryPolicy: retryPolicy,
            maxConcurrentRequests: maxConcurrentRequests,
            sleep: sleep.sleep,
            now: { Date(timeIntervalSince1970: 1_700_000_000) },
            makeNonce: { "nonce" }
        )
    }

    static let ok = #"{"stat":"ok"}"#
}

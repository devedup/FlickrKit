import Foundation

/// Sends one HTTP request. `URLSession` is the default; tests supply a stub.
public protocol FlickrTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: FlickrTransport {
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}

/// When to retry a request that failed with a rate limit or a server error.
public struct FlickrRetryPolicy: Sendable {

    /// Retries after the first attempt. `0` turns retrying off.
    public var maxRetries: Int
    /// The wait before the first retry. Each later retry doubles it.
    public var initialDelay: Duration
    /// No single wait is longer than this, including a server's `Retry-After`.
    public var maxDelay: Duration
    /// HTTP statuses that are retried.
    public var retryableStatuses: Set<Int>

    public init(
        maxRetries: Int = 3,
        initialDelay: Duration = .seconds(1),
        maxDelay: Duration = .seconds(30),
        retryableStatuses: Set<Int> = [429, 500, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.retryableStatuses = retryableStatuses
    }

    public static let `default` = FlickrRetryPolicy()
    public static let none = FlickrRetryPolicy(maxRetries: 0)

    /// The wait before retry number `attempt` (0-based), honouring a `Retry-After` in seconds.
    func delay(beforeRetry attempt: Int, retryAfter: String?) -> Duration {
        if let retryAfter, let seconds = Int(retryAfter.trimmingCharacters(in: .whitespaces)), seconds >= 0 {
            return min(.seconds(seconds), maxDelay)
        }
        let factor = 1 << min(attempt, 30)
        return min(initialDelay * factor, maxDelay)
    }

    static func isRetryable(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost: true
        default: false
        }
    }
}

/// Limits how many requests are in flight at once. Waiters are served first come, first served.
actor AsyncSemaphore {

    private var available: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) {
        available = max(1, value)
    }

    func wait() async {
        if available > 0 {
            available -= 1
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func signal() {
        if waiters.isEmpty {
            available += 1
        } else {
            waiters.removeFirst().resume()
        }
    }
}

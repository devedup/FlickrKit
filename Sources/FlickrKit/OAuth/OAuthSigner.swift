import CryptoKit
import Foundation

/// Signs requests with OAuth 1.0a HMAC-SHA1 (RFC 5849), the scheme Flickr uses for every
/// authenticated call and for the sign-in token exchanges.
///
/// The signer is a value with no hidden state: the nonce and timestamp are passed in, so a
/// signature can be reproduced exactly in tests.
public struct OAuthSigner: Sendable {

    /// The app's Flickr API key, sent as `oauth_consumer_key`.
    public let consumerKey: String
    /// The app's Flickr shared secret.
    public let consumerSecret: String

    public init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }

    /// Returns `parameters` with the `oauth_*` protocol parameters and `oauth_signature` added.
    ///
    /// - Parameters:
    ///   - httpMethod: `GET` or `POST`, any case.
    ///   - url: The request URL without its query. Query parameters belong in `parameters`.
    ///   - parameters: The request's own parameters (query and form body).
    ///   - token: The request or access token, if there is one.
    ///   - tokenSecret: The secret that goes with `token`.
    ///   - nonce: A value unique to this request.
    ///   - timestamp: Seconds since 1970.
    public func signedParameters(
        httpMethod: String,
        url: URL,
        parameters: [String: String],
        token: String? = nil,
        tokenSecret: String? = nil,
        nonce: String,
        timestamp: Int
    ) -> [String: String] {
        var all = parameters
        all["oauth_consumer_key"] = consumerKey
        all["oauth_nonce"] = nonce
        all["oauth_signature_method"] = "HMAC-SHA1"
        all["oauth_timestamp"] = String(timestamp)
        all["oauth_version"] = "1.0"
        if let token {
            all["oauth_token"] = token
        }
        let base = Self.signatureBaseString(httpMethod: httpMethod, url: url, parameters: all)
        all["oauth_signature"] = Self.signature(baseString: base, consumerSecret: consumerSecret, tokenSecret: tokenSecret)
        return all
    }

    /// The signature base string from RFC 5849 §3.4.1: method, base URL and the normalised
    /// parameters, each percent-encoded and joined with `&`.
    public static func signatureBaseString(httpMethod: String, url: URL, parameters: [String: String]) -> String {
        [
            httpMethod.uppercased(),
            baseURLString(for: url).oauthPercentEncoded,
            FormEncoding.query(from: parameters).oauthPercentEncoded
        ].joined(separator: "&")
    }

    /// HMAC-SHA1 of `baseString`, keyed with `consumerSecret&tokenSecret`, base64 encoded.
    public static func signature(baseString: String, consumerSecret: String, tokenSecret: String?) -> String {
        let key = consumerSecret.oauthPercentEncoded + "&" + (tokenSecret ?? "").oauthPercentEncoded
        let mac = HMAC<Insecure.SHA1>.authenticationCode(
            for: Data(baseString.utf8),
            using: SymmetricKey(data: Data(key.utf8))
        )
        return Data(mac).base64EncodedString()
    }

    /// RFC 5849 §3.4.1.2: lower-case scheme and host, default ports dropped, no query or fragment.
    static func baseURLString(for url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        if (components.scheme == "http" && components.port == 80) || (components.scheme == "https" && components.port == 443) {
            components.port = nil
        }
        components.query = nil
        components.fragment = nil
        return components.string ?? url.absoluteString
    }
}

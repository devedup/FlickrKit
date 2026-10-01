import Foundation

extension String {

    /// The string percent-encoded as RFC 3986 and OAuth 1.0a (RFC 5849 §3.6) require.
    ///
    /// Only the unreserved characters `A–Z a–z 0–9 - . _ ~` pass through; every other byte of the
    /// UTF-8 form becomes `%XX` with upper-case hex. Foundation's character sets are not used
    /// because `CharacterSet.alphanumerics` includes non-ASCII letters, and `URLComponents` leaves
    /// `+` unescaped, which Flickr then reads as a space.
    var oauthPercentEncoded: String {
        var encoded = ""
        encoded.reserveCapacity(utf8.count)
        for byte in utf8 {
            if byte.isUnreservedASCII {
                encoded.unicodeScalars.append(Unicode.Scalar(byte))
            } else {
                encoded += "%"
                encoded += String(byte, radix: 16, uppercase: true).leftPadded(to: 2)
            }
        }
        return encoded
    }

    private func leftPadded(to length: Int) -> String {
        count >= length ? self : String(repeating: "0", count: length - count) + self
    }
}

private extension UInt8 {
    var isUnreservedASCII: Bool {
        switch self {
        case UInt8(ascii: "A")...UInt8(ascii: "Z"),
             UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "_"), UInt8(ascii: "~"):
            true
        default:
            false
        }
    }
}

/// Query-string helpers shared by request building and the OAuth responses.
enum FormEncoding {

    /// `key=value` pairs, RFC 3986 encoded and sorted by key so the output is deterministic.
    static func query(from parameters: [String: String]) -> String {
        let encoded: [(key: String, value: String)] = parameters.map { pair in
            (key: pair.key.oauthPercentEncoded, value: pair.value.oauthPercentEncoded)
        }
        let sorted = encoded.sorted { lhs, rhs in
            lhs.key == rhs.key ? lhs.value < rhs.value : lhs.key < rhs.key
        }
        return sorted.map { pair in pair.key + "=" + pair.value }.joined(separator: "&")
    }

    /// Parses `a=1&b=2` into a dictionary, percent-decoding keys and values.
    ///
    /// Pieces without exactly one `=` are skipped, and a value whose escapes are malformed is kept
    /// as sent, so a bad response never crashes the parse (the 1.x fix for galleryr 2.4.0).
    static func parameters(fromQuery query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.split(separator: "&", omittingEmptySubsequences: true) {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let value = String(parts[1])
            result[key.removingPercentEncoding ?? key] = value.removingPercentEncoding ?? value
        }
        return result
    }
}

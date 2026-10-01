import Foundation

/// The `stat`, `code` and `message` every Flickr JSON response carries.
public struct FlickrStatus: Decodable, Sendable {
    /// `ok` or `fail`.
    public var stat: String?
    public var code: Int?
    public var message: String?

    public var isFailure: Bool { stat == "fail" }

    enum CodingKeys: String, CodingKey {
        case stat, code, message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stat = try container.decodeIfPresent(String.self, forKey: .stat)
        code = try container.decodeFlickrIntIfPresent(forKey: .code)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}

/// Flickr wraps many text values as `{"_content": "..."}`.
public struct FlickrContent<Value: Decodable & Sendable>: Decodable, Sendable {
    public var content: Value

    enum CodingKeys: String, CodingKey {
        case content = "_content"
    }
}

extension FlickrContent: Equatable where Value: Equatable {}
extension FlickrContent: Hashable where Value: Hashable {}

/// Lenient decoding for Flickr's numbers and flags, which arrive as JSON numbers from some
/// methods and as strings (`"1"`, `"3.5"`, `""`) from others, or from older responses.
extension KeyedDecodingContainer {

    public func decodeFlickrIntIfPresent(forKey key: Key) throws -> Int? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(exactly: value.rounded())
        }
        let text = try decode(String.self, forKey: key).trimmingCharacters(in: .whitespaces)
        return Int(text) ?? Double(text).flatMap { Int(exactly: $0.rounded()) }
    }

    public func decodeFlickrDoubleIfPresent(forKey key: Key) throws -> Double? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        return Double(try decode(String.self, forKey: key).trimmingCharacters(in: .whitespaces))
    }

    /// `true` for `1`, `"1"`, `true` and `"true"`.
    public func decodeFlickrBoolIfPresent(forKey key: Key) throws -> Bool? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let value = try? decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return value != 0
        }
        switch try decode(String.self, forKey: key).lowercased() {
        case "1", "true", "yes": return true
        case "0", "false", "no", "": return false
        default: return nil
        }
    }

    /// A string, accepting a number in its place (e.g. `farm`, `server`, `iconserver`).
    public func decodeFlickrStringIfPresent(forKey key: Key) throws -> String? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        return String(try decode(Double.self, forKey: key))
    }
}

import Foundation

/// One Flickr API call: the method name, its arguments, how it is authenticated and how long its
/// response may be cached.
///
/// Build one with the typed factories under ``FlickrMethod`` (e.g.
/// `FlickrMethod.Photos.search(...)`), adjust it with the modifiers below, and pass it to
/// ``FlickrClient/call(_:as:)`` with the `Decodable` type you want back. FlickrKit doesn't
/// define response models; your app decodes the JSON however it likes.
public struct FlickrRequest: Sendable, Hashable {

    /// The API method, e.g. `flickr.photos.search`.
    public var method: String
    /// The method's arguments, already in Flickr's string form.
    public var arguments: [String: String]
    public var auth: FlickrAuthMode
    /// How long a cached response stays usable. `nil` never caches, and removes any response
    /// cached earlier, which is what writes and "always fresh" reads want.
    public var maxAge: Duration?

    public init(method: String, arguments: [String: String] = [:], auth: FlickrAuthMode = .ifSignedIn, maxAge: Duration? = nil) {
        self.method = method
        self.arguments = arguments
        self.auth = auth
        self.maxAge = maxAge
    }

    /// Sets an argument; `nil` removes it.
    public func setting(_ key: String, _ value: String?) -> FlickrRequest {
        var copy = self
        copy.arguments[key] = value
        return copy
    }

    /// The `page` and `per_page` arguments. Flickr caps `per_page` at 500, so larger values
    /// are clamped (asking for more silently returns the wrong page).
    public func page(_ page: Int, perPage: Int) -> FlickrRequest {
        setting("page", String(max(1, page)))
            .setting("per_page", String(min(max(1, perPage), FlickrRequest.maxPerPage)))
    }

    /// The `extras` argument, e.g. `["url_m", "owner_name", "o_dims"]`.
    public func extras(_ extras: [String]) -> FlickrRequest {
        setting("extras", extras.isEmpty ? nil : extras.joined(separator: ","))
    }

    public func auth(_ auth: FlickrAuthMode) -> FlickrRequest {
        var copy = self
        copy.auth = auth
        return copy
    }

    public func maxAge(_ maxAge: Duration?) -> FlickrRequest {
        var copy = self
        copy.maxAge = maxAge
        return copy
    }

    /// The most results Flickr returns per page.
    public static let maxPerPage = 500
}

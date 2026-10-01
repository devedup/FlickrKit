import Foundation

/// Every image size Flickr serves for a photo, as listed by `flickr.photos.getSizes`.
///
/// Only some of these can be built from a photo's `secret`; see ``staticSize``.
public enum FlickrPhotoSize: String, Sendable, Codable, CaseIterable, Comparable {
    case square75
    case largeSquare150
    case thumbnail100
    case small240
    case small320
    case small400
    case medium500
    case medium640
    case medium800
    case large1024
    case large1600
    case large2048
    case extraLarge3072
    case extraLarge4096
    case extraLarge5120
    case extraLarge6144
    case original

    /// The size's label in `flickr.photos.getSizes`.
    public var label: String {
        switch self {
        case .square75: "Square"
        case .largeSquare150: "Large Square"
        case .thumbnail100: "Thumbnail"
        case .small240: "Small"
        case .small320: "Small 320"
        case .small400: "Small 400"
        case .medium500: "Medium"
        case .medium640: "Medium 640"
        case .medium800: "Medium 800"
        case .large1024: "Large"
        case .large1600: "Large 1600"
        case .large2048: "Large 2048"
        case .extraLarge3072: "X-Large 3K"
        case .extraLarge4096: "X-Large 4K"
        case .extraLarge5120: "X-Large 5K"
        case .extraLarge6144: "X-Large 6K"
        case .original: "Original"
        }
    }

    /// The size for a `flickr.photos.getSizes` label, or `nil` for video and unknown labels.
    /// Accepts both the current "X-Large 3K" labels and the older "Extra Large 3072" ones.
    public init?(label: String) {
        let legacy: [String: FlickrPhotoSize] = [
            "Extra Large 3072": .extraLarge3072,
            "Extra Large 4096": .extraLarge4096,
            "Extra Large 5120": .extraLarge5120,
            "Extra Large 6144": .extraLarge6144
        ]
        if let size = Self.allCases.first(where: { $0.label == label }) ?? legacy[label] {
            self = size
        } else {
            return nil
        }
    }

    /// The suffix in the image URL, e.g. `b` in `…_b.jpg`. Medium 500 has none.
    public var suffix: String {
        switch self {
        case .square75: "s"
        case .largeSquare150: "q"
        case .thumbnail100: "t"
        case .small240: "m"
        case .small320: "n"
        case .small400: "w"
        case .medium500: ""
        case .medium640: "z"
        case .medium800: "c"
        case .large1024: "b"
        case .large1600: "h"
        case .large2048: "k"
        case .extraLarge3072: "3k"
        case .extraLarge4096: "4k"
        case .extraLarge5120: "5k"
        case .extraLarge6144: "6k"
        case .original: "o"
        }
    }

    /// The `extras` value that adds this size's URL to photo lists, e.g. `url_l` for Large 1024.
    /// The response then carries `url_l`, `width_l` and `height_l`.
    public var extrasKey: String {
        switch self {
        case .square75: "url_sq"
        case .largeSquare150: "url_q"
        case .thumbnail100: "url_t"
        case .small240: "url_s"
        case .small320: "url_n"
        case .small400: "url_w"
        case .medium500: "url_m"
        case .medium640: "url_z"
        case .medium800: "url_c"
        case .large1024: "url_l"
        case .large1600: "url_h"
        case .large2048: "url_k"
        case .extraLarge3072: "url_3k"
        case .extraLarge4096: "url_4k"
        case .extraLarge5120: "url_5k"
        case .extraLarge6144: "url_6k"
        case .original: "url_o"
        }
    }

    /// The longest edge in pixels, or `nil` for the original.
    public var longestEdge: Int? {
        switch self {
        case .square75: 75
        case .largeSquare150: 150
        case .thumbnail100: 100
        case .small240: 240
        case .small320: 320
        case .small400: 400
        case .medium500: 500
        case .medium640: 640
        case .medium800: 800
        case .large1024: 1024
        case .large1600: 1600
        case .large2048: 2048
        case .extraLarge3072: 3072
        case .extraLarge4096: 4096
        case .extraLarge5120: 5120
        case .extraLarge6144: 6144
        case .original: nil
        }
    }

    /// The same size as a ``FlickrStaticPhotoSize``, when its URL can be built from the photo's
    /// `secret`. `nil` for Large 1600 and up: each of those has its own secret, so take its URL
    /// from the `url_h`… extras or `flickr.photos.getSizes`.
    public var staticSize: FlickrStaticPhotoSize? {
        FlickrStaticPhotoSize(rawValue: rawValue)
    }

    public static func < (lhs: FlickrPhotoSize, rhs: FlickrPhotoSize) -> Bool {
        (lhs.longestEdge ?? .max) < (rhs.longestEdge ?? .max)
    }
}

/// The sizes whose URL can be built from a photo's `id`, `server` and `secret` alone: Large 1024
/// and below.
public enum FlickrStaticPhotoSize: String, Sendable, Codable, CaseIterable {
    case square75
    case largeSquare150
    case thumbnail100
    case small240
    case small320
    case small400
    case medium500
    case medium640
    case medium800
    case large1024

    public var size: FlickrPhotoSize {
        FlickrPhotoSize(rawValue: rawValue) ?? .medium500
    }
}

/// Builds Flickr's image and page URLs.
///
/// See https://www.flickr.com/services/api/misc.urls.html.
public enum FlickrPhotoURL {

    /// `https://live.staticflickr.com/{server}/{id}_{secret}_{suffix}.jpg`.
    ///
    /// Larger sizes aren't offered here because their URLs use a different secret; see
    /// ``FlickrPhotoSize/staticSize``.
    public static func image(photoID: String, server: String, secret: String, size: FlickrStaticPhotoSize) -> URL? {
        let suffix = size.size.suffix
        let name = suffix.isEmpty ? "\(photoID)_\(secret).jpg" : "\(photoID)_\(secret)_\(suffix).jpg"
        return staticURL(server: server, file: name)
    }

    /// The original upload. Needs `originalsecret` and `originalformat` (the `original_format`
    /// extra or `flickr.photos.getInfo`), which Flickr only returns when the owner allows it.
    public static func original(photoID: String, server: String, originalSecret: String, originalFormat: String) -> URL? {
        staticURL(server: server, file: "\(photoID)_\(originalSecret)_o.\(originalFormat)")
    }

    /// A user's buddy icon, or Flickr's default icon when they haven't set one (`iconserver` 0).
    public static func buddyIcon(nsid: String, iconServer: String?) -> URL {
        guard let iconServer, let server = Int(iconServer), server > 0,
              let url = staticURL(server: iconServer, file: "buddyicons/\(nsid).jpg") else {
            return defaultBuddyIcon
        }
        return url
    }

    public static let defaultBuddyIcon = FlickrEndpoint.url("https://www.flickr.com/images/buddyicon.gif")

    /// The photo's page on flickr.com. `owner` is the NSID or path alias.
    public static func photoPage(owner: String, photoID: String) -> URL? {
        URL(string: "https://www.flickr.com/photos/\(owner.oauthPercentEncoded)/\(photoID.oauthPercentEncoded)/")
    }

    /// A user's photostream on flickr.com.
    public static func profile(owner: String) -> URL? {
        URL(string: "https://www.flickr.com/photos/\(owner.oauthPercentEncoded)/")
    }

    private static func staticURL(server: String, file: String) -> URL? {
        guard !server.isEmpty, !file.hasPrefix("_") else { return nil }
        return URL(string: "https://live.staticflickr.com/\(server.oauthPercentEncoded)/\(file)")
    }
}

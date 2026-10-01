import Foundation

/// Typed builders for the Flickr API methods, grouped as Flickr groups them.
///
/// Each returns a ``FlickrRequest`` with the method's required arguments, the auth it needs and a
/// sensible default cache age (the ages galleryr used with FlickrKit 1.x). Optional arguments are
/// parameters with `nil` defaults, and anything else can be added with
/// ``FlickrRequest/setting(_:_:)``, ``FlickrRequest/page(_:perPage:)`` and
/// ``FlickrRequest/extras(_:)``.
///
/// ```swift
/// let request = FlickrMethod.Interestingness.getList()
///     .page(1, perPage: 250)
///     .extras(["url_m", "owner_name"])
/// let page: MyPhotosPage = try await client.call(request)
/// ```
public enum FlickrMethod {

    // MARK: - activity

    public enum Activity {
        /// Recent activity on the signed-in user's photos. `timeframe` is e.g. `"7d"` or `"12h"`.
        public static func userPhotos(timeframe: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.activity.userPhotos", auth: .required(.read), maxAge: FlickrCacheAge.oneHour)
                .setting("timeframe", timeframe)
        }

        /// Recent activity on photos the signed-in user has commented on.
        public static func userComments() -> FlickrRequest {
            FlickrRequest(method: "flickr.activity.userComments", auth: .required(.read), maxAge: FlickrCacheAge.oneHour)
        }
    }

    // MARK: - auth

    public enum Auth {
        static let checkTokenName = "flickr.auth.oauth.checkToken"

        /// The token's user and permission. ``FlickrClient/restoreSession()`` calls this for you.
        public static func checkToken(_ token: String) -> FlickrRequest {
            FlickrRequest(method: checkTokenName, arguments: ["oauth_token": token], auth: .required(.read))
        }
    }

    // MARK: - collections

    public enum Collections {
        /// A user's collection tree, or one branch of it.
        public static func getTree(userID: String? = nil, collectionID: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.collections.getTree", maxAge: FlickrCacheAge.oneHour)
                .setting("user_id", userID)
                .setting("collection_id", collectionID)
        }
    }

    // MARK: - contacts

    public enum Contacts {
        /// The signed-in user's contacts. `filter` is `friends`, `family`, `both` or `neither`.
        public static func getList(filter: String? = nil, sort: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.contacts.getList", auth: .required(.read), maxAge: FlickrCacheAge.oneHour)
                .setting("filter", filter)
                .setting("sort", sort)
        }

        /// Another user's public contacts.
        public static func getPublicList(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.contacts.getPublicList", arguments: ["user_id": userID], maxAge: FlickrCacheAge.oneHour)
        }

        /// Adds a contact. Not in Flickr's published API list, but used by galleryr 2.x.
        public static func add(userID: String, friend: Bool = false, family: Bool = false) -> FlickrRequest {
            FlickrRequest(
                method: "flickr.contacts.add",
                arguments: ["user_id": userID, "friend": friend ? "1" : "0", "family": family ? "1" : "0"],
                auth: .required(.write)
            )
        }

        /// Removes a contact. Not in Flickr's published API list, but used by galleryr 2.x.
        public static func remove(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.contacts.remove", arguments: ["user_id": userID], auth: .required(.write))
        }
    }

    // MARK: - favorites

    public enum Favorites {
        public static func add(photoID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.favorites.add", arguments: ["photo_id": photoID], auth: .required(.write))
        }

        public static func remove(photoID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.favorites.remove", arguments: ["photo_id": photoID], auth: .required(.write))
        }

        /// A user's favourites; the signed-in user's when `userID` is `nil`. Never cached, so a
        /// fave shows up straight away.
        public static func getList(userID: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.favorites.getList")
                .setting("user_id", userID)
        }
    }

    // MARK: - galleries

    public enum Galleries {
        public static func getList(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.galleries.getList", arguments: ["user_id": userID], maxAge: FlickrCacheAge.oneDay)
        }

        public static func getPhotos(galleryID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.galleries.getPhotos", arguments: ["gallery_id": galleryID], maxAge: FlickrCacheAge.fiveMinutes)
        }
    }

    // MARK: - groups

    public enum Groups {
        public static func getInfo(groupID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.groups.getInfo", arguments: ["group_id": groupID], maxAge: FlickrCacheAge.oneHour)
        }

        public static func search(text: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.groups.search", arguments: ["text": text], maxAge: FlickrCacheAge.oneDay)
        }

        /// Joins a public group. `acceptRules` must be true for groups with rules.
        public static func join(groupID: String, acceptRules: Bool = false) -> FlickrRequest {
            FlickrRequest(method: "flickr.groups.join", arguments: ["group_id": groupID], auth: .required(.write))
                .setting("accept_rules", acceptRules ? "1" : nil)
        }

        /// Asks to join a group that needs an invitation or approval.
        public static func joinRequest(groupID: String, message: String, acceptRules: Bool) -> FlickrRequest {
            FlickrRequest(
                method: "flickr.groups.joinRequest",
                arguments: ["group_id": groupID, "message": message, "accept_rules": acceptRules ? "1" : "0"],
                auth: .required(.write)
            )
        }

        public enum Pools {
            public static func getPhotos(groupID: String, userID: String? = nil) -> FlickrRequest {
                FlickrRequest(method: "flickr.groups.pools.getPhotos", arguments: ["group_id": groupID], maxAge: FlickrCacheAge.fiveMinutes)
                    .setting("user_id", userID)
            }
        }
    }

    // MARK: - interestingness

    public enum Interestingness {
        /// Explore's interesting photos for `date` (a calendar day in `timeZone`), or the most
        /// recent day when `date` is `nil`.
        public static func getList(date: Date? = nil, timeZone: TimeZone = .current) -> FlickrRequest {
            FlickrRequest(method: "flickr.interestingness.getList", maxAge: FlickrCacheAge.halfDay)
                .setting("date", date.map { FlickrDate.day($0, timeZone: timeZone) })
        }
    }

    // MARK: - people

    public enum People {
        public static func getInfo(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.getInfo", arguments: ["user_id": userID], maxAge: FlickrCacheAge.oneHour)
        }

        /// Groups the user belongs to, including private ones the signed-in user can see.
        public static func getGroups(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.getGroups", arguments: ["user_id": userID], auth: .required(.read), maxAge: FlickrCacheAge.oneDay)
        }

        public static func getPublicGroups(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.getPublicGroups", arguments: ["user_id": userID], maxAge: FlickrCacheAge.oneDay)
        }

        public static func getPhotos(userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.getPhotos", arguments: ["user_id": userID], maxAge: FlickrCacheAge.fiveMinutes)
        }

        public static func findByUsername(_ username: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.findByUsername", arguments: ["username": username])
        }

        public static func findByEmail(_ email: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.people.findByEmail", arguments: ["find_email": email])
        }
    }

    // MARK: - photos

    public enum Photos {
        public static func search(_ parameters: PhotoSearchParameters) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.search", arguments: parameters.arguments, maxAge: FlickrCacheAge.fiveMinutes)
        }

        public static func getRecent() -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getRecent", maxAge: FlickrCacheAge.fiveMinutes)
        }

        /// Pass `secret` to read a photo shared with you by its secret.
        public static func getInfo(photoID: String, secret: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getInfo", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.oneHour)
                .setting("secret", secret)
        }

        /// Every size of the photo with its URL. The only reliable way to get the large sizes
        /// (see ``FlickrPhotoURL``).
        public static func getSizes(photoID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getSizes", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.oneDay)
        }

        public static func getExif(photoID: String, secret: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getExif", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.oneDay)
                .setting("secret", secret)
        }

        /// People who faved the photo.
        public static func getFavorites(photoID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getFavorites", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.fiveMinutes)
        }

        /// Recent photos from the signed-in user's contacts.
        public static func getContactsPhotos(count: Int? = nil, justFriends: Bool = false, singlePhoto: Bool = false, includeSelf: Bool = false) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getContactsPhotos", auth: .required(.read), maxAge: FlickrCacheAge.oneMinute)
                .setting("count", count.map(String.init))
                .setting("just_friends", justFriends ? "1" : nil)
                .setting("single_photo", singlePhoto ? "1" : nil)
                .setting("include_self", includeSelf ? "1" : nil)
        }

        /// The albums and groups the photo appears in.
        public static func getAllContexts(photoID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.getAllContexts", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.oneDay)
        }

        /// Adds tags. Tags with spaces are quoted for you.
        public static func addTags(photoID: String, tags: [String]) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.addTags", arguments: ["photo_id": photoID, "tags": FlickrTags.join(tags)], auth: .required(.write))
        }

        /// Removes a tag by the tag ID from `flickr.photos.getInfo` (the `id` of a `tag`).
        public static func removeTag(tagID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photos.removeTag", arguments: ["tag_id": tagID], auth: .required(.write))
        }

        public enum Comments {
            public static func getList(photoID: String) -> FlickrRequest {
                FlickrRequest(method: "flickr.photos.comments.getList", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.fiveMinutes)
            }

            public static func addComment(photoID: String, text: String) -> FlickrRequest {
                FlickrRequest(method: "flickr.photos.comments.addComment", arguments: ["photo_id": photoID, "comment_text": text], auth: .required(.write))
            }

            public static func deleteComment(commentID: String) -> FlickrRequest {
                FlickrRequest(method: "flickr.photos.comments.deleteComment", arguments: ["comment_id": commentID], auth: .required(.write))
            }
        }

        public enum Geo {
            public static func getLocation(photoID: String) -> FlickrRequest {
                FlickrRequest(method: "flickr.photos.geo.getLocation", arguments: ["photo_id": photoID], maxAge: FlickrCacheAge.oneDay)
            }
        }
    }

    // MARK: - photosets

    public enum Photosets {
        public static func getInfo(photosetID: String, userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photosets.getInfo", arguments: ["photoset_id": photosetID, "user_id": userID], maxAge: FlickrCacheAge.oneHour)
        }

        /// A user's albums; the signed-in user's when `userID` is `nil`.
        public static func getList(userID: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.photosets.getList", maxAge: FlickrCacheAge.oneHour)
                .setting("user_id", userID)
        }

        public static func getPhotos(photosetID: String, userID: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.photosets.getPhotos", arguments: ["photoset_id": photosetID, "user_id": userID], maxAge: FlickrCacheAge.fiveMinutes)
        }
    }

    // MARK: - places

    public enum Places {
        public static func find(query: String) -> FlickrRequest {
            FlickrRequest(method: "flickr.places.find", arguments: ["query": query], auth: .anonymous, maxAge: FlickrCacheAge.oneDay)
        }
    }

    // MARK: - stats

    public enum Stats {
        /// The signed-in user's most viewed photos. Needs a Flickr Pro account; others get a
        /// ``FlickrError/api(code:message:)``.
        public static func getPopularPhotos(date: Date? = nil, sort: String? = nil, timeZone: TimeZone = .current) -> FlickrRequest {
            FlickrRequest(method: "flickr.stats.getPopularPhotos", auth: .required(.read), maxAge: FlickrCacheAge.oneHour)
                .setting("date", date.map { FlickrDate.day($0, timeZone: timeZone) })
                .setting("sort", sort)
        }
    }

    // MARK: - tags

    public enum Tags {
        /// A user's tags; the signed-in user's when `userID` is `nil` (for tag autocomplete).
        public static func getListUser(userID: String? = nil) -> FlickrRequest {
            FlickrRequest(method: "flickr.tags.getListUser", maxAge: FlickrCacheAge.oneDay)
                .setting("user_id", userID)
        }
    }

    // MARK: - test

    public enum Test {
        /// The signed-in user. A cheap way to check a token.
        public static func login() -> FlickrRequest {
            FlickrRequest(method: "flickr.test.login", auth: .required(.read))
        }
    }
}

/// The arguments of `flickr.photos.search`. Every field is optional; Flickr needs at least one
/// limiting argument (text, tags, user, place, bbox, dates…) or it returns recent public photos.
public struct PhotoSearchParameters: Sendable, Hashable {

    public enum TagMode: String, Sendable { case any, all }
    public enum Media: String, Sendable { case all, photos, videos }
    public enum Sort: String, Sendable {
        case datePostedAscending = "date-posted-asc"
        case datePostedDescending = "date-posted-desc"
        case dateTakenAscending = "date-taken-asc"
        case dateTakenDescending = "date-taken-desc"
        case interestingnessAscending = "interestingness-asc"
        case interestingnessDescending = "interestingness-desc"
        case relevance
    }
    /// `1` safe, `2` moderate, `3` restricted.
    public enum SafeSearch: Int, Sendable { case safe = 1, moderate = 2, restricted = 3 }

    public var text: String?
    public var tags: [String] = []
    public var tagMode: TagMode?
    public var userID: String?
    public var groupID: String?
    public var media: Media?
    public var sort: Sort?
    public var safeSearch: SafeSearch?
    public var hasGeo: Bool?
    public var minTakenDate: Date?
    public var maxTakenDate: Date?
    public var minUploadDate: Date?
    public var maxUploadDate: Date?
    public var boundingBox: FlickrBoundingBox?
    public var placeID: String?
    /// e.g. `"1,2,3"` for `license`.
    public var license: String?
    /// Anything else, by Flickr's argument name.
    public var additional: [String: String] = [:]

    public init(text: String? = nil, tags: [String] = [], userID: String? = nil) {
        self.text = text
        self.tags = tags
        self.userID = userID
    }

    var arguments: [String: String] {
        var arguments = additional
        arguments["text"] = text
        arguments["tags"] = tags.isEmpty ? nil : tags.joined(separator: ",")
        arguments["tag_mode"] = tagMode?.rawValue
        arguments["user_id"] = userID
        arguments["group_id"] = groupID
        arguments["media"] = media?.rawValue
        arguments["sort"] = sort?.rawValue
        arguments["safe_search"] = safeSearch.map { String($0.rawValue) }
        arguments["has_geo"] = hasGeo.map { $0 ? "1" : "0" }
        arguments["min_taken_date"] = minTakenDate.map(FlickrDate.mysqlDateTime)
        arguments["max_taken_date"] = maxTakenDate.map(FlickrDate.mysqlDateTime)
        arguments["min_upload_date"] = minUploadDate.map { String(Int($0.timeIntervalSince1970)) }
        arguments["max_upload_date"] = maxUploadDate.map { String(Int($0.timeIntervalSince1970)) }
        arguments["bbox"] = boundingBox?.argument
        arguments["place_id"] = placeID
        arguments["license"] = license
        return arguments
    }
}

/// A `bbox` argument: west, south, east, north in degrees.
public struct FlickrBoundingBox: Sendable, Hashable, Codable {
    public var minLongitude: Double
    public var minLatitude: Double
    public var maxLongitude: Double
    public var maxLatitude: Double

    public init(minLongitude: Double, minLatitude: Double, maxLongitude: Double, maxLatitude: Double) {
        self.minLongitude = minLongitude
        self.minLatitude = minLatitude
        self.maxLongitude = maxLongitude
        self.maxLatitude = maxLatitude
    }

    var argument: String {
        [minLongitude, minLatitude, maxLongitude, maxLatitude].map { String($0) }.joined(separator: ",")
    }
}

/// Date formats Flickr's arguments use. Always the POSIX locale and Gregorian calendar, so a
/// device set to, say, the Buddhist calendar still sends 2026 rather than 2569.
enum FlickrDate {

    /// `yyyy-MM-dd` for the calendar day of `date` in `timeZone`.
    static func day(_ date: Date, timeZone: TimeZone) -> String {
        formatter("yyyy-MM-dd", timeZone: timeZone).string(from: date)
    }

    /// `yyyy-MM-dd HH:mm:ss`, which `min_taken_date` / `max_taken_date` take, in the device's zone
    /// (Flickr stores taken dates as the camera's local time).
    static func mysqlDateTime(_ date: Date) -> String {
        formatter("yyyy-MM-dd HH:mm:ss", timeZone: .current).string(from: date)
    }

    private static func formatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }
}

/// Tag list formatting.
enum FlickrTags {
    /// Space separated, with multi-word tags in double quotes as `flickr.photos.addTags` expects.
    static func join(_ tags: [String]) -> String {
        tags
            .map { $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.contains(" ") ? "\"\($0)\"" : $0 }
            .joined(separator: " ")
    }
}

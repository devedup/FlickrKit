import Foundation
import Testing
@testable import FlickrKit

struct FlickrMethodTests {

    @Test func perPageIsClampedTo500() {
        let request = FlickrMethod.Photos.getRecent().page(0, perPage: 1000)
        #expect(request.arguments["per_page"] == "500")
        #expect(request.arguments["page"] == "1")
    }

    @Test func extrasAreCommaSeparated() {
        let request = FlickrMethod.Interestingness.getList().extras(["url_m", "owner_name"])
        #expect(request.arguments["extras"] == "url_m,owner_name")
        #expect(FlickrMethod.Interestingness.getList().extras([]).arguments["extras"] == nil)
    }

    @Test func interestingnessDateIsGregorianWhateverTheDeviceCalendar() throws {
        let utc = try #require(TimeZone(identifier: "UTC"))
        let date = Date(timeIntervalSince1970: 1_790_000_000) // 2026-09-21 UTC
        #expect(FlickrMethod.Interestingness.getList(date: date, timeZone: utc).arguments["date"] == "2026-09-21")
        #expect(FlickrMethod.Interestingness.getList().arguments["date"] == nil)
        #expect(FlickrMethod.Interestingness.getList().maxAge == FlickrCacheAge.halfDay)
    }

    @Test func writesNeedWriteAccessAndAreNeverCached() {
        let writes = [
            FlickrMethod.Favorites.add(photoID: "1"),
            FlickrMethod.Favorites.remove(photoID: "1"),
            FlickrMethod.Photos.addTags(photoID: "1", tags: ["a"]),
            FlickrMethod.Photos.removeTag(tagID: "1"),
            FlickrMethod.Photos.Comments.addComment(photoID: "1", text: "x"),
            FlickrMethod.Photos.Comments.deleteComment(commentID: "1"),
            FlickrMethod.Contacts.add(userID: "1"),
            FlickrMethod.Contacts.remove(userID: "1"),
            FlickrMethod.Groups.join(groupID: "1")
        ]
        for request in writes {
            #expect(request.auth == .required(.write), "\(request.method)")
            #expect(request.maxAge == nil, "\(request.method)")
        }
    }

    @Test func searchBuildsFlickrArguments() throws {
        var search = PhotoSearchParameters(text: "sunset", tags: ["sea", "sky"])
        search.tagMode = .all
        search.media = .videos
        search.sort = .interestingnessDescending
        search.safeSearch = .safe
        search.hasGeo = true
        search.boundingBox = FlickrBoundingBox(minLongitude: -1.5, minLatitude: 50, maxLongitude: 0.5, maxLatitude: 52)
        search.additional = ["content_type": "1"]
        let arguments = FlickrMethod.Photos.search(search).arguments

        #expect(arguments["text"] == "sunset")
        #expect(arguments["tags"] == "sea,sky")
        #expect(arguments["tag_mode"] == "all")
        #expect(arguments["media"] == "videos")
        #expect(arguments["sort"] == "interestingness-desc")
        #expect(arguments["safe_search"] == "1")
        #expect(arguments["has_geo"] == "1")
        #expect(arguments["bbox"] == "-1.5,50.0,0.5,52.0")
        #expect(arguments["content_type"] == "1")
        #expect(arguments["user_id"] == nil)
    }

    @Test func tagsWithSpacesAreQuoted() {
        let request = FlickrMethod.Photos.addTags(photoID: "1", tags: ["sunset", "north sea", " ", "say \"hi\""])
        #expect(request.arguments["tags"] == "sunset \"north sea\" \"say hi\"")
    }

    @Test func optionalArgumentsAreLeftOutWhenNil() {
        #expect(FlickrMethod.Favorites.getList().arguments.isEmpty)
        #expect(FlickrMethod.Favorites.getList(userID: "1").arguments == ["user_id": "1"])
    }
}

struct FlickrPhotoURLTests {

    @Test func staticSizesUseTheSuffix() throws {
        let url = try #require(FlickrPhotoURL.image(photoID: "123", server: "65535", secret: "abc", size: .large1024))
        #expect(url.absoluteString == "https://live.staticflickr.com/65535/123_abc_b.jpg")
    }

    @Test func medium500HasNoSuffix() throws {
        let url = try #require(FlickrPhotoURL.image(photoID: "123", server: "65535", secret: "abc", size: .medium500))
        #expect(url.absoluteString == "https://live.staticflickr.com/65535/123_abc.jpg")
    }

    @Test func sizesAbove1024CannotBeBuiltFromTheSecret() {
        let unbuildable: [FlickrPhotoSize] = [.large1600, .large2048, .extraLarge3072, .extraLarge4096, .extraLarge5120, .extraLarge6144, .original]
        for size in FlickrPhotoSize.allCases {
            #expect((size.staticSize == nil) == unbuildable.contains(size), "\(size)")
        }
        #expect(FlickrStaticPhotoSize.allCases.count == FlickrPhotoSize.allCases.count - unbuildable.count)
    }

    @Test func originalUsesItsOwnSecretAndFormat() throws {
        let url = try #require(FlickrPhotoURL.original(photoID: "123", server: "65535", originalSecret: "xyz", originalFormat: "png"))
        #expect(url.absoluteString == "https://live.staticflickr.com/65535/123_xyz_o.png")
    }

    @Test func suffixesMatchFlickrsTable() {
        let expected: [FlickrPhotoSize: String] = [
            .square75: "s", .largeSquare150: "q", .thumbnail100: "t", .small240: "m", .small320: "n",
            .small400: "w", .medium500: "", .medium640: "z", .medium800: "c", .large1024: "b",
            .large1600: "h", .large2048: "k", .extraLarge3072: "3k", .extraLarge4096: "4k",
            .extraLarge5120: "5k", .extraLarge6144: "6k", .original: "o"
        ]
        for size in FlickrPhotoSize.allCases {
            #expect(size.suffix == expected[size], "\(size)")
        }
    }

    @Test func getSizesLabelsRoundTrip() {
        for size in FlickrPhotoSize.allCases {
            #expect(FlickrPhotoSize(label: size.label) == size)
        }
        #expect(FlickrPhotoSize(label: "Extra Large 4096") == .extraLarge4096)
        #expect(FlickrPhotoSize(label: "HD MP4") == nil)
    }

    @Test func sizesSortByLongestEdgeWithOriginalLast() {
        #expect(FlickrPhotoSize.allCases.sorted().last == .original)
        #expect(FlickrPhotoSize.thumbnail100 < .small240)
        #expect(FlickrPhotoSize.square75 < .thumbnail100)
    }

    @Test func buddyIconFallsBackToTheDefault() {
        #expect(FlickrPhotoURL.buddyIcon(nsid: "1@N01", iconServer: "4567").absoluteString == "https://live.staticflickr.com/4567/buddyicons/1@N01.jpg")
        #expect(FlickrPhotoURL.buddyIcon(nsid: "1@N01", iconServer: "0") == FlickrPhotoURL.defaultBuddyIcon)
        #expect(FlickrPhotoURL.buddyIcon(nsid: "1@N01", iconServer: nil) == FlickrPhotoURL.defaultBuddyIcon)
    }

    @Test func photoPage() {
        #expect(FlickrPhotoURL.photoPage(owner: "12345@N01", photoID: "99")?.absoluteString == "https://www.flickr.com/photos/12345%40N01/99/")
    }
}

struct FlickrJSONTests {

    private struct Sample: Decodable {
        var farm: String?
        var width: Int?
        var latitude: Double?
        var isPublic: Bool?
        var title: FlickrContent<String>?

        enum CodingKeys: String, CodingKey {
            case farm, width, latitude, title
            case isPublic = "ispublic"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            farm = try container.decodeFlickrStringIfPresent(forKey: .farm)
            width = try container.decodeFlickrIntIfPresent(forKey: .width)
            latitude = try container.decodeFlickrDoubleIfPresent(forKey: .latitude)
            isPublic = try container.decodeFlickrBoolIfPresent(forKey: .isPublic)
            title = try container.decodeIfPresent(FlickrContent<String>.self, forKey: .title)
        }
    }

    private func decode(_ json: String) throws -> Sample {
        try JSONDecoder().decode(Sample.self, from: Data(json.utf8))
    }

    @Test func numbersAsNumbers() throws {
        let sample = try decode(#"{"farm":66,"width":1024,"latitude":51.5,"ispublic":1,"title":{"_content":"Hi"}}"#)
        #expect(sample.farm == "66")
        #expect(sample.width == 1024)
        #expect(sample.latitude == 51.5)
        #expect(sample.isPublic == true)
        #expect(sample.title?.content == "Hi")
    }

    @Test func numbersAsStrings() throws {
        let sample = try decode(#"{"farm":"66","width":"1024","latitude":"51.5","ispublic":"0"}"#)
        #expect(sample.farm == "66")
        #expect(sample.width == 1024)
        #expect(sample.latitude == 51.5)
        #expect(sample.isPublic == false)
    }

    @Test func missingNullAndEmptyAreNil() throws {
        let sample = try decode(#"{"width":null,"latitude":""}"#)
        #expect(sample.farm == nil)
        #expect(sample.width == nil)
        #expect(sample.latitude == nil)
    }
}

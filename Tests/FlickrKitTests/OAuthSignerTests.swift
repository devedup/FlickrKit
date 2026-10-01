import Foundation
import Testing
@testable import FlickrKit

struct PercentEncodingTests {

    @Test func unreservedCharactersPassThrough() {
        #expect("AZaz09-._~".oauthPercentEncoded == "AZaz09-._~")
    }

    @Test func reservedCharactersAreEncodedUpperCase() {
        #expect("a b+c/d=e&f*".oauthPercentEncoded == "a%20b%2Bc%2Fd%3De%26f%2A")
    }

    @Test func nonASCIIIsEncodedAsUTF8() {
        #expect("é☃".oauthPercentEncoded == "%C3%A9%E2%98%83")
    }

    @Test func formParsingDecodesAndSkipsMalformedPairs() {
        let parsed = FormEncoding.parameters(fromQuery: "fullname=Jamal%20Fanaian&broken&empty=&bad=%E0%A4%A")
        #expect(parsed["fullname"] == "Jamal Fanaian")
        #expect(parsed["empty"] == "")
        #expect(parsed["bad"] == "%E0%A4%A")
        #expect(parsed["broken"] == nil)
    }
}

struct OAuthSignerTests {

    /// RFC 5849 §1.2, the photos.example.net walkthrough.
    @Test func rfc5849Example() {
        let signer = OAuthSigner(consumerKey: "dpf43f3p2l4k3l03", consumerSecret: "kd94hf93k423kf44")
        let signed = signer.signedParameters(
            httpMethod: "GET",
            url: URL(string: "http://photos.example.net/photos")!,
            parameters: ["file": "vacation.jpg", "size": "original"],
            token: "nnch734d00sl2jdk",
            tokenSecret: "pfkkdhi9sl3r4s00",
            nonce: "kllo9940pd9333jh",
            timestamp: 1191242096
        )
        #expect(signed["oauth_signature"] == "tR3+Ty81lMeYAr/Fid0kMTYa/WM=")
    }

    /// The worked example from Twitter's "Creating a signature" documentation.
    @Test func twitterDocumentationExample() {
        let signer = OAuthSigner(
            consumerKey: "xvz1evFS4wEEPTGEFPHBog",
            consumerSecret: "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
        )
        let signed = signer.signedParameters(
            httpMethod: "post",
            url: URL(string: "https://api.twitter.com/1.1/statuses/update.json")!,
            parameters: [
                "include_entities": "true",
                "status": "Hello Ladies + Gentlemen, a signed OAuth request!"
            ],
            token: "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
            tokenSecret: "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE",
            nonce: "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
            timestamp: 1318622958
        )
        #expect(signed["oauth_signature"] == "hCtSmYh+iHYCEqBWrE7C7hYmtUk=")
    }

    /// The base string from Flickr's "User Authentication" page (the request-token step). Flickr
    /// doesn't publish the secret it used, so only the base string can be checked.
    @Test func flickrDocumentationBaseString() {
        let base = OAuthSigner.signatureBaseString(
            httpMethod: "GET",
            url: URL(string: "https://www.flickr.com/services/oauth/request_token")!,
            parameters: [
                "oauth_callback": "http://www.example.com",
                "oauth_consumer_key": "653e7a6ecc1d528c516cc8f92cf98611",
                "oauth_nonce": "95613465",
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": "1305586162",
                "oauth_version": "1.0"
            ]
        )
        #expect(base == "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&oauth_callback%3Dhttp%253A%252F%252Fwww.example.com%26oauth_consumer_key%3D653e7a6ecc1d528c516cc8f92cf98611%26oauth_nonce%3D95613465%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305586162%26oauth_version%3D1.0")
    }

    @Test func baseURLDropsDefaultPortQueryAndCase() {
        let url = URL(string: "HTTPS://API.Flickr.com:443/services/rest/?method=x#frag")!
        #expect(OAuthSigner.baseURLString(for: url) == "https://api.flickr.com/services/rest/")
    }

    @Test func signingWithoutATokenUsesAnEmptyTokenSecret() {
        let signer = OAuthSigner(consumerKey: "key", consumerSecret: "secret")
        let signed = signer.signedParameters(
            httpMethod: "GET",
            url: URL(string: "https://www.flickr.com/services/oauth/request_token")!,
            parameters: [:],
            nonce: "n",
            timestamp: 1
        )
        #expect(signed["oauth_token"] == nil)
        let expected = OAuthSigner.signature(
            baseString: OAuthSigner.signatureBaseString(
                httpMethod: "GET",
                url: URL(string: "https://www.flickr.com/services/oauth/request_token")!,
                parameters: signed.filter { $0.key != "oauth_signature" }
            ),
            consumerSecret: "secret",
            tokenSecret: nil
        )
        #expect(signed["oauth_signature"] == expected)
    }
}

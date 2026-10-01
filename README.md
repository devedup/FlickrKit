# FlickrKit

## FlickrKit 2.0 (Swift)

FlickrKit 2.0 is a rewrite in Swift: a Swift package with async/await, Swift 6 strict concurrency and no dependencies. It is used by galleryr 3.0. The Objective-C 1.x library described further down stays available on the `1.x` branch and the `v1.1.0` tag; CocoaPods installs it from the tag.

**What it does**

* OAuth 1.0a signing (HMAC-SHA1 via CryptoKit) and the full sign-in flow, with an `ASWebAuthenticationSession` wrapper.
* The session stored in the Keychain behind a `FlickrTokenStore` protocol, with a one-time move of a token saved by FlickrKit 1.x.
* A `FlickrClient` actor that signs, sends and decodes calls into any `Decodable` type, with typed `FlickrError`s, back-off on 429 and 5xx, at most 4 requests in flight, and a response cache kept per signed-in user.
* Typed request builders for common methods (`FlickrMethod.Photos.search(...)`, `FlickrMethod.Interestingness.getList()` and so on). Any other method can be called by name.
* Photo, buddy icon and page URLs.

FlickrKit doesn't define response models: you decode Flickr's JSON into your own types. `FlickrContent` and the lenient `decodeFlickrInt/Double/Bool/StringIfPresent` helpers handle Flickr's `_content` wrappers and its numbers that sometimes arrive as strings.

**Requirements:** iOS 17 or macOS 14, Swift 6.2.

### Installation

In Xcode, choose File › Add Package Dependencies and enter `https://github.com/devedup/FlickrKit`. Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/devedup/FlickrKit", from: "2.0.0")
```

### Quick start

```swift
import FlickrKit

let client = FlickrClient(apiKey: "YOUR_KEY", sharedSecret: "YOUR_SECRET")

// Today's interesting photos, decoded into your own type.
struct PhotosPage: Decodable, Sendable {
    struct Photos: Decodable, Sendable { var photo: [Photo] }
    struct Photo: Decodable, Sendable { var id: String; var title: String; var url_m: String? }
    var photos: Photos
}

let page: PhotosPage = try await client.call(
    FlickrMethod.Interestingness.getList()
        .page(1, perPage: 100)
        .extras([FlickrPhotoSize.medium500.extrasKey])
)

// Any method by name.
let info: SomeType = try await client.call("flickr.photos.getInfo", args: ["photo_id": "123"])
```

Signing in, at launch and from a button:

```swift
// At launch: check the stored token (and move a 1.x token into the Keychain first).
try KeychainTokenStore().migrateLegacyToken()
let user = try await client.restoreSession()

// Sign in. The callback URL's scheme is all the session needs; it doesn't have to be registered.
let authenticator = FlickrWebAuthenticator(client: client)
let user = try await authenticator.signIn(
    callbackURL: URL(string: "myapp://flickr-auth")!,
    permission: .write,
    anchor: window
)
```

Image URLs for Large 1024 and below can be built from a photo's `secret`. Larger sizes and originals have their own secrets, so take their URLs from the `url_h`, `url_k`… extras or `flickr.photos.getSizes`:

```swift
let url = FlickrPhotoURL.image(photoID: photo.id, server: photo.server, secret: photo.secret, size: .large1024)
```

The documentation catalog in `Sources/FlickrKit/FlickrKit.docc` covers the rest (Product › Build Documentation in Xcode).

---

## FlickrKit 1.x (Objective-C)

FlickrKit is an iOS Objective-C library for accessing the Flickr API written by David Casserly. It is used by [galleryr pro iPad app](https://itunes.apple.com/gb/app/flickr-gallery-pro/id525519823?mt=8).

### Features
---

Who needs FlickrKit when we have ObjectiveFlickr? Why not? I used ObjectiveFlickr for a long time, and some of the methods in this library were born from ObjectiveFlickr. However, I sometimes had problems debugging ObjectiveFlickr as the networking code was custom and not familiar to me. Also I go a little further with FlickrKit and I provide a little bit more than ObjectiveFlickr does... read on....

* You have a few ways to call methods - using string method name/dictionary params - or using the Model classes that have been generated for every Flickr API call available! It's up to you - or mix it up!
* All methods return an NSOperation subclass, so you have the ability to cancel requests easily, requests are put onto an operation queue.
* FlickrKit uses latest iOS libraries where possible, and is built with ARC and uses block callbacks. So it's internals should be familiar.
*  Errors are packaged properly into NSError objects, again more familiarity.
*  There is a default disk caching of Flickr responses - you are allowed to cache up to 24 hrs. You can specify the cache time per request.
*  The code is (hopefully) easy to read and debug, as it uses standard iOS networking components in the simplest way possible.
*  It is (partially) unit tested. 
*  There is a demo project to see its usage.
*  There is a vastly simplified authentication mechanism, which is by far the most complicated part of using Flickr APi - even when using ObjectiveFlickr.
*  The model classes are auto generated and include all error codes, params, validation, and documentation. The code generation project is also included in the source if you need to regenerate.
*  Maybe there are more features that I’ve neglected to mentions… give it a go!
 
###### Limitations 
I don't support Mac OS X (as I’ve never worked with that ..sorry! - ports welcome!). I don't support the old authentication method or migration - it only uses OAuth - which is almost a year old with Flickr now anyway. It only supports single user authentication - so doesn't support multiple Flickr accounts


### Requirements
---
FlickrKit requires iOS 6.0 and above and uses ARC. It may be compatible with older OS's, but I haven't tested this.

If you are using FlickrKit in your non-arc project, you will need to set a `-fobjc-arc` compiler flag on all of the FlickrKit source files. 

To set a compiler flag in Xcode, go to your active target and select the "Build Phases" tab. Now select all FlickrKit source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for FlickrKit.

### Cocoapods Installation
---
Add this line to your target in your `Podfile`:

    pod 'FlickrKit'
    
Run `pod install` and you're good to go!

### Manual Installation
---
1. Drag FlickrKit.xcodeproj into your project.
2. In your project target, build phases, target dependencies... add FlickrKit as a depenendency
3. In your project target, build phases, link binary with library... add libFlickrKit.a
4. In build settings > header search paths... point to FlickrKit classes directory, recursively
5. Include SystemConfiguration.framework 

### Usage
---
Included in the source is a demo project that shows you how to get started. It has a few example use cases. The UI isn't pretty! - but the important part is the usage of the API in the code.

##### API Notes
 * You need to start the library using initializeWithAPIKey:sharedSecret: which you will get from your flickr account
 * Completion callbacks are not called on the main thread, so you must ensure you do any UI related work on the main thread
 * Flickr allow you to cache responses for up to 24 hrs, you can pass the maxCacheAge for the number of minutes you want to cache this for.
 * You can provide your own cache implementation if you want and plug it into FlickrKit. See [FlickrKit.h]
 * You can use either the string/dictionary call methods - or you can use the model api, where you use a model class. The advantage of the model classes is the clarity and the validation/error messaging built into them. They also contain all the Flickr documentation. They are auto generated from the Flickr API and can be regenerated with FKAPIBuilder class if the API updates.
 
##### Authentication 
 
 * You start auth using beginAuthWithCallbackURL with the url that Flickr will call back to your app - completion callback gives you a URL that you can present in a webview.
 * Once the user has logged in and Flickr will redirect back to your app on the callback URL you specified
 * Remember to include this URL scheme inside your Info.plist of registered URL Schemes. 
 * In your app delegate handle URL method, you can pass the full callback URL to completeAuthWithURL.
 * We store the auth token in NSUserDefaults - so when you launch your app again, you can call checkAuthorizationOnSuccess to see if the user is already validated.
 * Calling logout will remove all stored tokens and the user will have to authenticate again.

#### Startup
You can get an API Key and Secret from your Flickr account. You need these to use the API.

###### swift
```swift
FlickrKit.sharedFlickrKit().initializeWithAPIKey(apiKey, sharedSecret: secret)
```

###### objective-c
```objective-c
[[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"YOUR_KEY" sharedSecret:@"YOUR_SECRET"];
```

#### Load Interesting Photos - Flickr Explore 
This example demonstrates using the generated Flickr API Model classes.

###### swift
```swift
let flickrInteresting = FKFlickrInterestingnessGetList()
flickrInteresting.per_page = "15"
FlickrKit.sharedFlickrKit().call(flickrInteresting) { (response, error) -> Void in
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        	if (response != nil) {
                    // Pull out the photo urls from the results
                    let topPhotos = response["photos"] as! [NSObject: AnyObject]
                    let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                    for photoDictionary in photoArray {
                        let photoURL = FlickrKit.sharedFlickrKit().photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                        self.photoURLs.append(photoURL)
                    }
                } 
       })
}
```

###### objective-c
```objective-c
FlickrKit *fk = [FlickrKit sharedFlickrKit];
FKFlickrInterestingnessGetList *interesting = [[FKFlickrInterestingnessGetList alloc] init];
[fk call:interesting completion:^(NSDictionary *response, NSError *error) {
	// Note this is not the main thread!
	if (response) {				
		NSMutableArray *photoURLs = [NSMutableArray array];
		for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
			NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
			[photoURLs addObject:url];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			// Any GUI related operations here
		});
	}	
}];
```

#### Your Photostream Photos
This example uses the string/dictionary method of calling FlickrKit, and alternative to using the Model classes. It also demonstrates passing a cache time of one hour, meaning if you call this again within the hour - it will hit the cache and not the network. Fast!

```objective-c
[[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"user_id": self.userID, @"per_page": @"15"} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (response) {
			// extract images from the response dictionary	
		} else {
			// show the error
		}
	});			
}];
```

#### Uploading a Photo
Uploading a photo and observing its progress. imagePicked comes from the UIImagePickerControllerDelegate, but could be any UIImage.

```objective-c
self.uploadOp = [[FlickrKit sharedFlickrKit] uploadImage:imagePicked args:uploadArgs completion:^(NSString *imageID, NSError *error) {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (error) {
			// oops!
		} else {
			// Image is now in flickr!
		}            
       });
}];    
[self.uploadOp addObserver:self forKeyPath:@"uploadProgress" options:NSKeyValueObservingOptionNew context:NULL];
```

### Unit Tests
---
There are a few unit tests, but currently you should run the demo projects which cover a few areas of the API in both Swift and Objective-C. Sorry about the lack of tests!


### License and Warranty
---
The license for the code is included with the project; it's basically a BSD license with attribution.

You're welcome to use it in commercial, closed-source, open source, free or any other kind of software, as long as you credit me appropriately.

The FlickrKit code comes with no warranty of any kind. I hope it'll be useful to you (it certainly is to me), but I make no guarantees regarding its functionality or otherwise.

### Contact
---
I can't answer any questions about how to use the code, but I always welcome emails telling me that you're using it, or just saying thanks.

If you create an app, which uses the code, I'd also love to hear about it. You can find my contact details on my web site, listed below.

Likewise, if you want to submit a feature request or bug report, feel free to get in touch. Better yet, fork the code and implement the feature/fix yourself, then submit a pull request.

Enjoy!

Thanks,  
##### David Casserly

Me:      http://www.davidjc.com   
My Work: http://www.devedup.com   
Twitter: http://twitter.com/devedup     
Hire Me: http://linkedin.davidjc.com

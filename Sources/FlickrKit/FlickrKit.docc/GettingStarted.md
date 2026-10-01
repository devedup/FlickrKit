# Getting Started with FlickrKit

Create a client, make your first call, and sign a user in.

## Create a client

Get an API key and secret from Flickr's [App Garden](https://www.flickr.com/services/apps/create/),
and create one client for your app:

```swift
let client = FlickrClient(apiKey: "YOUR_KEY", sharedSecret: "YOUR_SECRET")
```

The defaults keep the session in the Keychain, use `URLSession.shared`, and cache responses on disk
in the Caches directory. Each of these can be replaced, which is how the tests run without a network.

## Make a call

Describe the call with a ``FlickrMethod`` factory, adjust it, and decode the response into your
own type:

```swift
struct PhotosPage: Decodable, Sendable {
    struct Photos: Decodable, Sendable {
        var page: Int
        var pages: Int
        var photo: [Photo]
    }
    struct Photo: Decodable, Sendable {
        var id: String
        var server: String
        var secret: String
        var title: String
    }
    var photos: Photos
}

let request = FlickrMethod.Interestingness.getList()
    .page(1, perPage: 250)
    .extras(["owner_name", "o_dims"])
let page: PhotosPage = try await client.call(request)
```

Methods without a factory can be called by name:

```swift
let page: PhotosPage = try await client.call(
    "flickr.photos.getPopular",
    args: ["user_id": nsid],
    auth: .ifSignedIn,
    maxAge: FlickrCacheAge.fiveMinutes
)
```

Flickr sends some numbers as strings. Inside a custom `init(from:)`, the lenient helpers such as
`decodeFlickrIntIfPresent(forKey:)` accept either form.

## Handle errors

Every call throws a ``FlickrError``. Two cases need a response from the app:

- ``FlickrError/invalidToken(code:message:)`` means Flickr no longer accepts the user's token.
  Sign them out and offer to sign in again. ``FlickrError/requiresSignIn`` covers this and the
  "not signed in" cases.
- ``FlickrError/transport(code:description:)`` with `URLError.notConnectedToInternet` means the
  device is offline.

## Sign a user in

At launch, check the stored token. ``FlickrClient/restoreSession()`` signs the user out if Flickr
has revoked it, and leaves the session alone if the device is offline:

```swift
let user = try await client.restoreSession()
```

To sign in, run the OAuth flow in a secure browser window:

```swift
let authenticator = FlickrWebAuthenticator(client: client)
let user = try await authenticator.signIn(
    callbackURL: URL(string: "myapp://flickr-auth")!,
    permission: .write,
    anchor: window
)
```

If you show Flickr's authorize page some other way, call
``FlickrClient/beginSignIn(callbackURL:permission:)``, open the URL it returns, pass the callback URL
to ``FlickrClient/completeSignIn(callbackURL:)``, and call ``FlickrClient/cancelSignIn()`` if the
user gives up.

## Moving from FlickrKit 1.x

FlickrKit 1.x kept the token in `UserDefaults`. Move it into the Keychain once, before restoring
the session, and the user stays signed in:

```swift
try KeychainTokenStore().migrateLegacyToken()
try await client.restoreSession()
```

Image URLs work differently from 1.x: only Large 1024 and smaller can be built from the photo's
`secret` (see ``FlickrPhotoURL``). Ask for the `url_h`, `url_k`… extras, or call
`flickr.photos.getSizes`, for anything bigger.

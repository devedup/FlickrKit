# ``FlickrKit``

Call the Flickr API from Swift: OAuth sign-in, signed and cached requests, and photo URLs.

## Overview

FlickrKit wraps Flickr's REST API in a ``FlickrClient`` actor. You describe a call with a
``FlickrRequest``, usually built with one of the typed ``FlickrMethod`` factories, and decode the
JSON into your own `Decodable` types. The client signs the call with OAuth 1.0a when a user is
signed in, retries rate limits and server errors, limits how many requests run at once, and
caches responses for as long as each request allows.

Signing in is a three-legged OAuth flow. ``FlickrWebAuthenticator`` runs all of it in an
`ASWebAuthenticationSession`, and the session is kept in the Keychain by ``KeychainTokenStore``.

## Topics

### Essentials

- <doc:GettingStarted>
- ``FlickrClient``
- ``FlickrRequest``
- ``FlickrMethod``
- ``FlickrError``

### Signing in

- ``FlickrWebAuthenticator``
- ``FlickrPermission``
- ``FlickrUser``
- ``FlickrSession``
- ``FlickrAccessToken``
- ``FlickrAuthMode``
- ``FlickrTokenStore``
- ``KeychainTokenStore``
- ``InMemoryTokenStore``
- ``FlickrLegacyTokenKeys``
- ``OAuthSigner``

### Requests

- ``PhotoSearchParameters``
- ``FlickrBoundingBox``
- ``FlickrEndpoint``

### Decoding responses

- ``FlickrStatus``
- ``FlickrContent``

### Photo URLs

- ``FlickrPhotoURL``
- ``FlickrPhotoSize``
- ``FlickrStaticPhotoSize``

### Networking and caching

- ``FlickrTransport``
- ``FlickrRetryPolicy``
- ``FlickrResponseCache``
- ``DiskResponseCache``
- ``InMemoryResponseCache``
- ``FlickrCacheKey``
- ``FlickrCacheAge``

//
//  FKAPI.h
//  FlickrKit
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import <Foundation/Foundation.h>
//! Project version number for FlickrKit.
FOUNDATION_EXPORT double FlickrKitVersionNumber;

//! Project version string for FlickrKit.
FOUNDATION_EXPORT const unsigned char FlickrKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <FlickrKitOSX/PublicHeader.h>

#import "FKDUDiskCache.h"
#import "FKDataTypes.h"
#import "FKFlickrNetworkOperation.h"
#import "FKImageUploadNetworkOperation.h"
#import "FKFlickrAPIMethod.h"
#import "FKAPIMethods.h"

//for module umbrella header
#import "FKDUBlocks.h"
#import "FKDUDefaultDiskCache.h"
#import "FKDUNetworkController.h"
#import "FKDUReachability.h"
#import "FKDUStreamUtil.h"
#import "FKOFHMACSha1Base64.h"
#import "FKUploadRespone.h"
#import "FKURLBuilder.h"
#import "FKUtilities.h"


@class FKFlickrNetworkOperation;

/**
 *  The main point of entry into FlickrKit
 */
@interface FlickrKit : NSObject

//You can inject your own disk cache if you like, or just use the default one and ignore this
@property (nonatomic, strong, nullable) id<FKDUDiskCache> diskCache;
// Flickr API Key
@property (nonatomic, strong, readonly, nullable) NSString *apiKey;
@property (nonatomic, strong, readonly, nullable) NSString *secret;
// Auth
@property (nonatomic, strong, readonly, nullable) NSString *authToken;
@property (nonatomic, strong, readonly, nullable) NSString *authSecret;
@property (nonatomic, assign, readonly) FKPermission permissionGranted;

/**
 *  Access the FlickrKit shared singleton
 *
 *  @return the FlickrKit shared singleton
 */
+ (nonnull FlickrKit *) sharedFlickrKit;

#pragma mark - Initialisation

/**
 *  Run this on startup with your API key and Shared Secret
 *
 *  @param apiKey Your flickr API key
 *  @param secret Your flickr API secret
 */
- (void) initializeWithAPIKey:(nonnull NSString *)apiKey sharedSecret:(nonnull NSString *)secret;

#pragma mark - Flickr Data Requests

/**
 *  Call the Flickr API using a string apiMethod passing any requestArgs
 *
 *  @param apiMethod   The Flickr method you want to call
 *  @param requestArgs An NSDictionary of arguments to pass to the method
 *  @param completion  The completion block of code to execute on completion of the network call
 *
 *  @return The FKFlickrNetworkOperation created
 */
- (nonnull FKFlickrNetworkOperation *) call:(nonnull NSString * )apiMethod args:(nullable NSDictionary *)requestArgs completion:(nullable FKAPIRequestCompletion)completion;

/**
 *  Call the Flickr API using a string apiMethod passing any requestArgs
 *
 *  @param apiMethod   The Flickr method you want to call
 *  @param requestArgs An NSDictionary of arguments to pass to the method
 *  @param maxAge      The maximum age the cached response can be around for
 *  @param completion  The completion block of code to execute on completion of the network call
 *
 *  @return The FKFlickrNetworkOperation created
 */
- (nonnull FKFlickrNetworkOperation *) call:(nonnull NSString *)apiMethod args:(nullable NSDictionary *)requestArgs maxCacheAge:(FKDUMaxAge)maxAge completion:(nullable FKAPIRequestCompletion)completion;

/**
 *  Call the Flickr API using the model objects
 *
 *  @param method     The flickr model object method you are calling
 *  @param completion The completion block of code to execute on completion of the network call
 *
 *  @return The FKFlickrNetworkOperation created
 */
- (nonnull FKFlickrNetworkOperation *) call:(nonnull id<FKFlickrAPIMethod>)method completion:(nullable FKAPIRequestCompletion)completion;

/**
 *  Call the Flickr API using the model objects
 *
 *  @param method     The flickr model object method you are calling
 *  @param maxAge     The maximum age the cached response can be around for
 *  @param completion The completion block of code to execute on completion of the network call
 *
 *  @return The FKFlickrNetworkOperation created
 */
- (nonnull FKFlickrNetworkOperation *) call:(nonnull id<FKFlickrAPIMethod>)method maxCacheAge:(FKDUMaxAge)maxAge completion:(nullable FKAPIRequestCompletion)completion;

@end


#pragma mark - Authentication

@interface FlickrKit (Authentication)

// Check if they are authorized
@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

// 1. Begin Authorization, onSuccess display authURL in a UIWebView - the url is a callback into your app with a URL scheme
- (nonnull FKDUNetworkOperation *) beginAuthWithCallbackURL:(nonnull NSURL *)url permission:(FKPermission)permission completion:(nullable FKAPIAuthBeginCompletion)completion;
// 2. After they login and authorize the app, need to get an auth token - this will happen via your URL scheme - (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
- (nonnull FKDUNetworkOperation *) completeAuthWithURL:(nonnull NSURL *)url completion:(nullable FKAPIAuthCompletion)completion;
// 3. On returning to the app, you want to re-log them in automatically - do it here
- (nonnull FKFlickrNetworkOperation *) checkAuthorizationOnCompletion:(nullable FKAPIAuthCompletion)completion;
// 4. Logout - just removes all the stored keys
- (void) logout;

@end

#pragma mark - Photo Response

@interface FlickrKit (PhotoResponse)

- (nullable NSArray<NSDictionary<NSString *, id> *> *) photoArrayFromResponse:(nonnull NSDictionary<NSString *, id> *)response;

@end


#pragma mark - Building Photo URLs

@interface FlickrKit (ImageURL)

// Build your own from the components required
- (nonnull NSURL *) photoURLForSize:(FKPhotoSize)size photoID:(nonnull NSString *)photoID server:(nonnull NSString *)server secret:(nonnull NSString *)secret farm:(nonnull NSString *)farm;
// Utility methods to extract the photoID/server/secret/farm from the input
- (nonnull NSURL *) photoURLForSize:(FKPhotoSize)size fromPhotoDictionary:(nonnull NSDictionary *)photoDict;
- (nonnull NSURL *) buddyIconURLForUser:(nonnull NSString *)userID;

@end


#pragma mark - Photo Upload

@interface FlickrKit (PhotoUpload)

- (nonnull FKImageUploadNetworkOperation *) uploadImage:(nonnull DUImage *)image args:(nullable NSDictionary *)args completion:(nullable FKAPIImageUploadCompletion)completion;

#if TARGET_OS_IOS
- (nonnull FKImageUploadNetworkOperation *) uploadAssetURL:(nonnull NSURL *)assetURL args:(nullable NSDictionary *)args completion:(nullable FKAPIImageUploadCompletion)completion;
#endif

@end


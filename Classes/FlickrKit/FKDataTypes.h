//
//  FKDataTypes.h
//  FlickrKit
//
//  Created by David Casserly on 03/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//



typedef void (^FKAPIImageUploadCompletion)(NSString * _Nullable imageID, NSError * _Nullable error);
typedef void (^FKAPIRequestCompletion)(NSDictionary<NSString *, id> * _Nullable response,  NSError * _Nullable error);
typedef void (^FKAPIAuthBeginCompletion)(NSURL * _Nullable flickrLoginPageURL, NSError * _Nullable error);
typedef void (^FKAPIAuthCompletion)(NSString * _Nullable userName, NSString * _Nullable userId, NSString * _Nullable fullName, NSError * _Nullable error);

extern NSString *const _Nonnull FKFlickrKitErrorDomain; // Errors internally from Flickr KIT
extern NSString *const _Nonnull FKFlickrAPIErrorDomain; // Error originating from Flickr API

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Error Codes

typedef NS_ENUM(unsigned int, FKError) {
	FKErrorURLParsing		= 100,
	FKErrorResponseParsing  = 101,
    FKErrorEmptyResponse    = 102,
	
	FKErrorNoInternet		= 200,
	
	FKErrorAuthenticating	= 300,
	FKErrorNoTokenToCheck	= 301,
	FKErrorNotAuthorized	= 302,
    
	FKErrorInvalidArgs      = 400,
};

#pragma mark - Flickr API Endpoint

extern NSString *const FKFlickrRESTAPI;

typedef NS_ENUM(unsigned int, FKPhotoSize) {
    FKPhotoSizeUnknown = 0,
    FKPhotoSizeCollectionIconLarge,
    FKPhotoSizeBuddyIcon,
	FKPhotoSizeSmallSquare75,
    FKPhotoSizeLargeSquare150,
	FKPhotoSizeThumbnail100,
	FKPhotoSizeSmall240,
    FKPhotoSizeSmall320,
    FKPhotoSizeMedium500,
    FKPhotoSizeMedium640,
    FKPhotoSizeMedium800,
    FKPhotoSizeLarge1024,
    FKPhotoSizeLarge1600,
    FKPhotoSizeLarge2048,
    FKPhotoSizeOriginal,
    FKPhotoSizeVideoOriginal,
    FKPhotoSizeVideoHDMP4,
    FKPhotoSizeVideoSiteMP4,
    FKPhotoSizeVideoMobileMP4,
    FKPhotoSizeVideoPlayer,
};

typedef NS_ENUM(unsigned int, FKPermission) {
	FKPermissionRead,
	FKPermissionWrite,
	FKPermissionDelete
};

NSString *FKPermissionStringForPermission(FKPermission permission);

NSString *FKIdentifierForSize(FKPhotoSize size);

/*
 Define platform specific image wrapper class.
 */
#if TARGET_OS_IPHONE
typedef UIImage DUImage;
#else
typedef NSImage DUImage;
#endif

NS_ASSUME_NONNULL_END

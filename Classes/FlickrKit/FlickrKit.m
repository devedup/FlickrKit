//
//  FKAPI.m
//  FlickrKit
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKit.h"
#import "FKDUNetworkController.h"
#import "FKDUDefaultDiskCache.h"
#import "FKDUReachability.h"
#import "FKFlickrNetworkOperation.h"
#import "FlickrKit+ImageURL.m"
#import "FlickrKit+Authentication.m"
#import "FlickrKit+PhotoUpload.m"

@interface FlickrKit ()
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *secret;
@end

@implementation FlickrKit

+ (FlickrKit *) sharedFlickrKit {
	static dispatch_once_t onceToken;
	static FlickrKit *flickrKit = nil;
	
	dispatch_once(&onceToken, ^{
		flickrKit = [[self alloc] init];
	});
	
	return flickrKit;
}

- (void) initializeWithAPIKey:(NSString *)apiKey sharedSecret:(NSString *)secret {
	NSAssert(apiKey, @"You must pass an apiKey");
	NSAssert(secret, @"You must pass an secret");
	self.apiKey = apiKey;
	self.secret = secret;
}

- (FKFlickrNetworkOperation *) call:(NSString *)apiMethod args:(NSDictionary *)requestArgs completion:(FKAPIRequestCompletion)completion {	
    return [self call:apiMethod args:requestArgs maxCacheAge:FKDUMaxAgeNeverCache completion:completion];
}

- (FKFlickrNetworkOperation *) call:(NSString *)apiMethod args:(NSDictionary *)requestArgs maxCacheAge:(FKDUMaxAge)maxAge completion:(FKAPIRequestCompletion)completion {
	NSAssert([FlickrKit sharedFlickrKit].apiKey, @"You must pass an apiKey to initializeWithAPIKey");
	NSAssert(apiMethod, @"You must pass an apiMethod");
	NSAssert(completion, @"You must pass a completion block");
	
	if ([FKDUReachability isOffline]) {		
		if (completion) {
			completion(nil, [FKDUReachability buildOfflineErrorMessage]);
		}
		return nil;
	}
	
	if (!self.diskCache) {
		self.diskCache = [FKDUDefaultDiskCache sharedDiskCache];
	}
	
	FKFlickrNetworkOperation *op = [[FKFlickrNetworkOperation alloc] initWithAPIMethod:apiMethod arguments:requestArgs maxAgeMinutes:maxAge diskCache:self.diskCache completion:completion];
	
	[[FKDUNetworkController sharedController] execute:op];
	return op;
}

#pragma mark - Flickr Using the Model Objects

- (FKFlickrNetworkOperation *) call:(id<FKFlickrAPIMethod>)method completion:(FKAPIRequestCompletion)completion {
    return [self call:method maxCacheAge:FKDUMaxAgeNeverCache completion:completion];
}

- (FKFlickrNetworkOperation *) call:(id<FKFlickrAPIMethod>)method maxCacheAge:(FKDUMaxAge)maxAge completion:(FKAPIRequestCompletion)completion {
    NSAssert([FlickrKit sharedFlickrKit].apiKey, @"You must pass an apiKey to initializeWithAPIKey");
    NSAssert(method, @"You must pass a method");
	
	// Check if this method needs auth
	if ([method needsLogin]) {
		if (![FlickrKit sharedFlickrKit].isAuthorized) {
			NSString *errorDescription = @"You need to login to call this method";
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription};
			NSError *error = [NSError errorWithDomain:FKFlickrAPIErrorDomain code:FKErrorNotAuthorized userInfo:userInfo];
			completion(nil, error);
			return nil;
		} else {
			// Check method permission
			FKPermission permissionRequired = [method requiredPerms];
			FKPermission grantedPermission = [FlickrKit sharedFlickrKit].permissionGranted;
			if (permissionRequired > grantedPermission) {
				NSString *requiredString = FKPermissionStringForPermission(permissionRequired);
				NSString *grantedString = FKPermissionStringForPermission(grantedPermission);
				NSString *errorDescription = [NSString stringWithFormat:@"This method needs %@ access, and you have only authorized %@ access to your Flickr account.", requiredString, grantedString];
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription};
				NSError *error = [NSError errorWithDomain:FKFlickrAPIErrorDomain code:FKErrorNotAuthorized userInfo:userInfo];
				completion(nil, error);
				return nil;
			}
		}
	}	
	

    if ([FKDUReachability isOffline]) {
		if (completion) {
			completion(nil, [FKDUReachability buildOfflineErrorMessage]);
		}
		return nil;
	}
	
	if (!self.diskCache) {
		self.diskCache = [FKDUDefaultDiskCache sharedDiskCache];
	}
    
    FKFlickrNetworkOperation *op = [[FKFlickrNetworkOperation alloc] initWithAPIMethod:method maxAgeMinutes:maxAge diskCache:self.diskCache completion:completion];
	
	[[FKDUNetworkController sharedController] execute:op];
	return op;
}

#ifdef DEBUG
- (void) clearContextForTests {
	self.apiKey = @"";
	self.secret = @"";
}
#endif

@end

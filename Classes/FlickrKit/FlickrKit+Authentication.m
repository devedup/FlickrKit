//
//  FlickrKit.m
//  FlickrKit
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKit.h"
#import "FKUtilities.h"
#import "FKURLBuilder.h"
#import "FKDUReachability.h"
#import "FKFlickrNetworkOperation.h"

#define kFKStoredTokenKey @"kFKStoredTokenKey"
#define kFKStoredTokenSecret @"kFKStoredTokenSecret"

@interface FlickrKit ()
@property (nonatomic, retain) NSURL *beginAuthURL;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *authSecret;
@property (nonatomic, assign) BOOL authorized;
@property (nonatomic, assign) FKPermission permissionGranted;
@end

@implementation FlickrKit (Authentication)

- (BOOL) isAuthorized {
	return self.authorized;
}

#pragma mark - Auth URL

- (NSURL *)userAuthorizationURLWithRequestToken:(NSString *)inRequestToken requestedPermission:(FKPermission)permission {
    NSString *perms = @"";
	
	NSString *permissionString = nil;
	switch (permission) {
		case FKPermissionRead:
			permissionString = @"read";
			break;
		case FKPermissionWrite:
			permissionString = @"write";
			break;
		case FKPermissionDelete:
			permissionString = @"delete";
			break;
	}
    
	self.permissionGranted = permission;
	
	perms = [NSString stringWithFormat:@"&perms=%@", permissionString];

	///http://www.flickr.com/services/oauth/authorize
    NSString *URLString = [NSString stringWithFormat:@"http://www.flickr.com/services/oauth/authorize?oauth_token=%@%@", inRequestToken, perms];
    return [NSURL URLWithString:URLString];
}

#pragma mark - 1. Begin Authorization

- (FKDUNetworkOperation *) beginAuthWithCallbackURL:(NSURL *)url permission:(FKPermission)permission completion:(FKAPIAuthBeginCompletion)completion {
	
	if ([FKDUReachability isOffline]) {
		if (completion) {
			completion(nil, [FKDUReachability buildOfflineErrorMessage]);
		}
		return nil;
	}
	
	if (self.beginAuthURL) {
		if (completion) {
			completion(self.beginAuthURL, nil);
		}
		return nil;
	}
	
	NSDictionary *paramsDictionary = @{@"oauth_callback": [url absoluteString]};
	FKURLBuilder *urlBuilder = [[FKURLBuilder alloc] init];
    NSURL *requestURL = [urlBuilder oauthURLFromBaseURL:[NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"] method:FKHttpMethodGET params:paramsDictionary];
	
	FKDUNetworkOperation *op = [[FKDUNetworkOperation alloc] initWithURL:requestURL];
	[op sendAsyncRequestOnCompletion:^(NSURLResponse *response, NSData *data, NSError *error) {
		
		if (response) {
			NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			NSDictionary *params = FKQueryParamDictionaryFromQueryString(responseString);
			NSString *oat = params[@"oauth_token"];
			NSString *oats = params[@"oauth_token_secret"];
			if (!oat || !oats) {
				
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response};
				NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorAuthenticating userInfo:userInfo];
				if (completion) {
					completion(nil, error);
				}
			} else {
				self.authToken = oat;
				self.authSecret = oats;
				self.beginAuthURL = [self userAuthorizationURLWithRequestToken:self.authToken requestedPermission:permission];
				if (completion) {
					completion(self.beginAuthURL, nil);
				}				
			}
		} else {
			if (completion) {
				completion(nil, error);
			}
		}
	}];
	return op;
}

- (FKDUNetworkOperation *) completeAuthWithURL:(NSURL *)url completion:(FKAPIAuthCompletion)completion {
	
	if ([FKDUReachability isOffline]) {
		if (completion) {
			completion(nil, nil, nil, [FKDUReachability buildOfflineErrorMessage]);
		}
		return nil;
	}
	
	NSDictionary *result = FKQueryParamDictionaryFromURL(url);
	NSString *token = [result valueForKey:@"oauth_token"];
	NSString *verifier = [result valueForKey:@"oauth_verifier"];
	
	if (!result) {
		NSString *errorString = [NSString stringWithFormat:@"Cannot obtain token/secret from URL: %@", [url absoluteString]];
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorString};
		NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorURLParsing userInfo:userInfo];
		if (completion) {
			completion(nil, nil, nil, error);
		}
		return nil;
	}
		
	NSDictionary *paramsDictionary = @{@"oauth_token": token, @"oauth_verifier": verifier};
	FKURLBuilder *urlBuilder = [[FKURLBuilder alloc] init];
    NSURL *requestURL = [urlBuilder oauthURLFromBaseURL:[NSURL URLWithString:@"http://www.flickr.com/services/oauth/access_token"] method:FKHttpMethodGET params:paramsDictionary];
		
	FKDUNetworkOperation *op = [[FKDUNetworkOperation alloc] initWithURL:requestURL];
	[op sendAsyncRequestOnCompletion:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (response && !error) {
			
			NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			response = [response stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if ([response hasPrefix:@"oauth_problem="]) {
				self.beginAuthURL = nil;
				self.authorized = NO;
				self.authToken = nil;
				self.authSecret = nil;
				NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response};
				NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorAuthenticating userInfo:userInfo];
				if (completion) {
					completion(nil, nil, nil, error);
				}
				
			} else {
				NSDictionary *params = FKQueryParamDictionaryFromQueryString(response);
				
				NSString *fn = params[@"fullname"];
				NSString *oat = params[@"oauth_token"];
				NSString *oats = params[@"oauth_token_secret"];
				NSString *nsid = params[@"user_nsid"];
				NSString *un = params[@"username"];
				if (!fn || !oat || !oats || !nsid || !un) {
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response};
					NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorAuthenticating userInfo:userInfo];
					if (completion) {
						completion(nil, nil, nil, error);
					}
				} else {
					[[NSUserDefaults standardUserDefaults] setValue:oat forKey:kFKStoredTokenKey];
					[[NSUserDefaults standardUserDefaults] setValue:oats forKey:kFKStoredTokenSecret];
					[[NSUserDefaults standardUserDefaults] synchronize];
					self.authorized = YES;
					self.authToken = oat;
					self.authSecret = oats;
					self.beginAuthURL = nil;
					if (completion) {
						completion(un, nsid, fn, nil);
					}
				}
			}
			
		} else {
			self.beginAuthURL = nil;
			
			NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response};
			NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorAuthenticating userInfo:userInfo];
			if (completion) {
				completion(nil, nil, nil, error);
			}
		}
	}];
	return op;
}

#pragma mark - 3. On returning to the app, you want to re-log them in automatically - do it here

- (FKFlickrNetworkOperation *) checkAuthorizationOnCompletion:(FKAPIAuthCompletion)completion {
	
	if ([FKDUReachability isOffline]) {
		if (completion) {
			completion(nil, nil, nil, [FKDUReachability buildOfflineErrorMessage]);
		}
		return nil;
	}
	
	NSString *storedToken = [[NSUserDefaults standardUserDefaults] stringForKey:kFKStoredTokenKey];
	NSString *storedSecret = [[NSUserDefaults standardUserDefaults] stringForKey:kFKStoredTokenSecret];
	if(storedToken && storedSecret) {
		
		NSDictionary *args = @{@"oauth_token": storedToken};
		
		FlickrKit *flickr = [[FlickrKit alloc] init];
		FKFlickrNetworkOperation *op = [flickr call:@"flickr.auth.oauth.checkToken" args:args maxCacheAge:FKDUMaxAgeNeverCache completion:^(NSDictionary *response, NSError *error) {
			
			if (response) {
				self.authToken = storedToken;
				self.authSecret = storedSecret;
				
				NSString *username = [response valueForKeyPath:@"oauth.user.username"];
				NSString *userid = [response valueForKeyPath:@"oauth.user.nsid"];
				NSString *fullname = [response valueForKeyPath:@"oauth.user.fullname"];
				
				self.authorized = YES;
				
				if (completion) {
					completion(username, userid, fullname, nil);
				}
			} else {
				if (completion) {
					completion(nil, nil, nil, error);
				}
			}			
		}];
		return op;
	} else {
		NSString *errorDescription = @"There isn't a stored token to check. Login first.";
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription};
		NSError *error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorNoTokenToCheck userInfo:userInfo];
		if (completion) {
			completion(nil, nil, nil, error);
		}
		return nil;
	}	
}

#pragma mark - 4. Logout - just removes all the stored keys

- (void) logout {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kFKStoredTokenKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kFKStoredTokenSecret];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.authorized = NO;
	self.authSecret = nil;
	self.authToken = nil;
	self.beginAuthURL = nil;
}

@end

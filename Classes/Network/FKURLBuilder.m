//
//  FKURLBuilder.m
//  FlickrKit
//
//  Created by David Casserly on 28/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKURLBuilder.h"
#import "FKOFHMACSha1Base64.h"
#import "FlickrKit.h"
#import "FKUtilities.h"

@interface FKURLBuilder ()
@property (nonatomic, strong) FlickrKit *flickrKit;
@end

@implementation FKURLBuilder

- (id)initWithFlickrKit:(FlickrKit *)flickrKit {
    self = [super init];
    if (self) {
        self.flickrKit = flickrKit;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        NSAssert(false, @"FKURLBuilder must be initialised with a FlickrKit instance");
    }
    return self;
}

#pragma mark - URL Encryption

- (NSURL *) oauthURLFromBaseURL:(NSURL *)inURL method:(FKHttpMethod)method params:(NSDictionary *)params {
		
    NSDictionary *newArgs = [self signedOAuthHTTPQueryParameters:params baseURL:inURL method:method];
    NSMutableArray *queryArray = [NSMutableArray array];
	
	for (NSString *key in newArgs) {
		[queryArray addObject:[NSString stringWithFormat:@"%@=%@", key, FKEscapedURLStringPlus(newArgs[key])]];
	}
	
    NSString *newURLStringWithQuery = [NSString stringWithFormat:@"%@?%@", [inURL absoluteString], [queryArray componentsJoinedByString:@"&"]];
    
    return [NSURL URLWithString:newURLStringWithQuery];
}

//private
- (NSDictionary *) signedOAuthHTTPQueryParameters:(NSDictionary *)params baseURL:(NSURL *)inURL method:(FKHttpMethod)method {
	
	NSString *httpMethod = nil;
	switch (method) {
		case FKHttpMethodGET:
			httpMethod = @"GET";
			break;
		case FKHttpMethodPOST:
			httpMethod = @"POST";
			break;
		default:
			break;
	}
	
    NSMutableDictionary *newArgs = params ? [params mutableCopy] : [NSMutableDictionary dictionary];
    newArgs[@"oauth_nonce"] = [FKGenerateUUID() substringToIndex:8];
	NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    newArgs[@"oauth_timestamp"] = [NSString stringWithFormat:@"%f", time];
    newArgs[@"oauth_version"] = @"1.0";
    newArgs[@"oauth_signature_method"] = @"HMAC-SHA1";
    newArgs[@"oauth_consumer_key"] = self.flickrKit.apiKey;
    
    if (!params[@"oauth_token"] && self.flickrKit.authToken) {
        newArgs[@"oauth_token"] = self.flickrKit.authToken;
    }
    
    NSString *signatureKey = nil;
    if (self.flickrKit.authSecret) {
        signatureKey = [NSString stringWithFormat:@"%@&%@", self.flickrKit.secret, self.flickrKit.authSecret];
    } else {
        signatureKey = [NSString stringWithFormat:@"%@&", self.flickrKit.secret];
    }
    
    NSMutableString *baseString = [NSMutableString string];
    [baseString appendString:httpMethod];
    [baseString appendString:@"&"];
    [baseString appendString:FKEscapedURLStringPlus([inURL absoluteString])];
    
    NSArray *sortedKeys = [[newArgs allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [baseString appendString:@"&"];
    
	NSMutableArray *baseStrArgs = [NSMutableArray array];
	for (NSString *key in sortedKeys) {
		[baseStrArgs addObject:[NSString stringWithFormat:@"%@=%@", key, FKEscapedURLStringPlus(newArgs[key])]];
	}	
    
    [baseString appendString:FKEscapedURLStringPlus([baseStrArgs componentsJoinedByString:@"&"])];
    
    NSString *signature = FKOFHMACSha1Base64(signatureKey, baseString);
    
    newArgs[@"oauth_signature"] = signature;
    return newArgs;
}

#pragma mark - Create query string from args and sign it

- (NSString *) signedQueryStringFromParameters:(NSDictionary *)params {
    NSArray *signedParams = [self signedArgumentComponentsFromParameters:params];
    NSMutableArray *args = [NSMutableArray array];
	
	for (NSArray *param in signedParams) {
		[args addObject:[param componentsJoinedByString:@"="]];
	}

    return [args componentsJoinedByString:@"&"];
}

//private
- (NSArray *) signedArgumentComponentsFromParameters:(NSDictionary *)params {
    NSMutableDictionary *args = params ? [params mutableCopy] : [NSMutableDictionary dictionary];
	if (self.flickrKit.apiKey) {
		args[@"api_key"] = self.flickrKit.apiKey;
	}

	NSMutableArray *argArray = [NSMutableArray array];
	NSMutableString *sigString = [NSMutableString stringWithString:self.flickrKit.secret ? self.flickrKit.secret  : @""];
	NSArray *sortedKeys = [[args allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	for (NSString *key in sortedKeys) {
		NSString *value = args[key];
		[sigString appendFormat:@"%@%@", key, value];
		[argArray addObject:@[key, FKEscapedURLString(value)]];
	}
	
	NSString *signature = FKMD5FromString(sigString);
    [argArray addObject:@[@"api_sig", signature]];
	return argArray;
}


#pragma mark - Args as array

- (NSDictionary *) signedArgsFromParameters:(NSDictionary *)params method:(FKHttpMethod)method url:(NSURL *)url {
	if (self.flickrKit.isAuthorized) {
		return [self signedOAuthHTTPQueryParameters:params baseURL:url method:method];
	} else {
		NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
		NSArray *signedArgs = [self signedArgumentComponentsFromParameters:params];
		for (NSArray *comp in signedArgs) {
			[returnDict setObject:comp[1] forKey:comp[0]];
		}
		return [returnDict copy];
	}
}

@end

//
//  FKNetworkOperation.h
//  FlickrKit
//
//  Created by David Casserly on 06/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

@class FlickrKit;

#import "FKDataTypes.h"
#import "FKDUConcurrentOperation.h"
#import "FKDUDiskCache.h"
#import "FKDUnetworkOperation.h"
#import "FKFlickrAPIMethod.h"

@interface FKFlickrNetworkOperation : FKDUNetworkOperation

- (id) initWithFlickrKit:(FlickrKit *)flickrKit APIMethod:(NSString *)api arguments:(NSDictionary *)args maxAgeMinutes:(FKDUMaxAge)maxAge completion:(FKAPIRequestCompletion)completion;
- (id) initWithFlickrKit:(FlickrKit *)flickrKit APIMethod:(id<FKFlickrAPIMethod>)method maxAgeMinutes:(FKDUMaxAge)maxAge completion:(FKAPIRequestCompletion)completion;

@end

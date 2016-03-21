//
//  FKImageUploadNetworkOperation.h
//  FlickrKit
//
//  Created by David Casserly on 06/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKDUNetworkOperation.h"
#import "FKDataTypes.h"

@class FlickrKit;

@interface FKImageUploadNetworkOperation : FKDUNetworkOperation
@property (nonatomic, assign, readonly) CGFloat uploadProgress;

- (id) initWithFlickrKit:(FlickrKit *)flickrKit image:(DUImage *)image arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;

#if TARGET_OS_IOS
- (id) initWithFlickrKit:(FlickrKit *)flickrKit assetURL:(NSURL *)assetURL arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;
#endif

@end

@interface FKImageUploadNetworkOperation (ImageSerialization)
+ (NSData *) jpegSerialzation:(DUImage *)image;
@end
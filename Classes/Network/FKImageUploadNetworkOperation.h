//
//  FKImageUploadNetworkOperation.h
//  FlickrKit
//
//  Created by David Casserly on 06/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKDUNetworkOperation.h"
#import "FKDataTypes.h"

@interface FKImageUploadNetworkOperation : FKDUNetworkOperation
@property (nonatomic, assign, readonly) CGFloat uploadProgress;

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithURL:(NSURL *)url NS_UNAVAILABLE;

- (instancetype) initWithImage:(DUImage *)image arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion NS_DESIGNATED_INITIALIZER;

#if TARGET_OS_IOS
- (instancetype) initWithAssetURL:(NSURL *)assetURL arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion NS_DESIGNATED_INITIALIZER;
#endif

@end

@interface FKImageUploadNetworkOperation (ImageSerialization)
+ (NSData *) jpegSerialzation:(DUImage *)image;
@end

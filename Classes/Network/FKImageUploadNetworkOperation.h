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
- (id) initWithImage:(DUImage *)image arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;
@end

#if TARGET_OS_IPHONE
@interface FKImageUploadNetworkOperation (iOS_Addition)
- (id) initWithAssetURL:(NSURL *)assetURL arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;
@end
#endif

@interface FKImageUploadNetworkOperation (ImageSerialization)
+(NSData*)jpegSerialzation:(DUImage*)image;
@end
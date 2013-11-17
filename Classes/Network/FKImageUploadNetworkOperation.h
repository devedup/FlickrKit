//
//  FKImageUploadNetworkOperation.h
//  FlickrKit
//
//  Created by David Casserly on 06/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKDUNetworkOperation.h"
#import "FKDataTypes.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Foundation/Foundation.h>
#endif

@interface FKImageUploadNetworkOperation : FKDUNetworkOperation 

@property (nonatomic, assign, readonly) CGFloat uploadProgress;

#if TARGET_OS_IPHONE
- (id) initWithImage:(UIImage *)image arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;
#elif TARGET_OS_MAC
- (id) initWithImage:(NSImage *)image arguments:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion;
#endif

@end

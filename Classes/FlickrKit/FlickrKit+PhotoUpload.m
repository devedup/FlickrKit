//
//  FlickrKit+PhotoUpload.m
//  FlickrKit
//
//  Created by David Casserly on 05/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKit.h"
#import "FKDUNetworkController.h"

@implementation FlickrKit (PhotoUpload)

- (FKImageUploadNetworkOperation *) uploadImage:(UIImage *)image args:(NSDictionary *)args completion:(FKAPIImageUploadCompletion)completion {
	FKImageUploadNetworkOperation *imageUpload = [[FKImageUploadNetworkOperation alloc] initWithImage:image arguments:args completion:completion];
	[[FKDUNetworkController sharedController] execute:imageUpload];
    return imageUpload;
}

@end

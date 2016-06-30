//
//  DUNetworkController.h
//  FlickrKit
//
//  Created by David Casserly on 05/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com

@class DUNetworkRequestOperation;

@interface FKDUNetworkController : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

+ (FKDUNetworkController *) sharedController;

- (void) execute:(NSOperation *)operation;

#pragma mark - Network Thread

+ (void) networkRequestThreadEntryPoint:(id)object;
+ (NSThread *) networkRequestThread;

@end

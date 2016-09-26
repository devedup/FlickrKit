//
//  FKDUNetworkOperation.h
//  FlickrKit
//
//  Created by David Casserly on 05/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

typedef void (^FKDUNetworkCompletion)(NSURLResponse *response, NSData *data, NSError *error);

#import "FKDUConcurrentOperation.h"

@interface FKDUNetworkOperation : FKDUConcurrentOperation 

@property (nonatomic, strong, readonly) NSURLConnection *httpConnection;
@property (nonatomic, strong, readonly) NSMutableData *receivedData;
@property (nonatomic, strong, readonly) NSMutableURLRequest *request;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;


- (instancetype) init NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (void) sendAsyncRequestOnCompletion:(FKDUNetworkCompletion)completion;

// This is used in subclasses
- (void) connectWithRequest:(NSURLRequest *)request;

@end

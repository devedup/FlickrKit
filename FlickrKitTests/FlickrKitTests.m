//
//  FlickrKitTests.m
//  FlickrKitTests
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKitTests.h"
#import "FlickrKit.h"
#import "FKDUDiskCache.h"

@implementation FlickrKitTests

- (void)setUp {
	[[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"" sharedSecret:@""];
    [super setUp];
}

- (void) testAPI_todaysInteresting {
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	FlickrKit *flickr = [[FlickrKit alloc] init];
	[flickr request:@"flickr.interestingness.getList" args:nil maxAgeMinutes:FKDUMaxAgeOneMinute onSuccess:^(NSDictionary *response) {
		STAssertNotNil(response, @"Must have a response");
		dispatch_semaphore_signal(semaphore);
	} onError:^(NSInteger errorCode, NSString *errorDescription, NSError *error) {
		STFail(@"This shouldn't have been a success, we didn't setup an api key");		
		dispatch_semaphore_signal(semaphore);
	}];
	
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}


@end

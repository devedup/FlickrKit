//
//  FlickrKitFailTests.m
//  FlickrKit
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKitFailTests.h"
#import "FlickrKit.h"

@implementation FlickrKitFailTests

- (void)setUp {
	[[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"" sharedSecret:@""];
    [super setUp];
}

- (void) testAPI_expectFail_noAPIKey {
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	FlickrKit *flickr = [[FlickrKit alloc] init];
	[flickr request:@"flickr.interestingness.getList" args:nil maxAgeMinutes:FKDUMaxAgeNeverCache onSuccess:^(NSDictionary *response) {
		STFail(@"This shouldn't have been a success, we didn't setup an api key");
		dispatch_semaphore_signal(semaphore);
	} onError:^(NSInteger errorCode, NSString *errorDescription, NSError *error) {
		STAssertEquals(100, errorCode, @"Should be 100 error code from Flickr");
		STAssertNotNil(errorDescription, @"There should have been an error");
		dispatch_semaphore_signal(semaphore);
	}];
	
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

@end

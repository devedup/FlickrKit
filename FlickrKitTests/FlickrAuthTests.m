//
//  FlickrAuthTests.m
//  FlickrKit
//
//  Created by David Casserly on 27/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrAuthTests.h"
#import "FlickrKit.h"
#import "FlickrKit.h"
#import "FlickrKit_Tests.h"

@implementation FlickrAuthTests

- (void)setUp {
	[[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"" sharedSecret:@""];
    [super setUp];
}

- (void)tearDown {
	[[FlickrKit sharedFlickrKit] clearContextForTests];
    [super tearDown];
}

- (void) testAuth {
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	FlickrKit *auth = [FlickrKit sharedFlickrKit];
	[auth beginAuthWithCallbackURL:[NSURL URLWithString:@"devedupflickrpro://auth"] onSuccess:^(NSURL *authURL) {
		STAssertNotNil(authURL, @"We must have a url returned");
		dispatch_semaphore_signal(semaphore);
	} onError:^(NSError *error) {
		STFail(@"The auth shouldn't fail");
		dispatch_semaphore_signal(semaphore);
	}];
	
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

// For this test, I get the auth url from testAuth and then paste it into a web browser, log in and then grab the url
- (void) testAuth_afterLogin {
	NSString *urlString = @"";
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	FlickrKit *auth = [FlickrKit sharedFlickrKit];
	[auth completeAuthWithURL:[NSURL URLWithString:urlString] onSuccess:^(NSString *userName, NSString *userId, NSString *fullName) {
		STAssertNotNil(userName, @"We must have a username");
		STAssertNotNil(userId, @"We must have a userId");
		STAssertNotNil(fullName, @"We must have a fullName");
		dispatch_semaphore_signal(semaphore);
	} onError:^(NSError *error) {
		STFail(@"The auth shouldn't fail");
		dispatch_semaphore_signal(semaphore);
	}];
	
	while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}





@end

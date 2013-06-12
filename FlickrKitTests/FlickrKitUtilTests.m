//
//  FlickrKitUtilTests.m
//  FlickrKit
//
//  Created by David Casserly on 29/05/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKitUtilTests.h"
#import "FKUtilities.h"
#import "FKUtilities.h"
#import "FKDUReachability.h"

@implementation FlickrKitUtilTests

- (void) setUp {
    [super setUp];
}

- (void) testMD5 {
//	NSString *testString = @"davecasserly";
//	
//	
//	NSString *oldResult = FKOFMD5HexStringFromNSString(testString);
//	
//	NSString *newResult = FKMD5FromString(testString);
//	
//	STAssertEqualObjects(oldResult, newResult, @"Should be the same");
	
}

//- (void) testEscaping {
//	
//	//static NSString *const kEscapeChars = @"`~!@#$^&*()=+[]\\{}|;':\",/<>?";
//	
//	NSString *testString = @"dave!cas@{}?serly";
//	
//	NSString *oldResult = FKOFEscapedURLStringFromNSString(testString);
//	
//	NSString *newResult = FKEscapedURLString(testString);
//	
//	STAssertEqualObjects(oldResult, newResult, @"Should be the same");
//	
//}

//- (void) testEscapingExtra {
//	
//	NSString *const kEscapeChars = @"`~!@#$^&*()=+[]\\{}|;':\",/<>?";
//	
//	//static NSString *const kEscapeChars = @"`~!@#$^&*()=+[]\\{}|;':\",/<>?";
//	
//	NSString *testString = @"dave!cas@{}?serly";
//	
//	NSString *oldResult = FKOFEscapedURLStringFromNSStringWithExtraEscapedChars(testString, kEscapeChars);
//	
//	NSString *newResult = FKEscapedURLStringPlus(testString);
//	
//	STAssertEqualObjects(oldResult, newResult, @"Should be the same");
//	
//}

//- (void) testQueryString {
//	
//
//	NSURL *testURL = [NSURL URLWithString:@"devedupflickrpro://auth?oauth_token=cas&oauth_verifier=cas2"];
//	
//	NSString *token = nil;
//	NSString *verifier = nil;
//	FKOFExtractOAuthCallback(testURL, [NSURL URLWithString:@"devedupflickrpro://auth"], &token, &verifier);
//	
//	
//	NSDictionary *newResult = FKQueryParamDictionaryFromURL(testURL);
//	NSString *newToken = [newResult valueForKey:@"oauth_token"];
//	NSString *newVerifier = [newResult valueForKey:@"oauth_verifier"];
//	
//	STAssertEqualObjects(newToken, token, @"Should be the same");
//	STAssertEqualObjects(newVerifier, verifier, @"Should be the same");
//	
//}

//- (void) testURLString {
//	
//	
//	NSString *testString = @"http:dave=cas&dave2=cas2&dave3=cas3";
//	
//	NSDictionary *oldResult = FKOFExtractURLQueryParameter(testString);
//	
//	NSDictionary *newResult = FKQueryParamDictionaryFromQueryString(testString);
//	
//	STAssertEqualObjects(oldResult, newResult, @"Should be the same");
//	
//}

//- (void) testReachability {
//	BOOL isReachable = [FKDUReachability isConnected];
//	
//	//STAssertTrue(isReachable, @"");
//}

@end

//
//  FlickrKit+ImageURL.m
//  FlickrKit
//
//  Created by David Casserly on 04/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FlickrKit.h"

@implementation FlickrKit (ImageURL)


- (NSURL *) buddyIconURLForUser:(NSString *)userID {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://flickr.com/buddyicons/%@.jpg", userID]];
}

// Utility methods to extract the photoID/server/secret/farm from the input
- (NSURL *) photoURLForSize:(FKPhotoSize)size fromPhotoDictionary:(NSDictionary *)photoDict {
				
	//Find possible photoID
	NSString *photoID = [photoDict valueForKey:@"id"];
	if (!photoID) {
		photoID = [photoDict valueForKey:@"primary"]; //sets return this
	}
	
	//Find possible server
	NSString *server = [photoDict valueForKey:@"server"];
		
	//Find possible farm
	NSString *farm = [[photoDict valueForKey:@"farm"] stringValue];
	
	//Find possible secret
	NSString *secret = [photoDict valueForKey:@"secret"];
	
	
	return [self photoURLForSize:size photoID:photoID server:server secret:secret farm:farm];
}

- (NSURL *) photoURLForSize:(FKPhotoSize)size photoID:(NSString *)photoID server:(NSString *)server secret:(NSString *)secret farm:(NSString *)farm {
    // http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg
	// http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
    
    static NSString *photoSource = @"http://static.flickr.com/";
	
	NSMutableString *URLString = [NSMutableString stringWithString:@"http://"];
	if ([farm length]) {
		[URLString appendFormat:@"farm%@.", farm];
	}
	
	NSAssert([server length], @"Must have server attribute");
	NSAssert([photoID length], @"Must have id attribute");
	NSAssert([secret length], @"Must have secret attribute");
	[URLString appendString:[photoSource substringFromIndex:7]];
	[URLString appendFormat:@"%@/%@_%@", server, photoID, secret];
	
	NSString *sizeKey = FKIdentifierForSize(size);
	[URLString appendFormat:@"_%@.jpg", sizeKey];

	return [NSURL URLWithString:URLString];
}

@end

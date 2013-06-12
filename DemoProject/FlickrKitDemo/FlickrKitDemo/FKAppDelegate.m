//
//  FKAppDelegate.m
//  FlickrKitDemo
//
//  Created by David Casserly on 03/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKAppDelegate.h"
#import "FKViewController.h"
#import "FlickrKit.h"

@implementation FKAppDelegate

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *scheme = [url scheme];
	if([@"flickrkitdemo" isEqualToString:scheme]) {
		// I don't recommend doing it like this, it's just a demo... I use an authentication
		// controller singleton object in my projects
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UserAuthCallbackNotification" object:url userInfo:nil];			
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {		

	// Initialise FlickrKit with your flickr api key and shared secret
	NSString *apiKey = nil;
	NSString *secret = nil;
	NSAssert(apiKey, @"You need to enter your own API key and secret");
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
	
		
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    
		self.viewController = [[FKViewController alloc] initWithNibName:@"FKViewController_iPhone" bundle:nil];
		self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
		
	}
	self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}


@end

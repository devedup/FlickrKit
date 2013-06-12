//
//  FKAppDelegate.m
//  APIBuilder
//
//  Created by Casserly on 12/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved.
//

#import "FKAppDelegate.h"
#import "FKViewController.h"


@implementation FKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	self.viewController = [[FKViewController alloc] initWithNibName:@"FKViewController_iPhone" bundle:nil];

	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}


@end

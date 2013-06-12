//
//  FKAppDelegate.h
//  FlickrKitDemo
//
//  Created by David Casserly on 03/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import <UIKit/UIKit.h>

@class FKViewController;

@interface FKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) UINavigationController *navigationController;

@property (strong, nonatomic) FKViewController *viewController;

@end

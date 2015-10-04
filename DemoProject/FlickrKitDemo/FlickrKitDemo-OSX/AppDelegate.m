//
//  AppDelegate.m
//  FlickrKitDemo-OSX
//
//  Created by raxcat on 2015/10/4.
//  Copyright © 2015年 DevedUp Ltd. All rights reserved.
//

#import "AppDelegate.h"
@import FlickrKit;
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *apiKey = nil;
    NSString *secret = nil;
    if (!apiKey) {
        NSLog(@"\n----------------------------------\nYou need to enter your own 'apiKey' and 'secret' in FKAppDelegate for the demo to run. \n\nYou can get these from your Flickr account settings.\n----------------------------------\n");
        exit(0);
    }
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleIncomingURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleIncomingURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{

    NSURL *callbackURL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Callback URL: %@", [callbackURL absoluteString]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kCallbackURLNotification" object:self userInfo:@{@"callbackURL": callbackURL}];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

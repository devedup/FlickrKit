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
{
    NSWindowController * _mainWindowController;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *apiKey = @"348ea26ca45d5f9d3da7fff4822a7fd1";
    NSString *secret = @"471cc96b04e60f27";
    if (!apiKey) {
        NSLog(@"\n----------------------------------\nYou need to enter your own 'apiKey' and 'secret' in FKAppDelegate for the demo to run. \n\nYou can get these from your Flickr account settings.\n----------------------------------\n");
        exit(0);
    }
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleIncomingURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    _mainWindowController =  [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"mainWindowController"];
    [_mainWindowController showWindow:nil];
    
    
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

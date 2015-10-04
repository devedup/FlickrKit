//
//  ViewController.m
//  FlickrKitDemo-OSX
//
//  Created by raxcat on 2015/10/4.
//  Copyright © 2015年 DevedUp Ltd. All rights reserved.
//

#import "ViewController.h"
@import FlickrKit;


@interface ViewController ()
@property (nonatomic, retain) FKDUNetworkOperation *authOp;
@property (nonatomic, retain) FKDUNetworkOperation *completeAuthOp;
@property (nonatomic, retain) FKDUNetworkOperation *checkAuthOp;
@property (weak) IBOutlet NSTextField *userLabel;
@end


@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void) userAuthenticateCallback:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"kCallbackURLNotification"];
    
    NSURL *callbackURL = notification.userInfo[@"callbackURL"];
    self.completeAuthOp = [[FlickrKit sharedFlickrKit] completeAuthWithURL:callbackURL completion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [self userLoggedIn:userName userID:userId];
            } else {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                [alert show];
            }
//            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }];
}


-(void)userLoggedIn:(NSString*)userName userID:(NSString*)userID{
    self.userLabel.stringValue = [NSString stringWithFormat:@"%@(%@)", userName, userID];
}

-(IBAction)authClick:(id)sender{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticateCallback:) name:@"kCallbackURLNotification" object:nil];
    
    if ([FlickrKit sharedFlickrKit].isAuthorized) {
        [[FlickrKit sharedFlickrKit] logout];
//        [self userLoggedOut];
    } else {

        // This must be defined in your Info.plist
        // See FlickrKitDemo-Info.plist
        // Flickr will call this back. Ensure you configure your flickr app as a web app
        NSString *callbackURLString = @"flickrkitdemo://auth";
        
        // Begin the authentication process
        self.authOp = [[FlickrKit sharedFlickrKit] beginAuthWithCallbackURL:[NSURL URLWithString:callbackURLString] permission:FKPermissionDelete completion:^(NSURL *flickrLoginPageURL, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {

                    [[NSWorkspace sharedWorkspace] openURL:flickrLoginPageURL];
//                    [self.webView loadRequest:urlRequest];
                } else {
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                    [alert show];
                }
            });		
        }];
        
    }
}


@end

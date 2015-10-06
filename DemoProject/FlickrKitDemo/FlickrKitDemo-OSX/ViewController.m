//
//  ViewController.m
//  FlickrKitDemo-OSX
//
//  Created by raxcat on 2015/10/4.
//  Copyright © 2015年 DevedUp Ltd. All rights reserved.
//

#import "ViewController.h"
#import "PhotosViewController.h"
@import FlickrKit;


@interface ViewController ()
@property (nonatomic, retain) FKDUNetworkOperation *authOp;
@property (nonatomic, retain) FKDUNetworkOperation *completeAuthOp;
@property (nonatomic, retain) FKDUNetworkOperation *checkAuthOp;

@property NSString * logginedUserName;
@property NSString * logginedUserID;

@end


@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Check if there is a stored token
    // You should do this once on app launch
    self.checkAuthOp = [[FlickrKit sharedFlickrKit] checkAuthorizationOnCompletion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [self userLoggedIn:userName userID:userId];
            } else {
                [self userLoggedOut];
            }
        });		
    }];
}

- (void) userAuthenticateCallback:(NSNotification *)notification {
    @try{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCallbackURLNotification" object:nil];
    }
    @catch(NSException * exception){
        NSLog(@"Error removing observer");
    }

    NSURL *callbackURL = notification.userInfo[@"callbackURL"];
    self.completeAuthOp = [[FlickrKit sharedFlickrKit] completeAuthWithURL:callbackURL completion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [self userLoggedIn:userName userID:userId];
            } else {
                [[NSAlert alertWithError:error] runModal];
            }
        });
    }];

}


-(void)userLoggedIn:(NSString*)userName userID:(NSString*)userID{
    self.logginedUserName = userName;
    self.logginedUserID = userID;
}

-(void)userLoggedOut{
    self.logginedUserName = nil;
    self.logginedUserID = nil;
}

-(IBAction)authClick:(id)sender{
    if ([FlickrKit sharedFlickrKit].isAuthorized) {
        [[FlickrKit sharedFlickrKit] logout];
        [self userLoggedOut];
    } else {

        // This must be defined in your Info.plist
        // See FlickrKitDemo-Info.plist
        // Flickr will call this back. Ensure you configure your flickr app as a web app
        NSString *callbackURLString = @"flickrkitdemo://auth";
        
        // Begin the authentication process
        self.authOp = [[FlickrKit sharedFlickrKit] beginAuthWithCallbackURL:[NSURL URLWithString:callbackURLString] permission:FKPermissionDelete completion:^(NSURL *flickrLoginPageURL, NSError *error) {
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticateCallback:) name:@"kCallbackURLNotification" object:nil];
                    [[NSWorkspace sharedWorkspace] openURL:flickrLoginPageURL];
                } else {
                    [[NSAlert alertWithError:error] runModal];
                    
                }
            });		
        }];
        
    }
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"showMyPhotos"]){
        PhotosViewController * vc = segue.destinationController;
        vc.userID = self.logginedUserID;
    }
}

@end

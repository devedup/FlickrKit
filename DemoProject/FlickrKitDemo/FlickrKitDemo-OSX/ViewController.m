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
@property (nonatomic, retain) FKImageUploadNetworkOperation *uploadOp;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

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


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        self.progressIndicator.doubleValue = progress;
        //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    });
}

-(IBAction)selectImage:(id)sender{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"jpg", @"png"];
    
    openPanel.allowsMultipleSelection = NO;
    [openPanel beginWithCompletionHandler: ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSURL* imageurl = [[openPanel URLs] objectAtIndex:0];
            if(!imageurl)
                return;
            
            self.progressIndicator.doubleValue = 0;
            self.progressIndicator.hidden = NO;
            
            NSDictionary *uploadArgs = @{@"title": @"Test Photo", @"description": @"A Test Photo via FlickrKitDemo", @"is_public": @"0", @"is_friend": @"0", @"is_family": @"0", @"hidden": @"2"};
            
            self.uploadOp = [[FlickrKit sharedFlickrKit] uploadImage:[[NSImage alloc] initWithContentsOfURL:imageurl] args:uploadArgs completion:^(NSString *imageID, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [[NSAlert alertWithError:error] runModal];
                    } else {
                        NSLog(@"upload complete");
                    }
                    self.progressIndicator.hidden = YES;
                    [self.uploadOp removeObserver:self forKeyPath:@"uploadProgress" context:NULL];
                });
            }];
            [self.uploadOp addObserver:self forKeyPath:@"uploadProgress" options:NSKeyValueObservingOptionNew context:NULL];
            
        }
    }];

}

@end

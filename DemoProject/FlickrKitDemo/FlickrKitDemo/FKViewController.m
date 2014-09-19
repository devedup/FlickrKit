//
//  FKViewController.m
//  FlickrKitDemo
//
//  Created by David Casserly on 03/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import "FKViewController.h"
#import "FlickrKit.h"
#import "FKAuthViewController.h"
#import "FKPhotosViewController.h"

@interface FKViewController ()
@property (nonatomic, retain) FKFlickrNetworkOperation *todaysInterestingOp;
@property (nonatomic, retain) FKFlickrNetworkOperation *myPhotostreamOp;
@property (nonatomic, retain) FKDUNetworkOperation *completeAuthOp;
@property (nonatomic, retain) FKDUNetworkOperation *checkAuthOp;
@property (nonatomic, retain) FKImageUploadNetworkOperation *uploadOp;
@property (nonatomic, retain) NSString *userID;
@end

@implementation FKViewController


- (void) dealloc {
    [self.todaysInterestingOp cancel];
	[self.myPhotostreamOp cancel];
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticateCallback:) name:@"UserAuthCallbackNotification" object:nil];
	
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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void) viewWillDisappear:(BOOL)animated {	
	//Cancel any operations when you leave views
    self.navigationController.navigationBarHidden = NO;
    
    [self.todaysInterestingOp cancel];
	[self.myPhotostreamOp cancel];
	[self.completeAuthOp cancel];
	[self.checkAuthOp cancel];
    [self.uploadOp cancel];
    [super viewWillDisappear:animated];
}
#pragma mark - Auth

- (void) userAuthenticateCallback:(NSNotification *)notification {
	NSURL *callbackURL = notification.object;
    self.completeAuthOp = [[FlickrKit sharedFlickrKit] completeAuthWithURL:callbackURL completion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!error) {
				[self userLoggedIn:userName userID:userId];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			[self.navigationController popToRootViewControllerAnimated:YES];
		});
	}];
}

- (void) userLoggedIn:(NSString *)username userID:(NSString *)userID {
	self.userID = userID;
	[self.authButton setTitle:@"Logout" forState:UIControlStateNormal];
	self.authLabel.text = [NSString stringWithFormat:@"You are logged in as %@", username];
}

- (void) userLoggedOut {
	[self.authButton setTitle:@"Login" forState:UIControlStateNormal];
	self.authLabel.text = @"Login to flickr";
}

#pragma mark - Button Actions

- (IBAction)loadTodaysInterestingPressed:(id)sender {
	/*
		Example using the model objects
	 */
	FKFlickrInterestingnessGetList *interesting = [[FKFlickrInterestingnessGetList alloc] init];
	interesting.per_page = @"15";
	self.todaysInterestingOp = [[FlickrKit sharedFlickrKit] call:interesting completion:^(NSDictionary *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (response) {				
				NSMutableArray *photoURLs = [NSMutableArray array];
				for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
					NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoDictionary];
					[photoURLs addObject:url];
				}
				
				FKPhotosViewController *fivePhotos = [[FKPhotosViewController alloc] initWithURLArray:photoURLs];
				[self.navigationController pushViewController:fivePhotos animated:YES];
				
			} else {
				/*
					Iterating over specific errors for each service
				 */
				switch (error.code) {
					case FKFlickrInterestingnessGetListError_ServiceCurrentlyUnavailable:
						
						break;
					default:
						break;
				}
								
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
        });				
	}];
}

- (IBAction)photostreamButtonPressed:(id)sender {
	if ([FlickrKit sharedFlickrKit].isAuthorized) {
		/*
			Example using the string/dictionary method of using flickr kit
		 */
		self.myPhotostreamOp = [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"user_id": self.userID, @"per_page": @"15"} maxCacheAge:FKDUMaxAgeNeverCache completion:^(NSDictionary *response, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (response) {
					NSMutableArray *photoURLs = [NSMutableArray array];
					for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
						NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoDictionary];
						[photoURLs addObject:url];
					}
					
					FKPhotosViewController *fivePhotos = [[FKPhotosViewController alloc] initWithURLArray:photoURLs];
					[self.navigationController pushViewController:fivePhotos animated:YES];
					
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
					[alert show];
				}
			});			
		}];		
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

- (IBAction)choosePhotoPressed:(id)sender {
	if ([FlickrKit sharedFlickrKit].isAuthorized) {
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.delegate = self;
		imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		[self presentViewController:imagePicker animated:YES completion:nil];
		
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

- (IBAction)searchErrorPressed:(id)sender {
	
	/*
		Another example - not using the factory
	 */
	// this will give an error because I haven't narrowed down the search, which flickr requires
	FKFlickrPhotosSearch *search = [[FKFlickrPhotosSearch alloc] init];
	[[FlickrKit sharedFlickrKit] call:search completion:^(NSDictionary *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!response) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
        });		
	}];
	
}

- (IBAction)searchPressed:(id)sender {
	[self.view endEditing:YES];
	
	FKFlickrPhotosSearch *search = [[FKFlickrPhotosSearch alloc] init];
	search.text = self.searchText.text;
	search.per_page = @"15";
	[[FlickrKit sharedFlickrKit] call:search completion:^(NSDictionary *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (response) {
				NSMutableArray *photoURLs = [NSMutableArray array];
				for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
					NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoDictionary];
					[photoURLs addObject:url];
				}
				
				
				FKPhotosViewController *fivePhotos = [[FKPhotosViewController alloc] initWithURLArray:photoURLs];
				[self.navigationController pushViewController:fivePhotos animated:YES];
				
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
		});
	}];
	
}

- (IBAction) authButtonPressed:(id)sender {
	if ([FlickrKit sharedFlickrKit].isAuthorized) {
		[[FlickrKit sharedFlickrKit] logout];
		[self userLoggedOut];
	} else {
		FKAuthViewController *authView = [[FKAuthViewController alloc] init];
		[self.navigationController pushViewController:authView animated:YES];
	}	
}

#pragma mark - Progress KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        self.progress.progress = progress;
        //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    });    
}


#pragma mark - UIImagePickerControllerDelegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL* imageurl = [info objectForKey:UIImagePickerControllerReferenceURL];
	
    NSDictionary *uploadArgs = @{@"title": @"Test Photo", @"description": @"A Test Photo via FlickrKitDemo", @"is_public": @"0", @"is_friend": @"0", @"is_family": @"0", @"hidden": @"2"};
    
    self.progress.progress = 0.0;
	self.uploadOp =  [[FlickrKit sharedFlickrKit] uploadAssetURL:imageurl args:uploadArgs completion:^(NSString *imageID, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			} else {
				NSString *msg = [NSString stringWithFormat:@"Uploaded image ID %@", imageID];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
            [self.uploadOp removeObserver:self forKeyPath:@"uploadProgress" context:NULL];
        });
	}];    
    [self.uploadOp addObserver:self forKeyPath:@"uploadProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end

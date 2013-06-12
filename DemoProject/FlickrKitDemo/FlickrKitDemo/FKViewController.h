//
//  FKViewController.h
//  FlickrKitDemo
//
//  Created by David Casserly on 03/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

@interface FKViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *photostreamButton;

@property (weak, nonatomic) IBOutlet UIButton *authButton;
@property (weak, nonatomic) IBOutlet UILabel *authLabel;
@property (weak, nonatomic) IBOutlet UILabel *todaysInterestingLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UITextField *searchText;

- (IBAction)loadTodaysInterestingPressed:(id)sender;
- (IBAction)authButtonPressed:(id)sender;
- (IBAction)photostreamButtonPressed:(id)sender;
- (IBAction)choosePhotoPressed:(id)sender;
- (IBAction)searchErrorPressed:(id)sender;
- (IBAction)searchPressed:(id)sender;

@end

//
//  PhotosViewController.m
//  FlickrKitDemo
//
//  Created by brianliu on 2015/10/6.
//  Copyright © 2015年 DevedUp Ltd. All rights reserved.
//

#import "PhotosViewController.h"
@import FlickrKit;
@interface PhotosViewController ()
@property (nonatomic, retain) FKFlickrNetworkOperation *myPhotostreamOp;
@property (strong) NSMutableArray * photoURLs;

@property (weak) IBOutlet NSScrollView * imageScrollView;
@property (strong) NSView * documentView;

@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
    if ([FlickrKit sharedFlickrKit].isAuthorized) {
        /*
         Example using the string/dictionary method of using flickr kit
         */
        self.myPhotostreamOp = [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"user_id": self.userID, @"per_page": @"15"} maxCacheAge:FKDUMaxAgeNeverCache completion:^(NSDictionary *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response) {
                    self.photoURLs = [NSMutableArray new];
                    for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
                        NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoDictionary];
                        [self.photoURLs addObject:url];
                    }
                    
                    [self showPhotos:self.photoURLs];
                    
                } else {
                    [[NSAlert alertWithError:error] runModal];
                }
            });			
        }];		
    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
    }
    
}


-(void)showPhotos:(NSArray*)photoURLs{
    for (NSURL *url in photoURLs) {
        
        NSURLSessionDownloadTask *downloadPhotoTask = [[NSURLSession sharedSession]
                                                       downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                           // 3
                                                           NSImage *downloadedImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:location]];
                                                           [self addImageToView:downloadedImage];
                                                       }];
        [downloadPhotoTask resume];
        
    }
}

- (void) addImageToView:(NSImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!self.documentView){
            self.documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.imageScrollView.bounds.size.width, 0)];
            self.imageScrollView.documentView = self.documentView;
        }
        
        NSImageView *imageView = [[NSImageView alloc] init];
        imageView.image = image;
        CGFloat width = CGRectGetWidth(self.documentView.frame);
        CGFloat imageRatio = image.size.width / image.size.height;
        CGFloat height = width / imageRatio;
        CGFloat x = 0;
        CGFloat y = self.documentView.frame.size.height;
        
        imageView.frame = CGRectMake(x, y, width, height);
        
        CGFloat newHeight = self.documentView.frame.size.height + height;
        self.documentView.frame = NSMakeRect(0, 0, width, newHeight);
        
        [self.documentView addSubview:imageView];
    });
}
@end

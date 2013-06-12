//
//  FKFivePhotosViewController.h
//  FlickrKitDemo
//
//  Created by David Casserly on 04/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//

#import <UIKit/UIKit.h>

@interface FKPhotosViewController : UIViewController

- (id) initWithURLArray:(NSArray *)urlArray;

@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;

@end

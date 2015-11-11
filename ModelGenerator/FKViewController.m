//
//  FKViewController.m
//  APIBuilder
//
//  Created by Casserly on 12/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved.
//

#import "FKViewController.h"
#import "FKAPIBuilder.h"

@interface FKViewController ()

@end

@implementation FKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)generatePressed:(id)sender {
	BOOL __unused success = [[FKAPIBuilder sharedBuilder] buildAPI];
	self.startButton.enabled = NO;
}

@end

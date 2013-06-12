//
//  FKAPIBuilder.h
//  FlickrKit
//
//  Created by David Casserly on 10/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FKAPIBuilder : NSObject

+ (FKAPIBuilder *) sharedBuilder;

- (BOOL) buildAPI;

@end

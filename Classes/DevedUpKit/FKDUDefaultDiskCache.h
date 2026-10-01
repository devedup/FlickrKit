//
//  FKDUDefaultDiskCache.h
//  FlickrKit
//
//  Created by David Casserly on 05/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com

#import "FKDUDiskCache.h"

/**
 *  File-backed cache for Flickr API responses. Every method is safe to call from any thread:
 *  all file access and size bookkeeping is serialised on a private queue.
 *
 *  Keys are hashed before they are used as file names, so a key may contain any characters
 *  and be any length. Entries are also scoped by `scopeIdentifier` so that responses cached
 *  for one Flickr account are never served to another (or to an anonymous session).
 */
@interface FKDUDefaultDiskCache : NSObject <FKDUDiskCache>

@property (nonatomic, assign, readonly) NSUInteger currentSizeOfCache;

/**
 *  Identifies whose responses are in the cache, normally the signed-in user's NSID, or nil when
 *  nobody is signed in. FlickrKit sets this as authorisation changes. Entries written under one
 *  scope are invisible under any other scope.
 */
@property (nonatomic, copy, nullable) NSString *scopeIdentifier;

+ (nonnull FKDUDefaultDiskCache *) sharedDiskCache;

#pragma mark - Clear the cache completely

- (void) emptyTheCache;

#pragma mark - Trimming the cache - do it during app going to background

- (nonnull NSString *) trimTheCache;

@end

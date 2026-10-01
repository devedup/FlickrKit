//
//  FKDUDefaultDiskCache.m
//  FlickrKit
//
//  Created by David Casserly on 05/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com

#import "FKDUDefaultDiskCache.h"
#import "FKUtilities.h"

// Length of the hex MD5 digest that every cache file is named with.
static const NSUInteger FKDUHashedFileNameLength = 32;

@interface FKDUDefaultDiskCache ()
// Everything below is only touched on `queue`.
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) NSUInteger cacheSize;
@property (nonatomic, assign) BOOL cacheSizeKnown;
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, assign) NSUInteger maxDiskCacheSize;
@property (nonatomic, copy) NSString *scope;
@end

@implementation FKDUDefaultDiskCache

+ (NSString *) cachesDirectory {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
}

+ (FKDUDefaultDiskCache *) sharedDiskCache {
    static dispatch_once_t onceToken;
    static FKDUDefaultDiskCache * __sharedManager = nil;
    
    dispatch_once(&onceToken, ^{
        __sharedManager = [[self alloc] init];
    });
    
    return __sharedManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        self.maxDiskCacheSize = 100000000; //That's 100 MB
        self.queue = dispatch_queue_create("com.devedup.flickrkit.diskcache", DISPATCH_QUEUE_SERIAL);
        self.cacheDirectory = [self createCacheDirectory];
    }
    return self;
}

// Resolved once at init so the directory path is immutable and needs no locking afterwards.
- (NSString *) createCacheDirectory {
    NSString *directory = [[FKDUDefaultDiskCache cachesDirectory] stringByAppendingPathComponent:@"FlickrKitDiskCache"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directory]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Error creating cache directory: %@", error);
            return nil;
        }
    }
    return directory;
}

- (NSString *) cacheDir {
    return self.cacheDirectory;
}

#pragma mark - Scope

- (void) setScopeIdentifier:(NSString *)scopeIdentifier {
    dispatch_sync(self.queue, ^{
        self.scope = scopeIdentifier;
    });
}

- (NSString *) scopeIdentifier {
    __block NSString *scope = nil;
    dispatch_sync(self.queue, ^{
        scope = self.scope;
    });
    return scope;
}

#pragma mark - Keys to file names (queue only)

// The raw key is the API method plus its arguments verbatim. That can contain '/' (search text),
// exceed the 255 byte file name limit, or collide across accounts, so hash it together with the scope.
- (NSString *) fileNameForKey:(NSString *)key {
    NSString *scoped = [NSString stringWithFormat:@"%@|%@", self.scope ?: @"", key];
    return FKMD5FromString(scoped);
}

- (NSString *) localPathForKey:(NSString *)key {
    return [self.cacheDirectory stringByAppendingPathComponent:[self fileNameForKey:key]];
}

+ (BOOL) isHashedFileName:(NSString *)fileName {
    if (fileName.length != FKDUHashedFileNameLength) {
        return NO;
    }
    static NSCharacterSet *nonHex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nonHex = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    });
    return [fileName rangeOfCharacterFromSet:nonHex].location == NSNotFound;
}

- (NSUInteger) fileSizeAtPath:(NSString *)path {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [attrs[NSFileSize] unsignedIntegerValue];
}

// Unsigned subtraction that can never wrap round to a huge number.
- (void) decreaseCacheSizeBy:(NSUInteger)bytes {
    self.cacheSize = bytes > self.cacheSize ? 0 : self.cacheSize - bytes;
}

#pragma mark - Data from the cache

- (BOOL) isDate:(NSDate *)date moreThanMinutesAgo:(NSInteger)minutes {
    NSTimeInterval intervalFromNow = fabs(date.timeIntervalSinceNow);
    if(intervalFromNow > (minutes * 60)) {
        return YES;
    } else {
        return NO;
    }
}

- (NSData *) dataForKey:(NSString *)key maxAgeMinutes:(FKDUMaxAge)maxAgeMinutes {
    if (0 == maxAgeMinutes || key == nil || self.cacheDirectory == nil) {
        return nil;
    }
    
    __block NSData *data = nil;
    dispatch_sync(self.queue, ^{
        NSString *localPath = [self localPathForKey:key];
        NSError *error = nil;
        NSDictionary *properties = [[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:&error];
        if (properties && !error) {
            //Check the modified date falls within the max age
            NSDate *modDate = properties[NSFileModificationDate];
            BOOL expired = [self isDate:modDate moreThanMinutesAgo:maxAgeMinutes];
            if (!expired) {
                data = [[NSFileManager defaultManager] contentsAtPath:localPath];
            }
        }
    });
    return data;
}

#pragma mark - Store Data in the cache

- (void) storeData:(NSData *)data forKey:(NSString *)key {
    if (key == nil || data == nil || self.cacheDirectory == nil) {
        return;
    }
    
    dispatch_sync(self.queue, ^{
        NSString *localPath = [self localPathForKey:key];
        
        // Replacing an entry must not count its old bytes twice.
        NSUInteger previousSize = [self fileSizeAtPath:localPath];
        
        if ([[NSFileManager defaultManager] createFileAtPath:localPath contents:data attributes:nil]) {
            [self decreaseCacheSizeBy:previousSize];
            self.cacheSize += data.length;
        } else {
            NSLog(@"ERROR: Could not create file at path: %@", localPath);
        }
    });
}

#pragma mark - Remove item (NSData) from cache

- (void) removeDataForKey:(NSString *)key {
    if (key == nil || self.cacheDirectory == nil) {
        return;
    }
    
    dispatch_sync(self.queue, ^{
        NSString *localPath = [self localPathForKey:key];
        NSUInteger size = [self fileSizeAtPath:localPath];
        if ([[NSFileManager defaultManager] removeItemAtPath:localPath error:nil]) {
            [self decreaseCacheSizeBy:size];
        }
    });
}

#pragma mark - Caculating the size of the cache

// Walks the directory once and remembers the total. Files that pre-date hashed names can never be
// hit again (their keys were used verbatim), so they are deleted here rather than counted.
- (NSUInteger) currentSizeOfCacheOnQueue {
    if (!self.cacheSizeKnown && self.cacheDirectory != nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:self.cacheDirectory error:nil];
        NSUInteger totalSize = 0;
        
        for (NSString *file in dirContents) {
            NSString *path = [self.cacheDirectory stringByAppendingPathComponent:file];
            if ([FKDUDefaultDiskCache isHashedFileName:file]) {
                totalSize += [self fileSizeAtPath:path];
            } else {
                [fileManager removeItemAtPath:path error:nil];
            }
        }
        
        self.cacheSize = totalSize;
        self.cacheSizeKnown = YES;
        NSLog(@"cache size is: %lu", (unsigned long)totalSize);
    }
    return self.cacheSize;
}

- (NSUInteger) currentSizeOfCache {
    __block NSUInteger size = 0;
    dispatch_sync(self.queue, ^{
        size = [self currentSizeOfCacheOnQueue];
    });
    return size;
}

#pragma mark - Empty the cache

- (void) emptyTheCache {
    if (self.cacheDirectory == nil) {
        return;
    }
    dispatch_sync(self.queue, ^{
        NSError *error = nil;
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory error:&error];
        for (NSString *file in dirContents) {
            NSString *path = [self.cacheDirectory stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
        self.cacheSize = 0;
        self.cacheSizeKnown = YES;
    });
}

#pragma mark - Trimming the cache - do it during app going to background

- (NSString *) trimTheCache {
    NSAssert(![NSThread currentThread].isMainThread, @"should be in background");
    NSUInteger targetBytes = self.maxDiskCacheSize * 0.75;
    NSLog(@"Checking disk cache size. Limit %lu bytes", (unsigned long)targetBytes);
    
    __block NSString *size = @"0";
    if (self.cacheDirectory == nil) {
        return size;
    }
    
    dispatch_sync(self.queue, ^{
        NSUInteger currentSize = [self currentSizeOfCacheOnQueue];
        size = [NSString stringWithFormat:@"%lu", (unsigned long)currentSize];
        
        if (currentSize <= targetBytes) {
            return;
        }
        
        NSLog(@"Time to clean the cache! size is: %@, %lu", self.cacheDirectory, (unsigned long)currentSize);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:self.cacheDirectory error:&error];
        if (error) {
            return;
        }
        
        // Stat each file once, then delete least recently modified first until under the target.
        NSMutableArray<NSDictionary *> *entries = [NSMutableArray arrayWithCapacity:dirContents.count];
        for (NSString *file in dirContents) {
            NSString *path = [self.cacheDirectory stringByAppendingPathComponent:file];
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:path error:nil];
            NSDate *modified = attrs[NSFileModificationDate] ?: [NSDate distantPast];
            NSNumber *fileSize = attrs[NSFileSize] ?: @0;
            [entries addObject:@{@"path": path, @"modified": modified, @"size": fileSize}];
        }
        [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"modified"] compare:b[@"modified"]];
        }];
        
        for (NSDictionary *entry in entries) {
            if (self.cacheSize <= targetBytes) {
                break;
            }
            if ([fileManager removeItemAtPath:entry[@"path"] error:nil]) {
                [self decreaseCacheSizeBy:[entry[@"size"] unsignedIntegerValue]];
            }
        }
        NSLog(@"Remaining cache size: %lu, target size: %lu", (unsigned long)self.cacheSize, (unsigned long)targetBytes);
    });
    
    NSLog(@"Finished checking disk cache");
    return size;
}

@end

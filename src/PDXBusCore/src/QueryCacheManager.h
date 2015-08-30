//
//  QueryCacheManager.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "UserPrefs.h"
#import "MemoryCaches.h"
#import "SharedFile.h"

#define kCacheDateAndTime   0
#define kCacheData          1

@interface QueryCacheManager : NSObject <ClearableCache>
{
    NSMutableDictionary *   _cache;
    SharedFile *            _sharedFile;
    int                     _maxSize;
}

@property (nonatomic) int maxSize;
@property (nonatomic, retain)   NSMutableDictionary *cache;
@property (nonatomic, retain)   SharedFile *sharedFile;


- (id)initWithFileName:(NSString *)shortFileName;
- (void)deleteCacheFile;
+ (NSString *)getCacheKey:(NSString *)query;
- (NSArray *)getCachedQuery:(NSString *)cacheQuery;
- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write;
- (void)removeFromCache:(NSString *)cacheQuery;
- (void)memoryWarning;


@end

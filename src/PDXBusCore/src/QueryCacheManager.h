//
//  QueryCacheManager.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Andrew Wallace
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
#define kAlwaysAgeOut      -1

@interface QueryCacheManager : NSObject <ClearableCache>

@property (nonatomic)           int maxSize;
@property (nonatomic, strong)   NSMutableDictionary<NSString *, NSArray*> *cache;
@property (nonatomic, strong)   SharedFile *sharedFile;
@property (nonatomic)           int ageOutDays;

- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write;
- (instancetype)initWithFileName:(NSString *)shortFileName;
- (NSArray *)getCachedQuery:(NSString *)cacheQuery;
- (void)removeFromCache:(NSString *)cacheQuery;
- (void)deleteCacheFile;
- (void)memoryWarning;
- (void)writeCache;

+ (instancetype)cacheWithFileName:(NSString *)shortFileName;
+ (NSString *)getCacheKey:(NSString *)query;

@end

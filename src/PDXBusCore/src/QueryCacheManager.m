//
//  QueryCacheManager.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "QueryCacheManager.h"
#import "TriMetTypes.h"
#import "DebugLogging.h"
#import <UIKit/UIKit.h>

@implementation QueryCacheManager

@synthesize maxSize = _maxSize;
@synthesize cache = _cache;
@synthesize sharedFile = _sharedFile;


- (void)dealloc
{
    self.cache          = nil;
    self.sharedFile     = nil;
    
    [MemoryCaches removeCache:self];
    
    [super dealloc];
}

- (void)openCache
{
    if (self.cache == nil && [UserPrefs singleton].useCaching)
    {

        if (self.sharedFile.urlToSharedFile !=nil)
        {
            self.cache = [NSMutableDictionary dictionaryWithContentsOfURL:self.sharedFile.urlToSharedFile];
        }
    
        if (self.cache == nil)
        {
            self.cache = [NSMutableDictionary dictionary];
        }
    }
}

- (void)writeCache
{
    if (self.cache!=nil && self.sharedFile.urlToSharedFile != nil && [UserPrefs singleton].useCaching)
    {
        [self.sharedFile writeDictionary:self.cache];
    }
}

- (instancetype)initWithFileName:(NSString *)fileName
{
    if ((self = [super init]))
	{
        self.sharedFile = [[[SharedFile alloc] initWithFileName:fileName initFromBundle:NO] autorelease];
        
        _maxSize               = 0;
        
        [MemoryCaches addCache:self];
    }
    
    return self;
}

- (void)deleteCacheFile
{
   
    [self.sharedFile deleteFile];
    self.cache = [NSMutableDictionary dictionary];
}

+ (NSString *)getCacheKey:(NSString *)query
{
    NSMutableString *cacheKey = [query.mutableCopy autorelease];
    
    [cacheKey replaceOccurrencesOfString:TRIMET_APP_ID 
                              withString:@"" 
                                 options:NSCaseInsensitiveSearch 
                                   range:NSMakeRange(0, cacheKey.length)]; 
    return cacheKey;
}

- (NSArray *)getCachedQuery:(NSString *)cacheQuery
{
    if ([UserPrefs singleton].useCaching)
    {
        [self openCache];
        return self.cache[cacheQuery];
    }
    return nil;
}

- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write
{
    if ([UserPrefs singleton].useCaching)
    {
        [self openCache];
        NSMutableArray *arrayToCache = [NSMutableArray array];
    
        [arrayToCache insertObject:[NSDate date] atIndex:kCacheDateAndTime];
        [arrayToCache insertObject:item atIndex:kCacheData];
    
        (self.cache)[cacheQuery] = arrayToCache; 
    
        if (self.maxSize > 0 && self.cache.count > 1)
        {
            // Eviction time
            NSString *oldestKey    = nil;
            NSDate   *oldestDate   = nil;
        
            while (self.cache.count > self.maxSize)
            {
                for (NSString *str in self.cache)
                {
                    NSArray *obj = self.cache[str];
                    NSDate  *objDate = obj[kCacheDateAndTime];
                    if (oldestKey == nil  || [oldestDate compare:objDate] == NSOrderedDescending)
                    {
                        oldestKey    = str;
                        oldestDate   = objDate;
                    }
                }
                if (oldestKey!=nil)
                {
                    [self.cache removeObjectForKey:oldestKey];
                }
            }
        }
    
        if (write)
        {
            [self writeCache];
        }
    }
}

- (void)removeFromCache:(NSString *)cacheQuery
{
    if ([UserPrefs singleton].useCaching)
    {
        [self openCache];
        [self.cache removeObjectForKey:cacheQuery]; 
    }
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Releasing query cache %p\n", self.cache);
    [self writeCache];
    self.cache = nil;
}

@end

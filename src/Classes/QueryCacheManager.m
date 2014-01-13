//
//  QueryCacheManager.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "QueryCacheManager.h"
#import "TriMetTypes.h"

@implementation QueryCacheManager

@synthesize maxSize = _maxSize;
@synthesize fullFileName = _fullFileName;
@synthesize cache = _cache;

- (void)dealloc
{
    self.fullFileName = nil;
    self.cache        = nil;
    
    [super dealloc];
}

- (void)openCache
{
    if (self.cache == nil && [UserPrefs getSingleton].useCaching)
    {
        // Check for cache in Documents directory. 
        NSFileManager *fileManager = [NSFileManager defaultManager];
    
        if ([fileManager fileExistsAtPath:self.fullFileName] == YES)
        {
            self.cache = [[[NSMutableDictionary alloc] initWithContentsOfFile:self.fullFileName] autorelease];
        }
    
        if (self.cache == nil)
        {
            self.cache = [[[NSMutableDictionary alloc] init] autorelease];
        }
    }
}

- (void)writeCache
{
    if (self.cache!=nil && self.fullFileName != nil && [UserPrefs getSingleton].useCaching)
    {
        //
        // Crash logs show that this often crashes here - but it is hard
        // to say why.  This is my attempt to catch that - saving the
        // cache is nice but if it fails we'll catch it and not worry.
        //
        @try {
            [self.cache writeToFile:self.fullFileName atomically:YES];
        }
        @catch (NSException *exception) 
        {
            NSLog(@"Failed to write the cache %@\n", self.fullFileName);
            // clear the local cache, as I assume it is corrupted.
            [self deleteCacheFile];
        }
        
    }
}


- (id)initWithFileName:(NSString *)fileName
{
    if ((self = [super init]))
	{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
        
		self.fullFileName      = [documentsDirectory stringByAppendingPathComponent:fileName]; 
        _maxSize               = 0;
    }
    
    return self;
}

- (void)deleteCacheFile
{
    @try {
        if (self.fullFileName !=nil)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:self.fullFileName error:nil];
        }
    }
    @catch (NSException *exception) {
        // if this fails don't worry
    }
        
	self.cache = [[[NSMutableDictionary alloc] init] autorelease];
}

+ (NSString *)getCacheKey:(NSString *)query
{
    NSMutableString *cacheKey = [[[NSMutableString alloc] initWithString:query] autorelease];
    
    [cacheKey replaceOccurrencesOfString:TRIMET_APP_ID 
                              withString:@"" 
                                 options:NSCaseInsensitiveSearch 
                                   range:NSMakeRange(0, [cacheKey length])]; 
    return cacheKey;
}

- (NSArray *)getCachedQuery:(NSString *)cacheQuery
{
    if ([UserPrefs getSingleton].useCaching)
    {
        [self openCache];
        return [self.cache objectForKey:cacheQuery];
    }
    return nil;
}

- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write
{
    if ([UserPrefs getSingleton].useCaching)
    {
        [self openCache];
        NSMutableArray *arrayToCache = [[[NSMutableArray alloc] init] autorelease];
    
        [arrayToCache insertObject:[NSDate date] atIndex:kCacheDateAndTime];
        [arrayToCache insertObject:item atIndex:kCacheData];
    
        [self.cache setObject:arrayToCache forKey:cacheQuery]; 
    
        if (self.maxSize > 0 && self.cache.count > 1)
        {
            // Eviction time
            NSString *oldestKey    = nil;
            NSDate   *oldestDate   = nil;
        
            while (self.cache.count > self.maxSize)
            {
                for (NSString *str in self.cache)
                {
                    NSArray *obj = [self.cache objectForKey:str];
                    NSDate  *objDate = [obj objectAtIndex:kCacheDateAndTime];
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
    if ([UserPrefs getSingleton].useCaching)
    {
        [self openCache];
        [self.cache removeObjectForKey:cacheQuery]; 
    }
}

@end

//
//  QueryCacheManager.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "QueryCacheManager.h"
#import "TriMetTypes.h"
#import "DebugLogging.h"
#import "TriMetXML.h"

@implementation QueryCacheManager

- (void)dealloc
{
    
    [MemoryCaches removeCache:self];
    
}

- (void)openCache
{
    if (self.cache == nil && [UserPrefs sharedInstance].useCaching)
    {
        if (self.sharedFile.urlToSharedFile !=nil)
        {
            NSPropertyListFormat format;
            self.cache = [self.sharedFile readFromFile:&format];
            
            if (self.cache != nil && format != NSPropertyListBinaryFormat_v1_0)
            {
                [self writeCache];
            }
        }
    
        if (self.cache == nil)
        {
            self.cache = [NSMutableDictionary dictionary];
        }
    }
}

- (void)writeCache
{
    if (self.cache!=nil && self.sharedFile.urlToSharedFile != nil && [UserPrefs sharedInstance].useCaching)
    {
        [self.sharedFile writeDictionaryBinary:self.cache];
    }
}

+ (instancetype)cacheWithFileName:(NSString *)shortFileName
{
    return [[[self class] alloc] initWithFileName:shortFileName];
}

- (instancetype)initWithFileName:(NSString *)fileName
{
    if ((self = [super init]))
    {
        self.sharedFile = [SharedFile fileWithName:fileName initFromBundle:NO];
        
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
    NSMutableString *cacheKey = query.mutableCopy;
    
    [cacheKey replaceOccurrencesOfString:[TriMetXML appId]
                              withString:@"" 
                                 options:NSCaseInsensitiveSearch 
                                   range:NSMakeRange(0, cacheKey.length)]; 
    return cacheKey;
}

- (NSArray *)getCachedQuery:(NSString *)cacheQuery
{
    if ([UserPrefs sharedInstance].useCaching)
    {
        [self openCache];
        
        if (self.cache)
        {
            NSArray *result = self.cache[cacheQuery];
            if (result && self.ageOutDays == kAlwaysAgeOut)
            {
                [self removeFromCache:cacheQuery];
                return nil;
            }
            else if (result && self.ageOutDays > 0)
            {
                NSDate *itemDate = result[kCacheDateAndTime];
                NSCalendar *cal = [NSCalendar currentCalendar];
                int units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear;
                
                NSDateComponents *itemDateComponents = [cal components:units fromDate:itemDate];
                NSDateComponents *nowDateComponents =  [cal components:units fromDate:[NSDate date]];
                
#define DEBUG_DATE(X) DEBUG_LOG(@"%@ %ld %ld\n", @#X,(long)itemDateComponents.X,(long)nowDateComponents.X)
                
                DEBUG_DATE(year);
                DEBUG_DATE(month);
                DEBUG_DATE(day);
                DEBUG_DATE(weekOfYear);
                
                
                /* This code is just to confirm that weeks change on Sunday! */
                /*
                 DEBUG_LOG(@"Cached week %d\n", itemDateComponents.week);
                 DEBUG_LOG(@"week now %d\n",    nowDateComponents.week);
                 
                 NSDateComponents *testDateComponents1 = [[NSDateComponents alloc] init];
                 testDateComponents1.day = 12; // Saturday
                 testDateComponents1.month = 6;
                 testDateComponents1.year = 2010;
                 
                 NSDate *testDate1 = [cal dateFromComponents:testDateComponents1];
                 testDateComponents1 = [cal components:NSWeekCalendarUnit fromDate:testDate1];
                 DEBUG_LOG(@"week 1 %d\n",    testDateComponents1.week);
                 
                 
                 testDateComponents1 = [[NSDateComponents alloc] init;
                 
                 testDateComponents1.day = 13;    // Sunday
                 testDateComponents1.month = 6;
                 testDateComponents1.year = 2010;
                 
                 testDate1 = [cal dateFromComponents:testDateComponents1];
                 testDateComponents1 = [cal components:NSWeekCalendarUnit fromDate:testDate1];
                 DEBUG_LOG(@"week 2 %d\n",    testDateComponents1.week);
                 */
                
                //
                // The cache expires at the end of the current calendar day, or at the end
                // of the current week. Weeks end on Satuday, and the above code proves that
                // the weeks in the calendar also end on Saturdays.
                // This conincides with when TriMet updates the routes, which is at 12am Sunday,
                // or occasionally 12am mid meek.
                //
                
                NSInteger itemWeek = itemDateComponents.weekOfYear;
                NSInteger nowWeek  = nowDateComponents.weekOfYear;
                
                if (
                     (self.ageOutDays == 1  && (  itemDateComponents.year  == nowDateComponents.year
                                            &&    itemDateComponents.month == nowDateComponents.month
                                            &&    itemDateComponents.day   == nowDateComponents.day))
                     ||
                     (self.ageOutDays == 7  && (  itemDateComponents.year  == nowDateComponents.year
                                            &&    itemWeek                 == nowWeek))
                     ||
                     (self.ageOutDays == 28 && ( ((nowDateComponents.year - itemDateComponents.year) * 52) + nowWeek - itemWeek) <= 4)
                     ||
                     (self.ageOutDays == 0)
                     )
                {
                    return result;
                }
                else
                {
                    [self removeFromCache:cacheQuery];
                    return nil;
                }
            }
            return result;
        }
    }
    return nil;
}

- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write
{
    if ([UserPrefs sharedInstance].useCaching && item!=nil && cacheQuery!=nil)
    {
        [self openCache];
        
        if (self.cache)
        {
            (self.cache)[cacheQuery] = @[[NSDate date], item];
            
            if (self.maxSize > 0 && self.cache.count > 1)
            {
                // Eviction time
                __block NSString *oldestKey    = nil;
                __block NSDate   *oldestDate   = nil;
                
                while (self.cache.count > self.maxSize)
                {
                    oldestKey   = nil;
                    oldestDate  = nil;
                    DEBUG_LOGL(self.cache.count);
                    [self.cache enumerateKeysAndObjectsUsingBlock: ^void (NSString* str, NSArray* obj, BOOL *stop)
                     {
                         NSDate *objDate = obj[kCacheDateAndTime];
                         if (oldestKey == nil  || [oldestDate compare:objDate] == NSOrderedDescending)
                         {
                             oldestKey    = str;
                             oldestDate   = objDate;
                         }
                     }];
                    if (oldestKey!=nil)
                    {
                        [self.cache removeObjectForKey:oldestKey];
                        DEBUG_LOGL(self.cache.count);
                    }
                    else
                    {
                        // We break to avoid an endless loop, and item must be removed
                        // usually or we'd go around forever. 
                        break;
                    }
                }
            }
            
            if (write)
            {
                [self writeCache];
            }
        }
    }
}

- (void)removeFromCache:(NSString *)cacheQuery
{
    if ([UserPrefs sharedInstance].useCaching)
    {
        [self openCache];
        
        if (self.cache)
        {
            [self.cache removeObjectForKey:cacheQuery];
        }
    }
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Releasing query cache %p\n", self.cache);
    [self writeCache];
    self.cache = nil;
}

@end

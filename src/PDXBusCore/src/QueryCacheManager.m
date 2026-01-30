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


#define DEBUG_LEVEL_FOR_FILE LogData

#import "QueryCacheManager.h"
#import "DebugLogging.h"
#import "TriMetTypes.h"
#import "TriMetXML.h"
#import <malloc/malloc.h>

@interface QueryCacheManager () {
    dispatch_queue_t _syncQueue;
    NSMutableDictionary<NSString *, NSArray *> *_rawCache;
}

@property (nonatomic, strong) SharedFile *sharedFile;

@end

@implementation QueryCacheManager

- (instancetype)initWithFileName:(NSString *)fileName {
    if ((self = [super init])) {
        _sharedFile = [SharedFile fileWithName:fileName initFromBundle:NO sync:self];
        _maxSize = 0;
        _syncQueue = dispatch_queue_create("org.teleportaloo.pdxbus.querycache.sync",
                                           DISPATCH_QUEUE_CONCURRENT);

        [MemoryCaches addCache:self];
    }
    return self;
}

- (void)dealloc {
    [MemoryCaches removeCache:self];
}

- (void)rawOpenCache {
    if (self->_rawCache == nil) {
        if (self.sharedFile.urlToSharedFile != nil) {
            NSPropertyListFormat format;
            self->_rawCache = [self.sharedFile readFromFile:&format];

            if (self->_rawCache != nil && format != NSPropertyListBinaryFormat_v1_0) {
                [self rawWriteCache];
            }
        }

        if (self->_rawCache == nil) {
            self->_rawCache = [NSMutableDictionary dictionary];
        }
    }
}

- (void)rawWriteCache {
    if (self->_rawCache != nil && self.sharedFile.urlToSharedFile != nil) {
        [self.sharedFile writeDictionaryBinary:self->_rawCache];
    }
}

- (void)writeCache {
    dispatch_barrier_async(_syncQueue, ^{
      [self rawWriteCache];
    });
}

+ (instancetype)cacheWithFileName:(NSString *)shortFileName {
    return [[[self class] alloc] initWithFileName:shortFileName];
}

- (void)deleteCacheFile {
    dispatch_barrier_sync(_syncQueue, ^{
      [self.sharedFile deleteFile];
      self->_rawCache = [NSMutableDictionary dictionary];
    });
}

+ (NSString *)getCacheKey:(NSString *)query {
    NSMutableString *cacheKey = query.mutableCopy;

    [cacheKey replaceOccurrencesOfString:TriMetXML.appId
                              withString:@""
                                 options:NSCaseInsensitiveSearch
                                   range:NSMakeRange(0, cacheKey.length)];
    return cacheKey;
}

- (NSUInteger)sizeInBytes {
    __block NSUInteger size = 0;

    dispatch_sync(_syncQueue, ^{
      self->_rawCache = nil;
      [self rawOpenCache];

#define OBJ_SIZE(X) malloc_size((__bridge const void *)(X))
      size += OBJ_SIZE(self);
      size += OBJ_SIZE(self->_rawCache);
      size += OBJ_SIZE(self.sharedFile);

      DEBUG_LOG_long(size);

      [self->_rawCache
          enumerateKeysAndObjectsUsingBlock:^void(NSString *str, NSArray *obj, BOOL *stop) {
            NSDate *objDate = obj[kCacheDateAndTime];
            NSData *objItem = obj[kCacheData];

            size += OBJ_SIZE(obj);
            size += OBJ_SIZE(objDate);
            size += OBJ_SIZE(objItem);
            size += OBJ_SIZE(str);
            size += str.length;
            size += objItem.length;
          }];

      DEBUG_LOG_long(self->_rawCache.count);
      DEBUG_LOG_class(self);
      DEBUG_LOG_long(size);
    });

    return size;
}

- (int)cacheAgeInDays:(NSString *)cacheQuery {
    __block int age = kNoCache;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenCache];

      if (self->_rawCache) {
          NSArray *result = self->_rawCache[cacheQuery];

          if (result && self.ageOutDays == kAlwaysAgeOut) {
              [self removeFromCache:cacheQuery];
              age = kNoCache;
          } else if (result && self.ageOutDays > 0) {
              NSDate *itemDate = result[kCacheDateAndTime];

              age = -[itemDate timeIntervalSinceNow];

              age = (int)(age / (60 * 60 * 24));
          }
      };
    });
    return age;
}

- (NSDate *)cacheDate:(NSString *)cacheQuery {
    __block NSDate *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenCache];

      if (self->_rawCache) {
          NSArray *array = self->_rawCache[cacheQuery];

          if (array) {
              result = array[kCacheDateAndTime];
          }
      }
    });
    return result;
}

- (int)daysLeftInCacheIncludingToday:(NSString *)cacheQuery {
    __block int days = 0;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenCache];

      if (self->_rawCache) {
          NSArray *result = self->_rawCache[cacheQuery];

          if (result && self.ageOutDays == kAlwaysAgeOut) {
              [self removeFromCache:cacheQuery];
              days = 0;
              return;
          } else if (result && self.ageOutDays > 0) {
              NSDate *itemDate = result[kCacheDateAndTime];
              NSCalendar *cal = [NSCalendar currentCalendar];
              int units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                          NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday;

              NSDateComponents *itemDateComponents = [cal components:units fromDate:itemDate];
              NSDateComponents *nowDateComponents = [cal components:units fromDate:[NSDate date]];

#define DEBUG_DATE(X)                                                                              \
    DEBUG_LOG(@"%@ %ld %ld\n", @ #X, (long)itemDateComponents.X, (long)nowDateComponents.X)

              DEBUG_DATE(year);
              DEBUG_DATE(month);
              DEBUG_DATE(day);
              DEBUG_DATE(weekOfYear);

              /* This code is just to confirm that weeks change on Sunday! */
              /*
               DEBUG_LOG(@"Cached week %d\n", itemDateComponents.week);
               DEBUG_LOG(@"week now %d\n",    nowDateComponents.week);

               NSDateComponents *testDateComponents1 = [[NSDateComponents
               alloc] init]; testDateComponents1.day = 12; // Saturday
               testDateComponents1.month = 6;
               testDateComponents1.year = 2010;

               NSDate *testDate1 = [cal
               dateFromComponents:testDateComponents1]; testDateComponents1 =
               [cal components:NSWeekCalendarUnit fromDate:testDate1];
               DEBUG_LOG(@"week 1 %d\n",    testDateComponents1.week);


               testDateComponents1 = [[NSDateComponents alloc] init;

               testDateComponents1.day = 13;    // Sunday
               testDateComponents1.month = 6;
               testDateComponents1.year = 2010;

               testDate1 = [cal dateFromComponents:testDateComponents1];
               testDateComponents1 = [cal components:NSWeekCalendarUnit
               fromDate:testDate1]; DEBUG_LOG(@"week 2 %d\n",
               testDateComponents1.week);
               */

              //
              // The cache expires at the end of the current calendar day, or
              // at the end of the current week. Weeks end on Satuday, and the
              // above code proves that the weeks in the calendar also end on
              // Saturdays. This conincides with when TriMet updates the
              // routes, which is at 12am Sunday, or occasionally 12am mid
              // meek.
              //
              NSInteger nowWeekday = nowDateComponents.weekday;
              NSInteger itemWeek = itemDateComponents.weekOfYear;
              NSInteger nowWeek = nowDateComponents.weekOfYear;

              DEBUG_LOG_long(nowWeekday);

              switch (self.ageOutDays) {
              default:
              case 0:
                  days = 0;
                  return;

              case 1:

                  if ((itemDateComponents.year == nowDateComponents.year &&
                       itemDateComponents.month == nowDateComponents.month &&
                       itemDateComponents.day == nowDateComponents.day)) {
                      days = 1;
                      return;
                  }
                  days = 0;
                  return;

              case 7: {
                  if (itemDateComponents.year != nowDateComponents.year && itemWeek != nowWeek) {
                      days = 0;
                      return;
                  }

                  days = (int)(8 - nowWeekday);
                  return;
              }

              case 28: {
                  NSInteger weeks = ((nowDateComponents.year - itemDateComponents.year) * 52) +
                                    nowWeek - itemWeek;

                  if (weeks > 4) {
                      days = 0;
                      return;
                  }

                  days = (int)(1 + (4 - weeks) * 7 - nowWeekday);
                  return;
              }
              }
          }
      }
    });
    return days;
}

- (NSArray *)getCachedQuery:(NSString *)cacheQuery {
    __block NSArray *query = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenCache];

      if (self->_rawCache) {
          NSArray *result = self->_rawCache[cacheQuery];

          if (result && self.ageOutDays == kAlwaysAgeOut) {
              [self removeFromCache:cacheQuery];
              return;
          } else if (result && self.ageOutDays > 0) {
              NSDate *itemDate = result[kCacheDateAndTime];
              NSCalendar *cal = [NSCalendar currentCalendar];
              int units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                          NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday;

              NSDateComponents *itemDateComponents = [cal components:units fromDate:itemDate];
              NSDateComponents *nowDateComponents = [cal components:units fromDate:[NSDate date]];

#define DEBUG_DATE(X)                                                                              \
    DEBUG_LOG(@"%@ %ld %ld\n", @ #X, (long)itemDateComponents.X, (long)nowDateComponents.X)

              DEBUG_DATE(year);
              DEBUG_DATE(month);
              DEBUG_DATE(day);
              DEBUG_DATE(weekOfYear);

              /* This code is just to confirm that weeks change on Sunday! */
              /*
               DEBUG_LOG(@"Cached week %d\n", itemDateComponents.week);
               DEBUG_LOG(@"week now %d\n",    nowDateComponents.week);

               NSDateComponents *testDateComponents1 = [[NSDateComponents
               alloc] init]; testDateComponents1.day = 12; // Saturday
               testDateComponents1.month = 6;
               testDateComponents1.year = 2010;

               NSDate *testDate1 = [cal
               dateFromComponents:testDateComponents1]; testDateComponents1 =
               [cal components:NSWeekCalendarUnit fromDate:testDate1];
               DEBUG_LOG(@"week 1 %d\n",    testDateComponents1.week);


               testDateComponents1 = [[NSDateComponents alloc] init;

               testDateComponents1.day = 13;    // Sunday
               testDateComponents1.month = 6;
               testDateComponents1.year = 2010;

               testDate1 = [cal dateFromComponents:testDateComponents1];
               testDateComponents1 = [cal components:NSWeekCalendarUnit
               fromDate:testDate1]; DEBUG_LOG(@"week 2 %d\n",
               testDateComponents1.week);
               */

              //
              // The cache expires at the end of the current calendar day, or
              // at the end of the current week. Weeks end on Satuday, and the
              // above code proves that the weeks in the calendar also end on
              // Saturdays. This conincides with when TriMet updates the
              // routes, which is at 12am Sunday, or occasionally 12am mid
              // meek.
              //

              NSInteger itemWeek = itemDateComponents.weekOfYear;
              NSInteger nowWeek = nowDateComponents.weekOfYear;

              if ((self.ageOutDays == 1 && (itemDateComponents.year == nowDateComponents.year &&
                                            itemDateComponents.month == nowDateComponents.month &&
                                            itemDateComponents.day == nowDateComponents.day)) ||
                  (self.ageOutDays == 7 &&
                   (itemDateComponents.year == nowDateComponents.year && itemWeek == nowWeek)) ||
                  (self.ageOutDays == 28 &&
                   (((nowDateComponents.year - itemDateComponents.year) * 52) + nowWeek -
                    itemWeek) <= 4) ||
                  (self.ageOutDays == 0) || (self.ageOutDays == INT_MAX)) {
                  query = result;
                  return;
              } else if (self.setAgedOutFlagIfOld) {
                  self.agedOut = YES;
                  query = result;
                  return;
              } else {
                  [self removeFromCache:cacheQuery];
                  query = nil;
                  return;
              }
          }
          query = result;
          return;
      }

      query = nil;
    });
    return query;
}

- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write {
    dispatch_barrier_async(_syncQueue, ^{
      if (item != nil && cacheQuery != nil) {
          [self rawOpenCache];

          if (self->_rawCache) {
              (self->_rawCache)[cacheQuery] = @[ [NSDate date], item ];

              if (self.maxSize > 0 && self->_rawCache.count > 1) {
                  // Eviction time
                  __block NSString *oldestKey = nil;
                  __block NSDate *oldestDate = nil;

                  while (self->_rawCache.count > self.maxSize) {
                      oldestKey = nil;
                      oldestDate = nil;
                      DEBUG_LOG_long(self->_rawCache.count);
                      [self->_rawCache enumerateKeysAndObjectsUsingBlock:^void(
                                           NSString *str, NSArray *obj, BOOL *stop) {
                        NSDate *objDate = obj[kCacheDateAndTime];

                        if (oldestKey == nil ||
                            [oldestDate compare:objDate] == NSOrderedDescending) {
                            oldestKey = str;
                            oldestDate = objDate;
                        }
                      }];

                      if (oldestKey != nil) {
                          [self->_rawCache removeObjectForKey:oldestKey];
                          DEBUG_LOG_long(self->_rawCache.count);
                      } else {
                          // We break to avoid an endless loop, and item must
                          // be removed usually or we'd go around forever.
                          break;
                      }
                  }
              }

              if (write) {
                  [self rawWriteCache];
              }
          }
      }
    });
}

- (void)removeFromCache:(NSString *)cacheQuery {
    dispatch_barrier_async(_syncQueue, ^{
      [self rawOpenCache];

      if (self->_rawCache) {
          [self->_rawCache removeObjectForKey:cacheQuery];
      }
    });
}

- (void)memoryWarning {
    dispatch_barrier_sync(_syncQueue, ^{
      DEBUG_LOG(@"Releasing query cache %p\n", self->_rawCache);
      [self rawWriteCache];
      self->_rawCache = nil;
    });
}

- (NSEnumerator<NSString *> *)keyEnumerator {
    __block NSEnumerator<NSString *> *result = nil;
    dispatch_sync(_syncQueue, ^{
      result = [self->_rawCache keyEnumerator];
    });
    return result;
}

@end

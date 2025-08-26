//
//  StopNameCacheManager.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopNameCacheManager.h"
#import "RunParallelBlocks.h"
#import "TaskDispatch.h"
#import "XMLDepartures.h"
#import "XMLMultipleDepartures.h"

#define kStopNameCacheLocation 0
#define kStopNameCacheLongDescription 1
#define kStopNameCacheShortDescription 2
#define kStopNameCacheArraySizeWithShortDescription 3

@implementation StopNameCacheManager

+ (instancetype)cache {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    if ((self = [super initWithFileName:@"stopNameCache.plist"])) {
        self.maxSize = 55;
    }

    return self;
}

+ (NSString *)shortDirection:(NSString *)dir {
    static NSDictionary *directions = nil;

    DoOnce((^{
      directions = @{
          @"Northbound" : @"N",
          @"Southbound" : @"S",
          @"Eastbound" : @"E",
          @"Westbound" : @"W",
          @"Northeastbound" : @"NE",
          @"Southeastbound" : @"SE",
          @"Southwestbound" : @"SW",
          @"Northwestbound" : @"NW"
      };
    }));

    if (dir == nil) {
        return @"";
    }

    NSString *result = directions[dir];

    if (result == nil) {
        return dir;
    }

    return result;
}

+ (NSString *)getShortName:(NSArray *)data {
    if (data) {
        if (data.count >= kStopNameCacheArraySizeWithShortDescription) {
            return data[kStopNameCacheShortDescription];
        }

        return data[kStopNameCacheLongDescription];
    }

    return nil;
}

+ (NSString *)getLongName:(NSArray *)data {
    if (data) {
        return data[kStopNameCacheLongDescription];
    }

    return nil;
}

+ (NSString *)getStopId:(NSArray *)data {
    if (data) {
        return data[kStopNameCacheLocation];
    }

    return nil;
}

- (NSDictionary *)getStopNames:(NSArray<NSString *> *)stopIds
                 fetchAndCache:(bool)fetchAndCache
                       updated:(bool *)updated
                    completion:(void (^__nullable)(int item))completion {
    NSMutableArray<NSString *> *itemsToFetch = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray *> *names =
        [NSMutableDictionary dictionary];
    __block int items = 0;

    for (NSString *stopId in stopIds) {
        NSArray *cachedData = [self getCachedQuery:stopId];
        NSArray *result = nil;

        // Need to check if this is an old cache with only two items in it, if
        // so we read it again.

        if (cachedData == nil) {
            if (fetchAndCache) {
                [itemsToFetch addObject:stopId];
            } else {
                NSString *name = [NSString
                    stringWithFormat:@"Stop ID %@ (getting full name)", stopId];
                result = @[ stopId, name, name ];

                if (updated) {
                    *updated = NO;
                }

                names[stopId] = result;
            }
        } else {
            NSData *data = cachedData[kCacheData];
#ifndef PDXBUS_WATCH
            // Untested
            NSError *error = nil;
            result = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class]
                                                       fromData:data
                                                          error:&error];
#else
            result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif

            if (fetchAndCache && result &&
                result.count < (kStopNameCacheArraySizeWithShortDescription)) {
                [itemsToFetch addObject:stopId];
            } else {
                names[stopId] = result;

                if (completion) {
                    completion(items);
                    items++;
                }
            }
        }
    }

    if (itemsToFetch.count > 0 && fetchAndCache) {
        __block NSArray *batches =
            [XMLMultipleDepartures batchesFromEnumerator:stopIds
                                          selToGetStopId:@selector(self)
                                                     max:INT_MAX];
        int batch = 0;

        RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

        while (batch < batches.count) {
            [parallelBlocks startBlock:^{
              XMLMultipleDepartures *multiple = [XMLMultipleDepartures
                  xmlWithOptions:DepOptionsOneMin | DepOptionsNoDetours];

              [multiple getDeparturesForStopIds:batches[batch]];

              @synchronized(self) {
                  for (XMLDepartures *deps in multiple) {
                      if (deps.stopId) {
                          NSString *longDesc = nil;
                          NSString *shortDesc = nil;
                          NSString *stopId = deps.stopId;

                          bool cache = NO;

                          if (deps.locDesc != nil) {
                              if (deps.locDir.length > 0) {
                                  longDesc = [NSString
                                      stringWithFormat:@"%@ (%@)", deps.locDesc,
                                                       deps.locDir];
                                  shortDesc = [NSString
                                      stringWithFormat:
                                          @"%@: %@",
                                          [StopNameCacheManager
                                              shortDirection:deps.locDir],
                                          deps.locDesc];
                              } else {
                                  longDesc = deps.locDesc;
                                  shortDesc = longDesc;
                              }

                              cache = YES;
                          } else {
                              longDesc =
                                  [NSString stringWithFormat:@"Stop ID - %@",
                                                             deps.stopId];
                              shortDesc = longDesc;
                          }

                          if (deps.stopId && longDesc && shortDesc) {
                              NSArray *result =
                                  @[ deps.stopId, longDesc, shortDesc ];

                              if (updated) {
                                  *updated = YES;
                              }

                              names[stopId] = result;

                              if (cache) {
#ifndef PDXBUS_WATCH
                                  // Untested
                                  NSError *error = nil;
                                  NSData *data = [NSKeyedArchiver
                                      archivedDataWithRootObject:result
                                           requiringSecureCoding:NO
                                                           error:&error];
#else
                                        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result];
#endif
                                  [self addToCache:stopId item:data write:YES];
                              }
                          }
                      }

                      if (completion) {
                          completion(items);
                          items++;
                      }
                  }
              }
            }];

            batch++;
        }

        [parallelBlocks waitForBlocks];
    }

    return names;
}

@end

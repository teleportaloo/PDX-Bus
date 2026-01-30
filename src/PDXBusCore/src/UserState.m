//
//  UserState.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogSettings

#import "UserState.h"
#import "DebugLogging.h"
#import "NSMutableDictionary+MutableElements.h"
#import "TaskDispatch.h"
#import "UserParams.h"

#define kFaves @"faves"
#define kRecents @"recents"
#define kVehicleIds @"vehicleIds"

#define kRecentTrips @"trips"
#define kLastTrip @"last_trip"
#define kLastRunApp @"last_run"

#define kLastLocate @"last_locate"

#define kTakeMeHome @"take_me_home"
#define kWatchSequenceNumber @"watch_sequence"

#define kDefaultFileName @"appData"
#define kDefaultFileType @"plist"

#define kDefaultFile kDefaultFileName @"." kDefaultFileType

#define IS_MORNING(hour) (hour < 12)

#define kiCloudKeyPrefixSize 4
#define kiCloudKey(i) [NSString stringWithFormat:@"fave%ld", (long)(i)]
#define kisCloudKeyFave(key)                                                                       \
    (((key).length > kiCloudKeyPrefixSize) &&                                                      \
     [[key substringToIndex:kiCloudKeyPrefixSize] isEqualToString:@"fave"])
#define kCloudKeyItem(key) [[key substringFromIndex:kiCloudKeyPrefixSize] integerValue]

#define kMaxRecentStops 25
#define kMaxRecentTrips 25

@interface NSArray (MutableDeepCopy)

- (NSMutableArray *)mutableDeepCopy;

@end

@implementation NSArray (MutableDeepCopy)

- (NSMutableArray *)mutableDeepCopy {
    NSMutableArray *newArray = NSMutableArray.array;

    for (NSObject *obj in self) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            [newArray addObject:[(NSDictionary *)obj mutableDeepCopy]];
        } else if ([obj isKindOfClass:NSArray.class]) {
            [newArray addObject:[(NSArray *)obj mutableDeepCopy]];
        } else {
            [newArray addObject:obj];
        }
    }

    return newArray;
}

@end

@implementation NSDictionary (MutableDeepCopy)

- (NSMutableDictionary *)mutableDeepCopy {
    NSMutableDictionary *newDict = NSMutableDictionary.dictionary;

    [self
        enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
          if ([obj isKindOfClass:NSDictionary.class]) {
              [newDict setObject:[(NSDictionary *)obj mutableDeepCopy] forKey:key];
          } else if ([obj isKindOfClass:NSArray.class]) {
              [newDict setObject:[(NSArray *)obj mutableDeepCopy] forKey:key];
          } else {
              [newDict setObject:obj forKey:key];
          }
        }];

    return newDict;
}

@end

@interface UserState () {
    dispatch_queue_t _syncQueue;
    bool _rawDirty;
    NSMutableDictionary *_rawData;
}

@end

@implementation UserState

static NSMutableDictionary *safeMutableDictionary(NSObject *obj) {
    if ([obj isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)obj;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return ((NSDictionary *)obj).mutableDeepCopy;
    } else {
        return nil;
    }
}

static NSMutableArray *safeMutableArray(NSObject *obj) {
    if ([obj isKindOfClass:[NSMutableArray class]]) {
        return (NSMutableArray *)obj;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return ((NSArray *)obj).mutableDeepCopy;
    } else {
        return nil;
    }
}

@dynamic dirty;
@dynamic watchData;

- (bool)dirty {
    __block bool result = NO;
    dispatch_sync(_syncQueue, ^{
      result = _rawDirty;
    });
    return result;
}

- (void)setDirty:(bool)favesChanged {
    dispatch_barrier_async(_syncQueue, ^{
      self->_rawDirty = favesChanged;
    });
}

- (void)memoryWarning {
    dispatch_barrier_sync(_syncQueue, ^{
      DEBUG_LOG(@"Clearing app data %p\n", self->_rawData);
      [self rawWriteState:NO];
      self->_rawData = nil;
    });
}

- (NSMutableArray *)rawGetOrInitItem:(NSString *)item {
    bool readOnly = self.readOnly;
    NSMutableArray *cache = self->_rawData[item];
    if (cache == nil) {
        cache = [NSMutableArray array];

        self->_rawData[item] = cache;
        [self rawWriteState:readOnly];
    }
    return cache;
}

- (void)rawLoad {
    if (_rawData == nil) {
        // We have to read the property list and make it mutable
        _rawData = [NSMutableDictionary
            mutableContainersWithContentsOfURL:_sharedUserCopyOfPlist.urlToSharedFile];

        [self rawGetOrInitItem:kRecentTrips];
        [self rawGetOrInitItem:kVehicleIds];
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        _sharedUserCopyOfPlist = [SharedFile fileWithName:kDefaultFile
                                           initFromBundle:YES
                                                     sync:self];

        _syncQueue = dispatch_queue_create("org.teleportaloo.pdxbus.UserState.sync",
                                           DISPATCH_QUEUE_CONCURRENT);

        _readOnly = FALSE;
        _lastRunKey = kLastRunApp;

        dispatch_barrier_async(_syncQueue, ^{
          [self rawLoad];
        });
    }

    return self;
}

+ (UserState *)sharedInstance {
    static UserState *singleton = nil;

    DO_ONCE(^{
      singleton = [[UserState alloc] init];
      [MemoryCaches addCache:singleton];
    });
    return singleton;
}

- (NSMutableDictionary *)newFave {
    return [MutableUserParams withChosenName:kNewBookMark location:[NSString string]]
        .mutableDictionary;
}

#ifndef PDXBUS_WATCH

- (void)rawFillGapInFaves:(NSMutableArray *)faves upTo:(NSInteger)total {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

    while (total > faves.count) {
        // Next item is item at faves.count

        NSDictionary *filler = [store objectForKey:kiCloudKey(faves.count)];

        if (filler == nil) {
            filler = self.newFave;
        }

        [faves addObject:filler.mutableCopy];
    }
}

#endif // !PDXBUS_WATCH

- (void)clearCloud {
#ifndef PDXBUS_WATCH
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *all = [store dictionaryRepresentation];

    for (NSString *keys in all) {
        [store removeObjectForKey:keys];
    }

    [store synchronize];
#endif // !PDXBUS_WATCH
}

- (void)mergeWithCloud:(NSArray *)changed {
#ifndef PDXBUS_WATCH

    DEBUG_FUNC();

    bool readOnly = self.readOnly;

    dispatch_barrier_sync(_syncQueue, ^{
      NSMutableArray<NSMutableDictionary *> *faves = self.rawFaves;
      NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

      if (changed) {
          for (NSString *key in changed) {
              if ([key isEqual:kiCloudTotal]) {
                  NSNumber *total = [store objectForKey:key];

                  // Delete any that are not needed
                  NSInteger items = 0;

                  if (total != nil) {
                      items = total.integerValue;
                  }

                  if (items < faves.count) {
                      DEBUG_LOG_long(faves.count - items);

                      while (items < faves.count) {
                          [self.rawFaves removeLastObject];
                      }
                  } else if (items > faves.count) {
                      DEBUG_LOG_long(items - faves.count);

                      [self rawFillGapInFaves:faves upTo:items];
                  }
              } else if (kisCloudKeyFave(key)) {
                  NSInteger item = kCloudKeyItem(key);
                  NSDictionary *cloudFave = [store objectForKey:key];
                  DEBUG_LOG_NSString(key);

                  if (cloudFave) {
                      // Pad out, but should never happen!
                      [self rawFillGapInFaves:faves upTo:item];
                      faves[item] = [cloudFave mutableDeepCopy];
                  }
              }
          }
      } else {
          // Replace them all the first time
          NSNumber *total = [store objectForKey:kiCloudTotal];

          if (total != nil) {
              [faves removeAllObjects];

              for (NSInteger item = 0; item < total.integerValue; item++) {
                  NSString *key = kiCloudKey(item);
                  NSDictionary *fave = [store dictionaryForKey:key];

                  if (fave) {
                      [faves addObject:[fave mutableDeepCopy]];
                  } else {
                      [faves addObject:self.newFave];
                  }
              }
          }
      }

      [self rawWriteState:readOnly];
    });
#endif // ifndef PDXBUS_WATCH
}

- (void)rawWriteToCloud {
#ifndef PDXBUS_WATCH

    if (Settings.iCloudToken && !Settings.firstLaunchWithiCloudAvailable && self.canWriteToCloud) {
        // Write to iCloud
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

        if (store) {
            NSNumber *total = [store objectForKey:kiCloudTotal];
            NSArray *faves = self.rawFaves;

            DEBUG_LOG_description(total);

            if (total != nil) {
                if (total.intValue > faves.count) {
                    for (NSInteger item = faves.count; item < total.intValue; item++) {
                        [store removeObjectForKey:kiCloudKey(item)];
                    }
                }
            }

            if (faves.count == 0 && total == nil) {
                // Do nothing
            } else if (faves.count == 0 && total != nil) {
                // Leave as is
            } else {
                for (NSInteger i = 0; i < faves.count; i++) {
                    NSDictionary *fave = faves[i];
                    NSString *key = kiCloudKey(i);
                    NSDictionary *cloudFave = [store dictionaryForKey:key];

                    if (cloudFave == nil || ![cloudFave isEqualToDictionary:fave]) {
                        [store setObject:[fave mutableDeepCopy] forKey:key];
                    }
                }

                if (total == nil || total.intValue != faves.count) {
                    total = [NSNumber numberWithInteger:faves.count];
                    [store setObject:total forKey:kiCloudTotal];
                }
            }

            DEBUG_LOG_description(total);
            [store synchronize];
        }
    }

#endif // ifndef PDXBUS_WATCH
}

- (void)writeToCloud {
    dispatch_sync(_syncQueue, ^{
      [self rawWriteToCloud];
    });
}

- (void)rawWriteState:(bool)readyOnly {
    if (_rawData && !readyOnly) {
        [_sharedUserCopyOfPlist writeDictionary:_rawData];
        [self rawWriteToCloud];
    }
}

- (void)cacheState {
    // This can be async - this is the point to save UI time
    bool readOnly = self.readOnly;
    dispatch_async(_syncQueue, ^{
      [self rawWriteState:readOnly];
    });
}
- (void)cacheStateNow {
    bool readOnly = self.readOnly;
    dispatch_barrier_sync(_syncQueue, ^{
      [self rawWriteState:readOnly];
    });
}

- (NSDictionary *)takeMeHomeUserRequest {
    return (NSDictionary *)[self item:kTakeMeHome];
}

- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userRequest {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];
      self->_rawData[kTakeMeHome] = userRequest;
      [self rawWriteState:readOnly];
    });
}

- (NSMutableDictionary *)watchData {
    __block NSMutableDictionary *result = nil;
    dispatch_sync(_syncQueue, ^{
      result = self->_rawData;
    });
    return result;
}

- (void)setWatchData:(NSMutableDictionary *)watchData {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      self->_rawData = watchData.mutableDeepCopy;
      [self rawWriteState:readOnly];
    });
}

- (NSUInteger)watchSequence {
    __block NSUInteger result = 0;
    dispatch_sync(_syncQueue, ^{
      [self rawLoad];
      NSNumber *seq = self->_rawData[kWatchSequenceNumber];

      if (seq == nil) {
          seq = @(0);
      }

      result = (NSUInteger)seq.integerValue;
    });
    return result;
}

- (void)incrementWatchSequence {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];
      NSNumber *seq = self->_rawData[kWatchSequenceNumber];

      if (seq == nil) {
          seq = @(0);
      }
      self->_rawData[kWatchSequenceNumber] = @((seq.integerValue + 1) % 0xFFFFFFFF);
      [self rawWriteState:readOnly];
    });
}

- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest
                            description:(NSString *)desc
                                   blob:(NSData *)blob {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];

      NSMutableArray *recentTrips = [self rawGetOrInitItem:kRecentTrips];

      NSDictionary *newItem = [MutableUserParams withChosenName:desc
                                                           trip:userRequest.mutableCopy
                                                    tripResults:blob]
                                  .dictionary;

      [recentTrips insertObject:newItem atIndex:0];

      while (recentTrips.count > kMaxRecentTrips) {
          [recentTrips removeLastObject];
      }

      self->_rawDirty = true;
      [self rawWriteState:readOnly];
    });
}

- (NSDictionary *)addToRecentStops:(NSString *)stopId description:(NSString *)desc {
    MutableUserParams *newItem = nil;
    newItem = MutableUserParams.new;
    newItem.valLocation = stopId;
    newItem.valOriginalName = desc;
    newItem.valChosenName = desc;

    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];

      NSMutableArray<NSDictionary *> *recents = self.rawRecentStops;

      int j = 0;

      for (j = 0; j < recents.count; j++) {
          if ([recents[j].userParams.valLocation isEqualToString:stopId]) {
              [recents removeObjectAtIndex:j];
              j--;
          }
      }

      [recents insertObject:newItem.mutableDictionary atIndex:0];

      while (recents.count > kMaxRecentStops) {
          [recents removeLastObject];
      }

      self->_rawDirty = true;
      [self rawWriteState:readOnly];
    });

    return newItem.dictionary;
}

- (void)addToVehicleIds:(NSString *)vehicleId {

    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];

      MutableUserParams *newItem = nil;
      NSMutableArray<NSDictionary *> *vehicleIds = self->_rawData[kVehicleIds];

      int j = 0;

      for (j = 0; j < vehicleIds.count; j++) {
          if ([vehicleIds[j].userParams.valVehicleId isEqualToString:vehicleId]) {
              [vehicleIds removeObjectAtIndex:j];
              j--;
          }
      }

      newItem = MutableUserParams.new;

      newItem.valVehicleId = vehicleId;

      [vehicleIds insertObject:newItem.mutableDictionary atIndex:0];

      while (vehicleIds.count > kMaxRecentStops) {
          [vehicleIds removeLastObject];
      }

      self->_rawDirty = true;
      [self rawWriteState:readOnly];
    });
}

- (NSObject *)item:(NSString *)item {
    __block NSObject *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawLoad];
      result = self->_rawData[item];
    });
    return result;
}

- (NSMutableArray *)rawFaves {
    [self rawLoad];
    return safeMutableArray(self->_rawData[kFaves]);
}

- (NSMutableArray *)stopsFromFaves {
    NSMutableArray *justStops = [NSMutableArray array];
    dispatch_sync(_syncQueue, ^{
      for (NSDictionary *dict in [self rawFaves]) {
          if (dict.userParams.valLocation != nil) {
              [justStops insertObject:dict.copy atIndex:justStops.count];
          }
      }
    });
    return justStops;
}

- (void)accessArray:(NSMutableArray *)array block:(void (^)(NSMutableArray *item))block {
    dispatch_barrier_sync(_syncQueue, ^{
      block(array);
    });
}

- (NSMutableArray *)faves {
    return safeMutableArray([self item:kFaves]);
}

- (NSArray *)favesArrivalsOnly {
    NSMutableArray *favesArrivalsOnly = [NSMutableArray array];

    NSArray<NSMutableDictionary *> *faves = self.faves;
    for (NSDictionary *item in faves) {
        if (item.userParams.valTrip == nil) {
            [favesArrivalsOnly addObject:item];
        }
    }

    return favesArrivalsOnly;
}

- (NSMutableArray *)rawRecentStops {
    [self rawLoad];

    NSMutableArray<NSDictionary *> *recents = nil;
    id existing = self->_rawData[kRecents];

    if ([existing isKindOfClass:[NSMutableArray class]]) {
        recents = (NSMutableArray *)existing;
    } else if ([existing isKindOfClass:[NSArray class]]) {
        recents = [existing mutableCopy];
    } else {
        recents = [NSMutableArray array];
        self->_rawDirty = true;
    }

    self->_rawData[kRecents] = recents;

    return recents;
}

- (NSMutableArray *)recentStops {
    __block NSMutableArray *result = nil;

    // This does write, so we do a sync barrier
    dispatch_barrier_sync(_syncQueue, ^{
      result = self.rawRecentStops;
    });
    return result;
}

- (NSMutableArray *)vehicleIds {
    return safeMutableArray([self item:kVehicleIds]);
}

- (NSMutableArray *)recentTrips {
    return safeMutableArray([self item:kRecentTrips]);
}

- (void)setLastRun:(NSDate *)last {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];

      if (last != nil) {
          self->_rawData[self.lastRunKey] = last;
      } else {
          [self->_rawData removeObjectForKey:kLastRunWatch];
          [self->_rawData removeObjectForKey:kLastRunApp];
      }
      [self rawWriteState:readOnly];
    });
}

- (NSDate *)lastRun {
    return (NSDate *)[self item:self.lastRunKey];
}

- (NSMutableDictionary *)lastTrip {
    return safeMutableDictionary([self item:kLastTrip]);
}

- (void)setLastTrip:(NSMutableDictionary *)dict {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];
      self->_rawData[kLastTrip] = dict;
      [self rawWriteState:readOnly];
      self->_rawDirty = YES;
    });
}

- (NSMutableDictionary *)lastLocate {
    return safeMutableDictionary([self item:kLastLocate]);
}

- (void)setLastLocate:(NSMutableDictionary *)dict {
    bool readOnly = self.readOnly;
    dispatch_barrier_async(_syncQueue, ^{
      [self rawLoad];
      self->_rawData[kLastLocate] = dict;
      self->_rawDirty = YES;
      [self rawWriteState:readOnly];
    });
}

- (NSDictionary *)checkForCommuterFaveShowOnlyOnce:(bool)onlyOnce {
    NSDate *lastRun = self.lastRun;
    NSDate *now = [NSDate date];

    // Text code forces the commuter bookmark every 5 seconds.
    if (Settings.debugCommuter && [lastRun timeIntervalSinceNow] < -5) {
        lastRun = nil;
    }

    bool readOnly = self.readOnly;

    self.readOnly = FALSE;

    if (onlyOnce) {
        self.lastRun = now;
    }

    self.readOnly = readOnly;
    bool firstRunInPeriod = YES;

    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                         kCFCalendarUnitHour | kCFCalendarUnitWeekday;

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *nowComponents = [cal components:(NSUInteger)unitFlags fromDate:now];

    if (lastRun != nil) {
        NSDateComponents *lastComponents = [cal components:(NSUInteger)unitFlags fromDate:lastRun];

        if (lastComponents.year == nowComponents.year &&
            lastComponents.month == nowComponents.month &&
            lastComponents.day == nowComponents.day &&
            IS_MORNING(lastComponents.hour) == IS_MORNING(nowComponents.hour)) {
            firstRunInPeriod = NO;
        }
    }

    if (!onlyOnce || firstRunInPeriod) {
        int todayBit = (0x1 << nowComponents.weekday);

        NSArray<NSMutableDictionary *> *faves = self.faves;

        for (NSDictionary *fave in faves) {
            UserParams *params = fave.userParams;
            int dow = params.valDayOfWeek;
            bool am = params.valMorning;

            if (dow && params.valLocation != nil) {
                // does the day of week match our day of week?
                if ((dow & todayBit) != 0) {
                    // Does AM match or PM match?
                    if ((am && IS_MORNING(nowComponents.hour)) ||
                        (!am && !IS_MORNING(nowComponents.hour))) {
                        return fave;
                    }
                }
            }
        }

        // Didn't find anything - set this to nil just in case the user sets one
        // up
        self.lastRun = nil;
    }

    return nil;
}

- (bool)hasEverChanged {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pathToDefaultPlist = [bundle pathForResource:kDefaultFileName
                                                    ofType:kDefaultFileType];
    NSURL *defaultPlist = [[NSURL alloc] initFileURLWithPath:pathToDefaultPlist isDirectory:NO];

    if (defaultPlist) {
        NSDictionary *defaultDict = [NSDictionary dictionaryWithContentsOfURL:defaultPlist];

        if (defaultDict != nil) {
            NSArray *faves = defaultDict[kFaves];
            return ![faves isEqualToArray:self.faves];
        }
    }
    return YES;
}

@end

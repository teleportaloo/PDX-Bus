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
#define kLast @"last"
#define kLastTrip @"last_trip"
#define kLastNames @"last_names"
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
#define kisCloudKeyFave(key)                                                   \
    (((key).length > kiCloudKeyPrefixSize) &&                                  \
     [[key substringToIndex:kiCloudKeyPrefixSize] isEqualToString:@"fave"])
#define kCloudKeyItem(key)                                                     \
    [[key substringFromIndex:kiCloudKeyPrefixSize] integerValue]

#define kMaxRecentStops 25
#define kMaxRecentTrips 25

@interface NSArray (MutableDeepCopy)

- (NSMutableArray *)mutableDeepCopy;

@end

@interface NSDictionary (MutableDeepCopy)

- (NSMutableDictionary *)mutableDeepCopy;

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

    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj,
                                              BOOL *_Nonnull stop) {
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

@implementation UserState

- (void)memoryWarning {
    @synchronized(self) {
        DEBUG_LOG(@"Clearing app data %p\n", self.rawData);
        [self cacheState];
        self.rawData = nil;
    }
}

- (NSMutableArray *)getOrInitItem:(NSString *)item {
    @synchronized(self) {
        NSMutableArray *cache = self.rawData[item];
        if (cache == nil) {
            cache = [NSMutableArray array];

            self.rawData[item] = cache;
            [self cacheState];
        }
        return cache;
    }
}

- (void)load {
    @synchronized(self) {
        if (self.rawData == nil) {
            // We have to read the property list and make it mutable
            self.rawData = [NSMutableDictionary
                mutableContainersWithContentsOfURL:self.sharedUserCopyOfPlist
                                                       .urlToSharedFile];

            [self getOrInitItem:kRecentTrips];
            [self getOrInitItem:kVehicleIds];
        }
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        self.sharedUserCopyOfPlist = [SharedFile fileWithName:kDefaultFile
                                               initFromBundle:YES
                                                         sync:self];
        self.readOnly = FALSE;
        self.lastRunKey = kLastRunApp;
        [self load];
    }

    return self;
}

+ (UserState *)sharedInstance {
    static UserState *singleton = nil;

    DoOnce(^{
      singleton = [[UserState alloc] init];
      [MemoryCaches addCache:singleton];
    });
    return singleton;
}

- (NSMutableDictionary *)newFave {
    return [MutableUserParams withChosenName:kNewBookMark
                                    location:[NSString string]]
        .mutableDictionary;
}

#ifndef PDXBUS_WATCH

- (void)fillGapInFaves:(NSMutableArray *)faves upTo:(NSInteger)total {
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

#endif

- (void)clearCloud {
#ifndef PDXBUS_WATCH
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *all = [store dictionaryRepresentation];

    for (NSString *keys in all) {
        [store removeObjectForKey:keys];
    }

    [store synchronize];
#endif
}

- (void)mergeWithCloud:(NSArray *)changed {
#ifndef PDXBUS_WATCH

    DEBUG_FUNC();
    @synchronized(self) {
        NSMutableArray<NSMutableDictionary *> *faves = self.faves;
        NSUbiquitousKeyValueStore *store =
            [NSUbiquitousKeyValueStore defaultStore];

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
                            [self.faves removeLastObject];
                        }
                    } else if (items > faves.count) {
                        DEBUG_LOG_long(items - faves.count);

                        [self fillGapInFaves:faves upTo:items];
                    }
                } else if (kisCloudKeyFave(key)) {
                    NSInteger item = kCloudKeyItem(key);
                    NSDictionary *cloudFave = [store objectForKey:key];
                    DEBUG_LOG_NSString(key);

                    if (cloudFave) {
                        // Pad out, but should never happen!
                        [self fillGapInFaves:faves upTo:item];
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

        [self cacheState];
    }
#endif // ifndef PDXBUS_WATCH
}

- (void)writeToiCloud {
#ifndef PDXBUS_WATCH

    if (Settings.iCloudToken && !Settings.firstLaunchWithiCloudAvailable &&
        self.canWriteToCloud) {
        // Write to iCloud
        NSUbiquitousKeyValueStore *store =
            [NSUbiquitousKeyValueStore defaultStore];

        if (store) {
            NSNumber *total = [store objectForKey:kiCloudTotal];
            NSArray *faves = self.faves;

            DEBUG_LOG_description(total);

            if (total != nil) {
                if (total.intValue > faves.count) {
                    for (NSInteger item = faves.count; item < total.intValue;
                         item++) {
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

                    if (cloudFave == nil ||
                        ![cloudFave isEqualToDictionary:fave]) {
                        [store setObject:[fave mutableDeepCopy] forKey:key];
                    }
                }

                if (total == nil || total.intValue != self.faves.count) {
                    total = [NSNumber numberWithInteger:self.faves.count];
                    [store setObject:total forKey:kiCloudTotal];
                }
            }

            DEBUG_LOG_description(total);
            [store synchronize];
        }
    }

#endif // ifndef PDXBUS_WATCH
}

- (void)cacheState {
    @synchronized(self) {
        if (self.rawData && !self.readOnly) {
            [self.sharedUserCopyOfPlist writeDictionary:self.rawData];
            [self writeToiCloud];
        }
    }
}

- (void)clearLastArrivals {
    @synchronized(self) {
        [self load];
        self.rawData[kLast] = @"";
        [self.rawData removeObjectForKey:kLastNames];
    }
}

- (void)setLastArrivals:(NSString *)locations {
    @synchronized(self) {
        [self load];
        self.rawData[kLast] = locations;

        DEBUG_PRINTF("setLastArrivals %s\n",
                     [locations cStringUsingEncoding:NSUTF8StringEncoding]);
        [self cacheState];
    }
}

- (void)setLastNames:(NSArray *)names {
    @synchronized(self) {
        [self load];

        if (names != nil) {
            self.rawData[kLastNames] = names;
        } else {
            [self.rawData removeObjectForKey:kLastNames];
        }

        [self cacheState];
    }
}

- (NSDictionary *)takeMeHomeUserRequest {
    @synchronized(self) {
        [self load];
        NSMutableDictionary *takeMeHome = self.rawData[kTakeMeHome];

        return takeMeHome;
    }
}

- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userRequest {
    @synchronized(self) {
        [self load];
        self.rawData[kTakeMeHome] = userRequest;

        [self cacheState];
    }
}

- (NSUInteger)watchSequence {
    @synchronized(self) {
        [self load];
        NSNumber *seq = self.rawData[kWatchSequenceNumber];

        if (seq == nil) {
            seq = @(0);
        }

        return (NSUInteger)seq.integerValue;
    }
}

- (void)incrementWatchSequence {
    @synchronized(self) {
        [self load];
        NSNumber *seq = self.rawData[kWatchSequenceNumber];

        if (seq == nil) {
            seq = @(0);
        }
        self.rawData[kWatchSequenceNumber] =
            @((seq.integerValue + 1) % 0xFFFFFFFF);
        [self cacheState];
    }
}

- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest
                            description:(NSString *)desc
                                   blob:(NSData *)blob {
    @synchronized(self) {
        [self load];

        NSMutableArray *recentTrips = [self getOrInitItem:kRecentTrips];

        NSDictionary *newItem =
            [MutableUserParams withChosenName:desc
                                         trip:userRequest.mutableCopy
                                  tripResults:blob]
                .dictionary;

        [recentTrips insertObject:newItem atIndex:0];

        while (recentTrips.count > kMaxRecentTrips) {
            [recentTrips removeLastObject];
        }

        _favesChanged = true;
        [self cacheState];
    }
}

- (NSDictionary *)addToRecentsWithStopId:(NSString *)stopId
                             description:(NSString *)desc {
    @synchronized(self) {
        [self load];

        MutableUserParams *newItem = nil;

        NSMutableArray<NSDictionary *> *recents = self.recents;

        int j = 0;

        for (j = 0; j < recents.count; j++) {
            if ([recents[j].userParams.valLocation isEqualToString:stopId]) {
                [recents removeObjectAtIndex:j];
                j--;
            }
        }

        newItem = MutableUserParams.new;

        newItem.valLocation = stopId;
        newItem.valOriginalName = desc;
        newItem.valChosenName = desc;

        [recents insertObject:newItem.mutableDictionary atIndex:0];

        while (recents.count > kMaxRecentStops) {
            [recents removeLastObject];
        }

        _favesChanged = true;
        [self cacheState];

        return newItem.dictionary;
    }
}

- (void)addToVehicleIds:(NSString *)vehicleId {
    @synchronized(self) {
        [self load];

        MutableUserParams *newItem = nil;

        // NSMutableArray *userFaves = [self.favesAndRecents
        // objectForKey:kFaves];
        NSMutableArray<NSDictionary *> *vehicleIds = self.rawData[kVehicleIds];

        int j = 0;

        for (j = 0; j < vehicleIds.count; j++) {
            if ([vehicleIds[j].userParams.valVehicleId
                    isEqualToString:vehicleId]) {
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

        _favesChanged = true;
        [self cacheState];
    }
}

- (NSMutableArray *)faves {
    @synchronized(self) {
        [self load];
        return self.rawData[kFaves];
    }
}

- (NSArray *)favesArrivalsOnly {
    @synchronized(self) {
        [self load];

        NSMutableArray *favesArrivalsOnly = [NSMutableArray array];
        NSMutableArray<NSMutableDictionary *> *faves = self.faves;

        NSDictionary *item;

        for (item in faves) {
            if (item.userParams.valTrip == nil) {
                [favesArrivalsOnly addObject:item];
            }
        }

        return favesArrivalsOnly;
    }
}

- (NSMutableArray *)recents {
    @synchronized(self) {
        [self load];

        NSMutableArray<NSDictionary *> *recents = nil;
        id existing = self.rawData[kRecents];

        if ([existing isKindOfClass:[NSMutableArray class]]) {
            recents = (NSMutableArray *)existing;
        } else if ([existing isKindOfClass:[NSArray class]]) {
            recents = [existing mutableCopy];
        } else {
            recents = [NSMutableArray array];
            _favesChanged = true;
        }

        self.rawData[kRecents] = recents;

        return recents;
    }
}

- (NSMutableArray *)vehicleIds {
    @synchronized(self) {
        [self load];
        return self.rawData[kVehicleIds];
    }
}

- (NSMutableArray *)recentTrips {
    @synchronized(self) {
        [self load];
        return self.rawData[kRecentTrips];
    }
}

- (NSString *)last {
    @synchronized(self) {
        [self load];
        return self.rawData[kLast];
    }
}

- (NSArray *)lastNames {
    @synchronized(self) {
        [self load];
        return self.rawData[kLastNames];
    }
}

- (void)setLastRun:(NSDate *)last {
    @synchronized(self) {
        [self load];

        if (last != nil) {
            self.rawData[self.lastRunKey] = last;
        } else {
            [self.rawData removeObjectForKey:kLastRunWatch];
            [self.rawData removeObjectForKey:kLastRunApp];
        }
    }
    [self cacheState];
}

- (NSDate *)lastRun {
    @synchronized(self) {
        [self load];
        return self.rawData[self.lastRunKey];
    }
}

- (NSMutableDictionary *)lastTrip {
    @synchronized(self) {
        [self load];
        return self.rawData[kLastTrip];
    }
}

- (void)setLastTrip:(NSMutableDictionary *)dict {
    @synchronized(self) {
        [self load];
        self.rawData[kLastTrip] = dict;
    }

    self.favesChanged = YES;
    [self cacheState];
}

- (NSMutableDictionary *)lastLocate {
    @synchronized(self) {
        [self load];
        return self.rawData[kLastLocate];
    }
}

- (void)setLastLocate:(NSMutableDictionary *)dict {
    @synchronized(self) {
        [self load];
        self.rawData[kLastLocate] = dict;
    }

    self.favesChanged = YES;
    [self cacheState];
}

- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce {
    [self load];
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

    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |
                         NSCalendarUnitDay | kCFCalendarUnitHour |
                         kCFCalendarUnitWeekday;

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *nowComponents = [cal components:(NSUInteger)unitFlags
                                             fromDate:now];

    if (lastRun != nil) {
        NSDateComponents *lastComponents = [cal components:(NSUInteger)unitFlags
                                                  fromDate:lastRun];

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
    NSURL *defaultPlist = [[NSURL alloc] initFileURLWithPath:pathToDefaultPlist
                                                 isDirectory:NO];

    if (defaultPlist) {
        NSDictionary *defaultDict =
            [NSDictionary dictionaryWithContentsOfURL:defaultPlist];

        if (defaultDict != nil) {
            NSArray *faves = defaultDict[kFaves];
            return ![faves isEqualToArray:self.faves];
        }
    }

    return YES;
}

@end

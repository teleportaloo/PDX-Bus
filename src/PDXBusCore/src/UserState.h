//
//  UserFaves.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MemoryCaches.h"
#import "SharedFile.h"
#import "Settings.h"

#define kUserFavesDescription        NSLocalizedString(@"Launch PDX Bus & open bookmark %@", @"bookmark name")
#define kAddBookmarkToSiri           NSLocalizedString(@"Add to Siri to launch PDX Bus with bookmark", @"button text")
#define kUserFavesChosenName         @"ChosenName"
#define kUserFavesOriginalName       @"OriginalName"
#define kUserFavesLocation           @"Location"
#define kUserFavesTrip               @"Trip"
#define kUserFavesTripResults        @"TripResults"
#define kUserFavesDayOfWeek          @"DayOfWeek"
#define kUserFavesMorning            @"AM"
#define kUserFavesBlock              @"Block"
#define kUserFavesDir                @"Dir"
#define kMaxFaves                    30
#define kNoBookmark                  -1
#define kDayNever                    0
#define kDaySun                      (0x1 << 1)
#define kDayMon                      (0x1 << 2)
#define kDayTue                      (0x1 << 3)
#define kDayWed                      (0x1 << 4)
#define kDayThu                      (0x1 << 5)
#define kDayFri                      (0x1 << 6)
#define kDaySat                      (0x1 << 7)
#define kDayWeekend                  (kDaySat | kDaySun)
#define kDayWeekday                  (kDayMon | kDayTue | kDayWed | kDayThu | kDayFri)
#define kDayAllWeek                  (kDayWeekend | kDayWeekday)

#define kWeekend

#define kFaves                       @"faves"
#define kRecents                     @"recents"
#define kVehicleIds                  @"vehicleIds"
#define kVehicleId                   @"vehicleId"
#define kRecentTrips                 @"trips"
#define kLast                        @"last"
#define kLastTrip                    @"last_trip"
#define kLastNames                   @"last_names"
#define kLastRunApp                  @"last_run"
#define kLastRunWatch                @"last_run_watch"
#define kTakeMeHome                  @"take_me_home"
#define kWatchSequenceNumber         @"watch_sequence"

#define kiCloudTotal                 @"total"
#define kiCloudKeyPrefixSize         4
#define kiCloudKey(i)                [NSString stringWithFormat:@"fave%ld", (long)(i)]
#define kisCloudKeyFave(key)         (((key).length > kiCloudKeyPrefixSize) &&  [[key substringToIndex:kiCloudKeyPrefixSize] isEqualToString:@"fave"])
#define kCloudKeyItem(key)           [[key substringFromIndex:kiCloudKeyPrefixSize] integerValue]


#define kLastLocate                  @"last_locate"
#define kiCloudFaves                 @"icloud_faves"
#define kLocateMode                  @"mode"
#define kLocateDist                  @"dist"
#define kLocateShow                  @"show"
#define kLocateDate                  @"LocationDatabaseDate"


#define kNewBookMark                 NSLocalizedString(@"New Stop Bookmark", @"new bookmark name")
#define kNewTripBookMark             NSLocalizedString(@"New Trip Bookmark", @"new bookmark name")
#define kNewTakeMeSomewhereBookMark  NSLocalizedString(@"Take me <somewhere> now", @"new bookmark name")

#define kNewSavedTrip                @"New Saved Trip"
#define kBookMarkUtil                @"bookmark util"

#define kUnknownDate                 @"unknown"

#define kHandoffUserActivityBookmark @"org.teleportaloo.pdxbus.bookmark"
#define kHandoffUserActivityLocation @"org.teleportaloo.pdxbus.location"
#define kHandoffUserActivityAlerts   @"org.teleportaloo.pdxbus.alerts"

#define kUserInfoAlertRoute          @"route"
#define kUserInfoAlertSystem         @"system"

#define kMaxRecentStops              25
#define kMaxRecentTrips              25


@interface UserState : NSObject <ClearableCache>

@property (strong)         NSMutableDictionary *rawData;
@property (weak, readonly) NSMutableArray<NSMutableDictionary *> *faves;
@property (weak, readonly) NSArray<NSDictionary *> *favesArrivalsOnly;
@property (weak, readonly) NSMutableArray<NSDictionary *> *recents;
@property (weak, readonly) NSMutableArray<NSDictionary *> *vehicleIds;
@property (weak, readonly) NSMutableArray<NSDictionary *> *recentTrips;
@property (weak, readonly) NSString *last;
@property (weak, readonly) NSArray<NSString *> *lastNames;
@property (strong)         NSMutableDictionary *lastTrip;
@property (strong)         NSMutableDictionary *lastLocate;
@property                  bool favesChanged;
@property (weak)           NSDate *lastRun;
@property (strong)         SharedFile *sharedUserCopyOfPlist;
@property                  bool readOnly;
@property (strong, nonatomic) NSString *lastRunKey;
@property (nonatomic, readonly, copy) NSDictionary *takeMeHomeUserRequest;
@property (nonatomic, readonly) NSTimeInterval locationDatabaseAge;
@property (nonatomic, readonly) bool hasEverChanged;
@property (atomic)              bool canWriteToCloud;

- (void)incrementWatchSequence;
- (NSUInteger)watchSequence;
- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob;
- (NSDictionary *)tripArchive:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob;
- (NSDictionary *)addToRecentsWithStopId:(NSString *)stopId description:(NSString *)desc;
- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce;
- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userReqest;
- (NSDictionary *)addToVehicleIds:(NSString *)vehicleId;
- (void)setLastArrivals:(NSString *)locations;
- (void)mergeWithCloud:(NSArray *)changed;
- (void)clearCloud;
- (void)setLastNames:(NSArray *)names;
- (void)clearLastArrivals;
- (void)writeToiCloud;
- (void)cacheState;

+ (UserState *)sharedInstance;

@end

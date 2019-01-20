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


#include "MemoryCaches.h"
#import "SharedFile.h"

#define kUserFavesDescription       NSLocalizedString(@"Launch PDX Bus & open bookmark %@", @"bookmark name")
#define kAddBookmarkToSiri          NSLocalizedString(@"Add to Siri to launch PDX Bus with bookmark", @"button text")
#define kUserFavesChosenName        @"ChosenName"
#define kUserFavesOriginalName      @"OriginalName"
#define kUserFavesLocation          @"Location"
#define kUserFavesTrip              @"Trip"
#define kUserFavesTripResults       @"TripResults"
#define kUserFavesDayOfWeek         @"DayOfWeek"
#define kUserFavesMorning           @"AM"
#define kUserFavesBlock             @"Block"
#define kMaxFaves                   30
#define kNoBookmark                -1
#define kDayNever                   0
#define kDaySun                    (0x1 << 1)
#define kDayMon                    (0x1 << 2)
#define kDayTue                    (0x1 << 3)
#define kDayWed                    (0x1 << 4)
#define kDayThu                    (0x1 << 5)
#define kDayFri                    (0x1 << 6)
#define kDaySat                    (0x1 << 7)
#define kDayWeekend                (kDaySat | kDaySun)
#define kDayWeekday                (kDayMon | kDayTue | kDayWed | kDayThu | kDayFri)
#define kDayAllWeek                (kDayWeekend | kDayWeekday)

#define kWeekend        

#define kFaves                      @"faves"
#define kRecents                    @"recents"
#define kVehicleIds                 @"vehicleIds"
#define kVehicleId                  @"vehicleId"
#define kRecentTrips                @"trips"
#define kLast                       @"last"
#define kLastTrip                   @"last_trip"
#define kLastNames                  @"last_names"
#define kLastRunApp                 @"last_run"
#define kLastRunWatch               @"last_run_watch"
#define kTakeMeHome                 @"take_me_home"

#define kLastLocate                 @"last_locate"
#define kLocateMode                 @"mode"
#define kLocateDist                 @"dist"
#define kLocateShow                 @"show"
#define kLocateDate                 @"LocationDatabaseDate"


#define kNewBookMark            NSLocalizedString(@"New Stop Bookmark", @"new bookmark name")
#define kNewTripBookMark        NSLocalizedString(@"New Trip Bookmark", @"new bookmark name")
#define kNewTakeMeSomewhereBookMark NSLocalizedString(@"Take me <somewhere> now", @"new bookmark name")

#define kNewSavedTrip               @"New Saved Trip"
#define kBookMarkUtil               @"bookmark util"

#define kUnknownDate                @"unknown"

#import "UserPrefs.h"

#define kHandoffUserActivityBookmark @"org.teleportaloo.pdxbus.bookmark"
#define kHandoffUserActivityLocation @"org.teleportaloo.pdxbus.location"


@interface SafeUserData : NSObject <ClearableCache>

@property (strong)         NSMutableDictionary *                  appData;
@property (weak, readonly) NSMutableArray<NSMutableDictionary*> * faves;
@property (weak, readonly) NSArray<NSDictionary*> *               favesArrivalsOnly;
@property (weak, readonly) NSMutableArray<NSDictionary*> *        recents;
@property (weak, readonly) NSMutableArray<NSDictionary*> *        vehicleIds;
@property (weak, readonly) NSMutableArray<NSDictionary*> *        recentTrips;
@property (weak, readonly) NSString *                             last;
@property (weak, readonly) NSArray<NSString*> *                   lastNames;
@property (strong)         NSMutableDictionary *                  lastTrip;
@property (strong)         NSMutableDictionary *                  lastLocate;
@property                  bool                                   favesChanged;
@property (weak)           NSDate *                               lastRun;
@property (strong)         SharedFile *                           sharedUserCopyOfPlist;
@property                  bool                                   readOnly;
@property (strong, nonatomic) NSString *                          lastRunKey;
@property (nonatomic, readonly, copy) NSDictionary *              takeMeHomeUserRequest;
@property (nonatomic, readonly, copy) NSString *                  locationDatabaseDateString;
@property (nonatomic, readonly) NSTimeInterval                    locationDatabaseAge;

- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob;
- (NSDictionary *)tripArchive:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob;
- (NSDictionary *)addToRecentsWithLocation:(NSString *)locid description:(NSString *)desc;
- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce;
- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userReqest;
- (NSDictionary *)addToVehicleIds:(NSString *)vehicleId;
- (void)setLocationDatabaseDate:(NSString *)date;
- (void)setLastArrivals:(NSString *)locations;
- (void)setLastNames:(NSArray *)names;
- (void)clearLastArrivals;
- (void)cacheAppData;

+ (SafeUserData *)sharedInstance;

@end


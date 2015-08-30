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

#define kUserFavesChosenName	@"ChosenName"
#define kUserFavesOriginalName	@"OriginalName"
#define kUserFavesLocation		@"Location"
#define kUserFavesTrip			@"Trip"
#define kUserFavesTripResults	@"TripResults"
#define kUserFavesDayOfWeek     @"DayOfWeek"
#define kUserFavesMorning		@"AM"
#define kMaxFaves				25
#define kNoBookmark				-1
#define kDayNever				0
#define kDaySun					(0x1 << 1)
#define kDayMon					(0x1 << 2)
#define kDayTue					(0x1 << 3)
#define kDayWed					(0x1 << 4)
#define kDayThu					(0x1 << 5)
#define kDayFri					(0x1 << 6)
#define kDaySat					(0x1 << 7)
#define kDayWeekend				(kDaySat | kDaySun)
#define kDayWeekday				(kDayMon | kDayTue | kDayWed | kDayThu | kDayFri)
#define kDayAllWeek				(kDayWeekend | kDayWeekday)

#define kWeekend		

#define kFaves					@"faves"
#define kRecents				@"recents"
#define kRecentTrips			@"trips"
#define kLast					@"last"
#define kLastTrip				@"last_trip"
#define kLastNames				@"last_names"
#define kLastRun				@"last_run"
#define kTakeMeHome             @"take_me_home"

#define kLastLocate				@"last_locate"
#define kLocateMode				@"mode"
#define kLocateDist				@"dist"
#define kLocateShow				@"show"


#define kNewBookMark			@"New Stop Bookmark"
#define kNewTripBookMark		@"New Trip Bookmark"
#define kNewSavedTrip			@"New Saved Trip"

#define kUnknownDate @"unknown"

#import "UserPrefs.h"


@interface SafeUserData : NSObject <ClearableCache>
{
	NSMutableDictionary *               _appData;
	bool                                _favesChanged;
    SharedFile *                        _sharedUserCopyOfPlist;
    bool                                _readOnly;
}

@property (retain)   NSMutableDictionary *      appData;
@property (readonly) NSMutableArray *           faves;
@property (readonly) NSArray *                  favesArrivalsOnly;
@property (readonly) NSMutableArray *           recents;
@property (readonly) NSMutableArray *           recentTrips;
@property (readonly) NSString *                 last;
@property (readonly) NSArray *                  lastNames;
@property (retain)	 NSMutableDictionary *      lastTrip;
@property (retain)   NSMutableDictionary *      lastLocate;
@property			 bool                       favesChanged;
@property (assign)	 NSDate *                   lastRun;
@property (retain)   SharedFile *               sharedUserCopyOfPlist;
@property            bool                       readOnly;

+ (SafeUserData *)getSingleton;
- (void)addToRecentsWithLocation:(NSString *)locid description:(NSString *)desc;
- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob;
- (NSDictionary *)getTakeMeHomeUserRequest;
- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userReqest;
- (void)clearLastArrivals;
- (void)setLastArrivals:(NSString *)locations;
- (void)setLastNames:(NSArray *)names;
- (void)cacheAppData;
- (void)setLocationDatabaseDate:(NSString *)date;
- (NSString*)getLocationDatabaseDateString;
- (NSTimeInterval)getLocationDatabaseAge;
- (NSArray*)arrayFromCommaSeparatedString:(NSString *)string;



@end


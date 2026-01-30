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
#import "Settings.h"
#import "SharedFile.h"

#define kUserFavesDescription                                                                      \
    NSLocalizedString(@"Launch PDX Bus & open bookmark %@", @"bookmark name")
#define kAddBookmarkToSiri                                                                         \
    NSLocalizedString(@"Add to Siri to launch PDX Bus with bookmark", @"button text")

#define kMaxFaves 30
#define kNoBookmark -1

#define kLastRunWatch @"last_run_watch"

#define kNewBookMark NSLocalizedString(@"New Stop Bookmark", @"new bookmark name")
#define kNewTripBookMark NSLocalizedString(@"New Trip Bookmark", @"new bookmark name")
#define kNewTakeMeSomewhereBookMark                                                                \
    NSLocalizedString(@"Take me <somewhere> now", @"new bookmark name")

#define kNewSavedTrip @"New Saved Trip"
#define kBookMarkUtil @"bookmark util"

#define kHandoffUserActivityBookmark @"org.teleportaloo.pdxbus.bookmark"
#define kHandoffUserActivityLocation @"org.teleportaloo.pdxbus.location"
#define kHandoffUserActivityAlerts @"org.teleportaloo.pdxbus.alerts"

#define kUserInfoAlertRoute @"route"
#define kUserInfoAlertSystem @"system"

#define kiCloudTotal @"total"

@interface NSDictionary (MutableDeepCopy)

- (NSMutableDictionary *)mutableDeepCopy;

@end

@interface UserState : NSObject <ClearableCache>

+ (UserState *)sharedInstance;

// Caching & writing to iCloud
@property bool readOnly;
@property (atomic) bool canWriteToCloud;
@property (nonatomic, readonly) NSTimeInterval locationDatabaseAge;
@property (strong, nonatomic) NSString *lastRunKey;
- (void)cacheState;
- (void)cacheStateNow;
- (void)mergeWithCloud:(NSArray *)changed;
- (void)clearCloud;
- (void)writeToCloud;

// Read / write array safely inside our access domain
- (void)accessArray:(NSMutableArray *)array block:(void (^)(NSMutableArray *safeArray))block;

// Faves (aka bookmarks)
- (NSMutableArray<NSMutableDictionary *> *)faves;
- (NSMutableArray *)stopsFromFaves;
- (NSArray<NSDictionary *> *)favesArrivalsOnly;
- (bool)hasEverChanged;
@property (nonatomic) bool dirty;
- (NSDictionary *)checkForCommuterFaveShowOnlyOnce:(bool)onlyOnce;

// Recent stops
- (NSMutableArray<NSDictionary *> *)recentStops;
- (NSDictionary *)addToRecentStops:(NSString *)stopId description:(NSString *)desc;

// Vehicle IDs
- (NSMutableArray<NSDictionary *> *)vehicleIds;
- (void)addToVehicleIds:(NSString *)vehicleId;

// Trips
@property (strong) NSMutableDictionary *lastTrip;
- (NSMutableArray<NSDictionary *> *)recentTrips;
- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest
                            description:(NSString *)desc
                                   blob:(NSData *)blob;
- (NSDictionary *)takeMeHomeUserRequest;
- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userReqest;

// Locate
@property (strong) NSMutableDictionary *lastLocate;

// Last run
@property (strong) NSDate *lastRun;

// Watch Sequence
- (void)incrementWatchSequence;
- (NSUInteger)watchSequence;

// Raw data and file.
@property (strong) NSMutableDictionary *watchData;
@property (strong) SharedFile *sharedUserCopyOfPlist;

@end

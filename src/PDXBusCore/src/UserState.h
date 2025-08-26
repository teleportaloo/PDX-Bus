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

#define kUserFavesDescription                                                  \
    NSLocalizedString(@"Launch PDX Bus & open bookmark %@", @"bookmark name")
#define kAddBookmarkToSiri                                                     \
    NSLocalizedString(@"Add to Siri to launch PDX Bus with bookmark",          \
                      @"button text")

#define kMaxFaves 30
#define kNoBookmark -1

#define kLastRunWatch @"last_run_watch"

#define kNewBookMark                                                           \
    NSLocalizedString(@"New Stop Bookmark", @"new bookmark name")
#define kNewTripBookMark                                                       \
    NSLocalizedString(@"New Trip Bookmark", @"new bookmark name")
#define kNewTakeMeSomewhereBookMark                                            \
    NSLocalizedString(@"Take me <somewhere> now", @"new bookmark name")

#define kNewSavedTrip @"New Saved Trip"
#define kBookMarkUtil @"bookmark util"

#define kHandoffUserActivityBookmark @"org.teleportaloo.pdxbus.bookmark"
#define kHandoffUserActivityLocation @"org.teleportaloo.pdxbus.location"
#define kHandoffUserActivityAlerts @"org.teleportaloo.pdxbus.alerts"

#define kUserInfoAlertRoute @"route"
#define kUserInfoAlertSystem @"system"

#define kiCloudTotal @"total"

@interface UserState : NSObject <ClearableCache>

@property(strong) NSMutableDictionary *rawData;
@property(weak, readonly) NSMutableArray<NSMutableDictionary *> *faves;
@property(weak, readonly) NSArray<NSDictionary *> *favesArrivalsOnly;
@property(weak, readonly) NSMutableArray<NSDictionary *> *recents;
@property(weak, readonly) NSMutableArray<NSDictionary *> *vehicleIds;
@property(weak, readonly) NSMutableArray<NSDictionary *> *recentTrips;
@property(weak, readonly) NSString *last;
@property(weak, readonly) NSArray<NSString *> *lastNames;
@property(strong) NSMutableDictionary *lastTrip;
@property(strong) NSMutableDictionary *lastLocate;
@property bool favesChanged;
@property(weak) NSDate *lastRun;
@property(strong) SharedFile *sharedUserCopyOfPlist;
@property bool readOnly;
@property(strong, nonatomic) NSString *lastRunKey;
@property(nonatomic, readonly, copy) NSDictionary *takeMeHomeUserRequest;
@property(nonatomic, readonly) NSTimeInterval locationDatabaseAge;
@property(nonatomic, readonly) bool hasEverChanged;
@property(atomic) bool canWriteToCloud;

- (void)incrementWatchSequence;
- (NSUInteger)watchSequence;
- (void)addToRecentTripsWithUserRequest:(NSDictionary *)userRequest
                            description:(NSString *)desc
                                   blob:(NSData *)blob;
- (NSDictionary *)addToRecentsWithStopId:(NSString *)stopId
                             description:(NSString *)desc;
- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce;
- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userReqest;
- (void)addToVehicleIds:(NSString *)vehicleId;
- (void)setLastArrivals:(NSString *)locations;
- (void)mergeWithCloud:(NSArray *)changed;
- (void)clearCloud;
- (void)setLastNames:(NSArray *)names;
- (void)clearLastArrivals;
- (void)writeToiCloud;
- (void)cacheState;

+ (UserState *)sharedInstance;

@end

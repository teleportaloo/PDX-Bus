//
//  UserPrefs.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/19/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@interface UserPrefs : NSObject {
    NSUserDefaults *_defaults;
    NSUserDefaults *_sharedDefaults;
}


@property (nonatomic, readonly)  bool  bookmarksAtTheTop;
@property (nonatomic, readonly)  bool  autoCommute;
@property (nonatomic, readonly)  bool  shakeToRefresh;
@property (nonatomic, readonly)  int   maxRecentStops;
@property (nonatomic, readonly)  int   maxRecentTrips;
@property (nonatomic, readonly)  float maxWalkingDistance;
@property (nonatomic, readonly)  int   travelBy;
@property (nonatomic, readonly)  int   tripMin;
@property (nonatomic, readonly)  bool  autoRefresh;
@property (nonatomic, readonly)  int   toolbarColors;
@property (nonatomic, readonly)  int   routeCacheDays;
@property (nonatomic, readonly)  int   networkTimeout;
@property (nonatomic, readonly)  bool  showTransitTracker; 
@property (nonatomic, readonly)  float useGpsWithin;
@property (nonatomic, readonly)  bool commuteButton;
@property (nonatomic)            bool flashLed;
@property (nonatomic)            bool showStreetcarMapFirst;
@property (nonatomic, readonly)  bool alarmInitialWarning;
@property (nonatomic, readonly)  bool useCaching;
@property (nonatomic, readonly)  bool debugXML;
@property (nonatomic, readonly)  int xmlViewer;
@property (nonatomic, readonly)  bool debugCommuter;
@property (nonatomic, readonly)  bool useChrome;
@property (nonatomic, readonly)  bool googleMapApp;
@property (nonatomic)            bool autoLocateShowOptions;
@property (weak, nonatomic, readonly)  NSString *alarmSoundFile;
@property (nonatomic, readonly)  bool vehicleLocations;
@property (nonatomic, readonly)  int  vehicleLocatorDistance;
@property (nonatomic)            bool locateToolbarIcon;
@property (nonatomic, readonly)  bool groupByArrivalsIcon;
@property (nonatomic)            bool flashingLightIcon;
@property (nonatomic, readonly)  bool qrCodeScannerIcon;
@property (nonatomic)            bool flashingLightWarning;
@property (nonatomic, readonly)  bool searchRoutes;
@property (nonatomic, readonly)  bool searchBookmarks;
@property (nonatomic, readonly)  bool searchStations;
@property (nonatomic, readonly)  bool useBetaVehicleLocator;
@property (weak, nonatomic, readonly)  NSString *busIcon;
@property (nonatomic, readonly)  bool showTrips;
@property (weak, nonatomic, readonly)  NSString *minsForArrivals;
@property (nonatomic)            NSSet<NSNumber*>* hiddenSystemWideDetours;
@property (nonatomic)            bool  kmlRoutes;
@property (nonatomic)            int   kmlAgeOut;
@property (nonatomic)            bool  kmlWifiOnly;
@property (nonatomic)            bool  showSizes;
@property (nonatomic)            bool  gitHubRouteShapes;
@property (nonatomic)            bool  progressDebug;
@property (nonatomic)            bool  firstLaunchWithiCloudAvailable;
@property (nonatomic)            id    iCloudToken;
@property (nonatomic, readonly)  bool  showDetourIds;
@property (nonatomic)            bool  hideWatchDetours;
@property (nonatomic, readonly)  bool  useAppleGeoLocator;
@property (nonatomic)            bool  useGpsForAllAlarms;

- (float)getFloatFromDefaultsForKey:(NSString*)key ifMissing:(float)missing max:(float)max min:(float)min writeToShared:(BOOL)writeToShared;
- (int) getIntFromDefaultsForKey:(NSString*)key ifMissing:(int)missing max:(int)max min:(int)min writeToShared:(BOOL)writeToShared;
- (BOOL)getBoolFromDefaultsForKey:(NSString*)key ifMissing:(BOOL)missing writeToShared:(BOOL)writeToShared;
- (void)removeOldSystemWideDetours:(NSSet *)detoursNoLongerFound;
- (void)toggleHiddenSystemWideDetour:(NSNumber *)detourId;
- (bool)isHiddenSystemWideDetour:(NSNumber *)detourId;

+ (UserPrefs*)sharedInstance;

@end

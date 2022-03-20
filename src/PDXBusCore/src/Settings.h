//
//  Settings.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/19/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@interface Settings : NSObject

// Common settings for watchOS and iOS
// Settings are not actually shared.

@property (class, weak, nonatomic, readonly)  NSString *minsForArrivals;
@property (class, nonatomic, readonly)  bool debugXML;
@property (class, nonatomic, readonly)  bool debugCommuter;

@property (class, nonatomic, readonly)  int networkTimeout;
@property (class, nonatomic)            bool hideWatchDetours;
@property (class, nonatomic, readonly)  bool networkInParallel;

@property (class, nonatomic)            NSSet<NSNumber *> *hiddenSystemWideDetours;
+ (void)toggleHiddenSystemWideDetour:(NSNumber *)detourId;
+ (bool)isHiddenSystemWideDetour:(NSNumber *)detourId;
+ (void)removeOldSystemWideDetours:(NSSet *)detoursNoLongerFound;

// iOS only settings
#ifndef PDXBUS_WATCH

@property (class, nonatomic, readonly)  bool clearCacheOnUnexpectedRestart;
@property (class, nonatomic, readonly)  bool autoCommute;
@property (class, nonatomic, readonly)  bool bookmarksAtTheTop;
@property (class, nonatomic)            bool locateToolbarIcon;
@property (class, nonatomic, readonly)  bool commuteButton;
@property (class, nonatomic)            bool flashingLightIcon;
@property (class, nonatomic, readonly)  int toolbarColors;
@property (class, nonatomic)            bool flashLed;
@property (class, nonatomic)            bool flashingLightWarning;
@property (class, nonatomic, readonly)  bool autoRefresh;
@property (class, nonatomic, readonly)  bool groupByArrivalsIcon;
@property (class, nonatomic)            bool autoLocateShowOptions;
@property (class, nonatomic, readonly)  bool useAppleGeoLocator;
@property (class, nonatomic, readonly)  float maxWalkingDistance;
@property (class, nonatomic, readonly)  int travelBy;
@property (class, nonatomic, readonly)  int tripMin;
@property (class, weak, nonatomic, readonly)  NSString *alarmSoundFile;
@property (class, nonatomic)            bool showStreetcarMapFirst;
@property (class, nonatomic, readonly)  bool useChrome;
@property (class, nonatomic, readonly)  bool searchStations;
@property (class, nonatomic, readonly)  bool searchBookmarks;
@property (class, nonatomic, readonly)  bool searchRoutes;
@property (class, nonatomic, readonly)  bool kmlRoutes;
@property (class, nonatomic, readonly)  int kmlAgeOut;
@property (class, nonatomic, readonly)  bool kmlManual;
@property (class, nonatomic, readonly)  bool kmlWifiOnly;
@property (class, nonatomic, readonly)  int vehicleLocatorDistance;
@property (class, nonatomic, readonly)  bool vehicleLocations;
@property (class, nonatomic, readonly)  float useGpsWithin;
@property (class, nonatomic, readonly)  int xmlViewer;
@property (class, nonatomic, readonly)  bool progressDebug;
@property (class, nonatomic, readonly)  bool showTransitTracker;
@property (class, nonatomic, readonly)  bool showSizes;
@property (class, nonatomic, readonly)  bool useVehicleLocator;
@property (class, nonatomic, readonly)  bool showTrips;
@property (class, nonatomic, readonly)  bool showDetourIds;
@property (class, nonatomic, readonly)  bool useGpsForAllAlarms;
@property (class, nonatomic)            bool firstLaunchWithiCloudAvailable;
@property (class, nonatomic)            id iCloudToken;

#endif // ifndef PDXBUS_WATCH

@end

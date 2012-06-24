//
//  UserPrefs.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/19/10.
//  Copyright 2010. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


#import <Foundation/Foundation.h>
#import"XMLReverseGeoCode.h"

#define UserPrefs_ReverseGeoCodeNone		0
#define UserPrefs_ReverseGeoCodeYahoo		1
#define UserPrefs_ReverseGeoCodeGeoNames	2
#define UserPrefs_ReverseGeoCodeGeoNamesNbh	3
#define UserPrefs_ReverseGeoCodeMax			3



@interface UserPrefs : NSObject {
		NSUserDefaults *_defaults;
}

- (BOOL) getBoolFromDefaultsForKey:(NSString*)key ifMissing:(BOOL)missing;
- (float)getFloatFromDefaultsForKey:(NSString*)key ifMissing:(float)missing max:(float)max min:(float)min;
- (int)  getIntFromDefaultsForKey:(NSString*)key ifMissing:(int)missing max:(int)max min:(int)min;

@property (nonatomic, readonly)  bool  bookmarksAtTheTop;
@property (nonatomic, readonly)  bool  autoCommute;
@property (nonatomic, readonly)  bool  shakeToRefresh;
@property (nonatomic, readonly)  int   maxRecentStops;
@property (nonatomic, readonly)  int   maxRecentTrips;
@property (nonatomic, readonly)  bool  lastScreenDisplayed;
@property (nonatomic, readonly)  bool  displayTripPlanning;
@property (nonatomic, readonly)  float maxWalkingDistance;
@property (nonatomic, readonly)  int   travelBy;
@property (nonatomic, readonly)  int   tripMin;
@property (nonatomic, readonly)  bool  autoRefresh;
@property (nonatomic, readonly)  int   toolbarColors;
@property (nonatomic, readonly)  bool  actionIcons;
@property (nonatomic, readonly)  int   routeCacheDays;
@property (nonatomic, readonly)  int   networkTimeout;
@property (nonatomic, readonly)  bool  showTransitTracker; 
@property (nonatomic, readonly)  float useGpsWithin;
@property (nonatomic, readonly)  bool commuteButton;
@property (nonatomic)            bool flashLed;
@property (nonatomic, readonly)  bool alarmInitialWarning;
@property (nonatomic, readonly)  bool useCaching;
@property (nonatomic, readonly)  XMLReverseGeoCode * reverseGeoCodeProvider;

@end

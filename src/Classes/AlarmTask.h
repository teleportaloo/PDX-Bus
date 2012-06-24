//
//  AlarmTask.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
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
#import <CoreLocation/CoreLocation.h>
#import "BackgroundTaskContainer.h"
#import "ScreenConstants.h"
#import "AlarmCell.h"
#import "debug.h"

#define kStopIdNotification @"stopId"
#define kAlarmBlock			@"alarmBlock"
#define kStopMapDescription @"stopDesc"
#define kStopMapLat			@"mapLat"
#define kStopMapLng			@"mapLng"
#define kCurrLocLat			@"curLat"
#define kCurrLocLng			@"curLng"
#define kCurrTimestamp		@"curTimestamp"
#define kDoNotDisplayIfActive @"not if active"
#define kNoBadge            @"no badge"

typedef enum AlarmStateTag {
	AlarmStateFetchArrivals,
	AlarmStateNearlyArrived,
	AlarmStateAccurateLocationNeeded,
	AlarmStateAccurateInitiallyThenInaccurate,
	AlarmStateInaccurateLocationNeeded,
	AlarmFired
} AlarmLocationNeeded;

#ifdef DEBUGLOGGING
// #define DEBUG_ALARMS
#endif

@protocol AlarmObserver <NSObject> 

- (void)taskStarted:(id)task;
- (void)taskUpdate:(id)task;
- (void)taskDone:(id)task;

@end

@interface AlarmTask : NSObject   {

	NSString *					_desc;
	AlarmLocationNeeded			_alarmState;
	NSString *					_stopId;
	id<AlarmObserver>			_observer;
	UILocalNotification *		_alarm;
#ifdef DEBUG_ALARMS
	NSMutableArray *			_dataReceived;
	bool						_done;
#endif
	NSDate *					_nextFetch;
    bool                        _alarmWarningDisplayed;
	
}

@property (nonatomic, retain)	NSString *desc;
@property (nonatomic)			AlarmLocationNeeded alarmState;
@property (nonatomic, retain)   NSDate *nextFetch;

@property (nonatomic, retain)	NSString * stopId;
@property (nonatomic, assign)	id<AlarmObserver> observer; // weak
@property (retain)				UILocalNotification *alarm;
@property (readonly, nonatomic) int threadReferenceCount;
@property (nonatomic)           bool alarmWarningDisplayed;

#ifdef DEBUG_ALARMS
@property (retain) NSMutableArray *dataReceived;
- (void)showMap:(UINavigationController *)navController;
#endif

- (NSString *)key;
- (void)cancelTask;
- (void)startTask;
- (int)internalDataItems;
- (NSString *)internalData:(int)item;
- (NSDate *)fetch;

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;

- (void)alert:(NSString *)string 
	 fireDate:(NSDate*)fireDate button:(NSString *)button userInfo:(NSDictionary *)userInfo defaultSound:(bool)defaultSound; 

- (void)cancelNotification;
- (NSString *)cellDescription;
- (NSString *)cellToGo;
- (void)showToUser:(BackgroundTaskContainer *)backgroundTask;
- (NSString *)icon;
- (UIColor *)color;
- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width;
- (void)populateCell:(AlarmCell *)cell;
- (NSDate*)earlierAlert:(NSDate *)alert;
- (NSString*)appState;


@end

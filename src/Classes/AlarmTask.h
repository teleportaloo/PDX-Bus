//
//  AlarmTask.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BackgroundTaskContainer.h"
#import "ScreenConstants.h"
#import "AlarmCell.h"
#import "DebugLogging.h"
#import "DataFactory.h"

#define kStopIdNotification @"stopId"
#define kAlarmBlock            @"alarmBlock"
#define kStopMapDescription @"stopDesc"
#define kStopMapLat            @"mapLat"
#define kStopMapLng            @"mapLng"
#define kCurrLocLat            @"curLat"
#define kCurrLocLng            @"curLng"
#define kCurrTimestamp        @"curTimestamp"
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

@class AlarmTaskList;

@interface AlarmTask : DataFactory
{    
#ifdef DEBUG_ALARMS
    NSMutableArray *            _dataReceived;
    bool                        _done;
#endif
    
}

@property (nonatomic, copy)        NSString *desc;
@property (atomic)                AlarmLocationNeeded alarmState;
@property (nonatomic, strong)   NSDate *nextFetch;
@property (nonatomic, copy)        NSString * stopId;
@property (nonatomic, weak)    id<AlarmObserver> observer; // weak
@property (strong)                UILocalNotification *alarm;
@property (readonly, nonatomic) int threadReferenceCount;
@property (nonatomic)           bool alarmWarningDisplayed;
@property (nonatomic, readonly, copy) NSString *key;
@property (nonatomic, readonly) int internalDataItems;
@property (nonatomic, readonly, copy) NSString *cellDescription;
@property (nonatomic, readonly, copy) NSString *cellToGo;
@property (nonatomic, readonly, copy) NSString *icon;
@property (nonatomic, readonly, copy) UIColor *color;
@property (nonatomic, readonly, copy) NSString *appState;

- (void)cancelTask;
- (void)startTask;
- (NSString *)internalData:(int)item;
- (NSDate *)fetch:(AlarmTaskList*)parent;
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation;
- (void)alert:(NSString *)string 
     fireDate:(NSDate*)fireDate button:(NSString *)button userInfo:(NSDictionary *)userInfo defaultSound:(bool)defaultSound
   thisThread:(bool)thisThread;
- (void)cancelNotification;
- (void)showToUser:(BackgroundTaskContainer *)backgroundTask;
- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width;
- (void)populateCell:(AlarmCell *)cell;
- (NSDate*)earlierAlert:(NSDate *)alert;

#ifdef DEBUG_ALARMS
@property (strong) NSMutableArray *dataReceived;
- (void)showMap:(UINavigationController *)navController;
#endif

@end

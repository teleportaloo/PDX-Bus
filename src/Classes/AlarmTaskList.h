//
//  AlarmTaskList.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/29/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "AlarmFetchArrivalsTask.h"
#import "Departure.h"
#import <CoreLocation/CoreLocation.h>


#define kMileProximity			(1609.344)
#define kHalfMile				(kMileProximity/2)
#define kThirdMile				(kMileProximity/3)
#define kProximity				kThirdMile
#define kBadAccuracy			(800.0)
#define kUserDistanceProximity  NSLocalizedString(@"1/3 mile", @"proximity alarm distance")
#define kUserProximityCellText  NSLocalizedString(@"Proximity alarm (1/3 mile)",@"proximity alarm distance")

@interface AlarmTaskList : NSObject <AlarmObserver>
{
	NSMutableDictionary *_backgroundTasks;
    NSMutableArray *_orderedTaskKeys;
    NSMutableArray *_newTaskKeys;
	id<AlarmObserver> _observer;
	UIBackgroundTaskIdentifier _taskId; 
	NSThread *_backgroundThread;
	bool _batchUpdate;
    bool _atomicTaskRunning;
}

// @property (nonatomic, retain) NSMutableDictionary *backgroundTasks;
@property (nonatomic, retain) id<AlarmObserver> observer;
@property (retain) NSThread *backgroundThread;


+ (AlarmTaskList*)getSingleton;
+ (bool)supported;
+ (bool)proximitySupported;
- (void)addTaskForDeparture:(Departure *)dep mins:(uint)mins;
- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block;
- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block;
- (void)cancelTaskForKey:(NSString *)key;
- (void)cancelTaskForStopId:(NSString *)stopId block:(NSString *)block;
- (void)addTaskForStopIdProximity:(NSString *)stopId lat:(NSString *)lat lng:(NSString *)lng desc:(NSString *)desc 
						 accurate:(bool)accurate;
- (bool)hasTaskForStopIdProximity:(NSString *)stopId;
- (void)cancelTaskForStopIdProximity:(NSString*)stopId;
- (void)runTask;

- (void)taskUpdate:(id)task;
- (void)taskDone:(id)task;
- (void)taskStarted:(id)task;
- (NSInteger)taskCount;
- (NSArray *)taskKeys;
- (AlarmTask *)taskForKey:(NSString *)key;
- (void)userAlertForProximity:(id<UIAlertViewDelegate>) delegate;
- (bool)userAlertForProximityAction:(NSInteger)button
							 stopId:(NSString *)stopId 
								lat:(NSString *)lat 
								lng:(NSString *)lng 
							   desc:(NSString *)desc;

- (void)resumeOnActivate;
- (void)checkForLongAlarms;
- (void)updateBadge;

@end

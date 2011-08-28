//
//  AlarmTaskList.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/29/11.
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
#import "AlarmFetchArrivalsTask.h"
#import "Departure.h"
#import <CoreLocation/CoreLocation.h>


#define kMileProximity			(1609.344)
#define kHalfMile				(kMileProximity/2)
#define kThirdMile				(kMileProximity/3)
#define kProximity				kThirdMile
#define kBadAccuracy			(800.0)
#define kUserDistanceProximity  @"1/3 mile"
#define kUserProximityCellText  @"Proximity alarm (1/3 mile)"

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
- (int)taskCount;
- (NSArray *)taskKeys;
- (AlarmTask *)taskForKey:(NSString *)key;
- (void)userAlertForProximity:(id<UIAlertViewDelegate>) delegate;
- (bool)userAlertForProximityAction:(int)button 
							 stopId:(NSString *)stopId 
								lat:(NSString *)lat 
								lng:(NSString *)lng 
							   desc:(NSString *)desc;

- (void)resumeOnActivate;

@end

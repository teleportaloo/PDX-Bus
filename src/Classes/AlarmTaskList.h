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
#import "DepartureData.h"
#import <CoreLocation/CoreLocation.h>

#define kMileProximity            (1609.344)
#define kHalfMile                (kMileProximity/2)
#define kThirdMile                (kMileProximity/3)
#define kProximity                kThirdMile
#define kBadAccuracy            (800.0)
#define kUserDistanceProximity  NSLocalizedString(@"⅓ mile", @"proximity alarm distance")
#define kUserProximityCellText  NSLocalizedString(@"Proximity alarm (⅓ mile)",@"proximity alarm distance")
#define kUserProximityDeniedCellText NSLocalizedString(@"Proximity alarm (not authorized)",@"proximity alarm error")


@interface AlarmTaskList : NSObject <AlarmObserver>
{
    NSMutableDictionary *       _backgroundTasks;
    NSMutableArray *            _orderedTaskKeys;
    NSMutableArray *            _newTaskKeys;
    UIBackgroundTaskIdentifier  _taskId;
    bool                        _batchUpdate;
}

@property (nonatomic, strong) id<AlarmObserver> observer;
@property (strong) NSThread *backgroundThread;
@property (atomic) bool atomicTaskRunning;
@property (atomic, strong) NSDate *nextFetch;
@property (nonatomic, readonly) NSInteger taskCount;
@property (nonatomic, readonly, copy) NSArray *taskKeys;

- (void)addTaskForDeparture:(DepartureData *)dep mins:(uint)mins;
- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block;
- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block;
- (void)cancelTaskForKey:(NSString *)key;
- (void)cancelTaskForStopId:(NSString *)stopId block:(NSString *)block;
- (void)addTaskForStopIdProximity:(NSString *)stopId loc:(CLLocation *)loc desc:(NSString *)desc
                         accurate:(bool)accurate;
- (bool)hasTaskForStopIdProximity:(NSString *)stopId;
- (void)cancelTaskForStopIdProximity:(NSString*)stopId;
- (void)runTask;

- (void)taskUpdate:(id)task;
- (void)taskDone:(id)task;
- (void)taskStarted:(id)task;
- ( AlarmTask __strong *)taskForKey:(NSString *)key;
- (void)userAlertForProximity:(UIViewController *)parent source:(UIView *)source completion:(void (^)(bool cancelled, bool accurate))completionHandler;
- (void)resumeOnActivate;
- (void)checkForLongAlarms;
- (void)updateBadge;

+ (AlarmTaskList*)sharedInstance;
+ (bool)supported;
+ (bool)proximitySupported;

@end

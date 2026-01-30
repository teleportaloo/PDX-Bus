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


#import "AlarmFetchArrivalsTask.h"
#import "Departure.h"
#import "FormatDistance.h"
#import "ViewControllerBase.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define kTargetProximity (kMetresInAMile / 3)
#define kBadAccuracy (800.0)
#define kUserDistanceProximity NSLocalizedString(@"⅓ mile", @"proximity alarm distance")
#define kUserProximityCellText                                                                     \
    NSLocalizedString(@"Proximity alarm (⅓ mile)", @"proximity alarm distance")
#define kUserProximityDeniedCellText                                                               \
    NSLocalizedString(@"Proximity alarm (not authorized)", @"proximity alarm error")

@interface AlarmTaskList : NSObject <AlarmObserver, CLLocationManagerDelegate>

@property (nonatomic, readonly, copy) NSArray *taskKeys;
@property (nonatomic, readonly) NSInteger taskCount;
@property (nonatomic, strong) id<AlarmObserver> observer;

- (void)cancelTaskForKey:(NSString *)key;
- (AlarmTask __strong *)taskForKey:(NSString *)key;

- (void)resumeOnActivate;
- (void)updateBadge;

- (bool)hasTaskForStopIdProximity:(NSString *)stopId;
- (void)cancelTaskForStopIdProximity:(NSString *)stopId;
- (void)userAlertForProximity:(ViewControllerBase *)parent
                       source:(UIView *)source
                   completion:(void (^)(bool cancelled, bool accurate))completionHandler;
- (void)addTaskForStopIdProximity:(NSString *)stopId
                              loc:(CLLocation *)loc
                             desc:(NSString *)desc
                         accurate:(bool)accurate
                       controller:(UIViewController *)controller;

- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir;
- (void)addTaskForDeparture:(Departure *)dep
                       mins:(uint)mins
                 controller:(UIViewController *)controller;
- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir;
- (void)cancelTaskForStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir;

+ (AlarmTaskList *)sharedInstance;
+ (bool)supported;
+ (bool)proximitySupported;

@end

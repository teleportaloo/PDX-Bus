//
//  TaskLocator.m
//  PDX Bus
//
//  Created by Andy Wallace on 7/17/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskLocator.h"
#import "FormatDistance.h"
#import "TaskDispatch.h"

#define MAX_AGE -30.0
#define DEBUG_LEVEL_FOR_FILE LogUI

@interface TaskLocator () {
    _Atomic(bool) _waitingForLocation;
    _Atomic(bool) _failed;
    double _accuracy;
    bool _askedForFullAccuracyOnce;
    dispatch_semaphore_t _locationAvailable;
}

@property(nonatomic, strong) CLLocation *lastLocation;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, copy) NSString *error;
@property(nonatomic, weak) TaskState *state;

@end

@implementation TaskLocator

- (void)dealloc {
    if (_locationManager) {
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
    }
}

- (instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy {
    if (self = [super init]) {
        _locationAvailable = dispatch_semaphore_create(0);
        _accuracy = accuracy;
    }
    return self;
}

- (CLLocation *)waitForLocation:(TaskState *)state {
    _waitingForLocation = true;
    self.state = state;

    MainTask(^{
      [self authorize];
      [self startLocating];
    });

    [state taskSubtext:@"locating"];
    [state displayItemsDone];

    __weak __typeof(self) weakSelf = self;

    [state
        addCancelObserver:self
                    block:^{
                      __strong __typeof(self) strongSelf = weakSelf;
                      if (!strongSelf)
                          return;

                      dispatch_semaphore_signal(strongSelf->_locationAvailable);
                    }];

    CLLocation *result = nil;

    // Adding a self retain in this loop as sometimes we appear to have
    // lost our self, especially on failure.

    __unused id keepAlive = self;
    while (_waitingForLocation) {
        dispatch_semaphore_wait(_locationAvailable, DISPATCH_TIME_FOREVER);

        if (state.taskCancelled) {
            _waitingForLocation = false;
        } else if (_failed) {
            _waitingForLocation = false;
            [state taskSetErrorMsg:
                       [NSString
                           stringWithFormat:
                               @"Unable to get location. Please check the "
                               @"settings to "
                               @"ensure location access has been granted. %@",
                               self.error ? self.error : @""]];
        } else {
            if (self.lastLocation) {
                if (self.lastLocation.horizontalAccuracy > _accuracy) {
                    [state
                        taskSubtext:
                            [NSString
                                stringWithFormat:
                                    @"Locating +/- %@",
                                    [FormatDistance
                                        formatMetres:self.lastLocation
                                                         .horizontalAccuracy]]];
                } else {
                    _waitingForLocation = false;
                    result = self.lastLocation;
                }
            }
        }
    }

    [self stopLocating];
    [state incrementItemsDoneAndDisplay];
    [state removeCancelObserver:self];
    self.state = nil;

    DEBUG_LOG(@"Final location %@", result.description);
    return result;
}

+ (CLLocation *)locateWithAccuracy:(double)accuracy
                         taskState:(TaskState *)state {

    TaskLocator *task = [[TaskLocator alloc] initWithAccuracy:accuracy];

    return [task waitForLocation:state];
}

- (void)authorize {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [self.locationManager requestAlwaysAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = locations.lastObject;

    DEBUG_LOG(@"location got %@\n", newLocation.description);

    if (!_waitingForLocation) {
        return;
    }

    if (self.locationManager.accuracyAuthorization ==
        CLAccuracyAuthorizationReducedAccuracy) {
        [self.state taskSubtext:@"Using approximate location"];
        DEBUG_LOG(@"Adjusting accuracy");
        if (_accuracy < 5000) {
            _accuracy = 5000;
        }
    }

    if (newLocation.timestamp.timeIntervalSinceNow < MAX_AGE) {
        DEBUG_LOG(@"too old %f\n", newLocation.timestamp.timeIntervalSinceNow);
        // too old!
        return;
    }

    self.lastLocation = newLocation;

    dispatch_semaphore_signal(self->_locationAvailable);
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    DEBUG_LOG(@"location error %@\n", [error localizedDescription]);

    if (!_waitingForLocation) {
        return;
    }

    switch (error.code) {

    case kCLErrorLocationUnknown:
        DEBUG_LOG(@"kCLErrorLocationUnknown");

        [self.state
            taskSubtext:[NSString stringWithFormat:@"Unknown location"]];
        break;
    default:
    case kCLErrorNetwork:
    case kCLErrorRegionMonitoringDenied:
    case kCLErrorDenied:
        _failed = YES;
        self.error = [error localizedDescription];
        dispatch_semaphore_signal(_locationAvailable);
        break;
    }
}

- (void)startLocating {
    self.locationManager.delegate = self;

    self.locationManager.desiredAccuracy = _accuracy; // or tune
    self.locationManager.distanceFilter = kCLDistanceFilterNone;

    _failed = false;

    if (self.locationManager.accuracyAuthorization ==
            CLAccuracyAuthorizationReducedAccuracy &&
        !_askedForFullAccuracyOnce) {
        _askedForFullAccuracyOnce = YES;
        __weak __typeof(self) weakSelf = self;
        // clang-format off
        [self.locationManager requestTemporaryFullAccuracyAuthorizationWithPurposeKey: @"NearbySearch"
                                                                           completion:^(__unused NSError *_Nullable err) {
            __strong __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) return;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(0.4 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [strongSelf.locationManager startUpdatingLocation];
            });
            // resume/start
        }];
        // clang-format on
    } else {
        // Keep going immediately; system will give reduced or full as
        // available
        [self.locationManager startUpdatingLocation];
    }
}

- (void)stopLocating {
    [self.locationManager stopUpdatingLocation];
}

@end

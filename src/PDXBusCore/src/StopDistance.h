//
//  StopDistance.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Route.h"
#import <CoreLocation/CoreLocation.h>

@interface StopDistance : NSObject

@property(nonatomic, strong) CLLocation *location;
@property(nonatomic) CLLocationDistance distanceMeters;
@property(nonatomic) CLLocationAccuracy accuracy;
@property(nonatomic, copy) NSString *stopId;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, copy) NSString *dir;
@property(nonatomic, strong) NSMutableArray<Route *> *routes;

- (instancetype)initWithStopId:(int)stopId
                distanceMeters:(CLLocationDistance)dist
                      accuracy:(CLLocationAccuracy)acc;
- (NSComparisonResult)compareUsingDistance:(StopDistance *)inStop;

@end

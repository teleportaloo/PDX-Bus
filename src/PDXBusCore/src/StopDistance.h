//
//  StopDistance.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"
#import "Route.h"

@interface StopDistance : DataFactory

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic, copy) NSString *stopId;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *dir;
@property (nonatomic, strong) NSMutableArray<Route *> *routes;

- (instancetype)initWithStopId:(int)stopId distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc;
- (NSComparisonResult)compareUsingDistance:(StopDistance *)inStop;

@end

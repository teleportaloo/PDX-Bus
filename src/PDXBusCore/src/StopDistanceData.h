//
//  StopDistanceData.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"
#import "Route.h"

@interface StopDistanceData : DataFactory 

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic, copy) NSString *locid;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *dir;
@property (nonatomic, strong) NSMutableArray<Route *> *routes;

-(instancetype)initWithLocId:(int)locid distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc;
-(NSComparisonResult)compareUsingDistance:(StopDistanceData*)inStop;

@end

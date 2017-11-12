//
//  StopDistanceData.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"

@interface StopDistanceData : DataFactory {
	NSString *          _locid;
	CLLocationDistance  _distance;
	CLLocationAccuracy  _accuracy;
	CLLocation          *_location;
	NSString *          _desc;
    NSString *          _dir;
}

-(instancetype)initWithLocId:(int)locid distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc;

-(NSComparisonResult)compareUsingDistance:(StopDistanceData*)inStop;


@property (nonatomic, copy)   NSString *locid;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *dir;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic, retain) CLLocation *location;

@end

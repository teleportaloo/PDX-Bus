//
//  StopDistance.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MapPinColor.h"


@interface StopDistance : NSObject <MapPinColor> {
	NSString *          _locid;
	CLLocationDistance  _distance;
	CLLocationAccuracy  _accuracy;
	CLLocation          *_location;
	NSString *          _desc;
    NSString *          _dir;
}

-(id)initWithLocId:(int)locid distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc;

-(NSComparisonResult)compareUsingDistance:(StopDistance*)inStop;


@property (nonatomic, retain) NSString *locid;
@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *dir;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic, retain) CLLocation *location;

@end

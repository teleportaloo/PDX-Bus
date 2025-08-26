//
//  Vehicle.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXML.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define kVehicleTypeBus @"bus"
#define kVehicleTypeTrain @"rail"
#define kVehicleTypeStreetcar @"streetcar"

// #define VEHICLE_TEST 1

@interface Vehicle : NSObject

@property(nonatomic, copy) NSString *signMessageLong;
@property(nonatomic, strong) NSDate *locationTime;
@property(nonatomic, strong) CLLocation *location;
@property(nonatomic, copy) NSString *signMessage;
@property(nonatomic, copy) NSString *routeNumber;
@property(nonatomic, copy) NSString *direction;
@property(nonatomic, copy) NSString *vehicleId;
@property(nonatomic, copy) NSString *nextStopId;
@property(nonatomic, copy) NSString *lastStopId;
@property(nonatomic, copy) NSString *bearing;
@property(nonatomic, copy) NSString *garage;
@property(nonatomic, copy) NSString *block;
@property(nonatomic, copy) NSString *type;
@property(nonatomic) NSInteger loadPercentage;
@property(nonatomic, copy) NSString *speedKmHr;
@property(nonatomic) bool inCongestion;
@property(nonatomic) bool offRoute;
@property(nonatomic, copy) NSString *delay;

@property(nonatomic) double distance;

- (bool)typeMatchesMode:(TripMode)mode;

+ (NSString *)locatedSomeTimeAgo:(NSDate *)date;

@end

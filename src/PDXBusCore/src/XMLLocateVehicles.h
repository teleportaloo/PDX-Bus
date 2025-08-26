//
//  XMLLocateVehicles.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"
#import "Vehicle.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface XMLLocateVehicles : TriMetXMLv2 <Vehicle *>

@property(nonatomic) double dist;
@property(nonatomic, strong) CLLocation *location;
@property(nonatomic) bool noErrorAlerts;

- (bool)findNearestVehicles:(NSSet<NSString *> *)routeIdSet
                  direction:(NSString *)direction
                     blocks:(NSSet<NSString *> *)blockIdSet
                   vehicles:(NSSet<NSString *> *)vehicleIdSet
                      since:(NSDate *)since;
@end

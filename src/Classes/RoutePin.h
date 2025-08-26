//
//  RoutePin.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/12/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapPin.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface RoutePin : NSObject <MapPin>

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic) CLLocationCoordinate2D touchPosition;
@property(nonatomic, strong) UIColor *color;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, copy) NSString *route;
@property(nonatomic, copy) NSString *dir;

- (BOOL)isEqualToRoutePin:(RoutePin *)pin;

@end

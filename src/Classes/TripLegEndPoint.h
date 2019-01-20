//
//  TripLegEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "MapPinColor.h"
#import "DataFactory.h"

@protocol ReturnTripLegEndPoint;

@interface TripLegEndPoint: DataFactory <MapPinColor, NSCopying>

@property (nonatomic, strong) id<ReturnTripLegEndPoint> callback;
@property (nonatomic, copy) NSString *xlat;
@property (nonatomic, copy) NSString *xlon;
@property (nonatomic, copy) NSString *xdescription;
@property (nonatomic, copy) NSString *xstopId;
@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, copy) NSString *mapText;
@property (nonatomic, copy) NSString *displayModeText;
@property (nonatomic, copy) NSString *displayTimeText;
@property (nonatomic, copy) UIColor *leftColor;
@property (nonatomic, copy) NSString *xnumber;
@property (nonatomic) int index;
@property (nonatomic) bool thruRoute;
@property (nonatomic) bool deboard;
@property (nonatomic, readonly, copy) NSString *stopId;
@property (nonatomic) MapPinColorValue pinColor;
@property (nonatomic, readonly, copy) NSString *mapStopId;
@property (nonatomic, readonly, copy) CLLocation *loc;

- (id)copyWithZone:(NSZone *)zone;

@end

@protocol ReturnTripLegEndPoint

@property (nonatomic, readonly, copy) NSString *actionText;

- (void)chosenEndpoint:(TripLegEndPoint*)endpoint;

@end


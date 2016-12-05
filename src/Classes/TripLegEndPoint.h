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
{
	NSString *                  _xlat;
	NSString *                  _xlon;
	NSString *                  _xdescription;
	NSString *                  _xstopId;
	NSString *                  _displayText;
	NSString *                  _mapText;
	NSString *                  _displayModeText;
	NSString *                  _displayTimeText;
	NSString *                  _xnumber;
	UIColor *                   _leftColor;
	int                         _index;
	id<ReturnTripLegEndPoint>   _callback;
}

@property (nonatomic, copy) id<ReturnTripLegEndPoint> callback;
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
@property (nonatomic) MKPinAnnotationColor pinColor;
@property (nonatomic, readonly, copy) NSString *mapStopId;
- (id)copyWithZone:(NSZone *)zone;
@property (nonatomic, readonly, copy) CLLocation *loc;


@end

@protocol ReturnTripLegEndPoint

- (void) chosenEndpoint:(TripLegEndPoint*)endpoint;
@property (nonatomic, readonly, copy) NSString *actionText;

@end


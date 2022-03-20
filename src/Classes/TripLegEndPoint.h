//
//  TripLegEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "MapPin.h"

@protocol ReturnTripLegEndPoint;

// XML Atributes starting with setX are read directly from XML, setters match XML exactly.

@interface TripLegEndPoint : NSObject <MapPin, NSCopying>

@property (nonatomic, strong) id<ReturnTripLegEndPoint> callback;
@property (nonatomic, copy, setter = setXml_lat:) NSString *lat;
@property (nonatomic, copy, setter = setXml_lon:) NSString *lon;
- (NSString *)lat UNAVAILABLE_ATTRIBUTE;
- (NSString *)lon UNAVAILABLE_ATTRIBUTE;
// Use the loc to read the location not the strings.
@property (nonatomic, copy) CLLocation *loc;

@property (nonatomic, copy, setter = setXml_description:) NSString *desc;
@property (nonatomic, copy, setter = setXml_stopId:) NSString *strStopId;
@property (nonatomic, readonly, copy) NSString *stopId;

@property (nonatomic, copy, setter = setXml_number:) NSString *displayRouteNumber;

@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, copy) NSString *mapText;
@property (nonatomic, copy) NSString *displayModeText;
@property (nonatomic, copy) NSString *displayTimeText;
@property (nonatomic, copy) UIColor *leftColor;

@property (nonatomic) int index;
@property (nonatomic) bool thruRoute;
@property (nonatomic) bool deboard;

@property (nonatomic) bool fromAppleMaps;

- (id)copyWithZone:(NSZone *)zone;

@end

@protocol ReturnTripLegEndPoint

@property (nonatomic, readonly, copy) NSString *actionText;

- (void)chosenEndpoint:(TripLegEndPoint *)endpoint;

@end

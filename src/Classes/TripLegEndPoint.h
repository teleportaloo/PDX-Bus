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

@protocol ReturnTripLegEndPoint;

@interface TripLegEndPoint: NSObject <MapPinColor, NSCopying>
{
	NSString *_xlat;
	NSString *_xlon;
	NSString *_xdescription;
	NSString *_xstopId;
	NSString *_displayText;
	NSString *_mapText;
	NSString *_displayModeText;
	NSString *_displayTimeText;
	NSString *_xnumber;
	UIColor *_leftColor;
	int _index;
	id<ReturnTripLegEndPoint> _callback;
}

@property (nonatomic, retain) id<ReturnTripLegEndPoint> callback;
@property (nonatomic, retain) NSString		*xlat;
@property (nonatomic, retain) NSString		*xlon;
@property (nonatomic, retain) NSString		*xdescription;
@property (nonatomic, retain) NSString		*xstopId;
@property (nonatomic, retain) NSString		*displayText;
@property (nonatomic, retain) NSString		*mapText;
@property (nonatomic, retain) NSString		*displayModeText;
@property (nonatomic, retain) NSString		*displayTimeText;
@property (nonatomic, retain) UIColor       *leftColor;
@property (nonatomic, retain) NSString      *xnumber;
@property (nonatomic) int index;
@property (nonatomic)         bool          thruRoute;
@property (nonatomic)         bool          deboard;

- (NSString*)stopId;
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;
- (bool)mapTapped:(id<BackgroundTaskProgress>) progress;
- (id)copyWithZone:(NSZone *)zone;
- (CLLocation *)loc;


@end

@protocol ReturnTripLegEndPoint

- (void) chosenEndpoint:(TripLegEndPoint*)endpoint;
- (NSString *)actionText;

@end


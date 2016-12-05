//
//  TripItinerary.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TripLeg.h"
#import "TripEndPoint.h"
#import "TripLegEndPoint.h"

@interface TripItinerary : NSObject {
	NSString *                          _xdate;
	NSString *                          _xstartTime;
	NSString *                          _xendTime;
	NSString *                          _xduration;
	NSString *                          _xdistance;
	NSString *                          _xnumberOfTransfers;
	NSString *                          _xnumberofTripLegs;
	NSString *                          _xwalkingTime;
	NSString *                          _xtransitTime;
	NSString *                          _xwaitingTime;
	NSMutableString *                   _fare;
	NSMutableArray<TripLeg *> *         _legs;
	NSMutableArray<TripLegEndPoint*> *  _displayEndPoints;
	TripLegEndPoint *                   _startPoint;
	NSString *                          _xmessage;
}

@property (nonatomic, copy) NSString *xwaitingTime;
@property (nonatomic, copy) NSString *xdate;
@property (nonatomic, copy) NSString *xstartTime;
@property (nonatomic, copy) NSString *xendTime;
@property (nonatomic, copy) NSString *xduration;
@property (nonatomic, copy) NSString *xdistance;
@property (nonatomic, copy) NSString *xmessage;
@property (nonatomic, copy) NSString *xnumberOfTransfers;
@property (nonatomic, copy) NSString *xnumberofTripLegs;
@property (nonatomic, copy) NSString *xwalkingTime;
@property (nonatomic, copy) NSString *xtransitTime;
@property (nonatomic, retain) NSMutableArray<TripLeg *> *legs;
@property (nonatomic, retain) NSMutableArray<TripLegEndPoint*> *displayEndPoints;
@property (nonatomic, retain) NSMutableString *fare;
@property (nonatomic, retain) TripLegEndPoint *startPoint;
- (TripLeg*)getLeg:(int)item;
@property (nonatomic, readonly) NSInteger legCount;
@property (nonatomic, readonly, copy) NSString *travelTime;
@property (nonatomic, readonly, copy) NSString *shortTravelTime;
@property (nonatomic, readonly) bool hasFare;
- (NSString *)startPointText:(TripTextType)type;

@end

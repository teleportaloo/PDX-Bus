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
	NSString *_xdate;
	NSString *_xstartTime;
	NSString *_xendTime;
	NSString *_xduration;
	NSString *_xdistance;
	NSString *_xnumberOfTransfers;
	NSString *_xnumberofTripLegs;
	NSString *_xwalkingTime;
	NSString *_xtransitTime;
	NSString *_xwaitingTime;
	NSMutableString *_fare;
	NSMutableArray *_legs;
	NSMutableArray *_displayEndPoints;
	TripLegEndPoint *_startPoint;
	NSString *_xmessage;
	NSString *_travelTime;;
}

@property (nonatomic, retain) NSString		*xwaitingTime;
@property (nonatomic, retain) NSString		*xdate;
@property (nonatomic, retain) NSString		*xstartTime;
@property (nonatomic, retain) NSString		*xendTime;
@property (nonatomic, retain) NSString		*xduration;
@property (nonatomic, retain) NSString		*xdistance;
@property (nonatomic, retain) NSString		*xmessage;
@property (nonatomic, retain) NSString		*xnumberOfTransfers;
@property (nonatomic, retain) NSString		*xnumberofTripLegs;
@property (nonatomic, retain) NSString		*xwalkingTime;
@property (nonatomic, retain) NSString		*xtransitTime;
@property (nonatomic, retain) NSMutableArray *legs;
@property (nonatomic, retain) NSMutableArray *displayEndPoints;
@property (nonatomic, retain) NSMutableString *fare;
@property (nonatomic, retain) NSString *travelTime;
@property (nonatomic, retain) TripLegEndPoint *startPoint;

- (TripLeg*)getLeg:(int)item;
- (NSInteger)legCount;
- (NSString *)getTravelTime;
- (NSString *)getShortTravelTime;
- (bool)hasFare;
- (NSString *)startPointText:(TripTextType)type;


@end

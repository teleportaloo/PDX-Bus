//
//  TripItinerary.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TripLeg.h"
#import "TripEndPoint.h"
#import "TripLegEndPoint.h"

@interface TripItinerary : NSObject 

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
@property (nonatomic, strong) NSMutableArray<TripLeg *> *legs;
@property (nonatomic, strong) NSMutableArray<TripLegEndPoint*> *displayEndPoints;
@property (nonatomic, strong) NSMutableString *fare;
@property (nonatomic, strong) TripLegEndPoint *startPoint;
@property (nonatomic, readonly) NSInteger legCount;
@property (nonatomic, readonly, copy) NSString *travelTime;
@property (nonatomic, readonly, copy) NSString *shortTravelTime;
@property (nonatomic, readonly) bool hasFare;

- (TripLeg*)getLeg:(int)item;
- (NSString *)startPointText:(TripTextType)type;
- (bool)hasBlocks;

@end

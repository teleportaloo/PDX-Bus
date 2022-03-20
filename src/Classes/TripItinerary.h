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

@property (nonatomic, copy, setter = setXml_waitingTime:) NSString *strWaitingTimeMins;
@property (nonatomic, readonly) NSInteger waitingTimeMins;
@property (nonatomic, copy, setter = setXml_date:) NSString *startDateFormatted;
@property (nonatomic, copy, setter = setXml_startTime:) NSString *startTimeFormatted;
@property (nonatomic, copy,  setter = setXml_endTime:) NSString *endTimeFormatted;
@property (nonatomic, copy, setter = setXml_duration:) NSString *strDurationMins;
@property (nonatomic, readonly) NSInteger durationMins;
@property (nonatomic, copy, setter = setXml_distance:) NSString *strDistanceMiles;
@property (nonatomic, readonly) double distanceMiles;
@property (nonatomic, copy, setter = setXml_message:) NSString *message;
@property (nonatomic, copy, setter = setXml_numberOfTransfers:) NSString *strNumberOfTransfers;
@property (nonatomic, readonly) NSInteger numberOfTransfers;
@property (nonatomic, copy, setter = setXml_numberOfTripLegs:) NSString *strNumberOfTripLegs;
@property (nonatomic, readonly) NSInteger numberOfTripLegs;
@property (nonatomic, copy, setter = setXml_walkingTime:) NSString *strWalkingTimeMins;
@property (nonatomic, readonly) NSInteger walkingTimeMins;
@property (nonatomic, copy, setter = setXml_transitTime:) NSString *strTransitTimeMins;
@property (nonatomic, readonly) NSInteger transitTimeMins;


@property (nonatomic, strong) NSMutableArray<TripLeg *> *legs;
@property (nonatomic, strong) NSMutableArray<TripLegEndPoint *> *displayEndPoints;
@property (nonatomic, strong) NSMutableString *fare;
@property (nonatomic, strong) TripLegEndPoint *startPoint;
@property (nonatomic, readonly) NSInteger legCount;
@property (nonatomic, readonly, copy) NSString *travelTime;
@property (nonatomic, readonly, copy) NSString *shortTravelTime;
@property (nonatomic, readonly) bool hasFare;
@property (nonatomic, readonly) NSString *formattedDistance;

- (TripLeg *)getLeg:(int)item;
- (NSString *)startPointText:(TripTextType)type;
- (bool)hasBlocks;

@end

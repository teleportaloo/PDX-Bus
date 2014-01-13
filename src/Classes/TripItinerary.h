//
//  TripItinerary.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


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
- (int)legCount;
- (NSString *)getTravelTime;
- (NSString *)getShortTravelTime;
- (bool)hasFare;
- (NSString *)startPointText:(TripTextType)type;


@end

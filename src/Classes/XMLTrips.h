//
//  XMLTrips.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import "MapPinColor.h"
#import "ReturnStopId.h"

#import "ScreenConstants.h"
#import "TripLegEndPoint.h"
#import "TripLeg.h"
#import "TripEndPoint.h"
#import "TripUserRequest.h"
#import "TripItinerary.h"



@interface XMLTrips : TriMetXML

@property (nonatomic, strong) TripUserRequest *userRequest;
@property (nonatomic, strong) NSArray *userFaves;

@property (nonatomic, strong) TripLegEndPoint *resultFrom;
@property (nonatomic, strong) TripLegEndPoint *resultTo;

@property (nonatomic)         bool reversed;

@property (nonatomic, strong) NSString *xdate;
@property (nonatomic, strong) NSString *xtime;

@property (nonatomic, readonly, copy) NSString *shortName;
@property (nonatomic, readonly, copy) NSString *longName;
@property (nonatomic, readonly, copy) NSString *mediumName;

@property (nonatomic, strong) NSMutableArray *toList;
@property (nonatomic, strong) NSMutableArray *fromList;

@property (nonatomic)         bool toAppleFailed;
@property (nonatomic)         bool fromAppleFailed;

- (void)fetchItineraries:(NSData *)rawData;
- (XMLTrips *)createReverse;
- (XMLTrips *)createAuto;
- (void)saveTrip;
- (void)resetCurrentLocation;
- (void)addStopsFromUserFaves:(NSArray *)userFaves;
- (instancetype)init;
- (NSUserActivity *)userActivity;

+ (NSArray *)distanceMapSingleton;
+ (int)distanceToIndex:(float)distance;
+ (float)indexToDistance:(int)index;

@end

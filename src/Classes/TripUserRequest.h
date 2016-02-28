//
//  TripUserRequest.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TripEndPoint.h"
#import "TriMetTypes.h"


#define kDictUserRequestHistorical @"historical"

typedef enum {
	TripAskForTime,
	TripDepartAfterTime,
	TripArriveBeforeTime
} TripTimeChoice;


@interface TripUserRequest : NSObject
{
	TripEndPoint	*_fromPoint;
	TripEndPoint	*_toPoint;
	TripMode		_tripMode;
	TripMin			_tripMin;
	int				_maxItineraries;
	float			_walk;
	NSDate			*_dateAndTime;
	bool			_arrivalTime;
	TripTimeChoice  _timeChoice;
    bool            _takeMeHome;
    bool            _historical;
}

@property (nonatomic, retain) TripEndPoint	*fromPoint;
@property (nonatomic, retain) TripEndPoint	*toPoint;
@property (nonatomic)	      TripMode		tripMode;
@property (nonatomic)		  TripMin		tripMin;
@property (nonatomic)		  int			maxItineraries;
@property (nonatomic)		  float			walk;
@property (nonatomic)		  bool			arrivalTime;
@property (nonatomic, retain) NSDate		*dateAndTime;
@property (nonatomic)		  TripTimeChoice timeChoice;
@property (nonatomic)         bool          takeMeHome;
@property (nonatomic)         bool          historical;

- (NSString *)getMode;
- (NSString *)getMin;
- (NSString *)minToString;
- (NSString *)modeToString;

- (id)initFromDict:(NSDictionary *)dict;
- (id)init;

- (NSMutableDictionary *)toDictionary;
- (bool)fromDictionary:(NSDictionary *)dict;
- (bool)equalsTripUserRequest:(TripUserRequest*)userRequest;

- (NSString *)getTimeType;

- (NSString*)getDateAndTime;
- (NSString*)tripName;
- (NSString*)shortName;
- (NSString*)optionsAccessability;
- (NSString*)optionsDisplayText;
- (void)clearGpsNames;


@end


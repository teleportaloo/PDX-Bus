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


@interface TripUserRequest : DataFactory
{
	TripEndPoint *  _fromPoint;
	TripEndPoint *  _toPoint;
	TripMode		_tripMode;
	TripMin			_tripMin;
	int				_maxItineraries;
	float			_walk;
	NSDate *        _dateAndTime;
	bool			_arrivalTime;
	TripTimeChoice  _timeChoice;
    bool            _historical;
}

@property (nonatomic, retain) TripEndPoint *fromPoint;
@property (nonatomic, retain) TripEndPoint *toPoint;
@property (nonatomic)	      TripMode		tripMode;
@property (nonatomic)		  TripMin		tripMin;
@property (nonatomic)		  int			maxItineraries;
@property (nonatomic)		  float			walk;
@property (nonatomic)		  bool			arrivalTime;
@property (nonatomic, retain) NSDate *      dateAndTime;
@property (nonatomic)		  TripTimeChoice timeChoice;
@property (nonatomic)         bool          historical;

@property (nonatomic, getter=getMode, readonly, copy) NSString *mode;
@property (nonatomic, getter=getMin, readonly, copy) NSString *min;
@property (nonatomic, readonly, copy) NSString *minToString;
@property (nonatomic, readonly, copy) NSString *modeToString;

+ (instancetype)fromDictionary:(NSDictionary *)dict;
- (instancetype)init;

@property (nonatomic, readonly, copy) NSMutableDictionary *toDictionary;
- (bool)readDictionary:(NSDictionary *)dict;
- (bool)equalsTripUserRequest:(TripUserRequest*)userRequest;

@property (nonatomic, getter=getTimeType, readonly, copy) NSString *timeType;

- (NSString*)getDateAndTime;
@property (nonatomic, readonly, copy) NSString *tripName;
@property (nonatomic, readonly, copy) NSString *shortName;
@property (nonatomic, readonly, copy) NSString *optionsAccessability;
@property (nonatomic, readonly, copy) NSString *optionsDisplayText;
- (void)clearGpsNames;


@end


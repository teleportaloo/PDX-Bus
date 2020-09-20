//
//  TripUserRequest.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
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

@property (nonatomic, strong) TripEndPoint *fromPoint;
@property (nonatomic, strong) TripEndPoint *toPoint;
@property (nonatomic)          TripMode tripMode;
@property (nonatomic)          TripMin tripMin;
@property (nonatomic)          int maxItineraries;
@property (nonatomic)          float walk;
@property (nonatomic)          bool arrivalTime;
@property (nonatomic, strong)  NSDate *dateAndTime;
@property (nonatomic)          TripTimeChoice timeChoice;
@property (nonatomic)          bool historical;
@property (nonatomic, readonly, copy) NSString *mode;
@property (nonatomic, readonly, copy) NSString *min;
@property (nonatomic, readonly, copy) NSString *minToString;
@property (nonatomic, readonly, copy) NSString *modeToString;
@property (nonatomic, readonly, copy) NSMutableDictionary *toDictionary;
@property (nonatomic, readonly, copy) NSString *timeType;
@property (nonatomic, readonly, copy) NSString *tripName;
@property (nonatomic, readonly, copy) NSString *shortName;
@property (nonatomic, readonly, copy) NSString *optionsAccessability;
@property (nonatomic, readonly, copy) NSString *optionsDisplayText;

- (instancetype)init;
- (void)clearGpsNames;
- (bool)readDictionary:(NSDictionary *)dict;
- (bool)equalsTripUserRequest:(TripUserRequest *)userRequest;
- (NSString *)getDateAndTime;
- (NSUserActivity *)userActivityWithTitle:(NSString *)title;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

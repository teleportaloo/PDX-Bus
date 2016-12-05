//
//  TripUserRequest.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripUserRequest.h"
#import "UserPrefs.h"
#import "XMLTrips.h"

#define kDictUserRequestTripMode		@"tripMode"
#define kDictUserRequestTripMin			@"tripMin"
#define kDictUserRequestMaxItineraries	@"maxItineraries"
#define kDictUserRequestWalk			@"walk"
#define kDictUserRequestFromPoint		@"fromPoint"
#define kDictUserRequestToPoint			@"toPoint"
#define kDictUserRequestDateAndTime		@"dateAndTime"
#define kDictUserRequestArrivalTime		@"arrivalTime"
#define kDictUserRequestTimeChoice		@"timeChoice"


@implementation TripUserRequest

@synthesize fromPoint		= _fromPoint;
@synthesize toPoint			= _toPoint;
@synthesize tripMode		= _tripMode;
@synthesize tripMin			= _tripMin;
@synthesize maxItineraries	= _maxItineraries;
@synthesize walk			= _walk;
@synthesize dateAndTime		= _dateAndTime;
@synthesize arrivalTime		= _arrivalTime;
@synthesize timeChoice	    = _timeChoice;
@synthesize historical      = _historical;

- (void)dealloc {
	self.fromPoint = nil;
	self.toPoint   = nil;
	self.dateAndTime = nil;
	[super dealloc];
}

#pragma mark Data helpers

- (NSString *)getMode
{
	switch (self.tripMode)
	{
		case TripModeBusOnly:
			return @"Bus only";
		case TripModeTrainOnly:
			return @"Train only";
		case TripModeAll:
			return @"Bus or train";
        default:
            break;
			
	}
	return @"";
}

- (NSString *)getMin
{
	switch (self.tripMin)
	{
		case TripMinQuickestTrip:
			return @"Quickest trip";
		case TripMinShortestWalk:
			return @"Shortest walk";
		case TripMinFewestTransfers:
			return @"Fewest transfers";
	}
	return @"T";
	
}

- (NSString *)minToString
{
	switch (self.tripMin)
	{
		case TripMinQuickestTrip:
			return @"T";
		case TripMinShortestWalk:
			return @"W";
		case TripMinFewestTransfers:
			return @"X";
	}
	return @"T";
	
}


- (NSString *)modeToString
{
	switch (self.tripMode)
	{
		case TripModeBusOnly:
			return @"B";
		case TripModeTrainOnly:
			return @"T";
        default:
		case TripModeAll:
			return @"A";
	}
	return @"A";
	
}

- (NSMutableDictionary *)toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	if (self.fromPoint)
	{
		dict[kDictUserRequestFromPoint] = self.fromPoint.toDictionary;
	}
	
	if (self.toPoint)
	{
		dict[kDictUserRequestToPoint] = self.toPoint.toDictionary;
	}
	
	dict[kDictUserRequestTripMode]       = @(self.tripMode);
	dict[kDictUserRequestTripMin]        = @(self.tripMin);
	dict[kDictUserRequestMaxItineraries] = @(self.maxItineraries);
	dict[kDictUserRequestWalk]           = @(self.walk);
	
	if (self.dateAndTime)
	{
		dict[kDictUserRequestArrivalTime] = @(self.arrivalTime);
		dict[kDictUserRequestDateAndTime] = self.dateAndTime;
	}
    
	dict[kDictUserRequestTimeChoice] = @(self.timeChoice);
	
	return dict;
}

- (instancetype) init
{
	if ((self = [super init]))
	{
		self.walk =             [UserPrefs singleton].maxWalkingDistance;
		self.tripMode =         [UserPrefs singleton].travelBy;
		self.tripMin =          [UserPrefs singleton].tripMin;
		self.maxItineraries =   6;
        self.toPoint =          [TripEndPoint data];
        self.fromPoint =        [TripEndPoint data];
	}
	return self;
}

+ (instancetype)fromDictionary:(NSDictionary *)dict
{
    id item = [[[[self class] alloc] init] autorelease];
    if (dict!=nil && [item readDictionary:dict])
    {
        return item;
    }
    return nil;
}

- (NSNumber *)forceNSNumber:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSNumber class]])
	{
		return (NSNumber*)obj;
	}
	return nil;
	
}


- (NSString *)forceNSString:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSString class]])
	{
		return (NSString*)obj;
	}
	return nil;
	
}

- (NSDictionary *)forceNSDictionary:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSDictionary class]])
	{
		return (NSDictionary*)obj;
	}
	return nil;
	
}

- (NSDate *)forceNSDate:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSDate class]])
	{
		return(NSDate*)obj;
	}
	return nil;
	
}


- (bool)readDictionary:(NSDictionary *)dict
{
	self.fromPoint = [TripEndPoint fromDictionary:[self forceNSDictionary:dict[kDictUserRequestFromPoint]]];
    self.toPoint   = [TripEndPoint fromDictionary:[self forceNSDictionary:dict[kDictUserRequestToPoint  ]]];
	
	NSNumber *tripMode = [self forceNSNumber:dict[kDictUserRequestTripMode]];
	
	self.tripMode = tripMode	? tripMode.intValue
                                : [UserPrefs singleton].travelBy;
    
    
	
	NSNumber *tripMin = [self forceNSNumber:dict[kDictUserRequestTripMin]];
	self.tripMin = tripMin	? tripMin.intValue
                            : [UserPrefs singleton].tripMin;
	
	NSNumber *maxItineraries = [self forceNSNumber:dict[kDictUserRequestMaxItineraries]];
	self.maxItineraries =  maxItineraries ? maxItineraries.intValue
                                          : 6;
	
	NSNumber *walk = [self forceNSNumber:dict[kDictUserRequestWalk]];
	self.walk = walk	? walk.floatValue
                        : [UserPrefs singleton].maxWalkingDistance;
    
	
	NSNumber *arrivalTime = [self forceNSNumber:dict[kDictUserRequestArrivalTime]];
	self.arrivalTime = arrivalTime	? arrivalTime.boolValue
                                    : false;
	
	
	NSNumber *timeChoice  = [self forceNSNumber:dict[kDictUserRequestTimeChoice]];
	if (timeChoice)
	{
		self.timeChoice = timeChoice.intValue;
	}
	
	self.dateAndTime = [self forceNSDate:dict[kDictUserRequestDateAndTime]];
    
    if (dict[kDictUserRequestHistorical])
    {
        self.historical = YES;
    }
    
	
	return YES;
}

- (NSString *)getTimeType
{
	if (self.dateAndTime == nil)
	{
		return (self.arrivalTime ? @"Arrive" : @"Depart");
	}
	return (self.arrivalTime ? @"Arrive by" : @"Depart after");;
}

- (NSString*)getDateAndTime
{
	if (self.dateAndTime == nil)
	{
		return @"Now";
	}

    return [NSDateFormatter localizedStringFromDate:self.dateAndTime
                                          dateStyle:NSDateFormatterShortStyle
                                          timeStyle:NSDateFormatterShortStyle];
}

- (NSString *)tripName
{
	return [NSString stringWithFormat:@"From: %@\nTo: %@",
            self.fromPoint.locationDesc==nil ? kAcquiredLocation : self.fromPoint.locationDesc,
            self.toPoint.locationDesc==nil ? kAcquiredLocation : self.toPoint.locationDesc];
    
	
	
}

- (NSString*)shortName
{
	NSString *title = nil;
	
	if (self.toPoint.locationDesc !=nil && !self.toPoint.useCurrentLocation)
	{
		title = [NSString stringWithFormat:@"To %@", self.toPoint.locationDesc];
	}
	else if (self.fromPoint.locationDesc !=nil)
	{
		if (self.fromPoint.useCurrentLocation)
		{
			title = [NSString stringWithFormat:@"From %@", kAcquiredLocation];
		}
		else
		{
			title = [NSString stringWithFormat:@"From %@", self.fromPoint.locationDesc];
		}
	}
	
	return title;
	
}

- (NSString *)optionsAccessability
{
    NSString *walk =
    [XMLTrips distanceMapSingleton][[XMLTrips distanceToIndex:self.walk]];
    
	return [NSString stringWithFormat:@"Options, Maximum walking distance %@ miles, Travel by %@, Show the %@",
			walk, [self getMode], [self getMin]];
	
}

- (NSString*)optionsDisplayText
{
    NSString *walk =
    [XMLTrips distanceMapSingleton][[XMLTrips distanceToIndex:self.walk]];
    
	return [NSString stringWithFormat:@"Max walk: %@ miles\nTravel by: %@\nShow the: %@", walk,
			[self getMode], [self getMin]];
}





- (bool)equalsTripUserRequest:(TripUserRequest *)userRequest
{
	return [self.fromPoint equalsTripEndPoint:userRequest.fromPoint]
    && [self.toPoint   equalsTripEndPoint:userRequest.toPoint]
    && self.tripMode  == userRequest.tripMode
    && self.tripMin   == userRequest.tripMin
    && self.maxItineraries == userRequest.maxItineraries
    && self.walk		== userRequest.walk
    && self.timeChoice  == userRequest.timeChoice;
}

- (void)clearGpsNames
{
    if (self.fromPoint.useCurrentLocation)
    {
        self.fromPoint.locationDesc = nil;
    }
    if (self.toPoint.useCurrentLocation)
    {
        self.toPoint.locationDesc = nil;
    }
}


@end

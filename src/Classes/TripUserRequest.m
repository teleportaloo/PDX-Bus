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
@synthesize takeMeHome      = _takeMeHome;

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
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	if (self.fromPoint)
	{
		[dict setObject:[self.fromPoint toDictionary]
				 forKey:kDictUserRequestFromPoint];
	}
	
	if (self.toPoint)
	{
		[dict setObject:[self.toPoint toDictionary]
				 forKey:kDictUserRequestToPoint];
	}
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.tripMode] autorelease]
			 forKey:kDictUserRequestTripMode];
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.tripMin] autorelease]
			 forKey:kDictUserRequestTripMin];
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.maxItineraries] autorelease]
			 forKey:kDictUserRequestMaxItineraries];
	
	[dict setObject:[[[NSNumber alloc] initWithFloat:self.walk] autorelease]
			 forKey:kDictUserRequestWalk];
	
	if (self.dateAndTime)
	{
		[dict setObject:[[[NSNumber alloc] initWithBool:self.arrivalTime] autorelease]
                 forKey:kDictUserRequestArrivalTime];
        
		[dict setObject:self.dateAndTime
                 forKey:kDictUserRequestDateAndTime];
	}
	
	[dict setObject:[[[NSNumber alloc] initWithFloat:self.timeChoice] autorelease]
			 forKey:kDictUserRequestTimeChoice];
	
	
	return dict;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.walk =             [UserPrefs getSingleton].maxWalkingDistance;
		self.tripMode =         [UserPrefs getSingleton].travelBy;
		self.tripMin =          [UserPrefs getSingleton].tripMin;
		self.maxItineraries =   6;
		self.toPoint =          [[[TripEndPoint alloc] init] autorelease];
		self.fromPoint =        [[[TripEndPoint alloc] init] autorelease];
	}
	return self;
}

- (id)initFromDict:(NSDictionary *)dict
{
	if ((self = [super init]))
	{
		[self fromDictionary:dict];
	}
	return self;
	
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


- (bool)fromDictionary:(NSDictionary *)dict
{
	self.fromPoint = [[[TripEndPoint alloc] initFromDict:[self forceNSDictionary:[dict objectForKey:kDictUserRequestFromPoint]]] autorelease];
	self.toPoint   = [[[TripEndPoint alloc] initFromDict:[self forceNSDictionary:[dict objectForKey:kDictUserRequestToPoint  ]]] autorelease];
	
	NSNumber *tripMode = [self forceNSNumber:[dict objectForKey:kDictUserRequestTripMode]];
	
	self.tripMode = tripMode	? [tripMode intValue]
    : [UserPrefs getSingleton].travelBy;
    
    
	
	NSNumber *tripMin = [self forceNSNumber:[dict objectForKey:kDictUserRequestTripMin]];
	self.tripMin = tripMin	? [tripMin intValue]
    : [UserPrefs getSingleton].tripMin;
	
	NSNumber *maxItineraries = [self forceNSNumber:[dict objectForKey:kDictUserRequestMaxItineraries]];
	self.maxItineraries =  maxItineraries ? [maxItineraries intValue]
    : 6;
	
	NSNumber *walk = [self forceNSNumber:[dict objectForKey:kDictUserRequestWalk]];
	self.walk = walk	? [walk floatValue]
    : [UserPrefs getSingleton].maxWalkingDistance;
    
	
	NSNumber *arrivalTime = [self forceNSNumber:[dict objectForKey:kDictUserRequestArrivalTime]];
	self.arrivalTime = arrivalTime	? [arrivalTime boolValue]
    : false;
	
	
	NSNumber *timeChoice  = [self forceNSNumber:[dict objectForKey:kDictUserRequestTimeChoice]];
	if (timeChoice)
	{
		self.timeChoice = [timeChoice intValue];
	}
	
	self.dateAndTime = [self forceNSDate:[dict objectForKey:kDictUserRequestDateAndTime]];
    
	
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
    
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	// [dateFormatter setDateFormat:@"MM-dd-yy"];
	
	[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
	[dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
	// NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	// [timeFormatter setDateFormat:@"hh:mm'%20'aa"];
	
	
	return [NSString stringWithFormat:@"%@",
			[dateFormatter stringFromDate:self.dateAndTime]];
	
	
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
    [[XMLTrips distanceMapSingleton] objectAtIndex:
     [XMLTrips distanceToIndex:self.walk]];
    
	return [NSString stringWithFormat:@"Options, Maximum walking distance %@ miles, Travel by %@, Show the %@",
			walk, [self getMode], [self getMin]];
	
}

- (NSString*)optionsDisplayText
{
    NSString *walk =
    [[XMLTrips distanceMapSingleton] objectAtIndex:
     [XMLTrips distanceToIndex:self.walk]];
    
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

//
//  TripItinerary.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripItinerary.h"

@implementation TripItinerary

@synthesize xdate				= _xdate;
@synthesize xstartTime			= _xstartTime;
@synthesize xendTime			= _xendTime;
@synthesize xduration			= _xduration;
@synthesize xdistance			= _xdistance;
@synthesize xmessage			= _xmessage;
@synthesize xnumberOfTransfers	= _xnumberOfTransfers;
@synthesize xnumberofTripLegs	= _xnumberofTripLegs;
@synthesize xwalkingTime		= _xwalkingTime;
@synthesize xtransitTime		= _xtransitTime;
@synthesize xwaitingTime		= _xwaitingTime;
@synthesize legs				= _legs;
@synthesize displayEndPoints    = _displayEndPoints;
@synthesize fare			    = _fare;
@synthesize travelTime          = _travelTime;
@synthesize startPoint			= _startPoint;

- (void)dealloc {
	self.xdate					= nil;
	self.xstartTime				= nil;
	self.xendTime				= nil;
	self.xduration				= nil;
	self.xdistance				= nil;
	self.xwalkingTime			= nil;
	self.xtransitTime			= nil;
	self.xwaitingTime			= nil;
	self.xnumberOfTransfers		= nil;
	self.xnumberofTripLegs		= nil;
	self.legs					= nil;
	self.xmessage				= nil;
	self.fare					= nil;
	self.travelTime				= nil;
	self.xnumberOfTransfers     = nil;
	self.xnumberofTripLegs      = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.legs = [[[ NSMutableArray alloc ] init] autorelease];
		
		
	}
	return self;
}

- (bool)hasFare
{
	return self.fare != nil && [self.fare length]!=0;
}

- (TripLeg*) getLeg:(int)item
{
	return [self.legs objectAtIndex:item];
}

- (NSString *)getShortTravelTime
{
	
	NSMutableString *strTime = [[[NSMutableString alloc] init] autorelease];
	int t = [self.xduration intValue];
	int h = t/60;
	int m = t%60;
    
	[strTime appendFormat:@"Travel time: %d:%02d", h, m];
	return strTime;
}


- (NSString *)mins:(int)t
{
	if (t==1)
	{
		return @"1 min";
	}
	return [NSString stringWithFormat:@"%d mins", t];
}

- (NSString *)getTravelTime
{
	if (self.travelTime == nil)
	{
		NSMutableString *strTime = [[[NSMutableString alloc] init] autorelease];
		int t = [self.xduration intValue];
		
		[strTime appendString:[self mins:t]];
		
        
		bool inc = false;
		
		if (self.xwalkingTime != nil)
		{
			int walking = [self.xwalkingTime intValue];
            
			if (walking > 0)
			{
				[strTime appendFormat: @", including %@ walking", [self mins:walking]];
				inc = true;
			}
		}
		
		if (self.xwaitingTime !=nil)
		{
			int waiting = [self.xwaitingTime intValue];
            
			if (waiting > 0)
			{
				if (!inc)
				{
					[strTime appendFormat: @", including %@ waiting", [self mins:waiting]];
				}
				else
				{
					[strTime appendFormat: @" and %@ waiting", [self mins:waiting]];
				}
			}
		}
        
		[strTime appendString: @"."];
        
		
		self.travelTime = strTime;
	}
	return self.travelTime;
	
}

- (NSInteger)legCount
{
	if (self.legs)
	{
		return [self.legs count];
	}
	return 0;
}

- (NSString *)startPointText:(TripTextType)type
{
	NSMutableString * text  = [[ NSMutableString alloc] init];
	
	TripLeg * firstLeg = nil;
	TripLegEndPoint * firstPoint = nil;
	
	if ([self.legs count] > 0)
	{
		firstLeg = [self.legs objectAtIndex:0];
		firstPoint = [firstLeg from];
	}
	else
	{
		[text release];
		return nil;
	}
	
	if (self.startPoint == nil)
	{
		self.startPoint = [[firstPoint copy] autorelease];
	}
	
	if (firstPoint!=nil && type != TripTextTypeMap)
	{
		bool nearTo = [firstPoint.xdescription hasPrefix:kNearTo];
		
		if (type == TripTextTypeUI)
		{
			self.startPoint.displayModeText = @"Start";
			[text appendFormat:@"%@%@", nearTo ? @"" : @"Start at ", firstPoint.xdescription];
		}
		else if (type == TripTextTypeHTML && firstPoint.xlon!=nil)
		{
			[text appendFormat:@"%@<a href=\"http://map.google.com/?q=location@%@,%@\">%@</a>",
             nearTo ? @"Start " : @"Start at ",
             firstPoint.xlat, firstPoint.xlon,  firstPoint.xdescription];
		}
		else
		{
			[text appendFormat:@"%@%@", nearTo ? @"Starting " : @"Starting at ",firstPoint.xdescription];
		}
	}
	
	if (self.startPoint.xstopId !=nil)
	{
		if (type == TripTextTypeHTML)
		{
			[text appendFormat:@" (ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
			 [self.startPoint.xdescription	stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
			 [self.startPoint stopId], [firstPoint stopId]];
		}
		else
		{
			[text appendFormat:@" (ID %@)", [self.startPoint stopId]];
		}
	}
	
	
	switch (type)
	{
		case TripTextTypeHTML:
			[text appendFormat:				@"<br><br>"];
			break;
		case TripTextTypeMap:
			if ([text length] != 0)
			{
				self.startPoint.mapText = text;
			}
			break;
		case TripTextTypeClip:
			[text appendFormat:				@"\n"];
        case TripTextTypeUI:
			self.startPoint.displayText = text;
			break;
	}
	[text autorelease];
	return text;
}

@end



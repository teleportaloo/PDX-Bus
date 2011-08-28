//
//  XMLLocateStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/13/10.
//  Copyright 2010. All rights reserved.
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


#import "XMLLocateStops.h"
#import "RouteDistance.h"


@implementation XMLLocateStops

@synthesize currentStop = _currentStop;
@synthesize location    = _location;
@synthesize mode = _mode;
@synthesize maxToFind = _maxToFind;
@synthesize minDistance = _minDistance;
@synthesize routes = _routes;


- (void)dealloc
{
	self.currentStop = nil;	
	self.location = nil;
	self.routes = nil;
	[super dealloc];
}

#pragma mark Error check 

- (bool)displayErrorIfNoneFound
{
	NSThread *thread = [NSThread currentThread]; 
	
	if ([self safeItemCount] == 0 && ![self gotData])
	{
		
		if (![thread isCancelled]) 
		{
			[thread cancel];
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
															   message:@"Network problem: please try again later."
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil] autorelease];
			[alert show];
			return true;
		}	
		
	}
	else if ([self safeItemCount] == 0)
	{
		if (![thread isCancelled]) 
		{
			[thread cancel];
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
															   message:[NSString stringWithFormat:@"No stops were found within %0.1f miles",
																		self.minDistance / 1609.344]
								   
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil] autorelease];
			[alert show];
			return true;
		}
	}
	
	return false;
	
}

#pragma mark Data fetchers


- (BOOL)findNearestStops
{
	NSString *query = [NSString stringWithFormat:@"stops/ll/%f,%f%@%@",
					   self.location.coordinate.longitude, self.location.coordinate.latitude,  
					   (self.minDistance > 0.0 ? [NSString stringWithFormat:@"/meters/%f", self.minDistance] : @""), 
					   (self.mode!=TripModeAll ? @"/showRoutes/true": @"")];
	
	NSError *error = nil;
	
					   
	bool res =  [self startParsing:query parseError:&error cacheAction:TriMetXMLNoCaching];
	
	if (hasData)
	{
		[_itemArray sortUsingSelector:@selector(compareUsingDistance:)];
	}
	
	return res;
}


- (BOOL)findNearestRoutes
{
	NSString *query = [NSString stringWithFormat:@"stops/ll/%f,%f%@%@",
					   self.location.coordinate.longitude, self.location.coordinate.latitude,  
					   (self.minDistance > 0.0 ? [NSString stringWithFormat:@"/meters/%f", self.minDistance] : @""), 
					   @"/showRoutes/true"];
	
	NSError *error = nil;
	self.routes = [[[NSMutableDictionary alloc] init] autorelease];
	
	
	bool res =  [self startParsing:query parseError:&error cacheAction:TriMetXMLNoCaching];
	
	if (hasData)
	{
		// We don't care about the stops stored in the array! We ditch 'em and replace with 
		// a sorted routes kinda thing.
		
		self.itemArray = [[NSMutableArray alloc] init];
		
		[_itemArray addObjectsFromArray:[self.routes allValues]];
		
		// We are done with this dictionary now may as well deference it.
		self.routes = nil;
		
		for (RouteDistance *rd in self.itemArray)
		{
			[rd sortStopsByDistance]; 
			
			// Truncate array - this can get far too big
			while (rd.stops.count > self.maxToFind)
			{
				[rd.stops removeLastObject];
			}
		}
		
		[_itemArray sortUsingSelector:@selector(compareUsingDistance:)];
	}
	
	return res;
}


#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (bool)modeMatch:(TripMode)first second:(TripMode)second
{
	if (first == second)
	{
		return true;
	}
	
	if (first == TripModeAll || second == TripModeAll)
	{
		return true;	
	}
		
	return false;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"resultSet"]) {
		
		[self initArray];
		hasData = YES;
	}
	
    if ([elementName isEqualToString:@"location"]) {
        self.currentStop = [[[StopDistance alloc] init] autorelease];
		_currentMode = TripModeNone;
		
		self.currentStop.locid = [self safeValueFromDict:attributeDict valueForKey:@"locid"];
		self.currentStop.desc  = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
		
		self.currentStop.location = [[[CLLocation alloc] initWithLatitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lat"] 
															   longitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lng"] ] autorelease];
		
#ifdef __IPHONE_3_2
		if ([self.location respondsToSelector:@selector(distanceFromLocation:)])
		{
			self.currentStop.distance = [self.location distanceFromLocation:self.currentStop.location];
		}
		else
#endif
		{
			// Cast avoids pragma warning
			self.currentStop.distance = [(id)self.location getDistanceFrom:self.currentStop.location];
		}
		
    }
	
	if ([elementName isEqualToString:@"route"])
	{
		NSString *type = [self safeValueFromDict:attributeDict valueForKey:@"type"];
		
		switch ([type characterAtIndex:0])
		{
			case 'R':
			case 'r':
				_currentMode = TripModeTrainOnly;
				break;
			case 'B':
			case 'b':
				_currentMode = TripModeBusOnly;
				break;
			default:
				_currentMode = TripModeAll;
				break;
		}
		if (self.routes != nil && [self modeMatch:_currentMode second:_mode])
		{
			NSString *xmlRoute = [self safeValueFromDict:attributeDict valueForKey:@"route"];
			
			RouteDistance *rd = [self.routes objectForKey:xmlRoute];
			
			if (rd == nil)
			{
				NSString *desc = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
				
				rd = [[[RouteDistance alloc] init] autorelease];
				
				rd.desc = desc;
				rd.type = type;
				rd.route = xmlRoute;
				
				[self.routes setObject:rd forKey:xmlRoute];
			}
			
			[rd.stops addObject:self.currentStop];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"location"]) {
		if ([self modeMatch:_currentMode second:_mode])
		{
			[self addItem:self.currentStop];
		}
		self.currentStop = nil; 
	}
}


@end

//
//  XMLStreetcarLocations.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/23/10.
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

#import "XMLStreetcarLocations.h"


@implementation XMLPosition

@synthesize lat;
@synthesize lng;

- (void)dealloc
{
	self.lat = nil;
	self.lng = nil;
	[super dealloc];
}

@end


@implementation XMLStreetcarLocations

@synthesize locations = _locations;

static  XMLStreetcarLocations *singleLocations = nil;

- (void)dealloc
{
	self.locations = nil;
	[super dealloc];
}

#pragma mark Singleton

+ (XMLStreetcarLocations *)getSingleton
{
	if (singleLocations == nil)
	{
		singleLocations = [[XMLStreetcarLocations alloc] init];
	}
	
	return [[singleLocations retain] autorelease];
}

#pragma mark Initiate Parsing

- (BOOL)getLocations:(NSError **)error
{
	hasData = false;
	[self startParsing:[NSString stringWithFormat:@"vehicleLocations&a=portland-sc&r=streetcar&t=%qu", _lastTime] parseError:error];
	return true;	
}

#pragma mark Parser Callbacks

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
	
    if (qName) {
        elementName = qName;
    }
	if ([elementName isEqualToString:@"body"])
	{
		if (self.locations == nil)
		{
			self.locations = [[[NSMutableDictionary alloc] init] autorelease];
		}
		hasData = true;
	}
	
    if ([elementName isEqualToString:@"vehicle"]) {
		
		NSString *id = [self safeValueFromDict:attributeDict valueForKey:@"id"];
		
		XMLPosition *pos = [[ XMLPosition alloc ] init];
		
		pos.lng = [self safeValueFromDict:attributeDict valueForKey:@"lon"];
		pos.lat = [self safeValueFromDict:attributeDict valueForKey:@"lat"];
		
		[self.locations setObject:pos forKey:id];
		
		[pos release];
	
	}
	
	if ([elementName isEqualToString:@"lastTime"])
	{
		_lastTime = [self getTimeFromAttribute:attributeDict valueForKey:@"time"];
	}
}

#pragma mark Access location data

-(void)insertLocation:(Departure *)dep
{
	XMLPosition *pos = [self.locations objectForKey:dep.block];
	
	if (pos !=nil)
	{
		dep.blockPositionLat = pos.lat;
		dep.blockPositionLng = pos.lng;
		
		CLLocation *carLocation  = [[CLLocation alloc] initWithLatitude:[pos.lat doubleValue] longitude:[pos.lng doubleValue]];
		CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[dep.stopLat doubleValue] longitude:[dep.stopLng doubleValue]];
		
		// This allows this to run on a 3.0 iPhone but makes the warning go away
#ifdef __IPHONE_3_2
		if ([stopLocation respondsToSelector:@selector(distanceFromLocation:)])
		{
			dep.blockPositionFeet = [stopLocation distanceFromLocation:carLocation] / 3.2808399; // convert meters to feet
		}
		else
#endif
		{
			dep.blockPositionFeet = [(id)stopLocation getDistanceFrom:carLocation] / 3.2808399; // convert meters to feet
		}
		
		[carLocation release];
		[stopLocation release];

		dep.blockPositionAt = _lastTime;
	}
}

@end

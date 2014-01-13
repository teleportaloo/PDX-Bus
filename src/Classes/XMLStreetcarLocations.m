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
#import "XMLDepartures.h"
#import "Vehicle.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"

@implementation XMLStreetcarLocations

@synthesize locations = _locations;
@synthesize route = _route;

static NSMutableDictionary *singleLocationsPerLine = nil;

- (void)dealloc
{
	self.locations = nil;
    self.route = nil;
    
    [_trimetRoute release];
    [_directionDict release];
	[super dealloc];
}

- (id)initWithRoute:(NSString *)route
{
    if (self = [super init])
    {
        TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate getSingleton];
        self.route = route;
        
        _trimetRoute = [[app getStreetcarRoutes] objectForKey:route];
        _directionDict = [app getStreetcarDirections];
        
    }
    return self;
}

#pragma mark Singleton

+ (XMLStreetcarLocations *)getSingletonForRoute:(NSString *)route
{
	if (singleLocationsPerLine == nil)
	{
        singleLocationsPerLine = [[NSMutableDictionary alloc] init];
    }
    
    XMLStreetcarLocations *singleLocations = [singleLocationsPerLine objectForKey:route];
    
    if (singleLocations == nil)
    {
		singleLocations = [[[XMLStreetcarLocations alloc] initWithRoute:route] autorelease];
        
        [singleLocationsPerLine setObject:singleLocations forKey:route];
	}
	
	return [[singleLocations retain] autorelease];
}

+ (NSSet *)getStreetcarRoutesInDepartureArray:(NSArray *)deps
{
    NSMutableSet *routes = [[[NSMutableSet alloc] init] autorelease];
    for (XMLDepartures *dep in deps)
    {
        for (Departure *dd in dep.itemArray)
		{
			if (dd.streetcar)
			{
				[routes addObject:dd.nextBusRouteId];
			}
		}
    }
    
    return routes;
}
+ (void)insertLocationsIntoDepartureArray:(NSArray *)deps forRoutes:(NSSet *)routes
{
    for (NSString *route in routes)
    {
        XMLStreetcarLocations *locs = [XMLStreetcarLocations getSingletonForRoute:route];
        for (XMLDepartures *dep in deps)
        {
            for (Departure *dd in dep.itemArray)
            {
                if (dd.streetcar && [dd.nextBusRouteId isEqualToString:route])
                {
                    [locs insertLocation:dd];
                }
            }
        }
    }
}

#pragma mark Initiate Parsing

- (BOOL)getLocations:(NSError **)error
{
	hasData = false;
	[self startParsing:[NSString stringWithFormat:@"vehicleLocations&a=portland-sc&r=%@&t=%qu", self.route, _lastTime] parseError:error];
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
    
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
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
		
		NSString *block = [self safeValueFromDict:attributeDict valueForKey:@"id"];
		
		Vehicle *pos = [[ Vehicle alloc ] init];
		
        pos.location = [[[CLLocation alloc] initWithLatitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lat"]
                                                   longitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lon"]] autorelease];
		
        pos.type = kVehicleTypeStreetcar;
        
        pos.block = block;
        pos.routeNumber = _trimetRoute;
        pos.locationTime = UnixToTriMetTime([[NSDate date] timeIntervalSince1970] + [self getTimeFromAttribute:attributeDict valueForKey:@"secsSinceReport"]);
        
        pos.direction = [_directionDict objectForKey:[self safeValueFromDict:attributeDict valueForKey:@"dirTag"]];
        
		[self.locations setObject:pos forKey:block];
		
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
	Vehicle *pos = [self.locations objectForKey:dep.block];
	
	if (pos !=nil)
	{
		dep.blockPositionLat = [NSString stringWithFormat:@"%f", pos.location.coordinate.latitude];
		dep.blockPositionLng = [NSString stringWithFormat:@"%f", pos.location.coordinate.longitude];
		
		CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[dep.stopLat doubleValue] longitude:[dep.stopLng doubleValue]];
		
		// This allows this to run on a 3.0 iPhone but makes the warning go away
#ifdef __IPHONE_3_2
		if ([stopLocation respondsToSelector:@selector(distanceFromLocation:)])
		{
			dep.blockPositionFeet = [stopLocation distanceFromLocation:pos.location] / 3.2808399; // convert meters to feet
		}
		else
#endif
		{
			dep.blockPositionFeet = [(id)stopLocation getDistanceFrom:pos.location] / 3.2808399; // convert meters to feet
		}
		
		[stopLocation release];

		dep.blockPositionAt = _lastTime;
	}
}

@end

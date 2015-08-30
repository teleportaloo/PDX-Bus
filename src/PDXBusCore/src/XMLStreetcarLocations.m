//
//  XMLStreetcarLocations.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/23/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStreetcarLocations.h"
#import "XMLDepartures.h"
#import "VehicleData.h"
#import "DebugLogging.h"

@implementation XMLStreetcarLocations

@synthesize locations = _locations;
@synthesize route = _route;

static NSMutableDictionary *singleLocationsPerLine = nil;

- (void)dealloc
{
	self.locations = nil;
    self.route = nil;
    
	[super dealloc];
}

- (id)initWithRoute:(NSString *)route
{
    if (self = [super init])
    {
        self.route = route;
        
        [MemoryCaches addCache:self];
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
        for (DepartureData *dd in dep.itemArray)
		{
			if (dd.streetcar)
			{
				[routes addObject:dd.route];
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
            for (DepartureData *dd in dep.itemArray)
            {
                if (dd.streetcar && [dd.route isEqualToString:route])
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
		
		NSString *strretcarId = [self safeValueFromDict:attributeDict valueForKey:@"id"];
		
		VehicleData *pos = [[ VehicleData alloc ] init];
		
        pos.location = [[[CLLocation alloc] initWithLatitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lat"]
                                                   longitude:[self getCoordFromAttribute:attributeDict valueForKey:@"lon"]] autorelease];
		
        pos.type = kVehicleTypeStreetcar;
        
        pos.block = strretcarId;
        pos.routeNumber = self.route;
        pos.locationTime = UnixToTriMetTime([[NSDate date] timeIntervalSince1970] + [self getTimeFromAttribute:attributeDict valueForKey:@"secsSinceReport"]);
        
        pos.direction = nil;
        
		[self.locations setObject:pos forKey:strretcarId];
		
		[pos release];
	
	}
	
	if ([elementName isEqualToString:@"lastTime"])
	{
		_lastTime = [self getTimeFromAttribute:attributeDict valueForKey:@"time"];
	}
}

#pragma mark Access location data

-(void)insertLocation:(DepartureData *)dep
{
	VehicleData *pos = [self.locations objectForKey:dep.streetcarId];
	
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

- (void)memoryWarning
{
    DEBUG_LOG(@"Clearing streetcar location cache %p\n", self.locations);
    self.locations = nil;
    _lastTime = 0;
}

@end

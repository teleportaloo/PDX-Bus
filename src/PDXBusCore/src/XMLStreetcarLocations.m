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
#import "FormatDistance.h"

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

- (instancetype)initWithRoute:(NSString *)route
{
    if (self = [super init])
    {
        self.route = route;
        
        [MemoryCaches addCache:self];
    }
    return self;
}

#pragma mark Singleton

+ (XMLStreetcarLocations *)autoSingletonForRoute:(NSString *)route
{
    @synchronized (self) {

        if (singleLocationsPerLine == nil)
        {
            singleLocationsPerLine = [[NSMutableDictionary alloc] init];
        }
    
        XMLStreetcarLocations *singleLocations = singleLocationsPerLine[route];
    
        if (singleLocations == nil)
        {
            singleLocations = [[[XMLStreetcarLocations alloc] initWithRoute:route] autorelease];
        
            singleLocationsPerLine[route] = singleLocations;
        }
	
        return [[singleLocations retain] autorelease];
    }
}

+ (NSSet *)getStreetcarRoutesInDepartureArray:(NSArray *)deps
{
    NSMutableSet *routes = [NSMutableSet set];
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
        XMLStreetcarLocations *locs = [XMLStreetcarLocations autoSingletonForRoute:route];
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

- (BOOL)getLocations
{
	_hasData = false;
	[self startParsing:[NSString stringWithFormat:@"vehicleLocations&a=portland-sc&r=%@&t=%qu", self.route, _lastTime]];
	return true;	
}

#pragma mark Parser Callbacks


START_ELEMENT(body)
{
    if (self.locations == nil)
    {
        self.locations = [NSMutableDictionary dictionary];
    }
    _hasData = true;
}

START_ELEMENT(vehicle)
{
    NSString *streetcarId = ATRVAL(id);
    
    VehicleData *pos = [VehicleData alloc].init;
    
    pos.location = [[[CLLocation alloc] initWithLatitude:ATRCOORD(lat)
                                               longitude:ATRCOORD(lon)] autorelease];
    
    pos.type = kVehicleTypeStreetcar;
    pos.block = streetcarId;
    pos.routeNumber = self.route;
    NSInteger secs = ATRINT(secsSinceReport);
    
    // Weird issue - just reversing the sign is something to do with the weird data.
    if (secs < 0)
    {
        secs = -secs;
    }
    
    pos.locationTime = UnixToTriMetTime([[NSDate date] timeIntervalSince1970] - secs);
    pos.bearing = ATRVAL(heading);
    
    NSString *dirTag = ATRVAL(dirTag);
    
    NSScanner *scanner = [NSScanner scannerWithString:dirTag];
    NSCharacterSet *underscore = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    NSString *aLoc;
    
    [scanner scanUpToCharactersFromSet:underscore intoString:&aLoc];
    
    if (!scanner.isAtEnd)
    {
        scanner.scanLocation++;
        
        if (!scanner.isAtEnd)
        {
            [scanner scanUpToCharactersFromSet:underscore intoString:&aLoc];
            pos.direction = aLoc;
        }
        
    }
    
    self.locations[streetcarId] = pos;
    
    [pos release];
}

START_ELEMENT(lastTime)
{
    _lastTime = ATRTIM(time);
}


#pragma mark Access location data

-(void)insertLocation:(DepartureData *)dep
{
	VehicleData *pos = self.locations[dep.streetcarId];
	
	if (pos !=nil)
	{
        dep.blockPosition = pos.location;
		
		// This allows this to run on a 3.0 iPhone but makes the warning go away
        dep.blockPositionFeet = [dep.stopLocation distanceFromLocation:pos.location] * kFeetInAMetre; // convert meters to feet
        dep.blockPositionHeading = pos.bearing;
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

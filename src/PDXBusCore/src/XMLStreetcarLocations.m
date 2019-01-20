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
#import "CLLocation+Helper.h"

@implementation XMLStreetcarLocations

static NSMutableDictionary *singleLocationsPerLine = nil;


- (instancetype)initWithRoute:(NSString *)route
{
    if (self = [super init])
    {
        self.route = route;
        
        [MemoryCaches addCache:self];
    }
    return self;
}

- (bool)cacheSelectors
{
    return YES;
}

#pragma mark Singleton

+ (XMLStreetcarLocations *)sharedInstanceForRoute:(NSString *)route
{
    @synchronized (self) {
        if (singleLocationsPerLine == nil)
        {
            singleLocationsPerLine = [[NSMutableDictionary alloc] init];
        }
    
        XMLStreetcarLocations *singleLocations = singleLocationsPerLine[route];
    
        if (singleLocations == nil)
        {
            singleLocations = [[XMLStreetcarLocations alloc] initWithRoute:route];
        
            singleLocationsPerLine[route] = singleLocations;
        }
    
        return singleLocations;
    }
}

+ (NSSet<NSString*> *)getStreetcarRoutesInDepartureArray:(NSArray *)deps
{
    NSMutableSet<NSString*> *routes = [NSMutableSet set];
    for (XMLDepartures *dep in deps)
    {
        for (DepartureData *dd in dep.items)
        {
            if (dd.streetcar)
            {
                [routes addObject:dd.route];
            }
        }
    }
    
    return routes;
}
+ (void)insertLocationsIntoDepartureArray:(NSArray *)deps forRoutes:(NSSet<NSString*> *)routes
{
    for (NSString *route in routes)
    {
        XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
        for (XMLDepartures *dep in deps)
        {
            for (DepartureData *dd in dep.items)
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
    [self startParsing:[NSString stringWithFormat:@"vehicleLocations&a=portland-sc&r=%@&t=%qu", self.route, 0LL]]; // _lastTime]];
    return true;    
}

#pragma mark Parser Callbacks


XML_START_ELEMENT(body)
{
    if (self.locations == nil)
    {
        self.locations = [NSMutableDictionary dictionary];
    }
    _hasData = true;
}

XML_START_ELEMENT(vehicle)
{
    NSString *streetcarId = ATRSTR(id);
    
    VehicleData *pos = [VehicleData data];
    
    pos.location = ATRLOC(lat,lon);
    
    pos.type = kVehicleTypeStreetcar;
    pos.block = streetcarId;
    pos.routeNumber = self.route;
    NSInteger secs = ATRINT(secsSinceReport);
    
    // Weird issue - just reversing the sign is something to do with the weird data.
    if (secs < 0)
    {
        secs = -secs;
    }
    
    pos.locationTime = [[NSDate date] dateByAddingTimeInterval:-secs];
    pos.bearing = ATRSTR(heading);
    
    NSString *dirTag = ATRSTR(dirTag);
    
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
    
}

XML_START_ELEMENT(lastTime)
{
    _lastTime = ATRTIM(time);
}

XML_END_ELEMENT(body)
{
    if (_lastTime==0)
    {
        _lastTime = UnixToTriMetTime([NSDate date].timeIntervalSince1970);
    }
}


#pragma mark Access location data

-(void)insertLocation:(DepartureData *)dep
{
    VehicleData *pos = self.locations[dep.streetcarId];
    
    if (pos !=nil)
    {
        dep.blockPosition = pos.location;
        dep.blockPositionFeet = [dep.stopLocation distanceFromLocation:pos.location] * kFeetInAMetre; // convert meters to feet
        dep.blockPositionHeading = pos.bearing;
        dep.blockPositionAt = pos.locationTime;
    }
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Clearing streetcar location cache %p\n", self.locations);
    self.locations = nil;
    _lastTime = 0;
}

@end

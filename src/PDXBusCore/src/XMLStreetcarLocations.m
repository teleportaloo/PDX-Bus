//
//  XMLStreetcarLocations.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/23/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogParsing

#import "XMLStreetcarLocations.h"
#import "XMLDepartures.h"
#import "Vehicle.h"
#import "DebugLogging.h"
#import "FormatDistance.h"
#import "CLLocation+Helper.h"
#import "NSDictionary+Types.h"

@interface XMLStreetcarLocations () {
    TriMetTime _lastTime;
}

@property (nonatomic, copy)   NSString *route;

@end

@implementation XMLStreetcarLocations

static NSMutableDictionary *singleLocationsPerLine = nil;


- (instancetype)initWithRoute:(NSString *)route {
    if (self = [super init]) {
        self.route = route;
        
        [MemoryCaches addCache:self];
    }
    
    return self;
}

- (bool)cacheSelectors {
    return YES;
}

#pragma mark Singleton

+ (XMLStreetcarLocations *)sharedInstanceForRoute:(NSString *)route {
    XmlParseSync() {
        if (singleLocationsPerLine == nil) {
            singleLocationsPerLine = [[NSMutableDictionary alloc] init];
        }
        
        XMLStreetcarLocations *singleLocations = singleLocationsPerLine[route];
        
        if (singleLocations == nil) {
            singleLocations = [[XMLStreetcarLocations alloc] initWithRoute:route];
            
            singleLocationsPerLine[route] = singleLocations;
        }
        
        return singleLocations;
    }
}

+ (NSSet<NSString *> *)getStreetcarRoutesInXMLDeparturesArray:(NSArray *)xmlDeps {
    NSMutableSet<NSString *> *routes = [NSMutableSet set];
    
    for (XMLDepartures *deps in xmlDeps) {
        for (Departure *departure in deps.items) {
            if (departure.streetcar) {
                [routes addObject:departure.route];
            }
        }
    }
    
    return routes;
}

+ (void)insertLocationsIntoXmlDeparturesArray:(NSArray *)xmlDeps forRoutes:(NSSet<NSString *> *)routes {
    XmlParseSync() {
        for (NSString *route in routes) {
            XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
            
            for (XMLDepartures *deps in xmlDeps) {
                for (Departure *departure in deps.items) {
                    if (departure.streetcar && [departure.route isEqualToString:route]) {
                        [locs insertLocation:departure];
                    }
                }
            }
        }
    }
}

#pragma mark Initiate Parsing

- (BOOL)getLocations {
    _hasData = false;
    [self startParsing:[NSString stringWithFormat:@"vehicleLocations&a=portland-sc&r=%@&t=%qu", self.route, 0LL]]; // _lastTime]];
    return true;
}

#pragma mark Parser Callbacks


XML_START_ELEMENT(body) {
    if (self.locations == nil) {
        self.locations = [NSMutableDictionary dictionary];
    }
    
    _hasData = true;
}

XML_START_ELEMENT(vehicle) {
    NSString *streetcarId = XML_NON_NULL_ATR_STR(@"id");
    
    Vehicle *pos = [Vehicle new];
    
    pos.location = XML_ATR_LOCATION(@"lat", @"lon");
    
    pos.type = kVehicleTypeStreetcar;
    pos.block = streetcarId;
    pos.vehicleId = [TriMetInfo vehicleIdFromStreetcarId:streetcarId];
    pos.routeNumber = self.route;
    pos.speedKmHr = XML_NULLABLE_ATR_STR(@"speedKmHr");
    NSInteger secs = XML_ATR_INT(@"secsSinceReport");
    
    // Weird issue - just reversing the sign is something to do with the weird data.
    if (secs < 0) {
        secs = -secs;
    }
    
    pos.locationTime = [[NSDate date] dateByAddingTimeInterval:-secs];
    pos.bearing = XML_NON_NULL_ATR_STR(@"heading");
    DEBUG_LOGS(pos.bearing);
    
    NSString *dirTag = XML_NON_NULL_ATR_STR(@"dirTag");
    
    NSScanner *scanner = [NSScanner scannerWithString:dirTag];
    NSCharacterSet *underscore = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    NSString *aLoc;
    
    [scanner scanUpToCharactersFromSet:underscore intoString:&aLoc];
    
    if (!scanner.isAtEnd) {
        scanner.scanLocation++;
        
        if (!scanner.isAtEnd) {
            [scanner scanUpToCharactersFromSet:underscore intoString:&aLoc];
            pos.direction = aLoc;
        }
    }
    
    self.locations[streetcarId] = pos;
}

XML_START_ELEMENT(lastTime) {
    _lastTime = XML_ATR_TIME(@"time");
}

XML_END_ELEMENT(body) {
    if (_lastTime == 0) {
        _lastTime = UnixToTriMetTime([NSDate date].timeIntervalSince1970);
    }
}


#pragma mark Access location data

- (void)insertLocation:(Departure *)dep {
    Vehicle *pos = self.locations[dep.streetcarId];
    
    if (pos != nil) {
        dep.blockPosition = pos.location;
        dep.blockPositionFeet = [dep.stopLocation distanceFromLocation:pos.location] * kFeetInAMetre; // convert meters to feet
        dep.blockPositionHeading = pos.bearing;
        dep.blockPositionAt = pos.locationTime;
    }
}

- (void)memoryWarning {
    @synchronized (self) {
        DEBUG_LOG(@"Clearing streetcar location cache %p\n", self.locations);
        self.locations = nil;
        _lastTime = 0;
    }
}

@end

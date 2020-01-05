//
//  XMLDepartures.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"
#import "Departure.h"
#import "DepartureTrip.h"
#import "XMLDetours.h"
#import "DebugLogging.h"
#import "Departure.h"
#import "NSString+Helper.h"
#import "CLLocation+Helper.h"
#import "UserPrefs.h"
#import "XMLStreetcarMessages.h"

@implementation XMLDepartures

+(instancetype)xmlWithOptions:(unsigned int)options
{
    XMLDepartures *item = [[[self class] alloc] init];
    
    item.options = options;
    
    return item;
}


- (instancetype)init
{
    if ((self = [super init]))
    {
        self.allDetours = [NSMutableDictionary dictionary];
        self.usedDetours = [NSMutableSet set];
        self.allRoutes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (bool)cacheSelectors
{
    return YES;
}

- (double)getDouble:(NSString *)str
{
    double d = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:str];    
    [scanner scanDouble:&d];
    return d;
}


- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (Departure*)departureForBlock:(NSString *)block
{
    for (Departure *dep in self) {
        if ([dep.block isEqualToString:block])
        {
            return dep;
        }
    }
    return nil;
}

#pragma mark Initiate parsing

- (void)startFromMultiple
{
    _hasData = NO;
    [self clearItems];
}

- (void)reparse:(NSMutableData *)data
{
    self.itemFromCache = NO;
    [self clearItems];
    self.rawData = data;
    [self reloadWithAction:^{
        NSError *parseError;
        [self parseRawData:&parseError];
        LOG_PARSE_ERROR(parseError);
    }];
}

- (void)reload
{
    [self reloadWithAction:^{
        NSString *mins = @"1";
        
        if (!DepOption(DepOptionsOneMin))
        {
            mins = [UserPrefs sharedInstance].minsForArrivals;
        }
        
        [self startParsing:[NSString stringWithFormat:@"arrivals/locIDs/%@/streetcar/true/showPosition/true/minutes/%@", self.locid,mins]
               cacheAction:TriMetXMLUseShortTermCache];
    }];
}

- (void)reloadWithAction:(void (^ __nullable)(void))action
{
    if (self.locid)
    {
        action();
        
        NSMutableArray *locs = self.locid.arrayFromCommaSeparatedString;
    
        int nStops = (int)locs.count;
    
        if (nStops > 1)
        {
            self.locDesc = [ NSString stringWithFormat:@"Stop Ids:%@", self.locid];
            self.loc = nil;
        }
        
        // NSArray *sorted = [self.itemArray sortedArrayUsingSelector:@selector(compareUsingTime:)];
    
        [self.items sortUsingSelector:@selector(compareUsingTime:)];
        // [self.itemArray addObjectsFromArray:sorted];
        
        if (self.nextBusFeedInTriMetData)
        {
            XMLStreetcarMessages * messages = [XMLStreetcarMessages sharedInstance];
            [messages getMessages];
            [messages insertDetoursIntoDepartureArray:self];
        }
    }
    
}

- (BOOL)getDeparturesForLocation:(NSString *)location
{    
    self.distance = nil;
    self.locid = location;
    [self reload];
    return YES;
}

- (BOOL)getDeparturesForLocation:(NSString *)location block:(NSString*)block
{    
    self.distance = nil;
    self.locid = location;
    self.blockFilter = block;
    [self reload];
    return YES;
}

- (Route *)route:(NSString *)route desc:(NSString *)desc
{
    Route *result = self.allRoutes[route];
    
    if (result == nil)
    {
        result = [Route data];
        result.desc = desc;
        result.route = route;
        [self.allRoutes setObject:result forKey:route];
    }
    
    return result;
}

#pragma mark Parser callbacks

- (void)dumpDict:(NSDictionary *)dict
{
#ifdef DEBUGLOGGING
    for (NSString *key in dict)
    {
        DEBUG_LOG(@"Key %@ value %@\n", key, dict[key]);
    }
#endif
}


#pragma mark Start Elements

XML_START_ELEMENT(resultset)
{
    self.queryTime = ATRDAT(queryTime);
    [self initItems];
    self.locDetours = [NSMutableOrderedSet orderedSet];
    self.nextBusFeedInTriMetData = NO;
    _hasData = YES;
}


// There is a location inside of a detour

XML_START_ELEMENT(location)
{
    if (self.currentDetour!=nil)
    {
#ifndef PDXBUS_WATCH
        if (!DepOption(DepOptionsNoDetours))
        {
            DetourLocation *loc = [DetourLocation data];
        
            loc.desc =  ATRSTR(desc);
            loc.locid = ATRSTR(id);
            loc.dir =   ATRSTR(dir);
            
            [loc setPassengerCodeFromString:NATRSTR(passengerCode)];
        
            loc.noServiceFlag = ATRBOOL(no_service_flag);
            loc.location = ATRLOC(lat,lng);
        
            [self.currentDetour.locations addObject:loc];
        }
#endif
    }
    else if (self.locDesc == nil)
    {
        self.locDesc = ATRSTR(desc);
    
        NSString *lat = ATRSTR(lat);
        NSString *lng = ATRSTR(lng);
    
        if (lat!=nil && lng!=nil)
        {
            self.loc = [CLLocation fromStringsLat:lat lng:lng];
        }
        self.locDir  = ATRSTR(dir);
    }
    
    
    if (self.currentDepartureObject!=nil && self.locDesc != nil)
    {
        self.currentTrip.name = ATRSTR(desc);
    }
}


XML_START_ELEMENT(arrival)
{
    NSString *block = NATRSTR(blockID);
    
    // Sometimes the streetcar block is in a different attribute - this
    // may be a temporary bug. 
    if (block==nil || block.length==0)
    {
        block = NATRSTR(block);
    }
    
    if (block == nil || block.length==0)
    {
        block = @"?";
    }
    
    if (((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block])) &&
        ((!DepOption(DepOptionsFirstOnly)|| self.count < 1)))
    {
        Departure *dep = [Departure data];
        
        dep.allDetours = self.allDetours;
        
        self.currentDepartureObject = dep;
        
        // Streetcar arrivals have an implicit block
        dep.hasBlock = ATRBOOL(streetCar);
        
        dep.cacheTime = self.cacheTime;
        
        // Adjust the query time based on the cache time
        dep.queryTime           =   self.queryTime;
        dep.route               =   ATRSTR(route);
        dep.fullSign            =   ATRSTR(fullSign);
        dep.shortSign           =   ATRSTR(shortSign);
        dep.dropOffOnly         =   ATRBOOL(dropOffOnly);
        dep.blockPositionFeet   =   ATRDIST(feet);

        static NSString *prefix    = @"Portland Streetcar ";
        NSInteger prefixLen = prefix.length;
        
        if (dep.shortSign.length > prefixLen && [dep.fullSign isEqualToString:dep.shortSign])
        {
            NSString *replace = @"";
            
            // Streetcar names are a little long.  Chop off the portland part
            if  ([[dep.shortSign substringToIndex:prefixLen] isEqualToString:prefix])
            {
                dep.shortSign = [NSString stringWithFormat:@"%@%@", replace, [self.currentDepartureObject.shortSign substringFromIndex:prefixLen]];
            }
        }
        
        dep.block   =         block;
        dep.dir     =         ATRSTR(dir);
        
        NSString *vehicleID = NATRSTR(vehicleID);
    
        if (vehicleID == nil || vehicleID.length==0)
        {
            dep.vehicleIDs = nil;
        }
        else
        {
            dep.vehicleIDs = @[ vehicleID ];
        }
        dep.reason         = NATRSTR(reason);
        dep.loadPercentage = ZATRINT(loadPercentage);
        dep.locationDesc   = self.locDesc;
        dep.locid          = self.locid;
        dep.locationDir    = self.locDir;
        dep.stopLocation   = self.loc;
        
        NSString *status = ATRSTR(status);
        
        if (ATREQ(status, @"estimated"))
        {
            dep.departureTime = ATRDAT(estimated);
            dep.status = kStatusEstimated;
        }
        else
        {
            dep.departureTime = ATRDAT(scheduled);
            
            if (ATREQ(status,@"scheduled"))
            {
                dep.status = kStatusScheduled;
            }
            else if (ATREQ(status, @"delayed"))
            {
                dep.status = kStatusDelayed;
            }
            else if (ATREQ(status, @"canceled"))
            {
                dep.status = kStatusCancelled;
            }
        }
        
        [dep extrapolateFromNow];
        
        dep.scheduledTime           = ATRDAT(scheduled);
        dep.nextBusFeedInTriMetData = ATRBOOL(nextBusFeed);
        dep.streetcar               = ATRBOOL(streetCar);
        
        if (dep.nextBusFeedInTriMetData || [[TriMetInfo streetcarRoutes] containsObject:dep.route])
        {
            self.nextBusFeedInTriMetData = YES;
        }

        // DEBUG_LOG(@"Nextbusfeed:%d %@\n", self.currentDepartureObject.nextBusFeedInTriMetData, ATRSTR(nextbusfeed)    ;
        // [self dumpDict:attributeDict];
    }
    else
    {
        self.currentDepartureObject=nil;
    }
}


XML_START_ELEMENT(error)
{
    self.currentDepartureObject   = [Departure data];
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_START_ELEMENT(blockposition)
{
    if (self.currentDepartureObject!=nil)
    {
        self.currentDepartureObject.blockPositionAt = ATRDAT(at);
        
        NSString *lat = ATRSTR(lat);
        NSString *lng = ATRSTR(lng);
        
        if (lat !=nil && lng!=nil)
        {
            self.currentDepartureObject.blockPosition = [CLLocation fromStringsLat:lat lng:lng];
        }
        
        self.currentDepartureObject.blockPositionDir            = ATRSTR(direction);
        self.currentDepartureObject.blockPositionRouteNumber    = ATRSTR(routeNumber);
        
        self.currentDepartureObject.nextLocid = ATRSTR(nextLocID);
        
        // self.currentDepartureObject.blockPositionFeet   = ATRDIST(feet);
        self.currentDepartureObject.blockPositionHeading= ATRSTR(heading);
        
        self.currentDepartureObject.hasBlock = true;
    }
}

XML_START_ELEMENT(trip)
{
    if (self.currentDepartureObject!=nil)
    {
        self.currentTrip = [DepartureTrip data];
        self.currentTrip.name     = ATRSTR(desc);
        self.currentTrip.distance = (unsigned long)ATRDIST(destDist);
        self.currentTrip.progress = (unsigned long)ATRDIST(progress);
        self.currentTrip.route = ATRSTR(route);
        self.currentTrip.dir = ATRSTR(dir);
        
        if (self.currentTrip.distance > 0)
        {
            [self.currentDepartureObject.trips addObject:self.currentTrip];
        }
    }
}

XML_START_ELEMENT(layover)
{
    if (self.currentDepartureObject!=nil)
    {
        self.currentTrip = [DepartureTrip data];
        self.currentTrip.startTime = ATRDAT(start);
        self.currentTrip.endTime   = ATRDAT(end);
        [self.currentDepartureObject.trips addObject:self.currentTrip];
    }
}

XML_START_ELEMENT(trackingerror)
{
    if (self.currentDepartureObject!=nil)
    {
        self.currentDepartureObject.trackingErrorOffRoute = ATRBOOL(offRoute);
        self.currentDepartureObject.trackingError = YES;
    }
}

XML_START_ELEMENT(detour)
{
    // There is a detour element inside an arrival and one outside
    if (self.currentDepartureObject!=nil)
    {
        NSNumber *detourId = @(ATRINT(id));
        [self.currentDepartureObject.detours addObject:detourId];
        [self.usedDetours addObject:detourId];
        self.currentDepartureObject.detour = YES;
    }
    else
    {
        // If we have a desc attibute then we are definately in the later detour section
        // we may get here if filtering on a block otherwise.
        if (!DepOption(DepOptionsNoDetours) && NATRSTR(desc)!=nil)
        {
            NSNumber *detourId = @(ATRINT(id));
            Detour *detour = [self.allDetours objectForKey:detourId];
            
            if (detour == nil)
            {
                detour = [Detour fromAttributeDict:attributeDict allRoutes:self.allRoutes];
                [self.allDetours setObject:detour forKey:detour.detourId];
            }
            
            self.currentDetour = detour;
            
            if (self.currentDetour.systemWideFlag)
            {
                [self.usedDetours addObject:self.currentDetour.detourId];
                // System wide alerts go at the top            
                for (Departure *dep in self)
                {
                    if ([dep.detours containsObject:self.currentDetour.detourId])
                    {
                        [dep.detours removeObject:self.currentDetour.detourId];
                    }
                    [dep.detours insertObject:self.currentDetour.detourId atIndex:0];
                    dep.systemWideDetours++;
                }
            }
        }
    }
}

#ifndef PDXBUS_WATCH
XML_START_ELEMENT(route)
{
    if (!DepOption(DepOptionsNoDetours))
    {
        if (self.currentDetour)
        {
            [self.currentDetour.routes addObject:[self route:ATRSTR(route) desc: ATRSTR(desc)]];
        }
    }
}
#endif

XML_END_ELEMENT(detour)
{
    if (self.currentDetour && !self.currentDetour.systemWideFlag)
    {
        for (NSString *stop in self.currentDetour.extractStops)
        {
            if ([stop isEqualToString:self.locid])
            {
                [self.locDetours addObject:self.currentDetour.detourId];
                [self.usedDetours addObject:self.currentDetour.detourId];
            }
        }
    
        for (DetourLocation *detourLoc in self.currentDetour.locations)
        {
            if ([detourLoc.locid isEqualToString:self.locid])
            {
                [self.locDetours addObject:self.currentDetour.detourId];
                [self.usedDetours addObject:self.currentDetour.detourId];
            }
        }
    }
    
    self.currentDetour = nil;
}

#pragma mark End Elements

XML_END_ELEMENT(error)
{
    if (self.currentDepartureObject!=nil) {
        self.currentDepartureObject.errorMessage = self.contentOfCurrentProperty;
        self.contentOfCurrentProperty = nil;
        self.locDesc = @"Error message";
        
        /*
        self.loc = nil;
        self.locid = nil;
        self.locDir = nil;
        self.locDesc = nil;
        self.distance = nil;
        self.sectionTitle = nil;
        */
        
        [self addItem:self.currentDepartureObject];
        self.currentDepartureObject = nil;
    }
}

XML_END_ELEMENT(arrival)
{
    if (self.currentDepartureObject!=nil)
    {
        [self.currentDepartureObject.detours sortUsingComparator:^NSComparisonResult(NSNumber * obj1, NSNumber * obj2) {
            return [obj1 compare:obj2];
        }];
        [self addItem:self.currentDepartureObject];
        self.currentDepartureObject = nil;
    }
}

XML_END_ELEMENT(resultset)
{
    if (self.items==nil || self.items.count==0)
    {
        // Not sure about the detours yet
        [self.allDetours enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Detour * _Nonnull detour, BOOL * _Nonnull stop) {
            // if (![self.usedDetours containsObject:key])
            {
                [self.locDetours addObject:key];
            }
        }];
    }
}

#pragma mark  Cached detours 

static NSMutableDictionary *cachedDetours = nil;

+ (void)clearCache
{
    if (cachedDetours !=nil)
    {
        cachedDetours = nil;
    }
}

- (bool)hasError
{
    if (self.items.count == 1 && self.items.firstObject.errorMessage!=nil)
    {
        return YES;
    }
    return NO;
}

- (void)appendQueryAndData:(NSMutableData *)buffer
{
    [super appendQueryAndData:buffer];
    
    if (self.nextBusFeedInTriMetData)
    {
        XMLStreetcarMessages *messages = [XMLStreetcarMessages sharedInstance];
        
        if (messages.gotData)
        {
            [messages appendQueryAndData:buffer];
        }
    }
}


@end

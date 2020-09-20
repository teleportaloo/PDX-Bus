//
//  XMLDepartures.m
//  PDXBus
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
#import "Settings.h"
#import "XMLStreetcarMessages.h"
#import "NSDictionary+TriMetCaseInsensitive.h"

@interface XMLDepartures ()

@property (nonatomic, strong) Departure *currentDepartureObject;
@property (nonatomic, strong) DepartureTrip *currentTrip;
@property (nonatomic, strong) NSMutableData *streetcarData;
@property (nonatomic) unsigned int options;

@end

@implementation XMLDepartures

+ (instancetype)xmlWithOptions:(unsigned int)options {
    XMLDepartures *item = [[[self class] alloc] init];
    
    item.options = options;
    
    return item;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.detourSorter = [DetourSorter data];
        self.allRoutes = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (bool)cacheSelectors {
    return YES;
}

- (double)getDouble:(NSString *)str {
    double d = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    
    [scanner scanDouble:&d];
    return d;
}

- (Departure *)departureForBlock:(NSString *)block {
    for (Departure *dep in self) {
        if ([dep.block isEqualToString:block]) {
            return dep;
        }
    }
    
    return nil;
}

#pragma mark Initiate parsing

- (void)startFromMultiple {
    _hasData = NO;
    [self clearItems];
}

- (void)reparse:(NSMutableData *)data {
    self.itemFromCache = NO;
    [self clearItems];
    self.rawData = data;
    [self reloadWithAction:^{
        NSError *parseError;
        [self parseRawData:&parseError];
        LOG_PARSE_ERROR(parseError);
    }];
}

- (void)reload {
    [self reloadWithAction:^{
        NSString *mins = @"1";
        
        if (!DepOption(DepOptionsOneMin)) {
            mins = Settings.minsForArrivals;
        }
        
        [self startParsing:[NSString stringWithFormat:@"arrivals/locIDs/%@/streetcar/true/showPosition/true/minutes/%@", self.stopId, mins]
               cacheAction:TriMetXMLUseShortTermCache];
    }];
}

- (void)reloadWithAction:(void (^__nullable)(void))action {
    if (self.stopId) {
        action();
        
        NSMutableArray<NSString *> *stopIdArray = self.stopId.arrayFromCommaSeparatedString;
        
        int nStops = (int)stopIdArray.count;
        
        if (nStops > 1) {
            self.locDesc = [NSString stringWithFormat:@"Stop Ids:%@", self.stopId];
            self.loc = nil;
        }
        
        // NSArray *sorted = [self.itemArray sortedArrayUsingSelector:@selector(compareUsingTime:)];
        
        [self.items sortUsingSelector:@selector(compareUsingTime:)];
        // [self.itemArray addObjectsFromArray:sorted];
        
        if (self.nextBusFeedInTriMetData) {
            XMLStreetcarMessages *messages = [XMLStreetcarMessages sharedInstance];
            [messages getMessages];
            [messages insertDetoursIntoDepartureArray:self];
        }
    }
}

- (BOOL)getDeparturesForStopId:(NSString *)stopId {
    self.distance = nil;
    self.stopId = stopId;
    [self reload];
    return YES;
}

- (BOOL)getDeparturesForStopId:(NSString *)stopId block:(NSString *)block {
    self.distance = nil;
    self.stopId = stopId;
    self.blockFilter = block;
    [self reload];
    return YES;
}

- (Route *)route:(NSString *)route desc:(NSString *)desc {
    Route *result = self.allRoutes[route];
    
    if (result == nil) {
        result = [Route data];
        result.desc = desc;
        result.route = route;
        [self.allRoutes setObject:result forKey:route];
    }
    
    return result;
}

#pragma mark Parser callbacks

- (void)dumpDict:(NSDictionary *)dict {
#ifdef DEBUGLOGGING
    
    for (NSString *key in dict) {
        DEBUG_LOG(@"Key %@ value %@\n", key, dict[key]);
    }
    
#endif
}

#pragma mark Start Elements

XML_START_ELEMENT(resultset) {
    self.queryTime = XML_ATR_DATE(@"queryTime");
    [self initItems];
    [self.detourSorter clear];
    self.nextBusFeedInTriMetData = NO;
    _hasData = YES;
}


// There is a location inside of a detour

XML_START_ELEMENT(location) {
    if (self.currentDetour != nil) {
#ifndef PDXBUS_WATCH
        
        if (!DepOption(DepOptionsNoDetours)) {
            DetourLocation *loc = [DetourLocation data];
            
            loc.desc = XML_NON_NULL_ATR_STR(@"desc");
            loc.stopId = XML_NON_NULL_ATR_STR(@"id");
            loc.dir = XML_NON_NULL_ATR_STR(@"dir");
            
            [loc setPassengerCodeFromString:XML_NULLABLE_ATR_STR(@"passengerCode")];
            
            loc.noServiceFlag = XML_ATR_BOOL(@"no_service_flag");
            loc.location = XML_ATR_LOCATION(@"lat", @"lng");
            
            [self.currentDetour.locations addObject:loc];
        }
        
#endif
    } else if (self.locDesc == nil) {
        self.locDesc = XML_NON_NULL_ATR_STR(@"desc");
        self.loc = XML_ATR_LOCATION(@"lat", @"lng");
        self.locDir = XML_NON_NULL_ATR_STR(@"dir");
    }
    
    if (self.currentDepartureObject != nil && self.locDesc != nil) {
        self.currentTrip.name = XML_NON_NULL_ATR_STR(@"desc");
    }
}


XML_START_ELEMENT(arrival) {
    NSString *block = XML_NULLABLE_ATR_STR(@"blockID");
    
    // Sometimes the streetcar block is in a different attribute - this
    // may be a temporary bug.
    if (block == nil || block.length == 0) {
        block = XML_NULLABLE_ATR_STR(@"block");
    }
    
    if (block == nil || block.length == 0) {
        block = @"?";
    }
    
    if (((self.blockFilter == nil) || ([self.blockFilter isEqualToString:block])) &&
        ((!DepOption(DepOptionsFirstOnly) || self.count < 1))) {
        Departure *dep = [Departure data];
        
        dep.sortedDetours.allDetours = self.detourSorter.allDetours;
        
        self.currentDepartureObject = dep;
        
        // Streetcar arrivals have an implicit block
        dep.hasBlock = XML_ATR_BOOL(@"streetCar");
        
        dep.cacheTime = self.cacheTime;
        
        // Adjust the query time based on the cache time
        dep.queryTime = self.queryTime;
        dep.route = XML_NON_NULL_ATR_STR(@"route");
        dep.fullSign = XML_NON_NULL_ATR_STR(@"fullSign");
        dep.shortSign = XML_NON_NULL_ATR_STR(@"shortSign");
        dep.dropOffOnly = XML_ATR_BOOL(@"dropOffOnly");
        dep.blockPositionFeet = XML_ATR_DISTANCE(@"feet");
        
        static NSString *prefix = @"Portland Streetcar ";
        NSInteger prefixLen = prefix.length;
        
        if (dep.shortSign.length > prefixLen && [dep.fullSign isEqualToString:dep.shortSign]) {
            NSString *replace = @"";
            
            // Streetcar names are a little long.  Chop off the portland part
            if ([[dep.shortSign substringToIndex:prefixLen] isEqualToString:prefix]) {
                dep.shortSign = [NSString stringWithFormat:@"%@%@", replace, [self.currentDepartureObject.shortSign substringFromIndex:prefixLen]];
            }
        }
        
        dep.block = block;
        dep.dir = XML_NON_NULL_ATR_STR(@"dir");
        
        NSString *vehicleId = XML_NULLABLE_ATR_STR(@"vehicleID");
        
        if (vehicleId == nil || vehicleId.length == 0) {
            dep.vehicleIds = nil;
        } else {
            dep.vehicleIds = @[ vehicleId ];
        }
        
        dep.reason = XML_NULLABLE_ATR_STR(@"reason");
        dep.loadPercentage = XML_ATR_INT_ZERO(@"loadPercentage");
        dep.locationDesc = self.locDesc;
        dep.stopId = self.stopId;
        dep.locationDir = self.locDir;
        dep.stopLocation = self.loc;
        
        NSString *status = XML_NON_NULL_ATR_STR(@"status");
        
        if (XML_EQ(status, @"estimated")) {
            dep.departureTime = XML_ATR_DATE(@"estimated");
            dep.status = kStatusEstimated;
        } else {
            dep.departureTime = XML_ATR_DATE(@"scheduled");
            
            if (XML_EQ(status, @"scheduled")) {
                dep.status = kStatusScheduled;
            } else if (XML_EQ(status, @"delayed")) {
                dep.status = kStatusDelayed;
            } else if (XML_EQ(status, @"canceled")) {
                dep.status = kStatusCancelled;
            }
        }
        
        [dep extrapolateFromNow];
        
        dep.scheduledTime = XML_ATR_DATE(@"scheduled");
        dep.nextBusFeedInTriMetData = XML_ATR_BOOL(@"nextBusFeed");
        dep.streetcar = XML_ATR_BOOL(@"streetCar");
        
        if (dep.nextBusFeedInTriMetData || [[TriMetInfo streetcarRoutes] containsObject:dep.route]) {
            self.nextBusFeedInTriMetData = YES;
        }
        
    } else {
        self.currentDepartureObject = nil;
    }
}


XML_START_ELEMENT(error) {
    self.currentDepartureObject = [Departure data];
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_START_ELEMENT(blockposition) {
    if (self.currentDepartureObject != nil) {
        self.currentDepartureObject.blockPositionAt = XML_ATR_DATE(@"at");
        
        NSString *lat = XML_NON_NULL_ATR_STR(@"lat");
        NSString *lng = XML_NON_NULL_ATR_STR(@"lng");
        
        if (lat != nil && lng != nil) {
            self.currentDepartureObject.blockPosition = [CLLocation fromStringsLat:lat lng:lng];
        }
        
        self.currentDepartureObject.blockPositionDir = XML_NON_NULL_ATR_STR(@"direction");
        self.currentDepartureObject.blockPositionRouteNumber = XML_NON_NULL_ATR_STR(@"routeNumber");
        
        self.currentDepartureObject.nextStopId = XML_NON_NULL_ATR_STR(@"nextLocID");
        
        // self.currentDepartureObject.blockPositionFeet   = XML_ATR_DISTANCE(feet);
        self.currentDepartureObject.blockPositionHeading = XML_NON_NULL_ATR_STR(@"heading");
        
        self.currentDepartureObject.hasBlock = true;
    }
}

XML_START_ELEMENT(trip) {
    if (self.currentDepartureObject != nil) {
        self.currentTrip = [DepartureTrip data];
        self.currentTrip.name = XML_NON_NULL_ATR_STR(@"desc");
        self.currentTrip.distance = (unsigned long)XML_ATR_DISTANCE(@"destDist");
        self.currentTrip.progress = (unsigned long)XML_ATR_DISTANCE(@"progress");
        self.currentTrip.route = XML_NON_NULL_ATR_STR(@"route");
        self.currentTrip.dir = XML_NON_NULL_ATR_STR(@"dir");
        
        if (self.currentTrip.distance > 0) {
            [self.currentDepartureObject.trips addObject:self.currentTrip];
        }
    }
}

XML_START_ELEMENT(layover) {
    if (self.currentDepartureObject != nil) {
        self.currentTrip = [DepartureTrip data];
        self.currentTrip.startTime = XML_ATR_DATE(@"start");
        self.currentTrip.endTime = XML_ATR_DATE(@"end");
        [self.currentDepartureObject.trips addObject:self.currentTrip];
    }
}

XML_START_ELEMENT(trackingerror) {
    if (self.currentDepartureObject != nil) {
        self.currentDepartureObject.trackingErrorOffRoute = XML_ATR_BOOL(@"offRoute");
        self.currentDepartureObject.trackingError = YES;
    }
}

XML_START_ELEMENT(detour) {
    // There is a detour element inside an arrival and one outside
    if (self.currentDepartureObject != nil) {
        NSNumber *detourId = @(TRIMET_DETOUR_ID(XML_ATR_INT(@"id")));
        [self.currentDepartureObject.sortedDetours.detourIds addObject:detourId];
        self.currentDepartureObject.detour = YES;
    } else {
        // If we have a desc attibute then we are definately in the later detour section
        // we may get here if filtering on a block otherwise.
        if (!DepOption(DepOptionsNoDetours) && XML_NULLABLE_ATR_STR(@"desc") != nil) {
            NSNumber *detourId = @(TRIMET_DETOUR_ID(XML_ATR_INT(@"id")));
            Detour *detour = [self.detourSorter.allDetours objectForKey:detourId];
            
            if (detour == nil) {
                detour = [Detour fromAttributeDict:XML_ATR_DICT allRoutes:self.allRoutes];
                [self.detourSorter.allDetours setObject:detour forKey:detour.detourId];
            }
            
            self.currentDetour = detour;
            
            if (self.currentDetour.systemWide) {
                // System wide alerts go at the top
                for (Departure *dep in self) {
                    [dep.sortedDetours.detourIds insertObject:self.currentDetour.detourId atIndex:0];
                }
            }
        }
    }
}

#ifndef PDXBUS_WATCH
XML_START_ELEMENT(route) {
    if (!DepOption(DepOptionsNoDetours)) {
        if (self.currentDetour) {
            [self.currentDetour.routes addObject:[self route:XML_NON_NULL_ATR_STR(@"route") desc:XML_NON_NULL_ATR_STR(@"desc")]];
        }
    }
}
#endif

XML_END_ELEMENT(detour) {
    if (self.currentDetour && !self.currentDetour.systemWide) {
        for (NSString *stop in self.currentDetour.extractStops) {
            if ([stop isEqualToString:self.stopId]) {
                [self.detourSorter.detourIds addObject:self.currentDetour.detourId];
            }
        }
        
        for (DetourLocation *detourLoc in self.currentDetour.locations) {
            if ([detourLoc.stopId isEqualToString:self.stopId]) {
                [self.detourSorter.detourIds addObject:self.currentDetour.detourId];
            }
        }
    }
    
    self.currentDetour = nil;
}

#pragma mark End Elements

XML_END_ELEMENT(error) {
    if (self.currentDepartureObject != nil) {
        self.currentDepartureObject.errorMessage = self.contentOfCurrentProperty;
        self.contentOfCurrentProperty = nil;
        self.locDesc = @"Error message";
                
        [self addItem:self.currentDepartureObject];
        self.currentDepartureObject = nil;
    }
}

XML_END_ELEMENT(arrival) {
    if (self.currentDepartureObject != nil) {
        [self addItem:self.currentDepartureObject];
        self.currentDepartureObject = nil;
    }
}

XML_END_ELEMENT(resultset) {
    if (self.items == nil || self.items.count == 0) {
        // Not sure about the detours yet
        [self.detourSorter.allDetours enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull key, Detour *_Nonnull detour, BOOL *_Nonnull stop) {
            if (!detour.systemWide)
            {
                [self.detourSorter.detourIds addObject:key];
            }
        }];
    }
    else
    {
        for (Departure *dep in self)
        {
            [dep.sortedDetours sort];
        }
    }
    
    [self.detourSorter sort];
}

#pragma mark  Cached detours

static NSMutableDictionary *cachedDetours = nil;


+ (NSString *)fixLocationForSpeaking:(NSString *)loc
{
    static NSDictionary<NSString *, NSString *> *replacements;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        replacements =
            @{ @"Stn" : @"Station" };
    });
    
    NSMutableString *fixedStopName = [NSMutableString stringWithString:loc];
    
    [replacements enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [fixedStopName replaceOccurrencesOfString:key withString:obj options:NSLiteralSearch range:NSMakeRange(0, fixedStopName.length)];
    }];
    
    return fixedStopName;
}

+ (void)clearCache {
    if (cachedDetours != nil) {
        cachedDetours = nil;
    }
}

- (bool)hasError {
    if (self.items.count == 1 && self.items.firstObject.errorMessage != nil) {
        return YES;
    }
    
    return NO;
}

- (void)appendQueryAndData:(NSMutableData *)buffer {
    [super appendQueryAndData:buffer];
    
    if (self.nextBusFeedInTriMetData) {
        XMLStreetcarMessages *messages = [XMLStreetcarMessages sharedInstance];
        
        if (messages.gotData) {
            [messages appendQueryAndData:buffer];
        }
    }
}

@end

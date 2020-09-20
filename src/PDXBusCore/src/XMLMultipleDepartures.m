//
//  XMLMultipleDepartures.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/21/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLMultipleDepartures.h"
#import "Departure.h"
#import "DepartureTrip.h"
#import "XMLDetours.h"
#import "DebugLogging.h"
#import "Departure.h"
#import "NSString+Helper.h"
#import "CLLocation+Helper.h"
#import "Settings.h"
#import "Route+iOS.h"
#import "XMLStreetcarMessages.h"
#import "NSDictionary+TriMetCaseInsensitive.h"

@interface XMLMultipleDepartures ()

@property (nonatomic)         unsigned int options;
@property (nonatomic, strong) XMLDepartures *currentStop;
@property (nonatomic, strong) Detour *currentDetour;

@end

@implementation XMLMultipleDepartures

- (instancetype)init {
    if (self = [super init]) {
        self.allRoutes = [NSMutableDictionary dictionary];
        self.allDetours = [NSMutableDictionary dictionary];
        self.stops = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (bool)cacheSelectors {
    return YES;
}

- (BOOL)getDeparturesForStopIds:(NSString *)stopIds {
    self.blockFilter = nil;
    self.stopIds = stopIds;
    [self reload];
    return YES;
}

- (BOOL)getDeparturesForStopIds:(NSString *)stopIds block:(NSString *)block {
    self.blockFilter = block;
    self.stopIds = stopIds;
    [self reload];
    return YES;
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
        
        [self       startParsing:[NSString stringWithFormat:@"arrivals/locIDs/%@/streetcar/true/showPosition/true/minutes/%@", self.stopIds, mins]
                     cacheAction:TriMetXMLUseShortTermCache];
    }];
}

- (void)reloadWithAction:(void (^__nullable)(void))action {
    if (self.stopIds == nil && self.stops.count > 0) {
        self.stopIds = [NSString commaSeparatedStringFromStringEnumerator:self.stops];
    }
    
    action();
    
    self.nextBusFeedInTriMetData = NO;
    XMLStreetcarMessages *messages = [XMLStreetcarMessages sharedInstance];
    
    for (XMLDepartures *dep in self) {
        [dep.items sortUsingSelector:@selector(compareUsingTime:)];
        
        if (dep.nextBusFeedInTriMetData) {
            [messages getMessages];
            [messages insertDetoursIntoDepartureArray:dep];
            self.nextBusFeedInTriMetData = YES;
        }
    }
    
    if (!_hasData) {
        [self initItems];
        NSArray<NSString *> *stopIdArray = self.stopIds.arrayFromCommaSeparatedString;
        
        for (NSString *stopId in stopIdArray) {
            XMLDepartures *xml = [XMLDepartures xml];
            xml.stopId = stopId;
            [self addItem:xml];
        }
    }
}

#pragma mark Start Elements

XML_START_ELEMENT(resultset) {
    self.queryTime = XML_ATR_DATE(@"queryTime");
    [self initItems];
    _hasData = YES;
}

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
    } else {
        NSString *stopId = XML_NON_NULL_ATR_STR(@"id");
        
        XMLDepartures *stop = self.stops[stopId];
        
        if (stop == nil) {
            stop = [XMLDepartures xmlWithOptions:self.options];
            stop.stopId = stopId;
            self.stops[stopId] = stop;
        }
        
        // [stop startFromMultiple];
        stop.detourSorter.allDetours = self.allDetours;
        stop.allRoutes = self.allRoutes;
        stop.blockFilter = self.blockFilter;
        stop.cacheTime = self.cacheTime;
        stop.itemFromCache = self.itemFromCache;
        
        CALL_XML_START_ELEMENT_ON(stop, resultset);
        stop.queryTime = self.queryTime;
        CALL_XML_START_ELEMENT_ON(stop, location);
    }
}

XML_START_ELEMENT(arrival) {
    NSString *stopId = XML_NON_NULL_ATR_STR(@"locid");
    
    self.currentStop = self.stops[stopId];
    CALL_XML_START_ELEMENT_ON(self.currentStop, arrival);
}

XML_START_ELEMENT(error) {
    XMLDepartures *errorStop = [XMLDepartures xmlWithOptions:self.options];
    
    self.currentStop = errorStop;
    self.contentOfCurrentProperty = [NSMutableString string];
    
    CALL_XML_START_ELEMENT_ON(errorStop, resultset);
    CALL_XML_START_ELEMENT_ON(errorStop, error);
    
    if (self.stops.count > 0) {
        [self.stops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, XMLDepartures *_Nonnull xml, BOOL *_Nonnull stop) {
            CALL_XML_START_ELEMENT_ON(xml, resultset);
            CALL_XML_START_ELEMENT_ON(xml, error);
        }];
    }
}

XML_START_ELEMENT(blockposition) {
    CALL_XML_START_ELEMENT_ON(self.currentStop, blockposition);
}

XML_START_ELEMENT(trip) {
    CALL_XML_START_ELEMENT_ON(self.currentStop, trip);
}

XML_START_ELEMENT(layover) {
    CALL_XML_START_ELEMENT_ON(self.currentStop, layover);
}

XML_START_ELEMENT(trackingerror) {
    CALL_XML_START_ELEMENT_ON(self.currentStop, trackingerror);
}

XML_START_ELEMENT(detour) {
    // There is a detour element inside an arrival and one outside
    if (self.currentStop) {
        CALL_XML_START_ELEMENT_ON(self.currentStop, detour);
    } else {
        // If we have a desc attibute then we are definately in the later detour section
        // we may get here if filtering on a block otherwise.
        if (!DepOption(DepOptionsNoDetours) && XML_NULLABLE_ATR_STR(@"desc") != nil) {
            NSNumber *detourId = @(TRIMET_DETOUR_ID(XML_ATR_INT(@"id")));
            Detour *detour = [self.allDetours objectForKey:detourId];
            
            if (detour == nil) {
                detour = [Detour fromAttributeDict:XML_ATR_DICT allRoutes:self.allRoutes];
                [self.allDetours setObject:detour forKey:detourId];
            }
            
            self.currentDetour = detour;
            
            if (self.currentDetour.systemWide) {
                // System wide alerts go at the top
                [self.stops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, XMLDepartures *_Nonnull xml, BOOL *_Nonnull stop) {
                    for (Departure *dep in xml) {
                        [dep.sortedDetours add:self.currentDetour];
                    }
                }];
            }
        }
    }
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
    if (!self.currentStop && !self.currentDetour.systemWide) {
        [self.stops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, XMLDepartures *_Nonnull xml, BOOL *_Nonnull stop) {
            xml.currentDetour = self.currentDetour;
            CALL_XML_END_ELEMENT_ON(xml, detour);
        }];
    }
    
    self.currentDetour = nil;
}

#pragma mark End Elements


XML_END_ELEMENT(error) {
    if (self.currentStop != nil) {
        self.currentStop.contentOfCurrentProperty = self.contentOfCurrentProperty;
        CALL_XML_END_ELEMENT_ON(self.currentStop, error);
        
        if (self.stops.count > 0) {
            [self.stops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, XMLDepartures *_Nonnull xml, BOOL *_Nonnull stop) {
                xml.contentOfCurrentProperty = self.contentOfCurrentProperty;
                CALL_XML_END_ELEMENT_ON(xml, error);
            }];
        } else {
            [self.items removeAllObjects];
            [self.items addObject:self.currentStop];
        }
    }
}


XML_END_ELEMENT(arrival) {
    if (self.currentStop != nil) {
        CALL_XML_END_ELEMENT_ON(self.currentStop, arrival);
        self.currentStop = nil;
    }
}

XML_END_ELEMENT(resultset) {
    NSArray<NSString *> *stopIdArray = self.stopIds.arrayFromCommaSeparatedString;
    
    for (NSString *stopId in stopIdArray) {
        XMLDepartures *xml = self.stops[stopId];
        
        if (xml) {
            [self addItem:xml];
            
            if (Settings.debugXML) {
                xml.fullQuery = self.fullQuery;
                xml.rawData = self.rawData;
            }
        }
        
        CALL_XML_END_ELEMENT_ON(xml, resultset);
    }
    
    if (self.currentStop && self.currentStop.items.count > 0 && self.currentStop.items.firstObject.errorMessage != nil && self.items.count == 0) {
        [self addItem:self.currentStop];
        self.currentStop = nil;
    }
    
    self.stops = [NSMutableDictionary dictionary];
}

+ (instancetype)xmlWithOptions:(unsigned int)options {
    XMLMultipleDepartures *item = [[[self class] alloc] init];
    
    item.options = options;
    
    return item;
}

+ (instancetype)xmlWithOptions:(unsigned int)options oneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate {
    XMLMultipleDepartures *item = [[[self class] alloc] init];
    
    item.options = options;
    item.oneTimeDelegate = delegate;
    
    return item;
}

+ (NSArray<NSString *> *)batchesFromEnumerator:(id<NSFastEnumeration>)container selector:(SEL)selector max:(NSInteger)max {
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    NSMutableString *string = [NSMutableString string];
    NSInteger batch = 0;
    NSInteger total = 0;
    
    for (NSObject *obj in container) {
        if ([obj respondsToSelector:selector]) {
            IMP imp = [obj methodForSelector:selector];
            NSObject * (*func)(id, SEL) = (void *)imp;
            
            NSObject *item = func(obj, selector);
            
            // = [obj performSelector:selector];
            
            if (item != nil) {
                if ([item isKindOfClass:[NSString class]]) {
                    batch++;
                    total++;
                    
                    if (batch > kMultipleDepsMaxStops) {
                        [result addObject:string];
                        string = [NSMutableString string];
                        batch = 1;
                    }
                    
                    if (string.length > 0) {
                        [string appendString:@","];
                    }
                    
                    [string appendString:(NSString *)item];
                    
                    if (total >= max) {
                        break;
                    }
                } else {
                    ERROR_LOG(@"batchesFromEnumerator - selector did not return string %@\n",
                              NSStringFromSelector(selector));
                }
            }
        } else {
            ERROR_LOG(@"batchesFromEnumerator - item does not respond to selector %@\n",
                      NSStringFromSelector(selector));
        }
    }
    
    if (string.length > 0) {
        [result addObject:string];
    }
    
    return result;
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

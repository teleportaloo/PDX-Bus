//
//  XMLStreetcarMessages.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/29/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStreetcarMessages.h"
#import "TriMetInfo.h"
#import "NSString+Helper.h"
#import "XMLDepartures.h"
#import "NSDictionary+Types.h"

@implementation XMLStreetcarMessages

+ (XMLStreetcarMessages *)sharedInstance {
    static XMLStreetcarMessages *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        //here was a retain
        sharedInstance = [XMLStreetcarMessages xml];
    });
    
    return sharedInstance;
}

- (Route *)route:(NSString *)route {
    Route *result = self.allRoutes[route];
    
    if (result == nil) {
        result = [Route new];
        result.route = route;
        PtrConstRouteInfo info = [result rawColor];
        
        if (info != nil) {
            result.desc = info->full_name;
        } else {
            result.desc = [NSString stringWithFormat:@"Portland Streetcar route:%@", route];
        }
        
        [self.allRoutes setObject:result forKey:route];
    }
    return result;
}

- (void)alwaysGetMessages {
    _hasData = false;
    [self startParsing:[NSString stringWithFormat:@"messages&a=portland-sc"]];
}

- (void)getMessages {
    if (self.needToGetMessages) {
        [self alwaysGetMessages];
    }
}

- (bool)needToGetMessages {
    return (!_hasData || self.queryTime == nil || [self.queryTime timeIntervalSinceNow] < -120);
}

XML_START_ELEMENT(body) {
    [self initItems];
    _hasData = TRUE;
    self.copyright = XML_NON_NULL_ATR_STR(@"copyright");
    self.queryTime = [NSDate date];
}

XML_END_ELEMENT(body) {
    // Merge detours by description
    // This is to remove streetcar duplicateds
    
    NSMutableArray *merged = [NSMutableArray array];
    bool found = NO;
    bool foundStop = NO;
    
    for (Detour *itemToAdd in self) {
        found = NO;
        int i = 0;
        
        for (Detour *existing in merged) {
            if ([existing.detourDesc isEqualToString:itemToAdd.detourDesc]) {
                found = YES;
                
                if (itemToAdd.embeddedStops != nil) {
                    if (existing.embeddedStops == nil) {
                        existing.embeddedStops = [NSMutableSet set];
                    }
                    
                    for (NSString *newStop in itemToAdd.embeddedStops) {
                        foundStop = NO;
                        
                        for (NSString *existingStop in existing.embeddedStops) {
                            if ([newStop isEqualToString:existingStop]) {
                                foundStop = YES;
                                break;
                            }
                        }
                        
                        if (!foundStop) {
                            [existing.embeddedStops addObject:newStop];
                        }
                    }
                }
                
                if (itemToAdd.routes != nil) {
                    if (existing.routes == nil) {
                        existing.routes = [NSMutableOrderedSet orderedSet];
                    }
                    
                    [existing.routes addObjectsFromArray:itemToAdd.routes.array];
                }
                
                break;
            }
            
            i++;
        }
        
        if (!found) {
            [merged addObject:itemToAdd];
        }
    }
    
    self.items = merged;
}


XML_START_ELEMENT(route) {
    NSString *route = XML_NON_NULL_ATR_STR(@"tag");
    
    if ([route caseInsensitiveCompare:@"all"] == NSOrderedSame) {
        self.currentAllRoutes = YES;
    } else {
        self.currentRoute = [self route:route];
    }
}

XML_END_ELEMENT(route) {
    self.currentRoute = nil;
    self.currentAllRoutes = NO;
}

XML_START_ELEMENT(message) {
    self.curentDetour = [Detour new];
    self.curentDetour.detourId = @(STREETCAR_DETOUR_ID(XML_ATR_INT(@"id")));
}

XML_END_ELEMENT(message) {
    [self addItem:self.curentDetour];
    self.curentDetour = nil;
}

XML_START_ELEMENT(text) {
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_END_ELEMENT(text) {
    if (self.curentDetour) {
        self.curentDetour.detourDesc = [TriMetXML replaceXMLcodes:self.contentOfCurrentProperty].stringByTrimmingWhitespace;
        self.curentDetour.routes = [NSMutableOrderedSet orderedSet];
        
        if (self.currentRoute) {
            [self.curentDetour.routes addObject:self.currentRoute];
        }
        
        if (self.currentAllRoutes) {
            if (self.allStreetcarRoutes == nil) {
                self.allStreetcarRoutes = [NSMutableArray array];
                
                NSSet<NSString *> *streetcarRouteIds = [TriMetInfo streetcarRoutes];
                
                for (NSString *rt in streetcarRouteIds) {
                    [self.allStreetcarRoutes addObject:[self route:rt]];
                }
            }
            
            [self.curentDetour.routes addObjectsFromArray:self.allStreetcarRoutes];
        }
    }
    
    self.contentOfCurrentProperty = nil;
}

XML_START_ELEMENT(stop) {
    if (self.curentDetour) {
        if (self.curentDetour.embeddedStops == nil) {
            self.curentDetour.embeddedStops = [NSMutableSet set];
        }
        
        NSString *stop = XML_NON_NULL_ATR_STR(@"tag");
        
        if (stop) {
            [self.curentDetour.embeddedStops addObject:stop];
        }
    }
}


- (void)insertDetoursIntoDepartureArray:(XMLDepartures *)departures {
    XmlParseSync() {
        for (Departure *dep in departures) {
            for (Detour *detour in self) {
                for (Route *route in detour.routes) {
                    if ([route.route isEqualToString:dep.route]) {
                        dep.detour = YES;
                        [dep.sortedDetours safeAddDetour:detour];
                        [departures.allRoutes setObject:route forKey:route.route];
                        break;
                    }
                }
            }
            [dep.sortedDetours sort];
        }
        
        for (Detour *detour in self) {
            if (detour.extractStops) {
                for (NSString *stop in detour.extractStops) {
                    if ([stop isEqualToString:departures.stopId]) {
                        [departures.detourSorter safeAddDetour:detour];
                    }
                }
            }
        }
    }
}

@end

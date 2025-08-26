//
//  XMLLocateStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/13/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLLocateStops.h"

#import "CLLocation+Helper.h"
#import "NSDictionary+Types.h"
#import "TriMetXMLSelectors.h"

@interface XMLLocateStops () {
    TripMode _currentMode;
}

@property(nonatomic, strong) StopDistance *currentStop;
@property(nonatomic, strong) NSMutableDictionary *routeStore;

@end

@implementation XMLLocateStops

#pragma mark Data fetchers

- (bool)findNearestStops {
    NSString *query = [NSString
        stringWithFormat:@"stops/ll/%@%@%@%@",
                         COORD_TO_LNG_LAT_STR(self.location.coordinate),
                         (self.minDistance > 0.0
                              ? [NSString stringWithFormat:@"/meters/%f",
                                                           self.minDistance]
                              : @""),
                         ((self.mode != TripModeAll ||
                           self.includeRoutesInStops)
                              ? @"/showRoutes/true"
                              : @""),
                         self.includeRoutesInStops ? @"/showRouteDirs/true"
                                                   : @""];

    bool res = [self startParsing:query cacheAction:TriMetXMLNoCaching];

    if (_hasData) {
        [self.items sortUsingSelector:@selector(compareUsingDistance:)];

        while (self.items.count > self.maxToFind) {
            [self.items removeLastObject];
        }
    }

    return res;
}

- (bool)findNearestRoutes {
    NSString *query = [NSString
        stringWithFormat:@"stops/ll/%@%@%@",
                         COORD_TO_LNG_LAT_STR(self.location.coordinate),
                         (self.minDistance > 0.0
                              ? [NSString stringWithFormat:@"/meters/%f",
                                                           self.minDistance]
                              : @""),
                         @"/showRoutes/true"];

    self.routeStore = [NSMutableDictionary dictionary];

    bool res = [self startParsing:query cacheAction:TriMetXMLNoCaching];

    if (_hasData) {
        // We don't care about the stops stored in the array!
        self.routes = [NSMutableArray array];
        [self.routes addObjectsFromArray:self.routeStore.allValues];

        // We are done with this dictionary now may as well deference it.
        self.routeStore = nil;

        for (RouteDistance *rd in self.routes) {
            [rd sortStopsByDistance];

            // Truncate array - this can get far too big
            while (rd.stops.count > self.maxToFind) {
                [rd.stops removeLastObject];
            }
        }

        [self.routes sortUsingSelector:@selector(compareUsingDistance:)];
    }

    return res;
}

#pragma mark Parser callbacks

- (bool)modeMatch:(TripMode)first second:(TripMode)second {
    if (first == second) {
        return true;
    }

    if (first == TripModeAll || second == TripModeAll) {
        return true;
    }

    return false;
}

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(location) {
    self.currentStop = [StopDistance new];
    _currentMode = TripModeNone;

    self.currentStop.stopId = XML_NON_NULL_ATR_STR(@"locid");
    self.currentStop.desc = XML_NON_NULL_ATR_STR(@"desc");
    self.currentStop.dir = XML_NON_NULL_ATR_STR(@"dir");

    self.currentStop.location = XML_ATR_LOCATION(@"lat", @"lng");

    self.currentStop.distanceMeters =
        [self.location distanceFromLocation:self.currentStop.location];

    if (self.includeRoutesInStops) {
        self.currentStop.routes = [NSMutableArray array];
    }
}

XML_START_ELEMENT(route) {
    NSString *type = XML_NON_NULL_ATR_STR(@"type");
    NSString *number = XML_NON_NULL_ATR_STR(@"route");

    if (self.includeRoutesInStops && self.currentStop.routes) {
        NSString *desc = XML_NON_NULL_ATR_STR(@"desc");

        if (desc) {
            Route *route = [Route new];
            route.desc = desc;
            route.routeId = number;
            [self.currentStop.routes addObject:route];
        }
    } else {
        // Route 98 is the MAX Shuttle and makes all max trains look like bus
        // stops
        if (number.intValue != 98) {
            switch ([type characterAtIndex:0]) {
            case 'R':
            case 'r':
                switch (_currentMode) {
                case TripModeNone:
                case TripModeTrainOnly:
                    _currentMode = TripModeTrainOnly;
                    break;

                case TripModeBusOnly:
                case TripModeAll:
                default:
                    _currentMode = TripModeAll;
                    break;
                }

                break;

            case 'B':
            case 'b':
                switch (_currentMode) {
                case TripModeNone:
                case TripModeBusOnly:
                    _currentMode = TripModeBusOnly;
                    break;

                case TripModeTrainOnly:
                case TripModeAll:
                default:
                    _currentMode = TripModeAll;
                    break;
                }
                break;

            default:
                _currentMode = TripModeAll;
                break;
            }
        }

        if (self.routeStore != nil && [self modeMatch:_currentMode
                                               second:_mode]) {
            NSString *xmlRoute = XML_NON_NULL_ATR_STR(@"route");

            RouteDistance *rd = self.routeStore[xmlRoute];

            if (rd == nil) {
                NSString *desc = XML_NON_NULL_ATR_STR(@"desc");

                rd = [RouteDistance new];
                rd.desc = desc;
                rd.type = type;
                rd.route = xmlRoute;

                self.routeStore[xmlRoute] = rd;
            }

            [rd.stops addObject:self.currentStop];
        }
    }
}

XML_START_ELEMENT(dir) {
    if (self.includeRoutesInStops && self.currentStop &&
        self.currentStop.routes) {
        NSString *dir = XML_NON_NULL_ATR_STR(@"dir");
        NSString *desc = XML_NON_NULL_ATR_STR(@"desc");

        if (dir != nil & desc != nil) {
            Route *route = self.currentStop.routes.lastObject;
            route.directions[dir] = [Direction withDir:dir desc:desc];
        }
    }
}

XML_END_ELEMENT(location) {
    if ([self modeMatch:_currentMode second:_mode]) {
        [self addItem:self.currentStop];
    }

    self.currentStop = nil;
}

@end

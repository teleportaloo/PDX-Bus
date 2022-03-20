//
//  XMLRoutes.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLRoutes.h"
#import "NSDictionary+Types.h"
#import "TriMetXMLSelectors.h"
#include <stdlib.h>
#include "CLLocation+Helper.h"
#import "NSString+Helper.h"

static NSString *routesURLString = @"routeConfig";
static NSString *routesAndDirsURLString = @"routeConfig/dir/true";
static NSString *someRoutesURLString = @"routeConfig/routes/%@/dir/true";
static NSString *someRoutesWithStops = @"routeConfig/routes/%@/dir/true/stops/true";


@interface XMLRoutes ()

@property (nonatomic, strong) Route *currentRouteObject;
@property (nonatomic, strong) Direction *currentDirectionObject;

@end

@implementation XMLRoutes

#pragma mark Data fetchers

- (NSDictionary<NSString *, Stop *>*)getAllRailStops {
    PtrConstRouteInfo info = nil;
    NSMutableDictionary<NSString *, Stop *> *allStops = [NSMutableDictionary dictionary];
    
    NSMutableArray *railRoutes = [NSMutableArray array];
    
    for (info = TriMetInfo.allColoredLines; info->short_name!=nil; info++) {
        if (info->hasStops) {
            [railRoutes addObject:[NSString stringWithFormat:@"%ld", (long)info->route_number]];
        }
    }
    
    [self getStops:[NSString commaSeparatedStringFromStringEnumerator:railRoutes] cacheAction:TriMetXMLNoCaching];
    
    if (self.gotData)
    {
        for (Route *route in self)
        {
            [route.directions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Direction * _Nonnull direction, BOOL * _Nonnull stopLoop) {
                for (Stop *stop in direction.stops)
                {
                    allStops[stop.stopId] = stop;
                }
            }];
        }
    }
    
    return allStops;
}

+ (NSDictionary<NSString *, Stop *>*)getAllRailStops
{
    XMLRoutes *routes = [XMLRoutes xml];
    return routes.getAllRailStops;
}

- (BOOL)getAllDirectionsCacheAction:(CacheAction)cacheAction {
    return [self startParsing:routesAndDirsURLString cacheAction:cacheAction];
}

- (BOOL)getRoutesCacheAction:(CacheAction)cacheAction {
    return [self startParsing:routesURLString cacheAction:cacheAction];
}

- (BOOL)getDirections:(NSString *)route cacheAction:(CacheAction)cacheAction {
    return [self startParsing:[NSString stringWithFormat:someRoutesURLString, route] cacheAction:cacheAction];
}

- (BOOL)getStops:(NSString *)route cacheAction:(CacheAction)cacheAction {
    return [self startParsing:[NSString stringWithFormat:someRoutesWithStops, route] cacheAction:cacheAction];
}

#pragma mark Parser callbacks

#pragma mark Start Elements

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(route) {
    self.currentRouteObject = [Route new];
    
    self.currentRouteObject.route           = XML_NON_NULL_ATR_STR(@"route");
    self.currentRouteObject.desc            = XML_NON_NULL_ATR_STR(@"desc");
    self.currentRouteObject.routeSortOrder  = XML_ATR_INT(@"routeSortOrder");
    
    if (XML_NULLABLE_ATR_STR(@"frequentService"))
    {
        self.currentRouteObject.frequentService = @(XML_ATR_BOOL_DEFAULT_FALSE(@"frequentService"));
    }
    
    
    NSString *color = XML_NULLABLE_ATR_STR(@"routeColor");
    
    if (color)
    {
        self.currentRouteObject.routeColor = strtol([color UTF8String], nil, 16);
    }
}

XML_START_ELEMENT(dir) {
    self.currentDirectionObject = [Direction new];
    self.currentDirectionObject.dir = XML_NON_NULL_ATR_STR(@"dir");
    self.currentDirectionObject.desc = XML_NON_NULL_ATR_STR(@"desc");
    self.currentRouteObject.directions[self.currentDirectionObject.dir] = self.currentDirectionObject;
}


XML_START_ELEMENT(stop) {
    Stop *stop = [Stop new];
    
    stop.stopId = XML_NON_NULL_ATR_STR(@"locid");
    stop.desc = XML_NON_NULL_ATR_STR(@"desc");
    stop.timePoint = XML_ATR_BOOL_DEFAULT_FALSE(@"tp");
    stop.location = XML_ATR_LOCATION(@"lat", @"lng");
    stop.dir = XML_NON_NULL_ATR_STR(@"dir");
    
    if (self.currentDirectionObject)
    {
        if (self.currentDirectionObject.stops == nil)
        {
            self.currentDirectionObject.stops = [NSMutableArray array];
        }
        [self.currentDirectionObject.stops addObject:stop];
    }
    stop.index = self.currentDirectionObject.stops.count;
}



#pragma mark End Elements

XML_END_ELEMENT(route) {
    [self addItem:self.currentRouteObject];
    self.currentRouteObject = nil;
}

@end

//
//  Route.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Route.h"
#import "DebugLogging.h"
#import "TriMetInfo.h"
#import "NSDictionary+Types.h"
#import "TriMetXML.h"
#import "TriMetXMLSelectors.h"

#define DEBUG_LEVEL_FOR_FILE LogData

@interface Route () {
    const TriMetInfo_Route *_col;
}

@end

@implementation Route

+ (instancetype)systemWide:(NSNumber *)detourId {
    Route *route = [Route new];

    route.routeId = [NSString
        stringWithFormat:@"%@ %d", kSystemWideRouteId, detourId.intValue];
    route.desc = kSystemWideDetour;
    return route;
}

- (bool)systemWide {
    return [self.routeId hasPrefix:kSystemWideRouteId];
}

- (NSInteger)systemWideId {
    if (self.routeId.length >= (kSystemWideRouteId.length + 1)) {
        return [self.routeId substringFromIndex:(kSystemWideRouteId.length + 1)]
            .integerValue;
    }

    return 0;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.directions = [NSMutableDictionary dictionary];
        _col = nil;
    }
    return self;
}

- (PtrConstRouteInfo)rawColor {
    // Placeholder - the address is used to signify no raw color
    static const TriMetInfo_Route noRoute;

    if (_col == &noRoute) {
        return nil;
    } else if (_col == nil) {
        _col = [TriMetInfo infoForRoute:self.routeId];
        if (_col == nil) {
            _col = &noRoute;
            return nil;
        }
    }

    return _col;
}

- (NSUInteger)hash {
    return self.routeId.hash;
}

- (BOOL)isEqualToRoute:(Route *)route {
    if (!route) {
        return NO;
    }
    return [self.routeId isEqual:route.routeId];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[Route class]]) {
        return NO;
    }

    return [self isEqualToRoute:(Route *)object];
}

- (NSComparisonResult)compare:(Route *)route2 {
    bool system1 = self.systemWide;
    bool system2 = route2.systemWide;

    if (system1 && system2) {
        DEBUG_LOG_ulong(self.systemWideId);
        DEBUG_LOG_ulong(route2.systemWideId);
        return self.systemWideId - route2.systemWideId;
    }

    if (system1) {
        return NSOrderedAscending;
    }

    if (system2) {
        return NSOrderedDescending;
    }

    if (self.routeSortOrder != 0 && route2.routeSortOrder != 0) {
        return self.routeSortOrder - route2.routeSortOrder;
    }

    NSString *r1 = self.routeId;
    NSString *r2 = route2.routeId;

    PtrConstRouteInfo c1 = self.rawColor;
    PtrConstRouteInfo c2 = route2.rawColor;

    if (c1 == nil && c2 == nil) {
        return r1.integerValue - r2.integerValue;
    } else if (c1 == nil && c2 != nil) {
        return NSOrderedDescending;
    }

    else if (c1 != nil && c2 == nil) {
        return NSOrderedAscending;
    }

    return c1->sort_order - c2->sort_order;
}

+ (Route *)fromAttributeDict:(NSDictionary *)XML_ATR_DICT {
    Route * route = [Route new];
    
    route.routeId = XML_NON_NULL_ATR_STR(@"route");
    route.desc = XML_NON_NULL_ATR_STR(@"desc");
    route.routeSortOrder = XML_ATR_INT(@"routeSortOrder");

    if (XML_NULLABLE_ATR_STR(@"frequentService")) {
        route.frequentService =
            @(XML_ATR_BOOL_DEFAULT_FALSE(@"frequentService"));
    }

    NSString *color = XML_NULLABLE_ATR_STR(@"routeColor");

    if (color) {
        route.routeColor =
            strtol([color UTF8String], nil, 16);
    }
    
    return route;
}

@end

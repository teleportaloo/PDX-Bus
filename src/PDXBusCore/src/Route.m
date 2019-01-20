//
//  Route.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Route.h"
#import "TriMetInfo.h"
#import "DebugLogging.h"


@implementation Route

+ (instancetype)systemWide:(NSNumber *)detourId
{
    Route *route = [Route data];
    route.route = [NSString stringWithFormat:@"%@ %d", kSystemWideRouteId, detourId.intValue];
    route.desc = kSystemWideDetour;
    return route;
}

- (bool)systemWide
{
    return [self.route hasPrefix:kSystemWideRouteId];
}


-(instancetype)init
{
    if ((self = [super init]))
    {
        self.directions = [NSMutableDictionary dictionary];
        _col = nil;
    }
    return self;
}

 -(PC_ROUTE_INFO )rawColor
{
    // Placeholder - the address is used to signify no raw color
    static const ROUTE_INFO noRoute;
    
    if (_col == &noRoute)
    {
        return nil;
    }
    else if (_col == nil)
    {
        _col = [TriMetInfo infoForRoute:self.route];
        if (_col == nil)
        {
            _col=&noRoute;
            return nil;
        }
    }
    return _col;
}

- (NSUInteger)hash
{
    return self.route.hash;
}

- (BOOL)isEqualToRoute:(Route*)route
{
    if (!route)
    {
        return NO;
    }
    return  [self.route isEqual:route.route];
}

- (BOOL)isEqual:(id)object
{
    if (self==object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:[Route class]])
    {
        return NO;
    }
    
    return [self isEqualToRoute:(Route*)object];
}

- (NSComparisonResult)compare:(Route *)route2
{
    if (self.systemWide)
    {
        return NSOrderedAscending;
    }
    
    if (route2.systemWide)
    {
        return NSOrderedDescending;
    }
    
    NSString *r1 = self.route;
    NSString *r2 = route2.route;
    
    PC_ROUTE_INFO c1 = self.rawColor;
    PC_ROUTE_INFO c2 = route2.rawColor;
    
    if (c1 == nil && c2 == nil)
    {
        return r1.integerValue - r2.integerValue;
    }
    else if (c1 == nil && c2 != nil)
    {
        return NSOrderedDescending;
    }
    else if (c1 !=nil && c2 == nil)
    {
        return NSOrderedAscending;
    }
    return c1->sort_order - c2->sort_order;
}

@end

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
#import "RouteDistance.h"
#import "CLLocation+Helper.h"


@implementation XMLLocateStops



#pragma mark Data fetchers


- (BOOL)findNearestStops
{
    NSString *query = [NSString stringWithFormat:@"stops/ll/%f,%f%@%@%@",
                       self.location.coordinate.longitude, self.location.coordinate.latitude,  
                       (self.minDistance > 0.0 ? [NSString stringWithFormat:@"/meters/%f", self.minDistance] : @""), 
                       ((self.mode!=TripModeAll || self.includeRoutesInStops )? @"/showRoutes/true": @""),
                       self.includeRoutesInStops ? @"/showRouteDirs/true": @""
                       ];
           
    bool res =  [self startParsing:query cacheAction:TriMetXMLNoCaching];
    
    if (_hasData)
    {
        [self.items sortUsingSelector:@selector(compareUsingDistance:)];
    }
    
    return res;
}


- (BOOL)findNearestRoutes
{
    NSString *query = [NSString stringWithFormat:@"stops/ll/%f,%f%@%@",
                       self.location.coordinate.longitude, self.location.coordinate.latitude,  
                       (self.minDistance > 0.0 ? [NSString stringWithFormat:@"/meters/%f", self.minDistance] : @""), 
                       @"/showRoutes/true"];
    
    self.routes = [NSMutableDictionary dictionary];
    
    
    bool res =  [self startParsing:query cacheAction:TriMetXMLNoCaching];
    
    if (_hasData)
    {
        // We don't care about the stops stored in the array! We ditch 'em and replace with 
        // a sorted routes kinda thing.
        
        self.items = [NSMutableArray array];
        
        [self.items addObjectsFromArray:self.routes.allValues];
        
        // We are done with this dictionary now may as well deference it.
        self.routes = nil;
        
        for (RouteDistance *rd in self.items)
        {
            [rd sortStopsByDistance]; 
            
            // Truncate array - this can get far too big
            while (rd.stops.count > self.maxToFind)
            {
                [rd.stops removeLastObject];
            }
        }
        
        [self.items sortUsingSelector:@selector(compareUsingDistance:)];
    }
    
    return res;
}


#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (bool)modeMatch:(TripMode)first second:(TripMode)second
{
    if (first == second)
    {
        return true;
    }
    
    if (first == TripModeAll || second == TripModeAll)
    {
        return true;    
    }
        
    return false;
}

XML_START_ELEMENT(resultset)
{
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(location)
{
    self.currentStop = [StopDistance data];
    _currentMode = TripModeNone;
    
    self.currentStop.locid = ATRSTR(locid);
    self.currentStop.desc  = ATRSTR(desc);
    self.currentStop.dir   = ATRSTR(dir);
    
    self.currentStop.location = ATRLOC(lat,lng);
    
    self.currentStop.distance = [self.location distanceFromLocation:self.currentStop.location];
    
    if (self.includeRoutesInStops)
    {
        self.currentStop.routes = [NSMutableArray array];
    }
}

XML_START_ELEMENT(route)
{
    NSString *type   = ATRSTR(type);
    NSString *number = ATRSTR(route);
    
    if (self.includeRoutesInStops && self.currentStop.routes)
    {
        NSString *desc = ATRSTR(desc);
        if (desc)
        {
            Route *route = [Route data];
            route.desc = desc;
            [self.currentStop.routes addObject:route];
        }
    }
    else
    {
        
        // Route 98 is the MAX Shuttle and makes all max trains look like bus stops
        if (number.intValue!=98)
        {
            switch ([type characterAtIndex:0])
            {
                case 'R':
                case 'r':
                    switch (_currentMode)
                {
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
                    switch (_currentMode)
                {
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
        if (self.routes != nil && [self modeMatch:_currentMode second:_mode])
        {
            NSString *xmlRoute = ATRSTR(route);
            
            RouteDistance *rd = self.routes[xmlRoute];
            
            if (rd == nil)
            {
                NSString *desc = ATRSTR(desc);
                
                rd = [RouteDistance data];
                rd.desc = desc;
                rd.type = type;
                rd.route = xmlRoute;
                
                self.routes[xmlRoute] = rd;
            }
            
            [rd.stops addObject:self.currentStop];
        }
    }
}

XML_START_ELEMENT(dir)
{
    if (self.includeRoutesInStops && self.currentStop && self.currentStop.routes)
    {
        NSString *dir = ATRSTR(dir);
        NSString *desc = ATRSTR(desc);
        
        if (dir!=nil & desc!=nil)
        {
            Route *route = self.currentStop.routes.lastObject;
            route.directions[dir] = desc;
        }
    }
}


XML_END_ELEMENT(location)
{
    if ([self modeMatch:_currentMode second:_mode])
    {
        [self addItem:self.currentStop];
    }
    self.currentStop = nil;
}


@end

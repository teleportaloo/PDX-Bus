//
//  XMLStops.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStops.h"

static NSString *stopsURLString = @"routeConfig/route/%@/dir/%@/stops/true";

@implementation XMLStops


#pragma mark Data fetchers

- (BOOL)getStopsAfterLocation:(NSString *)locid route:(NSString *)route direction:(NSString *)dir 
                  description:(NSString *)desc cacheAction:(CacheAction)cacheAction
{
    self.routeId = route;
    self.direction = dir;
    self.routeDescription = desc;
    self.afterStop = locid;
    
    return [self startParsing:[NSString stringWithFormat:stopsURLString, route, dir] cacheAction:cacheAction];
    
}

- (BOOL)getStopsForRoute:(NSString *)route direction:(NSString *)dir 
             description:(NSString *)desc cacheAction:(CacheAction)cacheAction
{    
    self.routeId = route;
    self.direction = dir;
    self.routeDescription = desc;
    self.afterStop = nil;
    
    return [self startParsing:[NSString stringWithFormat:stopsURLString, route, dir] cacheAction:cacheAction];
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (NSString*)fullAddressForQuery:(NSString *)query
{
    NSString *str = nil;
    
    if (self.staticQuery !=nil)
    {
        str = self.staticQuery;
    }
    else
    {
        str = [super fullAddressForQuery:query];
    }
    
    return str;
    
}

XML_START_ELEMENT(resultset)
{
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(stop)
{
    NSString *locid = ATRSTR(locid);
    
    if (self.afterStop !=nil && [locid isEqualToString:self.afterStop])
    {
        self.afterStop = nil;
        self.currentStopObject = nil;
    }
    else if (self.afterStop == nil)
    {
        self.currentStopObject = [Stop data];
        
        self.currentStopObject.locid =    ATRSTR(locid);
        self.currentStopObject.desc =    ATRSTR(desc);
        self.currentStopObject.tp =        ATRBOOL(tp);
        self.currentStopObject.lat =    ATRSTR(lat);
        self.currentStopObject.lng =    ATRSTR(lng);
    }
}

XML_END_ELEMENT(stop)
{
    if (self.currentStopObject !=nil)
    {
        [self addItem:self.currentStopObject];
        self.currentStopObject.index = (int)self.items.count;
        self.currentStopObject = nil;
    }
}

@end

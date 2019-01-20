//
//  XMLRoutes.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLRoutes.h"

//static NSString *routesURLString = @"routeConfig/dir/true";
static NSString *routesURLString = @"routeConfig";
static NSString *oneRouteURLString = @"routeConfig/route/%@/dir/true";

@implementation XMLRoutes


#pragma mark Data fetchers

- (BOOL)getRoutesCacheAction:(CacheAction)cacheAction;
{    
    return [self startParsing:routesURLString cacheAction:cacheAction];
}

- (BOOL)getDirections:(NSString *)route cacheAction:(CacheAction)cacheAction
{    
    return [self startParsing:[NSString stringWithFormat:oneRouteURLString, route] cacheAction:cacheAction];
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

#pragma mark Start Elements

XML_START_ELEMENT(resultset)
{
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(route)
{
    self.currentRouteObject = [Route data];
    
    self.currentRouteObject.route = ATRSTR(route);
    self.currentRouteObject.desc =  ATRSTR(desc);
}

XML_START_ELEMENT(dir)
{
    self.currentRouteObject.directions[ATRSTR(dir)] = ATRSTR(desc);
}

#pragma mark End Elements

XML_END_ELEMENT(route)
{
    [self addItem:self.currentRouteObject];
    self.currentRouteObject = nil;
}

@end

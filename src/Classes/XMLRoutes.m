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

@synthesize currentRouteObject = _currentRouteObject;

- (void)dealloc
{
	self.currentRouteObject = nil;	
	[super dealloc];
}

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

START_ELEMENT(resultset)
{
    [self initArray];
    _hasData = YES;
}

START_ELEMENT(route)
{
    self.currentRouteObject = [Route data];
    
    self.currentRouteObject.route = ATRVAL(route);
    self.currentRouteObject.desc =  ATRVAL(desc);
}

START_ELEMENT(dir)
{
    self.currentRouteObject.directions[ATRVAL(dir)] = ATRVAL(desc);
}

#pragma mark End Elements

END_ELEMENT(route)
{
    [self addItem:self.currentRouteObject];
    self.currentRouteObject = nil;
}

@end

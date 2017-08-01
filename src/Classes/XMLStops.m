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

@synthesize currentStopObject = _currentStopObject;
@synthesize routeId				= _routeId;
@synthesize direction			= _direction;
@synthesize routeDescription	= _routeDescription;
@synthesize afterStop			= _afterStop;
@synthesize staticQuery         = _staticQuery;

- (void)dealloc
{
	self.currentStopObject = nil;
	self.direction = nil;
	self.routeId = nil;
	self.routeDescription = nil;
	self.afterStop = nil;
    self.staticQuery = nil;
	[super dealloc];
	
}

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

START_ELEMENT(resultset)
{
    [self initArray];
    _hasData = YES;
}

START_ELEMENT(stop)
{
    NSString *locid = ATRVAL(locid);
    
    if (self.afterStop !=nil && [locid isEqualToString:self.afterStop])
    {
        self.afterStop = nil;
        self.currentStopObject = nil;
    }
    else if (self.afterStop == nil)
    {
        self.currentStopObject = [Stop data];
        
        self.currentStopObject.locid =	ATRVAL(locid);
        self.currentStopObject.desc =	ATRVAL(desc);
        self.currentStopObject.tp =		ATRBOOL(tp);
        self.currentStopObject.lat =	ATRVAL(lat);
        self.currentStopObject.lng =    ATRVAL(lng);
    }
}

END_ELEMENT(stop)
{
    if (self.currentStopObject !=nil)
    {
        [self addItem:self.currentStopObject];
        self.currentStopObject.index = (int)self.itemArray.count;
        self.currentStopObject = nil;
    }
}

@end

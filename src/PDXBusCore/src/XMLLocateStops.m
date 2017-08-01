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
#import "RouteDistanceData.h"


@implementation XMLLocateStops

@synthesize currentStop = _currentStop;
@synthesize location    = _location;
@synthesize mode        = _mode;
@synthesize maxToFind   = _maxToFind;
@synthesize minDistance = _minDistance;
@synthesize routes      = _routes;


- (void)dealloc
{
	self.currentStop = nil;	
	self.location = nil;
	self.routes = nil;
	[super dealloc];
}


#pragma mark Data fetchers


- (BOOL)findNearestStops
{
	NSString *query = [NSString stringWithFormat:@"stops/ll/%f,%f%@%@",
					   self.location.coordinate.longitude, self.location.coordinate.latitude,  
					   (self.minDistance > 0.0 ? [NSString stringWithFormat:@"/meters/%f", self.minDistance] : @""), 
					   (self.mode!=TripModeAll ? @"/showRoutes/true": @"")];
		   
	bool res =  [self startParsing:query cacheAction:TriMetXMLNoCaching];
	
	if (_hasData)
	{
		[_itemArray sortUsingSelector:@selector(compareUsingDistance:)];
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
		
        self.itemArray = [NSMutableArray array];
		
		[_itemArray addObjectsFromArray:self.routes.allValues];
		
		// We are done with this dictionary now may as well deference it.
		self.routes = nil;
		
		for (RouteDistanceData *rd in self.itemArray)
		{
			[rd sortStopsByDistance]; 
			
			// Truncate array - this can get far too big
			while (rd.stops.count > self.maxToFind)
			{
				[rd.stops removeLastObject];
			}
		}
		
		[_itemArray sortUsingSelector:@selector(compareUsingDistance:)];
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

START_ELEMENT(resultset)
{
    [self initArray];
    _hasData = YES;
}

START_ELEMENT(location)
{
    self.currentStop = [[[StopDistanceData alloc] init] autorelease];
    _currentMode = TripModeNone;
    
    self.currentStop.locid = ATRVAL(locid);
    self.currentStop.desc  = ATRVAL(desc);
    self.currentStop.dir   = ATRVAL(dir);
    
    self.currentStop.location = [[[CLLocation alloc] initWithLatitude:ATRCOORD(lat)
                                                            longitude:ATRCOORD(lng) ] autorelease];
    
    self.currentStop.distance = [self.location distanceFromLocation:self.currentStop.location];
}

START_ELEMENT(route)
{
    NSString *type   = ATRVAL(type);
    NSString *number = ATRVAL(route);
    
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
        NSString *xmlRoute = ATRVAL(route);
        
        RouteDistanceData *rd = self.routes[xmlRoute];
        
        if (rd == nil)
        {
            NSString *desc = ATRVAL(desc);
            
            rd = [RouteDistanceData data];
            rd.desc = desc;
            rd.type = type;
            rd.route = xmlRoute;
            
            self.routes[xmlRoute] = rd;
        }
        
        [rd.stops addObject:self.currentStop];
    }
}

END_ELEMENT(location)
{
    if ([self modeMatch:_currentMode second:_mode])
    {
        [self addItem:self.currentStop];
    }
    self.currentStop = nil;
}


@end

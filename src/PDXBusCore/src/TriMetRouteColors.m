//
//  TriMetRouteColors.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetRouteColors.h"
#import <UIKit/UIKit.h>
#import "DebugLogging.h"

@implementation TriMetRouteColors

#define RGB(R,G,B) ((CGFloat)R)/255.0, ((CGFloat)G)/255.0, ((CGFloat)B)/255.0
#define RGB_RED   RGB(255,  0,  0)
#define RGB_WHITE RGB(255,255,255)

// These must be in route order and the lines also in order so a binary search works on both!
static const ROUTE_COL routeColours[] =
{
    { 90,       kRedLine,           RGB(211, 31, 67),   RGB_WHITE,  @"MAX_Red_Line",				@"MAX Red Line",                @"MAX",       NO },		// Red line
	{ 100,      kBlueLine,          RGB( 15,106,172),   RGB_RED,    @"MAX_Blue_Line",				@"MAX Blue Line",               @"MAX",       NO },		// Blue Line
    { 190,      kYellowLine,        RGB(255,197, 36),   RGB_RED,    @"MAX_Yellow_Line",				@"MAX Yellow Line",             @"MAX",       NO },		// Yellow line
    { 193,      kStreetcarNsLine,	RGB(140,198, 63),	RGB_WHITE,  @"Portland_Streetcar",			@"Portland Streetcar - NS Line",@"NS Line",   YES},     // Streetcar Green
    { 194,      kStreetcarALoop,	RGB(224, 29,144),	RGB_WHITE,  @"Portland_Streetcar",			@"Portland Streetcar - A Loop", @"A Loop",    YES},     // Streetcar Blue
    { 195,      kStreetcarBLoop,    RGB(  0,169,204),	RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    YES},     // Streetcar Pink
    { 200,      kGreenLine,         RGB(  2,137, 83),   RGB_WHITE,  @"MAX_Green_Line",				@"MAX Green Line",              @"MAX",       NO },		// Green Line
	{ 203,      kWesLine,           RGB(  0,  0,  0),   RGB_WHITE,  @"Westside_Express_Service",	@"WES Commuter Rail",           @"WES",       NO },		// WES Black
    { 290,      kOrangeLine,        RGB(209, 95, 39),	RGB_WHITE,  @"MAX_Orange_Line",			    @"MAX Orange Line",             @"MAX",       NO },     // MAX Orange
	{ kNoRoute,	kNoLine,            RGB(  0,  0,  0),   RGB_WHITE,  nil,							nil,                            nil,          NO }      // Terminator
};

int compareRoute(const void *first, const void *second)
{    
    return (int)(((ROUTE_COL*)first)->route - ((ROUTE_COL*)second)->route);
}

int compareLine(const void *first, const void *second)
{
    return (int)((int)((ROUTE_COL*)first)->line - (int)((ROUTE_COL*)second)->line);
}

#define ROUTES ((sizeof(routeColours)/sizeof(routeColours[0]))-1)

+ (const ROUTE_COL*)rawColorForLine:(RAILLINES)line
{
    ROUTE_COL col = {0,line,0,0,0,0,0,0, nil, nil, nil, NO};
    
    return bsearch(&col, routeColours, ROUTES, sizeof(ROUTE_COL), compareLine);
}

+ (const ROUTE_COL*)rawColorForRoute:(NSString *)route
{
	ROUTE_COL col = {route.integerValue,0,0,0,0,0,0,0, nil, nil, nil, NO};
	
	return bsearch(&col, routeColours, ROUTES, sizeof(ROUTE_COL), compareRoute);
}

+ (UIColor*)colorForRoute:(NSString *)route
{
	const ROUTE_COL *col= [TriMetRouteColors rawColorForRoute:route];
	
	if (col == nil)
	{
		return nil;
	}
	return [UIColor colorWithRed:col->r green:col->g blue:col->b alpha:1.0];
}

+ (UIColor*)colorForLine:(RAILLINES)line
{
	const ROUTE_COL *col = [TriMetRouteColors rawColorForLine:line];
	return [UIColor colorWithRed:col->r green:col->g blue:col->b alpha:1.0];
}

+ (NSSet *)streetcarRoutes
{
    NSMutableSet *routes = [NSMutableSet set];
    
    const ROUTE_COL *col;
    
    for (col = routeColours; col->route!=kNoRoute; col++)
    {
        if (col->square)
        {
            [routes addObject:[TriMetRouteColors routeString:col]];
        }
    }
    
    return routes;
}

+ (NSSet *)triMetRoutes
{
    NSMutableSet *routes = [NSMutableSet set];
    
    const ROUTE_COL *col;
    
    for (col = routeColours; col->route!=kNoRoute; col++)
    {
        if (!col->square)
        {
            [routes addObject:[TriMetRouteColors routeString:col]];
        }
    }
    
    return routes;
}

+ (NSString*)routeString:(const ROUTE_COL*)col
{
    return [NSString stringWithFormat:@"%ld",(long)col->route];
}

@end

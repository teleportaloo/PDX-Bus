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


@implementation TriMetRouteColors


#define RGB(R,G,B) ((CGFloat)R)/255.0, ((CGFloat)G)/255.0, ((CGFloat)B)/255.0
#define RGB_RED   RGB(255,  0,  0)
#define RGB_WHITE RGB(255,255,255)


static ROUTE_COL routeColours[] = 
{
	{ @"100",	kBlueLine,          RGB( 15,106,172),   RGB_RED,    @"MAX_Blue_Line",				@"MAX Blue Line",               @"MAX",       NO},		// Blue Line
	{ @"200",	kGreenLine,         RGB(  2,137, 83),   RGB_WHITE,  @"MAX_Green_Line",				@"MAX Green Line",              @"MAX",       NO},		// Green Line
	{ @"90",	kRedLine,           RGB(211, 31, 67),   RGB_WHITE,  @"MAX_Red_Line",				@"MAX Red Line",                @"MAX",       NO},		// Red line
	{ @"190",	kYellowLine,        RGB(255,197, 36),   RGB_RED,    @"MAX_Yellow_Line",				@"MAX Yellow Line",             @"MAX",       NO},		// Yellow line
	{ @"203",	kWesLine,           RGB(  0,  0,  0),   RGB_WHITE,  @"Westside_Express_Service",	@"WES Commuter Rail",           @"WES",       NO},		// WES Black
	{ @"193",	kStreetcarNsLine,	RGB(140,198, 63),	RGB_RED,    @"Portland_Streetcar",			@"Portland Streetcar - NS Line",@"NS Line",   YES},     // Streetcar Green
    { @"194",	kStreetcarALoop,	RGB(224, 29,144),	RGB_RED,    @"Portland_Streetcar",			@"Portland Streetcar - A Loop", @"A Loop",    YES},     // Streetcar Blue
    { @"290",	kOrangeLine,        RGB(209, 95, 39),	RGB_RED,    @"MAX_Orange_Line",			    @"MAX Orange Line",             @"MAX",       NO},      // MAX Orange
    { @"195",   kStreetcarBLoop,    RGB(0,  169,204),	RGB_RED,    @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    YES},     // Streetcar Pink
	{ nil,		0,				0,	0,	0,	0, 0, 0, nil,							nil}
};

+ (ROUTE_COL*)rawColorForLine:(RAILLINES)line
{
	ROUTE_COL *col;
	
	for (col = routeColours; col->route!=nil; col++)
	{
		if (col->line == line)
		{
			return col;
		}
	}
	return nil;
	
}

+ (ROUTE_COL*)rawColorForRoute:(NSString *)route
{
	ROUTE_COL *col;
	
	for (col = routeColours; col->route!=nil; col++)
	{
		if ([col->route isEqualToString:route])
		{
			return col;
		}
	}
	return nil;
	
}

+ (UIColor*)colorForRoute:(NSString *)route
{
	ROUTE_COL *col= [TriMetRouteColors rawColorForRoute:route];
	
	if (col == nil)
	{
		return nil;
	}
	return [UIColor colorWithRed:col->r green:col->g blue:col->b alpha:1.0];
	
}

+ (UIColor*)colorForLine:(RAILLINES)line
{
	
	ROUTE_COL *col = [TriMetRouteColors rawColorForLine:line];
	return [UIColor colorWithRed:col->r green:col->g blue:col->b alpha:1.0];
}

@end

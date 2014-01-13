//
//  TriMetRouteColors.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

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
	{ @"193",	kStreetcarNsLine,	RGB(140,198, 63),	RGB_RED,    @"Portland_Streetcar",			@"Portland Streetcar - NS Line", @"NS Line", YES},	// Streetcar Green
    { @"194",	kStreetcarClLine,	RGB(0,  169,204),	RGB_RED,    @"Portland_Streetcar",			@"Portland Streetcar - CL Line", @"CL Line", YES},	// Streetcar Blue

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

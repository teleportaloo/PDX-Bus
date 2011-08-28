//
//  RouteDistance.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
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

#import "RouteDistance.h"
#import "StopDistance.h"
#import "ScreenConstants.h"
#import "RouteColorBlobView.h"


@implementation RouteDistance

@synthesize desc = _desc;
@synthesize type = _type;
@synthesize route = _route;
@synthesize stops = _stops;

- (id)init
{
	if ((self = [super init]))
	{	
		self.stops = [[[NSMutableArray alloc] init] autorelease];
	}
	return self;
}

-(void)dealloc
{
	self.desc = nil;
	self.type = nil;
	self.route = nil;
	self.stops = nil;
	
	[super dealloc];
}



-(void)sortStopsByDistance
{
	[_stops sortUsingSelector:@selector(compareUsingDistance:)];
}

-(NSComparisonResult)compareUsingDistance:(RouteDistance*)inRoute
{
	StopDistance *stop =   [self.stops objectAtIndex:0];
	StopDistance *inStop = [inRoute.stops objectAtIndex:0];
	
	
	if (stop.distance < inStop.distance)
	{
		return NSOrderedAscending;
	}

	if (stop.distance > inStop.distance)
	{
		return NSOrderedDescending;
	}

	return NSOrderedSame;
}

#pragma mark -
#pragma mark Cells

#define ROUTE_TAG 1
#define TIME_TAG  2
#define BIG_MINS_TAG  3
#define BIG_UNIT_TAG 4
#define COLOR_STRIPE_TAG 5



- (UILabel*)label:(UITableViewCell*)cell tag:(NSInteger)tag
{
	return ((UILabel*)[cell.contentView viewWithTag:tag]);
}

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
	return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
	CGFloat LEFT_COLUMN_OFFSET			= 11.0;
	CGFloat LEFT_COLUMN_WIDTH			= 280.0;
	
	CGFloat MAIN_FONT_SIZE				= 18.0;
	CGFloat LABEL_HEIGHT				= 26.0;
	CGFloat TIME_FONT_SIZE				= 14.0;	
	CGFloat ROW_HEIGHT					= kRouteCellHeight;
	CGFloat ROW_GAP  = ((ROW_HEIGHT - LABEL_HEIGHT - LABEL_HEIGHT) / 3.0);
	
	
	switch (width)
	{
        default:
		case WidthiPhoneNarrow:
			break;
			//case WidthiPhoneWide:
			//		MINS_LEFT					= 400.0;
			//		SHORT_LEFT_COLUMN_WIDTH     = 390.0;
			//		break;
		case WidthiPadWide:
		case WidthiPadNarrow:
			ROW_HEIGHT				= kRouteWideCellHeight;
			LEFT_COLUMN_OFFSET		= 16.0;
			LEFT_COLUMN_WIDTH		= 560.0;
			MAIN_FONT_SIZE			= 32.0;
			LABEL_HEIGHT			= 43.0;
			TIME_FONT_SIZE			= 28.0;
			
			ROW_GAP					= ((kRouteWideCellHeight - LABEL_HEIGHT - LABEL_HEIGHT) / 3.0);
			
			break;
	}
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
	
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, ROW_GAP, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = ROUTE_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	rect = CGRectMake(0, ROW_GAP, COLOR_STRIPE_WIDTH, LABEL_HEIGHT);
	RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
	colorStripe.tag = COLOR_STRIPE_TAG;
	[cell.contentView addSubview:colorStripe];
	[colorStripe release];
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET,ROW_GAP * 2.0 + LABEL_HEIGHT, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TIME_TAG;
	label.font = [UIFont systemFontOfSize:TIME_FONT_SIZE];
	label.textColor = [UIColor blueColor];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	
	return cell;
}

-(NSString *)formatDistance:(double)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:@"Distance: %d ft (%d meters)", (int)(distance * 3.2808398950131235),
			   (int)(distance) ];
	}
	else
	{
		str = [NSString stringWithFormat:@"Distance: %.2f miles (%.2f km)", (float)(distance / 1609.344),
			   (float)(distance / 1000) ];
	}	
	return str;
}


- (void)populateCell:(UITableViewCell *)cell wide:(BOOL)wide;
{
	cell.textLabel.text = nil;
	
	
	// cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	UILabel *routeLabel;
	UILabel *timeLabel;
	
	routeLabel = [self label:cell tag:ROUTE_TAG ];
	[self label:cell tag:TIME_TAG			].hidden = NO;
	[self label:cell tag:ROUTE_TAG			].hidden = NO;
	timeLabel = [self label:cell tag:TIME_TAG   ];
	timeLabel.text = [self formatDistance:((StopDistance*)[self.stops objectAtIndex:0]).distance];
	
	routeLabel.text = self.desc;
	
	
	[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@",
								 routeLabel.text, timeLabel.text]];
	routeLabel.textColor = [UIColor blackColor];

	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	[colorStripe setRouteColor:self.route];
}



@end

//
//  RouteDistanceUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RouteDistanceData+iOSUI.h"
#import "StopDistanceData.h"
#import "ScreenConstants.h"
#import "RouteColorBlobView.h"
#import "FormatDistance.h"

@implementation RouteDistanceData (iOSUI)

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

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width
{
	return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width
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
		case WidthiPhone:
			break;
			//case WidthiPhoneWide:
			//		MINS_LEFT					= 400.0;
			//		SHORT_LEFT_COLUMN_WIDTH     = 390.0;
			//		break;
		case WidthiPadWide:
        case WidthBigVariable:
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
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
	
	
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
	timeLabel.text = [FormatDistance formatMetres:self.stops.firstObject.distance];
	
	routeLabel.text = self.desc;
	
	
	cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
								 routeLabel.text, timeLabel.text];
	routeLabel.textColor = [UIColor blackColor];

	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	[colorStripe setRouteColor:self.route];
}



@end

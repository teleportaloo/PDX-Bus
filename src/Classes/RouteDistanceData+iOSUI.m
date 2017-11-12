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


- (void)populateCell:(DepartureCell *)cell
{
	// cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.routeLabel.text = self.desc;
    cell.timeLabel.text = [FormatDistance formatMetres:self.stops.firstObject.distance];
    cell.timeLabel.textColor = [UIColor blueColor];
	
	cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
								 cell.routeLabel.text, cell.timeLabel.text];
	cell.routeLabel.textColor = [UIColor blackColor];
	[cell.routeColorView setRouteColor:self.route];
}

@end

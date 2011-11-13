//
//  TripPlannerSummaryView.m
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

#import "TripPlannerSummaryView.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "UserFaves.h"
#import "TripPlannerEndPointView.h"
#import "TripPlannerOptions.h"
#import "TripPlannerDateView.h"
#import "TripPlannerLocatingView.h"

#define kRowsInTripSection			4
#define kTripSectionRowFrom			0
#define kTripSectionRowTo			1
#define kTripSectionRowOptions		2
#define kTripSectionRowTime			3
#define kTripSectionRowPlan			4

#define kSections					2
#define kSectionUserRequest			0
#define kSectionPlanTrip			1

#define kPlanTripSectionRows		1


#define kTripOptions @"option cell"
#define kTripId      @"trip id"


@implementation TripPlannerSummaryView


- (id)init
{
	if ((self = [super init]))
	{
		self.tripQuery = [[[XMLTrips alloc] init] autorelease];
		
		NSDictionary *lastTrip = _userData.lastTrip; 
		
		if (lastTrip !=nil)
		{
			TripUserRequest *req = [[TripUserRequest alloc] initFromDict:lastTrip];
			req.dateAndTime = nil;
			req.arrivalTime = NO;
			req.fromPoint.currentLocation   = nil;
			req.toPoint.currentLocation    = nil;
			req.timeChoice  = TripDepartAfterTime;
			self.tripQuery.userRequest = req;
            [req release];
		}
	}
	return self;
}

- (void)resetAction:(id)sender
{
	
	self.tripQuery = [[[XMLTrips alloc] init] autorelease];
	[self reloadData];
}

- (void)reverseAction:(id)sender
{
	TripEndPoint *savedFrom = [self.tripQuery.userRequest.fromPoint retain];
	self.tripQuery.userRequest.fromPoint =  self.tripQuery.userRequest.toPoint;
	self.tripQuery.userRequest.toPoint = savedFrom;
	[savedFrom release];
	[self reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Trip Planner";
	
	UIBarButtonItem *resetButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Reset", @"")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(resetAction:)];
	self.navigationItem.rightBarButtonItem = resetButton;
	[resetButton release];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_userData.lastTrip = [self.tripQuery.userRequest toDictionary];

}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	[self reloadData];
}
	
- (int)rowType:(NSIndexPath *)path
{
	if (path.section ==kSectionUserRequest)
	{
		return path.row;
	}
	return kTripSectionRowPlan;
}
	
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}
	
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section)
	{
		case kSectionUserRequest:
			return kRowsInTripSection;
		case kSectionPlanTrip:
			return kPlanTripSectionRows;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == kSectionUserRequest)
	{
		return @"Enter trip details:";
	}
	return nil;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (void)createToolbarItems
{	
	// create the system-defined "OK or Done" button
	UIBarButtonItem *reverse = [[[UIBarButtonItem alloc]
							   initWithTitle:@"Reverse trip" style:UIBarButtonItemStyleBordered 
							   target:self action:@selector(reverseAction:)] autorelease];
	
	
	NSArray *items = [NSArray arrayWithObjects: 
					  self.autoDoneButton, 
					  [CustomToolbar autoFlexSpace],
					  reverse,
					  [CustomToolbar autoFlexSpace],
					  self.autoFlashButton, 
					  nil];
	[self setToolbarItems:items animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;
	
	switch ([self rowType:indexPath])
	{
	case kTripSectionRowOptions:
		result = [TripLeg getTextHeight:[self.tripQuery.userRequest optionsDisplayText] 
								  width:[TripLeg bodyTextWidthForScreenWidth:[self screenWidth]]];
		break;
	case kTripSectionRowTo:
		result = [TripLeg getTextHeight:[self.tripQuery.userRequest.toPoint userInputDisplayText] 
								  width:[TripLeg bodyTextWidthForScreenWidth:[self screenWidth]]];
		break;
	case kTripSectionRowFrom:
		result = [TripLeg getTextHeight:[self.tripQuery.userRequest.fromPoint userInputDisplayText] 
								  width:[TripLeg bodyTextWidthForScreenWidth:[self screenWidth]]];
		break;
	case kTripSectionRowTime:
			result = [TripLeg getTextHeight:[self.tripQuery.userRequest getDateAndTime] 
									  width:[TripLeg bodyTextWidthForScreenWidth:[self screenWidth]]];
		break;
	case kTripSectionRowPlan:
			result = [self basicRowHeight];
			break;
	
	}	
	return result;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat h = [self tableView:[self table] heightForRowAtIndexPath:indexPath];
	NSString *cellIdentifier = [NSString stringWithFormat:@"TripLeg%f+%d", h,[self screenWidth]];
	
	switch([self rowType:indexPath])
	{
		case kTripSectionRowFrom:
		case kTripSectionRowTo:
		{
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:cellIdentifier 
													   rowHeight: h 
													 screenWidth: [self screenWidth]];
			}
			
			cell.accessoryType = UITableViewCellAccessoryNone;	
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			
			NSString *text;
			NSString *dir;
			
			if (indexPath.row == kTripSectionRowFrom)
			{
				text = [self.tripQuery.userRequest.fromPoint userInputDisplayText];
				dir = @"From";
				
			}
			else {
				text = [self.tripQuery.userRequest.toPoint userInputDisplayText];
				dir = @"To";
			}
			
			[TripLeg populateCell:cell body:text mode:dir time:nil leftColor:nil route:nil];
			return cell;
			
		}
		case kTripSectionRowOptions:
		{
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:kTripOptions];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:kTripOptions 
													   rowHeight: h 
													 screenWidth: [self screenWidth]];
			}
			
			cell.accessoryType = UITableViewCellAccessoryNone;	
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			
			[TripLeg populateCell:cell body:[self.tripQuery.userRequest optionsDisplayText] mode:@"Options" time:nil leftColor:nil route:nil];
			return cell;
		}
			
		case kTripSectionRowTime:
		{
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:kTripOptions];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:kTripOptions 
													   rowHeight: h 
													 screenWidth: [self screenWidth]];			}
			
			[TripLeg populateCell:cell body:[self.tripQuery.userRequest getDateAndTime] 
							 mode:[self.tripQuery.userRequest getTimeType] 
							 time:nil 
						leftColor:nil
							route:nil];

			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			return cell;	
		}
		case kTripSectionRowPlan:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTripId] autorelease];
			}
			
			// Set up the cell
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
			cell.textLabel.text = @"Show trip";
			cell.imageView.image = [self getActionIcon:kIconTripPlanner];
			return cell;
		}	

	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch([self rowType:indexPath])
	{		
		case kTripSectionRowFrom:
		case kTripSectionRowTo:
		{
			TripPlannerEndPointView *tripEnd = [[TripPlannerEndPointView alloc] init];
			
			
			tripEnd.from = (indexPath.row != kTripSectionRowTo) ;
			tripEnd.tripQuery = [[[XMLTrips alloc] init] autorelease];
			tripEnd.tripQuery.userRequest = self.tripQuery.userRequest;
			@synchronized (_userData)
			{
				[tripEnd.tripQuery addStopsFromUserFaves:_userData.faves];
			}
			tripEnd.popBackTo = self;
			// tripEnd.userRequestCallback = self;
			
			
			// Push the detail view controller
			[[self navigationController] pushViewController:tripEnd animated:YES];
			[tripEnd release];
			
			break;
		}
		case kTripSectionRowOptions:
		{
			TripPlannerOptions * options = [[ TripPlannerOptions alloc ] init];
			
			options.tripQuery = [[[XMLTrips alloc] init] autorelease];
			options.tripQuery.userRequest = self.tripQuery.userRequest;
			// options.userRequestCallback = self;
			
			[[self navigationController] pushViewController:options animated:YES];
			
			
			[options release];
			// _reloadTrip = YES;
			break;
			
		}
		case kTripSectionRowTime:
		{
			TripPlannerDateView * date = [[ TripPlannerDateView alloc ] init];
			date.tripQuery  = [[[XMLTrips alloc] init] autorelease];
			date.tripQuery.userRequest = self.tripQuery.userRequest;
			date.popBack = YES;
			
			[[self navigationController] pushViewController:date animated:YES];
			[date release];
			break;

		}
		case kTripSectionRowPlan:
		{
			if (self.tripQuery != nil 
					&& (self.tripQuery.userRequest.toPoint.useCurrentLocation || self.tripQuery.userRequest.toPoint.locationDesc!=nil)
					&& (self.tripQuery.userRequest.fromPoint.useCurrentLocation || self.tripQuery.userRequest.fromPoint.locationDesc!=nil))
			{
				_userData.lastTrip  = [self.tripQuery.userRequest toDictionary];
			
				TripPlannerLocatingView * locView = [[ TripPlannerLocatingView alloc ] init];
			
				locView.tripQuery = self.tripQuery;
			
				[locView nextScreen:[self navigationController] forceResults:NO postQuery:NO orientation:self.interfaceOrientation
					  taskContainer:self.backgroundTask];
			
				[locView release];
			}
			else {
				[self.table deselectRowAtIndexPath:indexPath animated:YES];
				
				UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Cannot continue"
																   message:@"Select a start and destination to plan a trip."
																  delegate:nil
														 cancelButtonTitle:@"OK"
														 otherButtonTitles:nil ] autorelease];
				[alert show];
			}

			break;
		}
	}
}
	
	
@end

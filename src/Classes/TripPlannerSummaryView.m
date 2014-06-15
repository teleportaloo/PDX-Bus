//
//  TripPlannerSummaryView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerSummaryView.h"
#import "UserFaves.h"
#import "TripPlannerEndPointView.h"
#import "TripPlannerOptions.h"
#import "TripPlannerDateView.h"
#import "TripPlannerLocatingView.h"
#import "TripPlannerCacheView.h"

#define kRowsInTripSection			4
#define kTripSectionRowFrom			0
#define kTripSectionRowTo			1
#define kTripSectionRowOptions		2
#define kTripSectionRowTime			3
#define kTripSectionRowPlan			4
#define kTripSectionRowHistory		5


#define kSections					3
#define kSectionUserRequest			0
#define kSectionPlanTrip			1
#define kSectionHistory             2


#define kPlanTripSectionRows		1
#define kHistorySectionRows         1


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
			req.fromPoint.coordinates   = nil;
			req.toPoint.coordinates     = nil;
			req.timeChoice  = TripDepartAfterTime;
            [req clearGpsNames];
           
			self.tripQuery.userRequest = req;
            [req release];
		}
	}
	return self;
}

- (void)initQuery
{
    [self.tripQuery addStopsFromUserFaves:_userData.faves];
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
	
- (NSInteger)rowType:(NSIndexPath *)path
{
    switch (path.section)
    {
        case kSectionUserRequest:
            return path.row;
        case kSectionPlanTrip:
            return kTripSectionRowPlan;
        case kSectionHistory:
            return kTripSectionRowHistory;
    }
    return 0;
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
        case kSectionHistory:
			return kHistorySectionRows;

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

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{	
	// create the system-defined "OK or Done" button
	UIBarButtonItem *reverse = [[[UIBarButtonItem alloc]
							   initWithTitle:@"Reverse trip" style:UIBarButtonItemStyleBordered
							   target:self action:@selector(reverseAction:)] autorelease];
	
	
	 [toolbarItems addObject:reverse];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
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
    case kTripSectionRowHistory:
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
        case kTripSectionRowHistory:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTripId] autorelease];
			}
			
			// Set up the cell
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
			cell.textLabel.text = @"Recent trips";
			cell.imageView.image = [self getActionIcon:kIconRecent];
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
        case kTripSectionRowHistory:
		{
            TripPlannerCacheView *tripCache = [[TripPlannerCacheView alloc] init];
            // Push the detail view controller
            [[self navigationController] pushViewController:tripCache animated:YES];
            [tripCache release];
        }
        break;
	}
}
	
	
@end

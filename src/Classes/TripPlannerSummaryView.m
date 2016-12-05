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

enum
{
    kSectionUserRequest,
    kTripSectionRowFrom,
    kTripSectionRowTo,
    kTripSectionRowOptions,
    kTripSectionRowTime,
    kTripSectionRowPlan,
    kTripSectionRowHistory
};


@implementation TripPlannerSummaryView


- (instancetype)init
{
	if ((self = [super init]))
	{
        self.tripQuery = [XMLTrips xml];
		
		NSDictionary *lastTrip = _userData.lastTrip;
		
		if (lastTrip !=nil)
		{
			TripUserRequest *req = [TripUserRequest fromDictionary:lastTrip];
			req.dateAndTime = nil;
			req.arrivalTime = NO;
			req.fromPoint.coordinates   = nil;
			req.toPoint.coordinates     = nil;
			req.timeChoice  = TripDepartAfterTime;
            [req clearGpsNames];
           
			self.tripQuery.userRequest = req;
		}
        
        [self makeSummaryRows];
	}
	return self;
}

- (void)makeSummaryRows
{
    [self clearSectionMaps];
    
    [self addSectionType:kSectionUserRequest];
    [self addRowType:kTripSectionRowFrom];
    [self addRowType:kTripSectionRowTo];
    [self addRowType:kTripSectionRowOptions];
    [self addRowType:kTripSectionRowTime];
    
    [self addSectionType:kTripSectionRowPlan];
    [self addRowType:kTripSectionRowPlan];
    
    [self addSectionType:kTripSectionRowHistory];
    [self addRowType:kTripSectionRowHistory];
}

- (void)initQuery
{
    [self.tripQuery addStopsFromUserFaves:_userData.faves];
}


- (void)resetAction:(id)sender
{
	
    self.tripQuery = [XMLTrips xml];
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
    self.title = NSLocalizedString(@"Trip Planner", @"page title");
	
	UIBarButtonItem *resetButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Reset", @"button text")
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(resetAction:)];
	self.navigationItem.rightBarButtonItem = resetButton;
	[resetButton release];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_userData.lastTrip = [self.tripQuery.userRequest toDictionary];
    [super viewWillDisappear:animated];

}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	[self reloadData];
}
	

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}
	
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
	if ([self sectionType:section] == kSectionUserRequest)
	{
		return NSLocalizedString(@"Enter trip details:", @"section header");
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
	UIBarButtonItem *reverse = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reverse trip", @"button text")
                                                                 style:UIBarButtonItemStylePlain
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
								  width:[TripLeg bodyTextWidth:self.screenInfo]];
		break;
	case kTripSectionRowTo:
		result = [TripLeg getTextHeight:[self.tripQuery.userRequest.toPoint userInputDisplayText] 
								  width:[TripLeg bodyTextWidth:self.screenInfo]];
		break;
	case kTripSectionRowFrom:
		result = [TripLeg getTextHeight:[self.tripQuery.userRequest.fromPoint userInputDisplayText] 
								  width:[TripLeg bodyTextWidth:self.screenInfo]];
		break;
	case kTripSectionRowTime:
			result = [TripLeg getTextHeight:[self.tripQuery.userRequest getDateAndTime] 
									  width:[TripLeg bodyTextWidth:self.screenInfo]];
		break;
	case kTripSectionRowPlan:
    case kTripSectionRowHistory:
			result = [self basicRowHeight];
			break;
	
	}	
	return result;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat h = [self tableView:self.table heightForRowAtIndexPath:indexPath];
	NSString *cellIdentifier = [NSString stringWithFormat:@"TripLeg%f+%f", h, self.screenInfo.appWinWidth];
    
    NSInteger rowType = [self rowType:indexPath];
	
	switch(rowType)
	{
		case kTripSectionRowFrom:
		case kTripSectionRowTo:
		{
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:cellIdentifier
													   rowHeight:h
                                                      screenInfo:self.screenInfo];
			}
			
			cell.accessoryType = UITableViewCellAccessoryNone;	
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			
			NSString *text;
			NSString *dir;
			
			if (rowType == kTripSectionRowFrom)
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
            NSString *cellId = MakeCellIdW(kTripSectionRowOptions, self.screenInfo.appWinWidth);
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:cellId
													   rowHeight:h
													  screenInfo:self.screenInfo];
			}
			
			cell.accessoryType = UITableViewCellAccessoryNone;	
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			
			[TripLeg populateCell:cell body:[self.tripQuery.userRequest optionsDisplayText] mode:@"Options" time:nil leftColor:nil route:nil];
			return cell;
		}
			
		case kTripSectionRowTime:
		{
            NSString *cellId = MakeCellIdW(kTripSectionRowTime, self.screenInfo.appWinWidth);
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) 
			{
				cell = [TripLeg tableviewCellWithReuseIdentifier:cellId
													   rowHeight:h
													  screenInfo:self.screenInfo];
            }
			
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
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTripSectionRowPlan)];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTripSectionRowPlan)] autorelease];
			}
			
			// Set up the cell
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            cell.textLabel.text = NSLocalizedString(@"Show trip", @"main menu item");
			cell.imageView.image = [self getActionIcon:kIconTripPlanner];
			return cell;
		}
        case kTripSectionRowHistory:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTripSectionRowHistory)];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTripSectionRowHistory)] autorelease];
			}
			
			// Set up the cell
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            cell.textLabel.text = NSLocalizedString(@"Recent trips", @"main menu item");
			cell.imageView.image = [self getActionIcon:kIconRecent];
			return cell;
		}

	}
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger rowType = [self rowType:indexPath];
    
	switch(rowType)
	{		
		case kTripSectionRowFrom:
		case kTripSectionRowTo:
		{
            TripPlannerEndPointView *tripEnd = [TripPlannerEndPointView viewController];
			
			
			tripEnd.from = (rowType != kTripSectionRowTo) ;
			tripEnd.tripQuery = [XMLTrips xml];
			tripEnd.tripQuery.userRequest = self.tripQuery.userRequest;
			@synchronized (_userData)
			{
				[tripEnd.tripQuery addStopsFromUserFaves:_userData.faves];
			}
			tripEnd.popBackTo = self;
			// tripEnd.userRequestCallback = self;
			
			
			// Push the detail view controller
			[self.navigationController pushViewController:tripEnd animated:YES];
			break;
		}
		case kTripSectionRowOptions:
		{
			TripPlannerOptions * options = [TripPlannerOptions viewController];
			
			options.tripQuery = [XMLTrips xml];
			options.tripQuery.userRequest = self.tripQuery.userRequest;
			// options.userRequestCallback = self;
			
			[self.navigationController pushViewController:options animated:YES];
			// _reloadTrip = YES;
			break;
			
		}
		case kTripSectionRowTime:
		{
            TripPlannerDateView * date = [TripPlannerDateView viewController];
			date.tripQuery  = [XMLTrips xml];
			date.tripQuery.userRequest = self.tripQuery.userRequest;
			date.popBack = YES;
			
			[self.navigationController pushViewController:date animated:YES];
			break;

		}
		case kTripSectionRowPlan:
		{
			if (self.tripQuery != nil 
					&& (self.tripQuery.userRequest.toPoint.useCurrentLocation || self.tripQuery.userRequest.toPoint.locationDesc!=nil)
					&& (self.tripQuery.userRequest.fromPoint.useCurrentLocation || self.tripQuery.userRequest.fromPoint.locationDesc!=nil))
			{
				_userData.lastTrip  = [self.tripQuery.userRequest toDictionary];
			
                TripPlannerLocatingView * locView = [TripPlannerLocatingView viewController];
			
				locView.tripQuery = self.tripQuery;
			
				[locView nextScreen:self.navigationController forceResults:NO postQuery:NO orientation:[UIApplication sharedApplication].statusBarOrientation
					  taskContainer:self.backgroundTask];
			}
			else {
				[self.table deselectRowAtIndexPath:indexPath animated:YES];
				
				UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
																   message:NSLocalizedString(@"Select a start and destination to plan a trip.", @"alert message")
																  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
														 otherButtonTitles:nil ] autorelease];
				[alert show];
			}

			break;
		}
        case kTripSectionRowHistory:
		{
            [self.navigationController pushViewController:[TripPlannerCacheView viewController] animated:YES];
        }
        break;
	}
}
	
	
@end

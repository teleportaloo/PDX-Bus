//
//  ArrivalDetail.m
//  TriMetTimes
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

#import "DepartureDetailView.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "Departure.h"
#import "CellTextView.h"
#import "XMLDetour.h"
#import "WebViewController.h"
#include "Detour.h"
#include "CellLabel.h"
#include "StopView.h"
#import "DepartureTimesView.h"
#import "DirectionView.h"

#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import "BigRouteView.h"
#import "AlarmTaskList.h"
#import "AlarmViewMinutes.h"

#define kRouteSection				0


#define kFontName					@"Arial"
#define kTextViewFontSize			16.0

#define kBlockRowFeet				0
#define kDepartureDetailsCellId		@"DepDetails"
#define kLocationId					@"Loc"
#define kTripDetailsCellId			@"Trip"

#define kWebId						@"WebId"
#define kWebAlerts					4 // not used 
#define kWebInfo					0
#define kWebStops					1
#define kWebRows					2
#define kWebRowsShort				1


#define kDestBrowseRow				0
#define kDestFilterRow				1

#define kDestAlarm					0

@implementation DepartureDetailView

@synthesize departure = _departure;
@synthesize detourData = _detourData;
@synthesize stops = _stops;
@synthesize allDepartures = _allDepartures;

- (void)dealloc {
	self.departure = nil;
	self.detourData = nil;
	self.allDepartures = nil;
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
		self.title = @"Details";
	}
	return self;
}

#pragma mark Data fetchers

- (void)fetchData:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int items = 0;
	
	if (self.departure.detour)
	{
		items++;
	}
	
	if (self.departure.streetcar)
	{
		items++;
	}
	
	[self.backgroundTask.callbackWhenFetching BackgroundStart:items title:@"getting details"];
	
	if (self.departure.detour)
	{
		NSError *parseError = nil;
		self.detourData = [[[XMLDetour alloc] init] autorelease];
	    [self.detourData getDetourForRoute:self.departure.route parseError:&parseError];
		
		[self.backgroundTask.callbackWhenFetching BackgroundItemsDone:1];
	}
	
	if (self.departure.streetcar && self.departure.blockPositionLat == nil)
	{
		NSError *parseError = nil;
		XMLStreetcarLocations *locs = [XMLStreetcarLocations getSingleton];
		[locs getLocations:&parseError];
		
		int i,j;
		
		if (self.allDepartures != nil)
		{
			for (i=[self.allDepartures count]-1; i>=0 ; i--)
			{
				XMLDepartures * dep = [self.allDepartures objectAtIndex:i];
			
				for (j=0; j< [dep safeItemCount]; j++)
				{
					Departure *dd = [dep itemAtIndex:j];
					if (dd.streetcar)
					{
						[locs insertLocation:dd];
					}
				}
			}
		}
		
		self.allDepartures = nil;

		
		[self.backgroundTask.callbackWhenFetching BackgroundItemsDone:items];
		
		//[locs release];
	}
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
	[pool release];
}

- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback dep:(Departure *)dep allDepartures:(NSArray*)deps allowDestination:(BOOL)allowDest
{
	self.departure = dep;
	self.allDepartures = deps;
	sections = 1;
	
	if ([dep detour] || (dep.streetcar && dep.blockPositionLat==nil))
	{
		if ([dep detour])
		{
			detourSection = sections;
			sections++;
		}
		else {
			detourSection = -1;
		}
		
		self.backgroundTask.callbackWhenFetching = callback;
		
		[NSThread detachNewThreadSelector:@selector(fetchData:) toTarget:self withObject:nil];
	}
	else
	{
		detourSection = -1;
	}
	
	if (self.departure.hasBlock)
	{
		locationSection = sections;
		sections++;
	}
	else {
		locationSection = -1;
	}
	
	if (dep.block && [AlarmTaskList supported] && dep.secondsToArrival > 0)
	{
		alertSection = sections;
		sections ++;
	}
	else {
		alertSection = -1;
	}
	
	

	
	if (dep.block !=nil && allowDest)
	{
		destinationSection = sections;
		sections ++;
	}
	else
	{
		destinationSection = -1;
	}
	
	if ([dep.trips count] > 0)
	{
		tripSection = sections;
		sections ++;
	}
	else 
	{
		tripSection = -1;
	}
	
	webSection = sections;
	sections++;
	
	
	
	disclaimerSection = sections;
	sections++;
	
	if (self.backgroundTask.callbackWhenFetching == nil)
	{
		[callback BackgroundCompleted:self];
	}
}

#pragma mark Helper functions

- (void)showStops:(NSString *)route
{
	if ([DepartureTimesView canGoDeeper])
	{
		// Detour *detour = [self.detourData itemAtIndex:indexPath.row];
		DirectionView *directionViewController = [[DirectionView alloc] init];
		
		// directionViewController.route = [detour route];
		[directionViewController fetchDirectionsInBackground:self.backgroundTask route:route];
		[directionViewController release];	
	}
	
}

-(void)showMap:(id)sender
{
	MapViewController *mapPage = [[MapViewController alloc] init];
	SimpleAnnotation *pin = [[[SimpleAnnotation alloc] init] autorelease];
	mapPage.title = self.departure.fullSign;
	mapPage.callback = self.callback;
	[pin setCoordinateLat:self.departure.blockPositionLat lng:self.departure.blockPositionLng ];
	pin.pinTitle = [self.departure routeName];
	pin.pinSubtitle = [NSString stringWithFormat:@"%@ away", [self.departure formatDistance:self.departure.blockPositionFeet]];
	pin.pinColor = MKPinAnnotationColorPurple;
	[mapPage addPin:pin];
	
	
	SimpleAnnotation *stopPin = [[[SimpleAnnotation alloc] init] autorelease];
	[stopPin setCoordinateLat:self.departure.stopLat lng:self.departure.stopLng ];
	stopPin.pinTitle = self.departure.locationDesc;
	stopPin.pinSubtitle = nil;
	stopPin.pinColor = MKPinAnnotationColorRed;
	[mapPage addPin:stopPin];
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];
}


-(void)showBig:(id)sender
{
	BigRouteView *bigPage = [[BigRouteView alloc] init];
	
	bigPage.departure = self.departure;
	
	[[self navigationController] pushViewController:bigPage animated:YES];
	[bigPage release];
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kRouteSection)
	{
		return 1;
	}
	
	if (section == locationSection)
	{
		return 1;
	}
	
	if (section == alertSection)
	{
		return 1;
	}
	
	if (section == destinationSection)
	{
		if (self.stops == nil)
		{
			return 1;
		}
		return 2;
	}
	
	if (section == webSection)
	{
		if ([DepartureTimesView canGoDeeper])
		{
			return kWebRows;
		}
		else
		{
			return kWebRowsShort;
		}
	}
	if (section == detourSection)
	{
		return [self.detourData safeItemCount];
	}
	if (section == tripSection)
	{
		return [self.departure.trips count];
	}	
	if (section ==  disclaimerSection)
	{
		return 1;
	}
	return 0;
}

- (NSString *)detourText:(Detour *)det
{
	return [NSString stringWithFormat:@"Detour: %@", [det detourDesc]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == kRouteSection)
	{
		UITableViewCell *cell = nil;
		NSString *cellId = [self.departure cellReuseIdentifier:kDepartureCellId width:[self screenWidth]];
		cell = [tableView dequeueReusableCellWithIdentifier: cellId];
		if (cell == nil) {
			cell = [self.departure tableviewCellWithReuseIdentifier:cellId 
																big:NO 
													spaceToDecorate:NO
															  width:[self screenWidth]];
		}
		[self.departure populateCell:cell decorate:NO big:NO busName:YES wide:NO];
		
		
		//NSString *newVoiceOver = [NSString stringWithFormat:@"%@, %@", self.departure.locationDesc, [cell accessibilityLabel]];
		//[cell setAccessibilityLabel:newVoiceOver];
		
		return cell;
	}
	else if (indexPath.section == locationSection)
	{
		UITableViewCell *cell = nil;
		
		NSString *cellId = [self.departure cellReuseIdentifier:kLocationId width:[self screenWidth]];
		cell = [tableView dequeueReusableCellWithIdentifier: cellId];
		
		if (cell == nil) {
			cell = [self.departure tableviewCellWithReuseIdentifier:cellId 
																big:NO 
													spaceToDecorate:YES
															  width:[self screenWidth]];
		}
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		
		[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		NSDate *lastPosition = [NSDate dateWithTimeIntervalSince1970: self.departure.blockPositionAt / 1000]; 
		
		[self.departure populateCellGeneric:cell
									  first:[NSString stringWithFormat:@"Last known location at %@", [dateFormatter stringFromDate:lastPosition]]
									 second:[NSString stringWithFormat:@"%@ away", [self.departure formatDistance:self.departure.blockPositionFeet]]
									   col1:[UIColor blueColor]
									   col2:[UIColor blueColor]];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	} 
	else if (indexPath.section == detourSection)
	{
		static NSString *detourId = @"detour";
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:detourId];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:detourId] autorelease];
			cell.view = [Detour create_UITextView:[self getParagraphFont]];
									
		}
			
		if (self.detourData.detour !=nil)
		{
			Detour *det = [self.detourData itemAtIndex:indexPath.row];
			cell.view.text = [self detourText:det];
			cell.view.textColor = [UIColor orangeColor];
			
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@",
										 [det routeDesc], [det detourDesc]]];
		}
		else
		{
			cell.view.text = @"Detour information not known.";
		}
		
		
		if ([DepartureTimesView canGoDeeper])
		{
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		else
		{
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
		return cell;
	}
	else if (indexPath.section == tripSection)
	{
		NSString *cellId = [self.departure cellReuseIdentifier:kDepartureCellId width:[self screenWidth]];
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
		
		if (cell == nil) {
			cell = [self.departure tableviewCellWithReuseIdentifier:cellId big:NO spaceToDecorate:NO
															  width:[self screenWidth]];
		}
		[self.departure populateTripCell:cell item:indexPath.row];
		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
		return cell;
	}
	else if (indexPath.section == disclaimerSection)
	{
		UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
		if (cell == nil) {
			cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
		}
		
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		NSDate *queryTime = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.departure.queryTime)]; 
		
		if (self.departure.block !=nil)
		{
			[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"(Trip ID %@) Updated: %@", 
													 self.departure.block,
													 [dateFormatter stringFromDate:queryTime]]];
		}
		else {
			[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"Updated: %@", 
													 [dateFormatter stringFromDate:queryTime]]];
		}

		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
		cell.accessoryType = UITableViewCellAccessoryNone;
	
		if (self.departure.streetcar && self.departure.copyright !=nil)
		{
			[self addStreetcarTextToDisclaimerCell:cell  text:self.departure.copyright trimetDisclaimer:YES];
		}
		
		return cell;
	}
	else if (indexPath.section == webSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];;
		}	
		
		switch (indexPath.row)
		{
		case kWebAlerts:
				cell.textLabel.text = @"Route alerts";
				cell.imageView.image = [self getActionIcon:kIconAlerts];
				break;
		case kWebInfo:
				cell.textLabel.text = @"Map & schedule";
				cell.imageView.image = [self getActionIcon:kIconEarthMap];
				break;
		case kWebStops:
				cell.textLabel.text = @"Browse stops";
				cell.imageView.image = [self getActionIcon:kIconBrowse];
				break;
		}
		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
		return cell;
	}
	else if (indexPath.section == destinationSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.textColor = [UIColor grayColor];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
		}
		
		switch (indexPath.row)
		{
			case kDestBrowseRow:
				cell.textLabel.text = @"Browse for destination arrival time";
				break;
			case kDestFilterRow:
				cell.textLabel.text = @"Show arrivals with just this trip";
				break;
		}
		return cell;
	}
	else if (indexPath.section == alertSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.textColor = [UIColor grayColor];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
		}
		
		switch (indexPath.row)
		{
			case kDestAlarm:
			{
				AlarmTaskList *taskList = [AlarmTaskList getSingleton];
				
				if ([taskList hasTaskForStopId:self.departure.locid block:self.departure.block])
				{
					cell.textLabel.text = @"Edit arrival alarm";
				}
				else {
					cell.textLabel.text = @"Set arrival alarm";
				}
				cell.imageView.image = [self getActionIcon:kIconAlarm];
				break;
			}
		}
		return cell;
	}
	
	// Configure the cell
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == kRouteSection)
	{
		return self.departure.locationDesc;
	}
	if (section == tripSection)
	{
		return @"Remaining trips before arrival:";
	}
	if (section == webSection)
	{
		return @"Route info:";
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == webSection)
	{
			switch (indexPath.row) {
				case kWebAlerts:
					[self showRouteAlerts:self.departure.route fullSign:self.departure.fullSign];
					break;
				case kWebInfo:
				    [self showRouteSchedule:self.departure.route];
					break;
				case kWebStops:
					[self showStops:self.departure.route];
					break;
				default:
					break;
			}
	}
	else if (indexPath.section == alertSection)
	{
		switch (indexPath.row)
		{
			case kDestAlarm:
			{
				// Create a an alert
				AlarmViewMinutes *alertViewMins = [[[AlarmViewMinutes alloc] init] autorelease];
				alertViewMins.dep = self.departure;
				
				[[self navigationController] pushViewController:alertViewMins animated:YES];
				break;
				
			}
		}
	}
	else if (indexPath.section == destinationSection)
	{
		switch (indexPath.row)
		{
			case kDestBrowseRow:
			{
				StopView *stopViewController = [[StopView alloc] init];
				
				stopViewController.callback = self.callback;
				
				[stopViewController fetchDestinationsInBackground:self.backgroundTask dep:self.departure ];
				[stopViewController release];	
				break;
			}
			case kDestFilterRow:
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				
				departureViewController.callback = self.callback;
				
				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:self.stops block:self.departure.block];
				
				[departureViewController release];
				break;
				
			}
		}
	}
	else if (indexPath.section == locationSection)
	{
		[self showMap:nil];
	}
	else if (indexPath.section == detourSection)
	{
		if (self.detourData.detour !=nil)
		{
			Detour *detour = [self.detourData itemAtIndex:indexPath.row];
			[self showStops:detour.route];
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;
	
	if (indexPath.section == webSection)
	{
		return 35.0;
	}
	else if (indexPath.section == destinationSection)
	{
		return 35.0;
	}
	else if (indexPath.section == alertSection)
	{
		return 35.0;
	}
	else if (indexPath.section == kRouteSection || indexPath.section == tripSection || indexPath.section == locationSection)
	{
		if (([self screenWidth] & WidthiPad) !=0)
		{
			return kWideDepartureCellHeight;
		}
		else {
			return kDepartureCellHeight;
		}
	}
	else if (indexPath.section == detourSection)
	{		
		Detour *det = [self.detourData itemAtIndex:indexPath.row];
		return [self getTextHeight:[self detourText:det] font:[self getParagraphFont]];
		// return [Detour getTextHeight:[det detourDesc]];
	}
	else if (indexPath.section == disclaimerSection)
	{
		return kDepartureCellHeight;
	}
	
	return result;
}

#pragma mark View functions 

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	UIBarButtonItem *magnifyButton = [[UIBarButtonItem alloc] initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
																	  style:(UIBarButtonItemStyle)UIBarButtonItemStyleBordered 
																	 target:self action:@selector(showBig:)];

	magnifyButton.accessibilityHint = @"Bus line indentifier";
	self.navigationItem.rightBarButtonItem = magnifyButton;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark TableViewWithToolbar functions

- (void)createToolbarItems
{	
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control

	if (self.departure.hasBlock)
	{
		NSArray *items = [NSArray arrayWithObjects: 
						  [self autoDoneButton], 
						  [CustomToolbar autoFlexSpace],
						  [CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)],
						  [CustomToolbar autoFlexSpace],
						  [self autoFlashButton], nil];
		[self setToolbarItems:items animated:NO];	
		
	}
	else
	{
		NSArray *items = [NSArray arrayWithObjects: 
						  [self autoDoneButton], 
						  [CustomToolbar autoFlexSpace],
						  [self autoFlashButton], 
						  nil];
		[self setToolbarItems:items animated:NO];
	}
	
}

@end


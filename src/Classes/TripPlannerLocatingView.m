//
//  TripPlannerLocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
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

#import "TripPlannerLocatingView.h"
#import "TripPlannerLocationListView.h"
#import "TripPlannerResultsView.h"
#import "XMLReverseGeoCode.h"

@implementation TripPlannerLocatingView

@synthesize tripQuery = _tripQuery;
@synthesize currentEndPoint = _currentEndPoint;
@synthesize backgroundTaskController = _backgroundTaskController;
@synthesize backgroundTaskForceResults = _backgroundTaskForceResults;

- (void)dealloc {
	self.tripQuery = nil;
	self.backgroundTaskController = nil;
	self.currentEndPoint = nil;
    [super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.title = @"Locating";
	}
	return self;
}

#pragma mark UI helpers

- (void)refreshAction:(id)sender
{
	[self.locationManager startUpdatingLocation];
	self.currentEndPoint.locationDesc = nil;
	[self startAnimating:YES];
	
	waitingForLocation = true;
}

#pragma mark Data fetchers

- (void)nextScreen:(UINavigationController *)controller forceResults:(bool)forceResults postQuery:(bool)postQuery orientation:(UIInterfaceOrientation)orientation
	 taskContainer:(BackgroundTaskContainer*)taskContainer
{	
	bool findLocation = false;
	
	if (self.tripQuery.userRequest.fromPoint.useCurrentLocation == false
		&& self.tripQuery.userRequest.toPoint.useCurrentLocation == false)
	{
		findLocation = false;
	}
	else if (self.tripQuery.userRequest.fromPoint.useCurrentLocation == true && !postQuery)
	{
		findLocation = true; // (self.tripQuery.fromPoint.lat==nil);
		self.currentEndPoint = self.tripQuery.userRequest.fromPoint;
	}
	else if (self.tripQuery.userRequest.toPoint.useCurrentLocation == true && !postQuery)
	{
		findLocation = true; // (self.tripQuery.toPoint.lat==nil);
		self.currentEndPoint = self.tripQuery.userRequest.toPoint;
	}
		
	if (findLocation && !forceResults)
	{
		[controller pushViewController:self animated:YES];
	}
	else
	{
		_cachedOrientation = orientation;
		_useCachedOrientation = true;
		[self fetchAndDisplay:controller forceResults:forceResults taskContainer:taskContainer];
	}
}

- (void)fetchItineraries:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	
	TripEndPoint *geoNameRequired = nil;
	
	XMLReverseGeoCode *geoProvider = [UserPrefs getSingleton].reverseGeoCodeProvider;
	
	if (geoProvider !=nil && self.tripQuery.userRequest.toPoint.useCurrentLocation && self.tripQuery.userRequest.toPoint.locationDesc == nil)
	{
		geoNameRequired = self.tripQuery.userRequest.toPoint;
	}
	
	if (geoProvider !=nil && self.tripQuery.userRequest.fromPoint.useCurrentLocation && self.tripQuery.userRequest.fromPoint.locationDesc == nil)
	{
		geoNameRequired = self.tripQuery.userRequest.fromPoint;
	}
		
	if (geoNameRequired && geoProvider !=nil)
	{
		[self.backgroundTask.callbackWhenFetching backgroundStart:2 title:@"getting trip"];
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:@"geolocating"];
		
		geoNameRequired.locationDesc = [geoProvider fetchAddress:geoNameRequired.currentLocation];
		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:@"planning trip"];
		
		[self.tripQuery fetchItineraries:nil];
		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
	}
	else {
		[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting trip"];
		[self.tripQuery fetchItineraries:nil];
	}

	// Here we should create the objects and not do it in our own background task complete
	
	if (self.tripQuery.fromList != nil && !self.backgroundTaskForceResults && !self.tripQuery.userRequest.fromPoint.useCurrentLocation)
	{
		TripPlannerLocationListView *locView = [[TripPlannerLocationListView alloc] init];
		
		locView.tripQuery = self.tripQuery;
		locView.from = true;
		
		// Push the detail view controller
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:locView];
		[locView release];
	}
	else if (self.tripQuery.toList != nil && !self.backgroundTaskForceResults && !self.tripQuery.userRequest.toPoint.useCurrentLocation)
	{
		TripPlannerLocationListView *locView = [[TripPlannerLocationListView alloc] init];
		
		locView.tripQuery = self.tripQuery;
		locView.from = false;
		
		// Push the detail view controller
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:locView];
		[locView release];
	}
	else
	{
		TripPlannerResultsView *tripResults = [[TripPlannerResultsView alloc] init];
		
		tripResults.tripQuery = self.tripQuery;
		
		[tripResults.tripQuery saveTrip];
		
		
		// Push the detail view controller
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:tripResults];
		[tripResults release];
	}

	[pool release];
	
}

-(void)fetchAndDisplay:(UINavigationController *)controller forceResults:(bool)forceResults
		 taskContainer:(BackgroundTaskContainer *)taskContainer
{
	self.backgroundTask.callbackWhenFetching = taskContainer;
	self.backgroundTaskController = controller;
	self.backgroundTaskForceResults = forceResults;
	
	[NSThread detachNewThreadSelector:@selector(fetchItineraries:) toTarget:self withObject:nil];
}
	
#pragma mark Background task callbacks


- (UIInterfaceOrientation)BackgroundTaskOrientation
{
	if (_useCachedOrientation)
	{
		return _cachedOrientation;
	}
	return [super BackgroundTaskOrientation];	
}

#pragma mark View callbacks

- (void)viewDidLoad {
    [super viewDidLoad];
	accuracy = 200.0;
	
	if (self.currentEndPoint.currentLocation == nil)
	{
		[self.locationManager startUpdatingLocation];
		waitingForLocation = true;
	}
	else
	{
		self.lastLocation = self.currentEndPoint.currentLocation;
	}
	
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}



#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (waitingForLocation)
	{
		return @"Acquiring location. Accuracy will improve momentarily; search will start when accuracy is sufficient or whenever you choose.";
	}
	
	
	if (failed)
	{
		if (self.tripQuery.userRequest.fromPoint.useCurrentLocation)
		{
			return @"Failed to acquire location, please go back and change the starting location for the trip.\n\n";
		}
		return @"Failed to acquire location, please go back and change the trip's destination.\n\n";
	}
	return @"Location acquired. Select 'Refresh' to re-acquire current location.\n\n\n";
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kLocatingRowHeight;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *locSectionId = @"LocatingSection";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:locSectionId];
	if (cell == nil) {
		cell = [self accuracyCellWithReuseIdentifier:locSectionId];
	}
	
	UILabel* text = (UILabel *)[cell.contentView viewWithTag:[self LocationTextTag]];
	
	if (waitingForLocation)
	{
		[self startAnimating:NO];
	}
	
	
	if (self.lastLocation != nil)
	{
		text.text = [NSString stringWithFormat:@"Accuracy acquired:\n+/- %@", 
					 [self formatDistance:self.lastLocation.horizontalAccuracy]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[cell setAccessibilityHint:@"Double-tap for results"];
	}
	else if(!failed)
	{
		text.text = @"Locating...";
		cell.accessoryType = UITableViewCellAccessoryNone;
		[cell setAccessibilityHint:nil];
	}
	else
	{
		text.text = @"Location not acquired.";
		cell.accessoryType = UITableViewCellAccessoryNone;
		[cell setAccessibilityHint:nil];
		
	}
	[self updateAccessibility:cell indexPath:indexPath text:text.text alwaysSaySection:YES];
	return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	if (self.lastLocation!=nil)
	{
		[self.locationManager stopUpdatingLocation];
		waitingForLocation = NO;
		[self stopAnimating:YES];
		[self located];
	}
}


#pragma mark LocatingTableView callbacks

- (void)failedToLocate
{
	
}


- (void)located
{
	
	TripEndPoint *point = nil;
	
	if (self.tripQuery.userRequest.fromPoint.useCurrentLocation)
	{
		point = self.tripQuery.userRequest.fromPoint;
	}
	else
	{
		point = self.tripQuery.userRequest.toPoint;
	}
	
	point.currentLocation = self.lastLocation;
	
	
	[self fetchAndDisplay:self.navigationController forceResults:NO taskContainer:self.backgroundTask];
}




@end


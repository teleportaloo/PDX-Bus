//
//  TripPlannerLocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerLocatingView.h"
#import "TripPlannerLocationListView.h"
#import "TripPlannerResultsView.h"
#import "AddressBookUI/ABAddressFormatting.h"
#import "AddressBook/AddressBook.h"
#import <AddressBook/ABPerson.h>
#import "DebugLogging.h"
#import "ReverseGeoLocator.h"

@implementation TripPlannerLocatingView

@synthesize tripQuery = _tripQuery;
@synthesize currentEndPoint = _currentEndPoint;
@synthesize backgroundTaskController = _backgroundTaskController;
@synthesize backgroundTaskForceResults = _backgroundTaskForceResults;
@synthesize waitingForGeocoder = _waitingForGeocoder;

- (void)dealloc {
	self.tripQuery = nil;
	self.backgroundTaskController = nil;
	self.currentEndPoint = nil;
    [super dealloc];
}


#pragma mark UI helpers

- (void)refreshAction:(id)sender
{
	
	self.currentEndPoint.locationDesc = nil;
	
    [super refreshAction:sender];
}

#pragma mark Data fetchers

- (void)nextScreen:(UINavigationController *)controller
      forceResults:(bool)forceResults postQuery:(bool)postQuery
       orientation:(UIInterfaceOrientation)orientation
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
	
    NSMutableArray *geoNamesRequired = [[[NSMutableArray alloc] init] autorelease];
	
    bool canReverseGeocode = [ReverseGeoLocator supported];
    
	if (canReverseGeocode && (self.tripQuery.userRequest.toPoint.useCurrentLocation || self.tripQuery.userRequest.toPoint.coordinates!=nil) && self.tripQuery.userRequest.toPoint.locationDesc == nil)
	{
		[geoNamesRequired addObject:self.tripQuery.userRequest.toPoint];
	}
	
	if (canReverseGeocode && (self.tripQuery.userRequest.fromPoint.useCurrentLocation || self.tripQuery.userRequest.fromPoint.coordinates!=nil) && self.tripQuery.userRequest.fromPoint.locationDesc == nil)
	{
		[geoNamesRequired addObject:self.tripQuery.userRequest.fromPoint];
	}
		
	if (geoNamesRequired.count > 0 && canReverseGeocode)
	{
		[self.backgroundTask.callbackWhenFetching backgroundStart:1+(int)geoNamesRequired.count title:@"getting trip"];
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:@"geolocating"];
		
        int taskCounter = 0;
        for (TripEndPoint *point in geoNamesRequired)
        {
            ReverseGeoLocator *geocoder = [[[ReverseGeoLocator alloc] init] autorelease];
        
            if ([geocoder fetchAddress:point.coordinates])
            {
                point.locationDesc = geocoder.result;
            }
		
            taskCounter++;
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:taskCounter];
        }
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


- (void)viewDidAppear:(BOOL)animated
{
    self.delegate = self;
    _accuracy = 200.0;
    
	
	if (self.currentEndPoint.coordinates == nil || !_appeared)
	{
		[self startLocating];
        _appeared = YES;
	}
	else
	{
		self.lastLocation = self.currentEndPoint.coordinates;
        [self stopLocating];
        [self reloadData];
	}
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.delegate = nil;
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark LocatingTableView callbacks


- (void)locatingViewFinished:(LocatingView *)locatingView
{
    if (!locatingView.failed && !locatingView.cancelled)
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
	
        point.coordinates = self.lastLocation;
	
	
        [self fetchAndDisplay:locatingView.navigationController forceResults:NO taskContainer:locatingView.backgroundTask];
        
    } else if (locatingView.cancelled)
    {
        [locatingView.navigationController popViewControllerAnimated:YES];
    }
}




@end


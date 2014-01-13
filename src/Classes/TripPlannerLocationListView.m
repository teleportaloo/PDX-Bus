//
//  TripPlannerLocationListView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/29/09.
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

#import "TripPlannerLocationListView.h"
#import "TripPlannerResultsView.h"
#import "TripPlannerLocatingView.h"
#import "MapViewController.h"
#import "TripPlannerEndPointView.h"


@implementation TripPlannerLocationListView

@synthesize tripQuery = _tripQuery;
@synthesize from = _from;
@synthesize locList = _locList;

static int depthCount = 0;

- (void)dealloc {
	self.tripQuery = nil;
	self.locList = nil;
	depthCount --;
    [super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	[toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}


- (void)editHomeAction:(id)sender
{
	TripPlannerEndPointView *editHome = [[TripPlannerEndPointView alloc] init];
    
    [editHome initTakMeHome:self.tripQuery.userRequest];
    
    UINavigationController * navigationController = self.navigationController;
    [navigationController popToRootViewControllerAnimated:NO];
    [navigationController pushViewController:editHome animated:YES];
    
    [editHome release];
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	depthCount ++;
	
	if (self.from)
	{
		self.title = @"Uncertain Start";
		if (self.locList == nil)
		{
			self.locList = self.tripQuery.fromList;
		}
	}
	else
	{
		self.title = @"Uncertain End";
		if (self.locList == nil)
		{
			self.locList = self.tripQuery.toList;
		}
	}
    
    if (self.tripQuery.userRequest.takeMeHome)
    {
        UIBarButtonItem *editHome = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"Edit Home", @"")
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(editHomeAction:)];
        self.navigationItem.rightBarButtonItem = editHome;
        
        [editHome release];
    }
    
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




#pragma mark ReturnTripLegEndPoint methods

- (NSString *)actionText
{
	return nil;
}

- (void) chosenEndpoint:(TripLegEndPoint*)endpoint
{
	bool displayResults = true;
	
	if (self.from)
	{
		self.tripQuery.userRequest.fromPoint.locationDesc = endpoint.xdescription;
		self.tripQuery.userRequest.fromPoint.currentLocation  = [[[CLLocation alloc] initWithLatitude:[endpoint.xlat doubleValue] longitude:[endpoint.xlon doubleValue]]
                                                                    autorelease];
		
		if (self.tripQuery.toList && !self.tripQuery.userRequest.toPoint.useCurrentLocation)
		{
			TripPlannerLocationListView *locView = [[TripPlannerLocationListView alloc] init];
			
			locView.tripQuery = self.tripQuery;
			locView.from = false;
			
			// Push the detail view controller
			[[self navigationController] pushViewController:locView animated:YES];
			[locView release];
			displayResults = false;
		}
	}
	else
	{
		self.tripQuery.userRequest.toPoint.locationDesc = endpoint.xdescription;
		self.tripQuery.userRequest.toPoint.currentLocation  = [[[CLLocation alloc] initWithLatitude:[endpoint.xlat doubleValue] longitude:[endpoint.xlon doubleValue]]
                                                                autorelease];
	}
	
	
	if (displayResults)
	{
		TripPlannerLocatingView * locView = [[ TripPlannerLocatingView alloc ] init];
		
		locView.tripQuery = self.tripQuery;
		
		[locView nextScreen:[self navigationController] forceResults:(depthCount > 5) postQuery:YES 
				orientation:self.interfaceOrientation taskContainer:self.backgroundTask];
		
		[locView release];
		
	}
	
	
}

#pragma mark UI Helpers

-(void)showMap:(id)sender
{
	MapViewController *mapPage = [[MapViewController alloc] init];
	mapPage.callback = self.callback;
	mapPage.annotations = self.locList;
	
	if (self.from)
	{
		mapPage.title = @"Uncertain Start";
	}
	else
	{
		mapPage.title = @"Uncertain Destination";
	}
	
	for (int i=0; i< [self.locList count]; i++)
	{
		TripLegEndPoint *p = [self.locList objectAtIndex:i];
		
		p.callback = self;
	}
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];
}

#pragma mark  Table View methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.from)
	{
		return @"Uncertain starting location - select a choice from below:";
	}
	return @"Uncertain destination - select a choice from below:";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.locList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TripLocation";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	TripLegEndPoint *p = [self.locList objectAtIndex:indexPath.row];
	
    cell.textLabel.text = p.xdescription;
	cell.textLabel.font = [self getBasicFont];
	cell.textLabel.adjustsFontSizeToFitWidth = true;
	[cell setAccessibilityLabel:p.xdescription];
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
	
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	[self chosenEndpoint:[self.locList objectAtIndex:indexPath.row] ];

}


@end


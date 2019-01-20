//
//  TripPlannerLocationListView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/29/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerLocationListView.h"
#import "TripPlannerResultsView.h"
#import "TripPlannerLocatingView.h"
#import "MapViewController.h"
#import "TripPlannerEndPointView.h"
#import "StringHelper.h"


@implementation TripPlannerLocationListView

static int depthCount = 0;

- (void)dealloc {
    depthCount --;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) style
{
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}


#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    depthCount ++;
    
    if (self.from)
    {
        self.title = NSLocalizedString(@"Uncertain Start", @"page title");
        if (self.locList == nil)
        {
            self.locList = self.tripQuery.fromList;
        }
    }
    else
    {
        self.title = NSLocalizedString(@"Uncertain End", @"page title");
        if (self.locList == nil)
        {
            self.locList = self.tripQuery.toList;
        }
    }
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
        self.tripQuery.userRequest.fromPoint.coordinates  = endpoint.loc;
        
        if (self.tripQuery.toList && !self.tripQuery.userRequest.toPoint.useCurrentLocation)
        {
            TripPlannerLocationListView *locView = [TripPlannerLocationListView viewController];
            
            locView.tripQuery = self.tripQuery;
            locView.from = false;
            
            // Push the detail view controller
            [self.navigationController pushViewController:locView animated:YES];
            displayResults = false;
        }
    }
    else
    {
        self.tripQuery.userRequest.toPoint.locationDesc = endpoint.xdescription;
        self.tripQuery.userRequest.toPoint.coordinates  = endpoint.loc;
    }
    
    
    if (displayResults)
    {
        TripPlannerLocatingView * locView = [TripPlannerLocatingView viewController];
        
        locView.tripQuery = self.tripQuery;
        
        [locView nextScreen:self.navigationController forceResults:(depthCount > 5) postQuery:YES 
                orientation:[UIApplication sharedApplication].statusBarOrientation taskContainer:self.backgroundTask];
        
    }
    
    
}

#pragma mark UI Helpers

-(void)showMap:(id)sender
{
    MapViewController *mapPage = [MapViewController viewController];
    mapPage.callback = self.callback;
    mapPage.annotations = self.locList;
    
    if (self.from)
    {
        mapPage.title = NSLocalizedString(@"Uncertain Start", @"page title");
    }
    else
    {
        mapPage.title = NSLocalizedString(@"Uncertain End", @"page title");
    }
    
    for (TripLegEndPoint *p in self.locList)
    {        
        p.callback = self;
    }
    
    [self.navigationController pushViewController:mapPage animated:YES];
}

#pragma mark  Table View methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.from)
    {
        return NSLocalizedString(@"Uncertain starting location - select a choice from below:", @"section header");
    }
    return NSLocalizedString(@"Uncertain destination - select a choice from below:", @"section header");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.locList.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"TripLocation"];
    
    TripLegEndPoint *p = self.locList[indexPath.row];
    
    cell.textLabel.text = p.xdescription;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = true;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.accessibilityLabel = p.xdescription.phonetic;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    [self chosenEndpoint:self.locList[indexPath.row]];

}


@end


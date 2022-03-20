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
#import "NSString+Helper.h"
#import "WebViewController.h"
#import "UIApplication+Compat.h"

@interface TripPlannerLocationListView ()

@property (nonatomic, strong) NSMutableArray<TripLegEndPoint *> *locList;

@end

@implementation TripPlannerLocationListView

static int depthCount = 0;

- (void)dealloc {
    depthCount--;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)feedback:(UIBarButtonItem *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Feedback", @"Alert title")
                                                                   message:NSLocalizedString(@"If a business or address is missing from this list, please contact TriMet with the details.", @"Warning text")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Trip Planneer Feedback", @"Button text") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [WebViewController displayNamedPage:@"TriMet Trip Planner Feedback"
                                  navigator:self.navigationController
                             itemToDeselect:self
                                   whenDone:self.callbackWhenDone];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Button text") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    UIView *source =  (UIView *)[sender valueForKey:@"view"];
    
    if (source == nil)
    {
        source = self.view;
    }
    
    alert.popoverPresentationController.sourceView = source;
    alert.popoverPresentationController.sourceRect = CGRectMake(source.frame.size.width / 2, source.frame.size.height / 2, 0, 0);
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    
    if (self.locList && self.locList.count > 0 && !self.locList.firstObject.fromAppleMaps) {
        [toolbarItems addObject:[UIToolbar flexSpace]];
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc]
                                   initWithTitle:NSLocalizedString(@"Feedback", @"warning") style:UIBarButtonItemStylePlain
                                   target:self action:@selector(feedback:)];
        
        [toolbarItems addObject:button];
    }
    
    // https://trimet.org/contact/tripfeedback.htm
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)loadView
{
    depthCount++;
    
    if (self.from) {
        self.title = NSLocalizedString(@"Uncertain Start", @"page title");
        
        if (self.locList == nil) {
            self.locList = self.tripQuery.fromList;
        }
    } else {
        self.title = NSLocalizedString(@"Uncertain End", @"page title");
        
        if (self.locList == nil) {
            self.locList = self.tripQuery.toList;
        }
    }
    
    [super loadView];
}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark ReturnTripLegEndPoint methods

- (NSString *)actionText {
    return nil;
}

- (void)chosenEndpoint:(TripLegEndPoint *)endpoint {
    bool displayResults = true;
    
    if (self.from) {
        self.tripQuery.userRequest.fromPoint.locationDesc = endpoint.desc;
        self.tripQuery.userRequest.fromPoint.coordinates = endpoint.loc;
        
        if (self.tripQuery.toList && !self.tripQuery.userRequest.toPoint.useCurrentLocation) {
            TripPlannerLocationListView *locView = [TripPlannerLocationListView viewController];
            
            locView.tripQuery = self.tripQuery;
            locView.from = false;
            
            // Push the detail view controller
            [self.navigationController pushViewController:locView animated:YES];
            displayResults = false;
        }
    } else {
        self.tripQuery.userRequest.toPoint.locationDesc = endpoint.desc;
        self.tripQuery.userRequest.toPoint.coordinates = endpoint.loc;
    }
    
    if (displayResults) {
        TripPlannerLocatingView *locView = [TripPlannerLocatingView viewController];
        
        locView.tripQuery = self.tripQuery;
        
        [locView nextScreen:self.navigationController forceResults:(depthCount > 5) postQuery:YES
                orientation:[UIApplication sharedApplication].compatStatusBarOrientation taskContainer:self.backgroundTask];
    }
}

#pragma mark UI Helpers

- (void)showMap:(id)sender {
    MapViewController *mapPage = [MapViewController viewController];
    
    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    mapPage.annotations = (NSMutableArray<id<MapPin> > *)self.locList;
    
    if (self.from) {
        mapPage.title = NSLocalizedString(@"Uncertain Start", @"page title");
    } else {
        mapPage.title = NSLocalizedString(@"Uncertain End", @"page title");
    }
    
    for (TripLegEndPoint *p in self.locList) {
        p.callback = self;
    }
    
    [self.navigationController pushViewController:mapPage animated:YES];
}

#pragma mark  Table View methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.from) {
        if (self.locList && self.locList.count > 0 && self.locList.firstObject.fromAppleMaps) {
            return NSLocalizedString(@"Searching Apple maps found multiple possible starting locations - select a choice from below, or view on a map:", @"section header");
        }
        
        if (self.tripQuery.fromAppleFailed) {
            return NSLocalizedString(@"Apple maps could not find a starting location, so we checked with TriMet.\n\nThe TriMet Trip Planner found multiple possible starting locations - select a choice from below, or view on a map:", @"section header");
        }
        
        return NSLocalizedString(@"The TriMet Trip Planner found multiple possible starting locations - select a choice from below, or view on a map:", @"section header");
    }
    
    if (self.locList && self.locList.count > 0 && self.locList.firstObject.fromAppleMaps) {
        return NSLocalizedString(@"Searching Apple maps found multiple possible destinations - select a choice from below, or view on a map:", @"section header");
    }
    
    if (self.tripQuery.toAppleFailed) {
        return NSLocalizedString(@"Apple maps could not find that destination, we we checked with TriMet.\n\nThe TriMet Trip Planner found multiple possible destinations - select a choice from below, or view on a map:", @"section header");
    }
    
    return NSLocalizedString(@"The TriMet Trip Planner found multiple possible destinations - select a choice from below, or view on a map:", @"section header");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.locList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"TripLocation"];
    
    TripLegEndPoint *p = self.locList[indexPath.row];
    
    cell.textLabel.text = p.desc;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = true;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.accessibilityLabel = p.desc.phonetic;
    
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

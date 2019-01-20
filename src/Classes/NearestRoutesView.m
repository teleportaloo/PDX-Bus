//
//  NearestRoutesView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "NearestRoutesView.h"
#import "RouteDistanceData+iOSUI.h"
#import "DepartureTimesView.h"
#include "DepartureCell.h"

#define kRouteSections        2
#define kSectionRoutes        0
#define kSectionDisclaimer    1

@implementation NearestRoutesView


#pragma mark -
#pragma mark Initialization

- (instancetype) init
{
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Routes",@"page title");
    }
    return self;
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

#pragma mark -
#pragma mark Fetch data



- (void)fetchNearestRoutesAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
    [task taskRunAsync:^{        
        self.routeData = [XMLLocateStops xml];
        
        self.routeData.maxToFind = max;
        self.routeData.location = here;
        self.routeData.mode = mode;
        self.routeData.minDistance = min;
        
        [task taskStartWithItems:1 title:@"getting routes"];
        [self.routeData findNearestRoutes];
        [self.routeData displayErrorIfNoneFound:task];
        self.checked = [NSMutableArray array];
        for (int i=0; i<self.routeData.count; i++)
        {
            self.checked[i] = @NO;
        }
        return (UIViewController*)self;

    }];
}


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add the following line if you want the list to be editable
    // self.navigationItem.leftBarButtonItem = self.editButtonItem;
    // self.title = originalName;
    
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                      initWithTitle:NSLocalizedString(@"Get arrivals", @"button text")
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(showArrivalsAction:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.prompt = NSLocalizedString(@"Select the routes you need:", "page prompt");
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.prompt = nil;
}

#pragma mark UI callbacks

- (void)showArrivalsAction:(id)sender
{
    NSMutableArray *multipleStops = [NSMutableArray array];
    
    for (int i=0; i<self.routeData.count; i++)
    {
        RouteDistanceData *rd = (RouteDistanceData *)self.routeData[i];
        
        if (self.checked[i].boolValue)
        {
            [multipleStops addObjectsFromArray:rd.stops];
        }
    }
    
    [multipleStops sortUsingSelector:@selector(compareUsingDistance:)];
    
    // remove duplicates, they are sorted so the dups will be adjacent
    NSMutableArray *uniqueStops = [NSMutableArray array];

    NSString *lastStop = nil;
    for (StopDistanceData *sd in multipleStops)
    {
        if (lastStop == nil || ![sd.locid isEqualToString:lastStop])
        {
            [uniqueStops addObject:sd];
        }
        lastStop = sd.locid;
    }
    
    while (uniqueStops.count > kMaxStops)
    {
        [uniqueStops removeLastObject];
    }
        
    if (uniqueStops.count > 0)
    {
        [[DepartureTimesView viewController] fetchTimesForNearestStopsAsync:self.backgroundTask stops:uniqueStops];
    }
}



#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case kSectionRoutes:
            if (LARGE_SCREEN)
            {
                return kRouteWideCellHeight;
            }
            return kRouteCellHeight;
        case kSectionDisclaimer:
            return kDisclaimerCellHeight;
    }
    return 1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kRouteSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section)
    {
        case kSectionRoutes:
            return self.routeData.count;
        case kSectionDisclaimer:
            return 1;
    }
    
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    
    switch (indexPath.section)
    {
        case kSectionRoutes:
        {
            RouteDistanceData *rd = (RouteDistanceData*)self.routeData[indexPath.row];
            DepartureCell *dcel = [DepartureCell tableView:tableView genericWithReuseIdentifier:MakeCellId(XkSectionRoutes)];
            [rd populateCell:dcel];
            
            cell = dcel;
            
            if (self.checked[indexPath.row].boolValue)
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else 
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

            break;
        }
        default:
        case kSectionDisclaimer:
            cell = [self disclaimerCell:tableView];
            
            [self addTextToDisclaimerCell:cell text:[self.routeData displayDate:self.routeData.cacheTime]];    
            
            if (self.routeData.items == nil)
            {
                [self noNetworkDisclaimerCell:cell];
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            [self updateDisclaimerAccessibility:cell];
            break;
            
    }
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
       switch (indexPath.section)
    {
        case kSectionRoutes:
        {
            self.checked[indexPath.row] = self.checked[indexPath.row].boolValue ? @NO : @YES;
            [self reloadData];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            /*
            RouteDistance *rd = [self.routeData itemAtIndex:indexPath.row];
            DepartureTimesView *depView = [[DepartureTimesView alloc] init];
            [depView fetchTimesForNearestStopsAsync:self.backgroundTask stops:rd.stops];
            [depView release];
            */
            break;
        }
        case kSectionDisclaimer:
        {
            if (self.routeData.items == nil)
            {
                [self networkTips:self.routeData.htmlError networkError:self.routeData.errorMsg];
                [self clearSelection];
            }
        }
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self updateToolbarItemsWithXml:toolbarItems];
}

-(void)appendXmlData:(NSMutableData *)buffer
{
    [self.routeData appendQueryAndData:buffer];
}


@end


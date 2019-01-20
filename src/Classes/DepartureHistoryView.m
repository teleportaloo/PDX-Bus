//
//  DepartureHistoryView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/15/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "DepartureHistoryView.h"
#import "DepartureTimesView.h"
#import "UserFaves.h"

#define kPlainId @"plain"

@implementation DepartureHistoryView



-(NSString*)stringToFilter:(NSObject*)i
{
    NSNumber *n = (NSNumber*)i;
    NSDictionary *item = self.localRecents[n.integerValue];
    return item[kUserFavesOriginalName];
}

- (NSMutableArray *)loadItems
{
    return _userData.recents;
}

- (bool)tableView:(UITableView*)tableView isHistorySection:(NSInteger)section
{
    return YES;
}

- (NSString *)noItems
{
    return NSLocalizedString(@"These recently viewed stops can be re-used to get current arrivals.", @"section title");
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Recent stops", @"screen title");
}

#pragma mark  Table View methods


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainId];

    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    // Set up the cell

    NSDictionary *item =[self tableView:tableView filteredDict:indexPath.row];
    
    cell.textLabel.text = item[kUserFavesOriginalName];
    cell.textLabel.font = self.basicFont;
    cell.textLabel.numberOfLines = 0;
    [self updateAccessibility:cell];
    cell.imageView.image = [self getFaveIcon:kIconRecent]; 
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    // [self chosenEndpoint:[self.locList objectAtIndex:indexPath.row] ];
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    NSDictionary *item =[self tableView:tableView filteredDict:indexPath.row];
    
    departureViewController.displayName = item[kUserFavesOriginalName];
    [departureViewController fetchTimesForLocationAsync:self.backgroundTask 
                                                    loc:item[kUserFavesLocation]
                                                  title:item[kUserFavesOriginalName]];    
}

@end

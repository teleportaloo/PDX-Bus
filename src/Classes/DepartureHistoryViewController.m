//
//  DepartureHistoryViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/15/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureHistoryViewController.h"
#import "DepartureTimesViewController.h"
#import "Icons.h"
#import "UITableViewCell+Icons.h"
#import "UserParams.h"
#import "UserState.h"

#define kPlainId @"plain"

@interface DepartureHistoryViewController ()

@end

@implementation DepartureHistoryViewController

- (NSString *)stringToFilter:(NSObject *)i {
    NSNumber *n = (NSNumber *)i;
    UserParams *item = self.localRecents[n.integerValue].userParams;

    return item.valOriginalName;
}

- (NSMutableArray *)loadItems {
    return _userState.recentStops;
}

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section {
    return YES;
}

- (NSString *)infoText {
    return NSLocalizedString(@"These recently viewed stops can be re-used to "
                             @"get current departures.",
                             @"section title");
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Recent stops", @"screen title");
}

#pragma mark Table View methods

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UserParams *item = [self tableView:tableView filteredDict:indexPath.row].userParams;

    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainId];

    return [self simpleCell:cell
                       text:item.valOriginalName
                       icon:kIconRecent
              accessoryType:UITableViewCellAccessoryDisclosureIndicator
             selectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];
    UserParams *item = [self tableView:tableView filteredDict:indexPath.row].userParams;

    departureViewController.displayName = item.valOriginalName;
    [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                 stopId:item.valLocation
                                                  title:item.valOriginalName];
}

@end

//
//  DepartureSortTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureSortTableViewController.h"
#import "DepartureTimesViewController.h"
#import "SegmentCell.h"

@interface DepartureSortTableViewController () {
    BOOL _segSetup;
}

@property (nonatomic, copy) NSString *info;

@end

@implementation DepartureSortTableViewController

#define kSections 2

enum { kSectionInfo = 0, kSectionSeg = 1 };

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Group departures", @"screen title");
        self.info =
            NSLocalizedString(@"Group by stop: shows departures for each stop.\n\n"
                               "Group by trip: follows a particular bus or train as it passes "
                               "through each stop.\n\n"
                               "Tip: 'Group by trip' is only useful with bookmarks containing "
                               "several close stops on "
                               "the same route.",
                              @"description of group feature");
    }

    return self;
}

#pragma mark Helper functions

- (void)sortSegmentChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case 0:
        self.depView.blockSort = FALSE;
        break;

    case 1:
        self.depView.blockSort = TRUE;
        break;
    }

    if (!_segSetup) {
        [self.depView resort];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS DepartureSortTableViewController
//--------------------------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView
          vTableOffset:(NSIndexPath *)indexPath
              extraOut:(__autoreleasing id *)extra {
    return indexPath.section;
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionSeg

CREATE_CELL_WITH_CONFIG(kSectionSeg, nil, SegmentCell) {
    _segSetup = YES;
    UITableViewCell *cell = [SegmentCell tableView:tableView
                                   reuseIdentifier:MakeCellId(kSectionSeg)
                                   cellWithContent:@[
                                       NSLocalizedString(@"Group by stop", @"button text"),
                                       NSLocalizedString(@"Group by trip", @"button text")
                                   ]
                                            target:self
                                            action:@selector(sortSegmentChanged:)
                                     selectedIndex:self.depView.blockSort ? 1 : 0];

    _segSetup = NO;
    return cell;
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionInfo

PARA_CELL(kSectionInfo, self.info, nil);

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionSeg),
    CELL_MAP(kSectionInfo),
};

@end

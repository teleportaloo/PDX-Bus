//
//  DepartureSortTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureSortTableView.h"
#import "DepartureTimesView.h"
#import "SegmentCell.h"

@interface DepartureSortTableView () {
    BOOL _segSetup;
}

@property (nonatomic, copy)   NSString *info;


@end

@implementation DepartureSortTableView

#define kSections    2

#define kSectionInfo 0
#define kSectionSeg  1


- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Group departures", @"screen title");
        self.info = NSLocalizedString(@"Group by stop: shows departures for each stop.\n\n"
                                      "Group by trip: follows a particular bus or train as it passes through each stop.\n\n"
                                      "Tip: 'Group by trip' is only useful with bookmarks containing several close stops on "
                                      "the same route.", @"description of group feature");
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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionSeg: {
            _segSetup = YES;
            UITableViewCell *cell = [SegmentCell tableView:tableView
                                           reuseIdentifier:MakeCellId(kSectionSeg)
                                           cellWithContent:@[NSLocalizedString(@"Group by stop", @"button text"),
                                                             NSLocalizedString(@"Group by trip", @"button text")]
                                                    target:self
                                                    action:@selector(sortSegmentChanged:)
                                             selectedIndex:self.depView.blockSort ? 1 : 0];
            
            _segSetup = NO;
            return cell;
            
            break;
        }
            
        case kSectionInfo: {
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionInfo) font:self.smallFont];
            cell.textLabel.text = self.info;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundView = [self clearView];
            return cell;
        }
            break;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionInfo) {
        return UITableViewAutomaticDimension;
    }
    
    return SegmentCell.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

@end

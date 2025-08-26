//
//  TripPlannerOptions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/15/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerOptionsViewController.h"
#import "SegmentCell.h"

@interface TripPlannerOptionsViewController ()

@property(nonatomic, copy) NSString *info;

- (void)walkSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)minSegmentChanged:(id)sender;

@end

@implementation TripPlannerOptionsViewController

enum { kSectionWalk, kSectionMode, kSectionMin, kMinRowSeg, kMinRowInfo };

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Options", @"page title");
        self.info = NSLocalizedString(@"Note: \"Shortest walk\" may suggest a "
                                      @"long ride to avoid a few steps.",
                                      @"trip planner warning info");

        [self createSections];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDoneButtonSameAsBack];
}



- (void)createSections {
    [self clearSectionMaps];

    [self addSectionTypeWithRow:kSectionWalk];
    [self addSectionTypeWithRow:kSectionMode];
    [self addSectionType:kSectionMin];
    [self addRowType:kMinRowSeg];
    [self addRowType:kMinRowInfo];
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Segmented controls

- (void)modeSegmentChanged:(UISegmentedControl *)sender {
    self.tripQuery.userRequest.tripMode = (TripMode)sender.selectedSegmentIndex;
}

- (void)minSegmentChanged:(UISegmentedControl *)sender {
    self.tripQuery.userRequest.tripMin = (TripMin)sender.selectedSegmentIndex;
}

- (void)walkSegmentChanged:(UISegmentedControl *)sender {
    self.tripQuery.userRequest.walk =
        [XMLTrips indexToDistance:(int)sender.selectedSegmentIndex];
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionWalk:
        return NSLocalizedString(@"Maximum walking distance in miles:",
                                 @"section header");

    case kSectionMode:
        return NSLocalizedString(@"Travel by:", @"section header");

    case kSectionMin:
        return NSLocalizedString(@"Show me the:", @"section header");
    }
    return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
    case kSectionWalk:
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kSectionWalk)
            cellWithContent:[XMLTrips distanceMapSingleton]
                     target:self
                     action:@selector(walkSegmentChanged:)
              selectedIndex:[XMLTrips distanceToIndex:self.tripQuery.userRequest
                                                          .walk]];
    case kSectionMode:
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kSectionMode)
            cellWithContent:@[ @"Bus only", @"Rail only", @"Bus or Rail" ]
                     target:self
                     action:@selector(modeSegmentChanged:)
              selectedIndex:self.tripQuery.userRequest.tripMode];

    case kMinRowSeg:
        return
            [SegmentCell tableView:tableView
                   reuseIdentifier:MakeCellId(kMinRowSeg)
                   cellWithContent:@[
                       @"Quickest trip", @"Fewest transfers", @"Shortest walk"
                   ]
                            target:self
                            action:@selector(minSegmentChanged:)
                     selectedIndex:self.tripQuery.userRequest.tripMin];

    case kMinRowInfo: {
        UITableViewCell *cell = [self tableView:tableView
               multiLineCellWithReuseIdentifier:MakeCellId(kMinRowInfo)
                                           font:self.smallFont];
        cell.textLabel.text = self.info;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundView = [self clearView];
        cell.backgroundColor = [UIColor clearColor];

        return cell;
    }
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kMinRowInfo) {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kMinRowInfo) {
        return UITableViewAutomaticDimension;
    }

    return SegmentCell.rowHeight;
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

@end

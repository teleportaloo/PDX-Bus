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

@property (nonatomic, copy) NSString *info;

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
    self.tripQuery.userRequest.walk = [XMLTrips indexToDistance:(int)sender.selectedSegmentIndex];
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionWalk:
        return NSLocalizedString(@"Maximum walking distance in miles:", @"section header");

    case kSectionMode:
        return NSLocalizedString(@"Travel by:", @"section header");

    case kSectionMin:
        return NSLocalizedString(@"Show me the:", @"section header");
    }
    return @"";
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS TripPlannerOptionsViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionWalk

CREATE_CELL_WITH_CONFIG(kSectionWalk, nil, SegmentCell) {
    return [SegmentCell tableView:tableView
                  reuseIdentifier:MakeCellId(kSectionWalk)
                  cellWithContent:[XMLTrips distanceMapSingleton]
                           target:self
                           action:@selector(walkSegmentChanged:)
                    selectedIndex:[XMLTrips distanceToIndex:self.tripQuery.userRequest.walk]];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionMode

CREATE_CELL_WITH_CONFIG(kSectionMode, nil, SegmentCell) {
    return [SegmentCell tableView:tableView
                  reuseIdentifier:MakeCellId(kSectionMode)
                  cellWithContent:@[ @"Bus only", @"Rail only", @"Bus or Rail" ]
                           target:self
                           action:@selector(modeSegmentChanged:)
                    selectedIndex:self.tripQuery.userRequest.tripMode];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kMinRowSeg

CREATE_CELL_WITH_CONFIG(kMinRowSeg, nil, SegmentCell) {
    return [SegmentCell tableView:tableView
                  reuseIdentifier:MakeCellId(kMinRowSeg)
                  cellWithContent:@[ @"Quickest trip", @"Fewest transfers", @"Shortest walk" ]
                           target:self
                           action:@selector(minSegmentChanged:)
                    selectedIndex:self.tripQuery.userRequest.tripMin];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kMinRowInfo

PARA_CELL(kMinRowInfo, self.info, nil);

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kSectionWalk),
    CELL_MAP(kSectionMode),
    CELL_MAP(kMinRowSeg),
    CELL_MAP(kMinRowInfo),
};

@end

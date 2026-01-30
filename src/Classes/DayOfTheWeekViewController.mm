//
//  DayOfTheWeekViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/26/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DayOfTheWeekViewController.h"
#import "EditBookMarkViewController.h"
#import "SegmentCell.h"
#import "UserParams.h"

#define kCommuteSectionSegAm 0
#define kCommuteSectionSegPm 1

#define kAmOrPmId @"AmOrPm"
#define kDayOfWeekId @"DayOfWeek"

@interface DayOfTheWeekViewController ()

@end

@implementation DayOfTheWeekViewController

enum { kMorningOrEvening = kDayNoBit, kSection = 0 };

- (int)days {
    return self.originalFave.valDayOfWeek;
}

- (bool)autoCommuteMorning {
    return self.originalFave.valMorning;
}

#pragma mark Segmented controls

- (void)amOrPmSegmentChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case kCommuteSectionSegAm:
        self.originalFave.valMorning = true;
        break;

    case kCommuteSectionSegPm:
        self.originalFave.valMorning = false;
        break;
    }
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Days of the week", @"screen title");

    [self clearSectionMaps];
    [self addSectionType:kSection];
    [self addRowType:kDayInfo];
    [self addRowType:kDayMonBit];
    [self addRowType:kDayTueBit];
    [self addRowType:kDayWedBit];
    [self addRowType:kDayThuBit];
    [self addRowType:kDayFriBit];
    [self addRowType:kDaySatBit];
    [self addRowType:kDaySunBit];
    [self addRowType:kMorningOrEvening];

    [super viewDidLoad];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS DayOfTheWeekViewController

//--------------------------------------------------------------------------------------------------
#pragma mark kMorningOrEvening

CREATE_CELL_WITH_CONFIG(kMorningOrEvening, nil, SegmentCell) {
    return [SegmentCell
              tableView:tableView
        reuseIdentifier:kAmOrPmId
        cellWithContent:@[
            NSLocalizedString(@"Morning", @"commuter bookmark option"),
            NSLocalizedString(@"Afternoon", @"commuter bookmark option")
        ]
                 target:self
                 action:@selector(amOrPmSegmentChanged:)
          selectedIndex:[self autoCommuteMorning] ? kCommuteSectionSegAm : kCommuteSectionSegPm];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kDayMon kDayTue kDayWed kDayThu kDayFri kDaySat kDaySun

// We re-use monday for all he other days of the week
BASIC_CELL_SELECT(kDayMonBit,
                  ([NSString
                      stringWithFormat:
                          NSLocalizedString(@"Every %@", @"before a list of the days of the week"),
                          [EditBookMarkViewController daysString:DAY_BIT_SHIFT(offset)]]),
                  nil,
                  ((self.days & DAY_BIT_SHIFT(offset)) != 0) ? UITableViewCellAccessoryCheckmark
                                                             : UITableViewCellAccessoryNone) {
    unsigned int days = self.days;
    days = days ^ DAY_BIT_SHIFT(offset);
    self.originalFave.valDayOfWeek = days;

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

#define STATIC_DAY(TOK)                                                                            \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_SELECT_SEL(kDayMonBit),                                                           \
        SET_CELL_UPDATE_SEL(kDayMonBit),                                                           \
        SET_CELL_HEIGHT_SEL(basic),                                                                \
    };

STATIC_DAY(kDayTueBit);
STATIC_DAY(kDayWedBit);
STATIC_DAY(kDayThuBit);
STATIC_DAY(kDayFriBit);
STATIC_DAY(kDaySatBit);
STATIC_DAY(kDaySunBit);

//--------------------------------------------------------------------------------------------------
PARA_CELL(
    kDayInfo,
    NSLocalizedString(@"Select each day of the week that the bookmark will be automatically shown:",
                      @"info text"),
    nil);

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kMorningOrEvening),
    CELL_MAP(kDayMonBit),
    CELL_MAP(kDayTueBit),
    CELL_MAP(kDayWedBit),
    CELL_MAP(kDayThuBit),
    CELL_MAP(kDayFriBit),
    CELL_MAP(kDaySatBit),
    CELL_MAP(kDaySunBit),
    CELL_MAP(kDayInfo),
};

@end

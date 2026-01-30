//
//  TripPlannerSummaryView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "TripPlannerSummaryViewController.h"
#import "DatePickerCell.h"
#import "Icons.h"
#import "SegmentCell.h"
#import "TripPlannerEndPointViewController.h"
#import "TripPlannerFetcher.h"
#import "TripPlannerHistoryViewController.h"
#import "TripPlannerOptionsViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UITableViewCell+Icons.h"
#import "UserState.h"

enum {
    kSectionUserRequest,
    kTripSectionRowFrom,
    kTripSectionRowTo,
    kTripSectionRowOptions,
    kTripSectionRowDateSeg,
    kTripSectionRowDatePicker,
    kTripSectionRowPlan,
    kTripSectionRowHistory
};

enum { kSegTimeNow = 0, kSegDepartureTime, kSegArrivalTime };

@interface TripPlannerSummaryViewController () {
    NSUInteger _pickerRow;
    NSUInteger _pickerSection;
}

@property (nonatomic, strong) UIDatePicker *datePickerView;

@end

@implementation TripPlannerSummaryViewController

- (instancetype)init {
    if ((self = [super init])) {
        self.tripQuery = [XMLTrips xml];

        NSDictionary *lastTrip = _userState.lastTrip;

        if (lastTrip != nil) {
            TripUserRequest *req = [TripUserRequest fromDictionary:lastTrip];
            req.dateAndTime = nil;
            req.arrivalTime = NO;
            req.fromPoint.coordinates = nil;
            req.toPoint.coordinates = nil;
            req.timeChoice = TripDepartAfterTime;
            [req clearGpsNames];

            self.tripQuery.userRequest = req;
        }

        [self makeSummaryRows];
    }

    return self;
}

- (void)makeSummaryRows {
    [self makeSummaryRowsWithPicker:self.tripQuery.userRequest.dateAndTime != nil];
}

- (void)makeSummaryRowsWithPicker:(bool)hasPicker {
    [self clearSectionMaps];

    _pickerSection = [self addSectionType:kSectionUserRequest];
    [self addRowType:kTripSectionRowFrom];
    [self addRowType:kTripSectionRowTo];
    [self addRowType:kTripSectionRowOptions];

    if (hasPicker) {
        [self addRowType:kTripSectionRowDateSeg];
        _pickerRow = [self addRowType:kTripSectionRowDatePicker];
    } else {
        _pickerRow = [self addRowType:kTripSectionRowDateSeg] + 1;
    }

    [self addSectionType:kTripSectionRowPlan];
    [self addRowType:kTripSectionRowPlan];

    [self addSectionType:kTripSectionRowHistory];
    [self addRowType:kTripSectionRowHistory];
}

- (void)initQuery {
    self.tripQuery.userFaves = _userState.stopsFromFaves;
    [self makeSummaryRows];
}

- (void)reloadData {
    [self makeSummaryRows];
    [super reloadData];
}

- (void)resetAction:(id)sender {
    self.tripQuery = [XMLTrips xml];
    [self reloadData];
}

- (void)reverseAction:(id)sender {
    TripEndPoint *savedFrom = self.tripQuery.userRequest.fromPoint;

    self.tripQuery.userRequest.fromPoint = self.tripQuery.userRequest.toPoint;
    self.tripQuery.userRequest.toPoint = savedFrom;
    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    [self.tableView registerNib:[TripItemCell nib] forCellReuseIdentifier:kTripItemCellId];

    self.title = NSLocalizedString(@"Trip Planner", @"page title");

    self.navigationItem.rightBarButtonItem =
        [UIBarButtonItem textButton:NSLocalizedString(@"Reset", @"button text")
                             target:self
                             action:@selector(resetAction:)];
    ;
}

- (void)viewWillDisappear:(BOOL)animated {
    _userState.lastTrip = [self.tripQuery.userRequest toDictionary];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self sectionType:section] == kSectionUserRequest) {
        return NSLocalizedString(@"Enter trip details:", @"section header");
    }

    return nil;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [toolbarItems
        addObject:[UIBarButtonItem textButton:NSLocalizedString(@"Reverse trip", @"button text")
                                       target:self
                                       action:@selector(reverseAction:)]];

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)populateOptions:(TripItemCell *)cell {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    [cell populateMarkedUpBody:[self.tripQuery.userRequest optionsDisplayText]
                          mode:@"Options"
                          time:nil
                     leftColor:nil
                         route:nil];
}

- (void)populateEnd:(TripItemCell *)cell from:(bool)from {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    NSString *text;
    NSString *dir;

    if (from) {
        text = [self.tripQuery.userRequest.fromPoint markedUpUserInputDisplayText];
        dir = @"From";
    } else {
        text = [self.tripQuery.userRequest.toPoint markedUpUserInputDisplayText];
        dir = @"To";
    }

    [cell populateMarkedUpBody:text mode:dir time:nil leftColor:nil route:nil];
}

- (NSUInteger)timeChoice {
    if (self.tripQuery.userRequest.dateAndTime == nil) {
        return kSegTimeNow;
    }

    if (self.tripQuery.userRequest.arrivalTime) {
        return kSegArrivalTime;
    }

    return kSegDepartureTime;
}

- (void)pickerChanged:(id)sender {
    UIDatePicker *datePicker = (UIDatePicker *)sender;

    self.tripQuery.userRequest.dateAndTime = datePicker.date;
}

- (void)timeSegmentChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case kSegTimeNow:

        if (self.tripQuery.userRequest.dateAndTime != nil) {
            self.tripQuery.userRequest.dateAndTime = nil;

            NSInteger userRequestSection = [self firstSectionOfType:kSectionUserRequest];

            if ([self firstRowOfType:kTripSectionRowDatePicker
                           inSection:userRequestSection] != kNoRowSectionTypeFound) {
                [self makeSummaryRows];

                [self.tableView beginUpdates];
                [self.tableView
                    deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow
                                                                 inSection:_pickerSection] ]
                          withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
            }
        }

        break;

    case kSegArrivalTime:
        self.tripQuery.userRequest.arrivalTime = YES;

        if (self.tripQuery.userRequest.dateAndTime == nil) {
            self.tripQuery.userRequest.dateAndTime = [NSDate date];

            NSInteger userRequestSection = [self firstSectionOfType:kSectionUserRequest];

            if ([self firstRowOfType:kTripSectionRowDatePicker
                           inSection:userRequestSection] == kNoRowSectionTypeFound) {
                [self makeSummaryRows];

                [self.tableView beginUpdates];
                [self.tableView
                    insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow
                                                                 inSection:_pickerSection] ]
                          withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
            }
        }

        break;

    case kSegDepartureTime:
        self.tripQuery.userRequest.arrivalTime = NO;

        if (self.tripQuery.userRequest.dateAndTime == nil) {
            self.tripQuery.userRequest.dateAndTime = [NSDate date];

            NSInteger userRequestSection = [self firstSectionOfType:kSectionUserRequest];

            if ([self firstRowOfType:kTripSectionRowDatePicker
                           inSection:userRequestSection] == kNoRowSectionTypeFound) {
                [self makeSummaryRows];

                [self.tableView beginUpdates];
                [self.tableView
                    insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow
                                                                 inSection:_pickerSection] ]
                          withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
            }
        }

        break;
    }
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS TripPlannerSummaryViewController
//--------------------------------------------------------------------------------------------------

CELL_SELECT_METHOD(ToAndFrom) {
    TripPlannerEndPointViewController *tripEnd = [TripPlannerEndPointViewController viewController];

    tripEnd.from = (offset != kTripSectionRowTo);
    tripEnd.tripQuery = [XMLTrips xml];
    tripEnd.tripQuery.userRequest = self.tripQuery.userRequest;
    tripEnd.tripQuery.userFaves = _userState.stopsFromFaves;
    tripEnd.popBackTo = self;
    [self.navigationController pushViewController:tripEnd animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowFrom

CELL_CONFIG_METHOD(kTripSectionRowFrom) {
    TripItemCell *cell =
        (TripItemCell *)[tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
    [self populateEnd:cell from:YES];
    return cell;
}

CELL_STATIC_VTABLE(kTripSectionRowFrom){
    SET_CELL_SELECT_SEL(ToAndFrom),
    SET_CELL_CONFIG_SEL(kTripSectionRowFrom),
    SET_CELL_HEIGHT_SEL(auto),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowTo

CELL_CONFIG_METHOD(kTripSectionRowTo) {
    TripItemCell *cell =
        (TripItemCell *)[tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
    [self populateEnd:cell from:NO];
    return cell;
}

CELL_STATIC_VTABLE(kTripSectionRowTo){
    SET_CELL_SELECT_SEL(ToAndFrom),
    SET_CELL_CONFIG_SEL(kTripSectionRowTo),
    SET_CELL_HEIGHT_SEL(auto),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowOptions

CELL_CONFIG_METHOD(kTripSectionRowOptions) {
    TripItemCell *cell =
        (TripItemCell *)[tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
    [self populateOptions:cell];
    return cell;
}

CELL_SELECT_METHOD(kTripSectionRowOptions) {
    TripPlannerOptionsViewController *options = [TripPlannerOptionsViewController viewController];

    options.tripQuery = [XMLTrips xml];
    options.tripQuery.userRequest = self.tripQuery.userRequest;
    // options.userRequestCallback = self;

    [self.navigationController pushViewController:options animated:YES];
}

STATIC_VTABLE_VCS_H(kTripSectionRowOptions, auto)

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowDateSeg

CREATE_CELL_WITH_CONFIG(kTripSectionRowDateSeg, nil, SegmentCell) {
    return [SegmentCell tableView:tableView
                  reuseIdentifier:MakeCellId(kTripSectionRowDateSeg)
                  cellWithContent:@[
                      NSLocalizedString(@"Depart now", @"trip time in bookmark"),
                      NSLocalizedString(@"Depart after...", @"trip time in bookmark"),
                      NSLocalizedString(@"Arrive by...", @"trip time in bookmark")
                  ]
                           target:self
                           action:@selector(timeSegmentChanged:)
                    selectedIndex:self.timeChoice];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowDatePicker

CREATE_CELL_WITH_CONFIG(kTripSectionRowDatePicker, CELL_REG_SEL(DatePickerCell), auto) {
    DatePickerCell *datePicker =
        (DatePickerCell *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(DatePickerCell)];

    self.datePickerView = datePicker.datePickerView;

    if (self.tripQuery.userRequest.dateAndTime != nil) {
        datePicker.datePickerView.date = self.tripQuery.userRequest.dateAndTime;
    }

    [datePicker.datePickerView addTarget:self
                                  action:@selector(pickerChanged:)
                        forControlEvents:UIControlEventValueChanged];
    return datePicker;
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowPlan

BASIC_CELL_SELECT(kTripSectionRowPlan,
                  NSLocalizedString(@"Show trip", @"main menu item"),
                  kIconTripPlanner,
                  UITableViewCellAccessoryDisclosureIndicator) {

    if (self.tripQuery != nil &&
        (self.tripQuery.userRequest.toPoint.useCurrentLocation ||
         self.tripQuery.userRequest.toPoint.locationDesc != nil) &&
        (self.tripQuery.userRequest.fromPoint.useCurrentLocation ||
         self.tripQuery.userRequest.fromPoint.locationDesc != nil)) {
        _userState.lastTrip = [self.tripQuery.userRequest toDictionary];

        TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

        fetcher.tripQuery = self.tripQuery;

        [fetcher nextScreen:self.navigationController
               forceResults:NO
                  postQuery:NO
              taskContainer:self.backgroundTask];
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
                      message:NSLocalizedString(@"Select a start and destination to plan "
                                                @"a trip.",
                                                @"alert message")
               viewController:self
                   completion:nil];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTripSectionRowHistory

BASIC_CELL_SELECT(kTripSectionRowHistory,
                  NSLocalizedString(@"Recent trips", @"main menu item"),
                  kIconRecent,
                  UITableViewCellAccessoryDisclosureIndicator) {

    [self.navigationController pushViewController:[TripPlannerHistoryViewController viewController]
                                         animated:YES];
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kTripSectionRowTo),
    CELL_MAP(kTripSectionRowFrom),
    CELL_MAP(kTripSectionRowOptions),
    CELL_MAP(kTripSectionRowDateSeg),
    CELL_MAP(kTripSectionRowDatePicker),
    CELL_MAP(kTripSectionRowPlan),
    CELL_MAP(kTripSectionRowHistory),
};

@end

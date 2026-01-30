//
//  TripPlannerDateView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerDateViewController.h"
#import "DatePickerCell.h"
#import "TableViewControllerWithToolbar.h"
#import "TripPlannerFetcher.h"
#import "TripPlannerOptionsViewController.h"
#import "UIApplication+Compat.h"

enum {
    kSectionDateButtons,
    kSectionDateDepartNow,
    kSectionDateDeparture,
    kSectionDateArrival,
    kSectionDatePicker
};

@interface TripPlannerDateViewController ()

@property (nonatomic, strong) UIDatePicker *datePickerView;

@end

@implementation TripPlannerDateViewController

#define kDatePickerSections 1
#define kDatePickerButtonsPerSection 3

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Date and Time", @"page title");
    }

    return self;
}

- (void)initializeFromBookmark:(TripUserRequest *)req {
    self.tripQuery = [XMLTrips xml];
    self.tripQuery.userRequest = req;

    if (!req.historical) {
        req.dateAndTime = nil;

        // Force a getting of the current location
        if (req.fromPoint.useCurrentLocation) {
            req.fromPoint.coordinates = nil;
            req.fromPoint.additionalInfo = nil;
            req.fromPoint.locationDesc = nil;
        }

        if (req.toPoint.useCurrentLocation) {
            req.toPoint.coordinates = nil;
            req.toPoint.additionalInfo = nil;
            req.toPoint.locationDesc = nil;
        }
    }
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark UI Helper functions

- (void)showOptions:(id)sender {
    TripPlannerOptionsViewController *options = [TripPlannerOptionsViewController viewController];

    options.tripQuery = self.tripQuery;

    [self.navigationController pushViewController:options animated:YES];
}

#pragma mark TableView methods

- (void)cellSelected {
    if (self.popBack) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

        fetcher.tripQuery = self.tripQuery;

        [fetcher nextScreen:self.navigationController
               forceResults:NO
                  postQuery:NO
              taskContainer:self.backgroundTask];
    }
}

- (void)nextScreen:(UINavigationController *)controller
     taskContainer:(BackgroundTaskContainer *)taskContainer {
    if (self.tripQuery.userRequest.timeChoice == TripAskForTime) {
        [controller pushViewController:self animated:YES];
    } else {
        self.tripQuery.userRequest.arrivalTime =
            (self.tripQuery.userRequest.timeChoice == TripArriveBeforeTime);

        if (!self.tripQuery.userRequest.historical) {
            self.tripQuery.userRequest.dateAndTime = [NSDate date];
        }

        TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

        fetcher.tripQuery = self.tripQuery;

        [fetcher nextScreen:controller forceResults:NO postQuery:NO taskContainer:taskContainer];
    }
}

#pragma mark View Methds

- (void)loadView {
    [super loadView];

    [self clearSectionMaps];

    [self addSectionType:kSectionDateButtons];

    [self addRowType:kSectionDateDepartNow];
    [self addRowType:kSectionDateDeparture];
    [self addRowType:kSectionDateArrival];

    [self addSectionType:kSectionDatePicker];
    [self addRowType:kSectionDatePicker];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.tripQuery == nil) {
        self.tripQuery = [XMLTrips xml];
        self.tripQuery.userFaves = self.userFaves;
    }
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS TripPlannerDateViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDateDepartNow

MARKUP_CELL_SELECT(kSectionDateDepartNow,
                   auto,
                   NSLocalizedString(@"Depart now", @"button text"),
                   nil,
                   self.popBack ? UITableViewCellAccessoryNone
                                : UITableViewCellAccessoryDisclosureIndicator) {

    self.tripQuery.userRequest.arrivalTime = false;
    self.tripQuery.userRequest.dateAndTime = nil;
    [self cellSelected];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDateArrival

MARKUP_CELL_SELECT(kSectionDateDeparture,
                   auto,
                   NSLocalizedString(@"Depart after the time below", @"button text"),
                   nil,
                   self.popBack ? UITableViewCellAccessoryNone
                                : UITableViewCellAccessoryDisclosureIndicator) {

    self.tripQuery.userRequest.arrivalTime = false;
    self.tripQuery.userRequest.dateAndTime = self.datePickerView.date;
    [self cellSelected];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDateArrival

MARKUP_CELL_SELECT(kSectionDateArrival,
                   auto,
                   NSLocalizedString(@"Arrive by the time below", @"button text"),
                   nil,
                   self.popBack ? UITableViewCellAccessoryNone
                                : UITableViewCellAccessoryDisclosureIndicator) {

    self.tripQuery.userRequest.arrivalTime = true;
    self.tripQuery.userRequest.dateAndTime = self.datePickerView.date;
    [self cellSelected];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDatePicker

CREATE_CELL_WITH_CONFIG(kSectionDatePicker, CELL_REG_SEL(DatePickerCell), auto) {
    DatePickerCell *datePicker =
        (DatePickerCell *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(DatePickerCell)];

    self.datePickerView = datePicker.datePickerView;

    if (self.tripQuery.userRequest.dateAndTime != nil) {
        self.datePickerView.date = self.tripQuery.userRequest.dateAndTime;
    }
    return datePicker;
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kSectionDateDepartNow),
    CELL_MAP(kSectionDateArrival),
    CELL_MAP(kSectionDateDeparture),
    CELL_MAP(kSectionDatePicker),
};

@end

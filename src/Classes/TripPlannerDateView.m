//
//  TripPlannerDateView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerDateView.h"
#import "TableViewWithToolbar.h"
#import "TripPlannerLocatingView.h"
#import "TripPlannerOptions.h"
#import "DatePickerCell.h"
#import "UIApplication+Compat.h"

enum {
    kSectionDateButtons,
    kSectionDateDepartNow,
    kSectionDateDeparture,
    kSectionDateArrival,
    kSectionDatePicker
};

@interface TripPlannerDateView ()

@property (nonatomic, strong) UIDatePicker *datePickerView;

@end

@implementation TripPlannerDateView

#define kDatePickerSections          1
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
    TripPlannerOptions *options = [TripPlannerOptions viewController];
    
    options.tripQuery = self.tripQuery;
    
    [self.navigationController pushViewController:options animated:YES];
}

#pragma mark TableView methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [self rowType:indexPath];
    NSInteger section = [self sectionType:indexPath.section];
    UITableViewCell *cell = nil;
    
    
    switch (section) {
        default:
        case kSectionDateButtons: {
            cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionDateButtons)];
            switch (row) {
                case kSectionDateDepartNow:
                default:
                    cell.textLabel.text = NSLocalizedString(@"Depart now", @"button text");
                    break;
                    
                case kSectionDateDeparture:
                    cell.textLabel.text = NSLocalizedString(@"Depart after the time below", @"button text");
                    break;
                    
                case kSectionDateArrival:
                    cell.textLabel.text = NSLocalizedString(@"Arrive by the time below", @"button text");
                    break;
            }
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = self.popBack ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
            
        case kSectionDatePicker: {
            cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionDatePicker)];
            
            DatePickerCell *datePicker = (DatePickerCell *)cell;
            
            self.datePickerView = datePicker.datePickerView;
            
            if (self.tripQuery.userRequest.dateAndTime != nil) {
                self.datePickerView.date = self.tripQuery.userRequest.dateAndTime;
            }
            
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tripQuery.userRequest.dateAndTime = self.datePickerView.date;
    
    switch ([self rowType:indexPath]) {
        case kSectionDateDeparture:
            self.tripQuery.userRequest.arrivalTime = false;
            break;
            
        case kSectionDateArrival:
            self.tripQuery.userRequest.arrivalTime = true;
            break;
            
        case kSectionDateDepartNow:
            self.tripQuery.userRequest.arrivalTime = false;
            self.tripQuery.userRequest.dateAndTime = nil;
            break;
    }
    
    if (self.popBack) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        TripPlannerLocatingView *locView = [TripPlannerLocatingView viewController];
        
        locView.tripQuery = self.tripQuery;
        
        [locView nextScreen:self.navigationController forceResults:NO postQuery:NO
                orientation:[UIApplication sharedApplication].compatStatusBarOrientation
              taskContainer:self.backgroundTask];
    }
}

- (void)nextScreen:(UINavigationController *)controller taskContainer:(BackgroundTaskContainer *)taskContainer {
    if (self.tripQuery.userRequest.timeChoice == TripAskForTime) {
        [controller pushViewController:self animated:YES];
    } else {
        self.tripQuery.userRequest.arrivalTime = (self.tripQuery.userRequest.timeChoice == TripArriveBeforeTime);
        
        if (!self.tripQuery.userRequest.historical) {
            self.tripQuery.userRequest.dateAndTime = [NSDate date];
        }
        
        TripPlannerLocatingView *locView = [TripPlannerLocatingView viewController];
        
        locView.tripQuery = self.tripQuery;
        
        [locView nextScreen:controller forceResults:NO postQuery:NO orientation:[UIApplication sharedApplication].compatStatusBarOrientation taskContainer:taskContainer];
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
    
    [self.table registerNib:[DatePickerCell nib] forCellReuseIdentifier:MakeCellId(kSectionDatePicker)];
    
    if (self.tripQuery == nil) {
        self.tripQuery = [XMLTrips xml];
        self.tripQuery.userFaves = self.userFaves;
    }
}

@end

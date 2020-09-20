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


#import "TripPlannerSummaryView.h"
#import "UserState.h"
#import "TripPlannerEndPointView.h"
#import "TripPlannerOptions.h"
#import "TripPlannerLocatingView.h"
#import "TripPlannerHistoryView.h"
#import "SegmentCell.h"
#import "DatePickerCell.h"
#import "Icons.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

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

enum {
    kSegTimeNow = 0,
    kSegDepartureTime,
    kSegArrivalTime
};

@interface TripPlannerSummaryView () {
    NSUInteger _pickerRow;
    NSUInteger _pickerSection;
}

@property (nonatomic, strong) UIDatePicker *datePickerView;

@end

@implementation TripPlannerSummaryView

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
    [self.tripQuery addStopsFromUserFaves:_userState.faves];
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
    
    
    [self.table registerNib:[DatePickerCell nib] forCellReuseIdentifier:MakeCellId(kTripSectionRowDatePicker)];
    
    [self.table registerNib:[TripItemCell nib] forCellReuseIdentifier:kTripItemCellId];
    
    self.title = NSLocalizedString(@"Trip Planner", @"page title");
    
    UIBarButtonItem *resetButton = [[UIBarButtonItem alloc]
                                    initWithTitle:NSLocalizedString(@"Reset", @"button text")
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(resetAction:)];
    
    self.navigationItem.rightBarButtonItem = resetButton;
}

- (void)viewWillDisappear:(BOOL)animated {
    _userState.lastTrip = [self.tripQuery.userRequest toDictionary];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
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

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *reverse = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reverse trip", @"button text")
                                                                style:UIBarButtonItemStylePlain
                                                               target:self action:@selector(reverseAction:)];
    
    
    [toolbarItems addObject:reverse];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = 0.0;
    
    switch ([self rowType:indexPath]) {
        case kTripSectionRowDateSeg:
            return SegmentCell.rowHeight;
            
        case kTripSectionRowOptions:
        case kTripSectionRowTo:
        case kTripSectionRowFrom:
        case kTripSectionRowDatePicker:
            return UITableViewAutomaticDimension;
            
        case kTripSectionRowPlan:
        case kTripSectionRowHistory:
            result = [self basicRowHeight];
            break;
    }
    return result;
}

- (void)populateOptions:(TripItemCell *)cell {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    
    [cell populateBody:[self.tripQuery.userRequest optionsDisplayText] mode:@"Options" time:nil leftColor:nil route:nil];
}

- (void)populateEnd:(TripItemCell *)cell from:(bool)from {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    
    NSString *text;
    NSString *dir;
    
    if (from) {
        text = [self.tripQuery.userRequest.fromPoint userInputDisplayText];
        dir = @"From";
    } else {
        text = [self.tripQuery.userRequest.toPoint userInputDisplayText];
        dir = @"To";
    }
    
    [cell populateBody:text mode:dir time:nil leftColor:nil route:nil];
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
                
                if ([self firstRowOfType:kTripSectionRowDatePicker inSection:userRequestSection] != kNoRowSectionTypeFound) {
                    [self makeSummaryRows];
                    
                    [self.table beginUpdates];
                    [self.table deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow inSection:_pickerSection] ]
                                      withRowAnimation:UITableViewRowAnimationRight];
                    [self.table endUpdates];
                }
            }
            
            break;
            
        case kSegArrivalTime:
            self.tripQuery.userRequest.arrivalTime = YES;
            
            if (self.tripQuery.userRequest.dateAndTime == nil) {
                self.tripQuery.userRequest.dateAndTime = [NSDate date];
                
                NSInteger userRequestSection = [self firstSectionOfType:kSectionUserRequest];
                
                if ([self firstRowOfType:kTripSectionRowDatePicker inSection:userRequestSection] == kNoRowSectionTypeFound) {
                    [self makeSummaryRows];
                    
                    [self.table beginUpdates];
                    [self.table insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow inSection:_pickerSection] ]
                                      withRowAnimation:UITableViewRowAnimationRight];
                    [self.table endUpdates];
                }
            }
            
            break;
            
        case kSegDepartureTime:
            self.tripQuery.userRequest.arrivalTime = NO;
            
            if (self.tripQuery.userRequest.dateAndTime == nil) {
                self.tripQuery.userRequest.dateAndTime = [NSDate date];
                
                NSInteger userRequestSection = [self firstSectionOfType:kSectionUserRequest];
                
                if ([self firstRowOfType:kTripSectionRowDatePicker inSection:userRequestSection] == kNoRowSectionTypeFound) {
                    [self makeSummaryRows];
                    
                    [self.table beginUpdates];
                    [self.table insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_pickerRow inSection:_pickerSection] ]
                                      withRowAnimation:UITableViewRowAnimationRight];
                    [self.table endUpdates];
                }
            }
            
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType) {
        case kTripSectionRowFrom:
        case kTripSectionRowTo: {
            TripItemCell *cell = (TripItemCell *)[tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
            [self populateEnd:cell from:rowType == kTripSectionRowFrom];
            return cell;
        }
            
        case kTripSectionRowOptions: {
            TripItemCell *cell = (TripItemCell *)[tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
            [self populateOptions:cell];
            return cell;
        }
            
        case kTripSectionRowDateSeg: {
            return [SegmentCell tableView:tableView
                          reuseIdentifier:MakeCellId(kTripSectionRowDateSeg)
                          cellWithContent:@[NSLocalizedString(@"Depart now", @"trip time in bookmark"),
                                            NSLocalizedString(@"Depart after...", @"trip time in bookmark"),
                                            NSLocalizedString(@"Arrive by...", @"trip time in bookmark")]
                                   target:self
                                   action:@selector(timeSegmentChanged:)
                            selectedIndex:self.timeChoice];
        }
            
        case kTripSectionRowDatePicker: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTripSectionRowDatePicker)];
            
            DatePickerCell *datePicker = (DatePickerCell *)cell;
            self.datePickerView = datePicker.datePickerView;
            
            if (self.tripQuery.userRequest.dateAndTime != nil) {
                datePicker.datePickerView.date = self.tripQuery.userRequest.dateAndTime;
            }
            
            [datePicker.datePickerView addTarget:self action:@selector(pickerChanged:) forControlEvents:UIControlEventValueChanged];
            return cell;;
            break;
        }
            
        case kTripSectionRowPlan: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTripSectionRowPlan)];
            
            // Set up the cell
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Show trip", @"main menu item");
            cell.imageView.image = [Icons getIcon:kIconTripPlanner];
            return cell;
        }
            
        case kTripSectionRowHistory: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTripSectionRowHistory)];
            
            // Set up the cell
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Recent trips", @"main menu item");
            cell.imageView.image = [Icons getIcon:kIconRecent];
            return cell;
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType) {
        case kTripSectionRowFrom:
        case kTripSectionRowTo: {
            TripPlannerEndPointView *tripEnd = [TripPlannerEndPointView viewController];
            
            
            tripEnd.from = (rowType != kTripSectionRowTo);
            tripEnd.tripQuery = [XMLTrips xml];
            tripEnd.tripQuery.userRequest = self.tripQuery.userRequest;
            @synchronized (_userState)
            {
                [tripEnd.tripQuery addStopsFromUserFaves:_userState.faves];
            }
            tripEnd.popBackTo = self;
            // tripEnd.userRequestCallback = self;
            
            
            // Push the detail view controller
            [self.navigationController pushViewController:tripEnd animated:YES];
            break;
        }
            
        case kTripSectionRowOptions: {
            TripPlannerOptions *options = [TripPlannerOptions viewController];
            
            options.tripQuery = [XMLTrips xml];
            options.tripQuery.userRequest = self.tripQuery.userRequest;
            // options.userRequestCallback = self;
            
            [self.navigationController pushViewController:options animated:YES];
            // _reloadTrip = YES;
            break;
        }
            
        case kTripSectionRowPlan: {
            if (self.tripQuery != nil
                && (self.tripQuery.userRequest.toPoint.useCurrentLocation || self.tripQuery.userRequest.toPoint.locationDesc != nil)
                && (self.tripQuery.userRequest.fromPoint.useCurrentLocation || self.tripQuery.userRequest.fromPoint.locationDesc != nil)) {
                _userState.lastTrip = [self.tripQuery.userRequest toDictionary];
                
                TripPlannerLocatingView *locView = [TripPlannerLocatingView viewController];
                
                locView.tripQuery = self.tripQuery;
                
                [locView nextScreen:self.navigationController forceResults:NO postQuery:NO orientation:[UIApplication sharedApplication].compatStatusBarOrientation
                      taskContainer:self.backgroundTask];
            } else {
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
                
                UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
                                                                        message:NSLocalizedString(@"Select a start and destination to plan a trip.", @"alert message")];
                [self presentViewController:alert animated:YES completion:nil];
                
            }
            
            break;
        }
            
        case kTripSectionRowHistory: {
            [self.navigationController pushViewController:[TripPlannerHistoryView viewController] animated:YES];
        }
            break;
    }
}

@end

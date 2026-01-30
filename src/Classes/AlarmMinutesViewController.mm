//
//  AlarmViewMinutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmMinutesViewController.h"
#import "AlarmTaskList.h"
#import "Icons.h"
#import "PickerCell.h"
#import "RootViewController.h"
#import "SegmentCell.h"
#import "Settings.h"
#import "TriMetInfo+UI.h"
#import "UITableViewCell+Icons.h"
#import "UIViewController+LocationAuthorization.h"

enum { kAlertViewRowTitle, kAlertViewRowAlert, kAlertViewRowCancel, kAlertPicker, kAlertGps };

@interface AlarmMinutesViewController () {
    NSInteger _rowChosen;
}

@property (nonatomic, strong) UIPickerView *pickerView;

@end

@implementation AlarmMinutesViewController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Alert Time", @"screen title");
        _rowChosen = kAlertViewRowAlert;
    }

    return self;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self sectionType:section] == kAlertGps) {
        if ([UIViewController locationAuthorizedOrNotDeterminedWithBackground:YES]) {
            return NSLocalizedString(
                @"Departure alarms are more accurate as the app can track your "
                @"location in the background while the alarm is active.",
                @"Title");
        } else {
            return NSLocalizedString(
                @"Departure alarms are not so accurate as the app cannot track "
                @"your location in the background.",
                @"Title");
        }
    }

    return nil;
}

- (void)setAlarmAction:(id)sender {
    _rowChosen = kAlertViewRowAlert;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [toolbarItems addObject:[UIBarButtonItem textButton:NSLocalizedString(@"Set Alarm", @"button")
                                                 target:self
                                                 action:@selector(setAlarmAction:)]];

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark View Methds

- (void)loadView {
    [super loadView];

    [self clearSectionMaps];

    [self addSectionType:kAlertViewRowTitle];
    [self addRowType:kAlertViewRowTitle];

    [self addSectionType:kAlertPicker];
    [self addRowType:kAlertViewRowAlert];
    [self addRowType:kAlertPicker];

    [self addSectionType:kAlertGps];

    [self addSectionType:kAlertViewRowAlert];
    [self addRowType:kAlertViewRowCancel];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[PickerCell nib] forCellReuseIdentifier:MakeCellId(kAlertPicker)];
}

- (void)viewDidDisappear:(BOOL)animated {

    AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
    switch (_rowChosen) {
    case kAlertViewRowAlert: {
        int mins = (int)[self.pickerView selectedRowInComponent:0];
        [taskList addTaskForDeparture:self.dep
                                 mins:mins
                           controller:RootViewController.currentRootViewController
                                          .navigationController.topViewController];
        break;
    }

    case kAlertViewRowCancel:
        [taskList cancelTaskForStopId:self.dep.stopId block:self.dep.block dir:self.dep.dir];
        break;
    }

    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (int)startValue {
    return self.dep.minsToArrival;
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    switch (row) {
    case 0:
        return NSLocalizedString(@"when due", @"alarm option");

    case 1:
        return NSLocalizedString(@"1 minute before departure", @"alarm option");

    default:
        return [NSString
            stringWithFormat:NSLocalizedString(@"%d minutes before departure", @"alarm option"),
                             (int)row];
    }
    return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self startValue];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS AlarmMinutesViewController

//--------------------------------------------------------------------------------------------------
#pragma mark kAlertViewRowTitle

CELL_HEIGHT_METHOD(kAlertViewRowTitle) { return [AlarmCell rowHeight]; }

CREATE_CELL_WITH_CONFIG(kAlertViewRowTitle, nil, kAlertViewRowTitle) {
    AlarmCell *alarmCell = (AlarmCell *)[tableView
        dequeueReusableCellWithIdentifier:MakeCellId(kAlertViewSectionTitle)];

    if (alarmCell == nil) {
        alarmCell = [AlarmCell tableviewCellWithReuseIdentifier:MakeCellId(kAlertViewSectionTitle)];
    }

    [alarmCell populateCellLine1:self.dep.locationDesc
                           line2:self.dep.shortSign
                        line2col:[UIColor modeAwareBlue]];

    alarmCell.icon = kIconAlarm;
    alarmCell.selectionStyle = UITableViewCellSelectionStyleNone;

    return alarmCell;
}

//--------------------------------------------------------------------------------------------------
#pragma mark kAlertViewRowAlert

MULTI_CELL_SELECT(kAlertViewRowAlert,
                  auto,
                  NSLocalizedString(@"Set alarm for the time below", @"button text"),
                  kIconAdd,
                  UITableViewCellAccessoryDisclosureIndicator,
                  UITableViewCellSelectionStyleBlue) {
    _rowChosen = kAlertViewRowAlert;
    CELL_POP();
}

//--------------------------------------------------------------------------------------------------
#pragma mark kAlertViewRowCancel

MULTI_CELL_SELECT(kAlertViewRowCancel,
                  auto,
                  NSLocalizedString(@"#RCancel alarm", @"button text"),
                  kIconDelete,
                  UITableViewCellAccessoryDisclosureIndicator,
                  UITableViewCellSelectionStyleBlue) {
    _rowChosen = kAlertViewRowCancel;
    CELL_POP();
}

CREATE_CELL_WITH_CONFIG(kAlertPicker, CELL_REG_SEL(PickerCell), auto) {
    PickerCell *picker =
        (PickerCell *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(PickerCell)];

    self.pickerView = picker.pickerView;

    picker.pickerView.delegate = self;

    AlarmTaskList *taskList = [AlarmTaskList sharedInstance];

    if ([taskList hasTaskForStopId:self.dep.stopId block:self.dep.block dir:self.dep.dir]) {
        int mins = [taskList minsForTaskWithStopId:self.dep.stopId
                                             block:self.dep.block
                                               dir:self.dep.dir];
        [picker.pickerView selectRow:mins inComponent:0 animated:NO];
    }

    return picker;
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kAlertViewRowTitle),
    CELL_MAP(kAlertViewRowAlert),
    CELL_MAP(kAlertViewRowCancel),
    CELL_MAP(kAlertPicker),
};

@end

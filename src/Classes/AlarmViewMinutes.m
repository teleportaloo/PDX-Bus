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


#import "AlarmViewMinutes.h"
#import "AlarmTaskList.h"
#import "InterfaceOrientation.h"
#import "PickerCell.h"
#import "SegmentCell.h"
#import "Settings.h"
#import "UIViewController+LocationAuthorization.h"
#import "Icons.h"

enum {
    kAlertViewRowTitle,
    kAlertViewRowAlert,
    kAlertViewRowCancel,
    kAlertPicker,
    kAlertGps
};

@interface AlarmViewMinutes () {
    NSInteger _rowChosen;
}

@property (nonatomic, strong) UIPickerView *pickerView;

@end

@implementation AlarmViewMinutes

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self sectionType:section] == kAlertGps) {
        if ([UIViewController locationAuthorizedOrNotDeterminedWithBackground:YES]) {
            return NSLocalizedString(@"Departure alarms are more accurate as the app can track your location in the background while the alarm is active.", @"Title");
        } else {
            return NSLocalizedString(@"Departure alarms are not so accurate as the app cannot track your location in the background.", @"Title");
        }
    }
    
    return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
        case kAlertViewRowTitle:
            return [AlarmCell rowHeight];
            
        case kAlertPicker:
        default:
            return UITableViewAutomaticDimension;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSInteger row = [self rowType:indexPath];
    
    switch (row) {
        default:
        case kAlertViewRowTitle: {
            AlarmCell *alarmCell = (AlarmCell *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kAlertViewSectionTitle)];
            
            if (alarmCell == nil) {
                alarmCell = [AlarmCell tableviewCellWithReuseIdentifier:MakeCellId(kAlertViewSectionTitle)];
            }
            
            [alarmCell populateCellLine1:self.dep.locationDesc line2:self.dep.shortSign line2col:[UIColor modeAwareBlue]];
            
            alarmCell.imageView.image = [Icons getIcon:kIconAlarm];
            alarmCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell = alarmCell;
            break;
        }
            
        case kAlertViewRowAlert:
        case kAlertViewRowCancel: {
            cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kAlertViewSectionAlert)];
            
            if (row == kAlertViewRowAlert) {
                cell.textLabel.text = NSLocalizedString(@"Set alarm for the time below", @"button text");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconAdd];
            } else {
                cell.textLabel.text = NSLocalizedString(@"Cancel alarm", @"button text");
                cell.imageView.image = [Icons getIcon:kIconDelete];
                cell.textLabel.textColor = [UIColor redColor];
            }
            
            cell.textLabel.font = self.basicFont;
            break;
        }
            
        case kAlertPicker: {
            cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kAlertPicker)];
            
            PickerCell *picker = (PickerCell *)cell;
            
            self.pickerView = picker.pickerView;
            
            picker.pickerView.delegate = self;
            
            // picker.pickerView.showsSelectionIndicator = YES;
            
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            
            if ([taskList hasTaskForStopId:self.dep.stopId block:self.dep.block]) {
                int mins = [taskList minsForTaskWithStopId:self.dep.stopId block:self.dep.block];
                [picker.pickerView selectRow:mins inComponent:0 animated:NO];
            }
            
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
        case kAlertViewRowAlert: {
            _rowChosen = kAlertViewRowAlert;
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
            
        case kAlertViewRowCancel:
            _rowChosen = kAlertViewRowCancel;
            [self.navigationController popViewControllerAnimated:YES];
            break;
    }
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
    
    [self.table registerNib:[PickerCell nib] forCellReuseIdentifier:MakeCellId(kAlertPicker)];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSInteger indexOfWindow = [self.navigationController.viewControllers indexOfObject:self];
    
    if (indexOfWindow == NSNotFound || indexOfWindow == 0) {
        AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
        switch (_rowChosen) {
            case kAlertViewRowAlert: {
                int mins = (int)[self.pickerView selectedRowInComponent:0];
                [taskList addTaskForDeparture:self.dep mins:mins];
                break;
            }
                
            case kAlertViewRowCancel:
                [taskList cancelTaskForStopId:self.dep.stopId block:self.dep.block];
                break;
        }
    }
    
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // do nothing for now
}

- (int)startValue {
    return self.dep.minsToArrival;
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case 0:
            return NSLocalizedString(@"when due", @"alarm option");
            
        case 1:
            return NSLocalizedString(@"1 minute before departure", @"alarm option");
            
        default:
            return [NSString stringWithFormat:NSLocalizedString(@"%d minutes before departure", @"alarm option"), (int)row];
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

@end

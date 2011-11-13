//
//  AlarmViewMinutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "AlarmViewMinutes.h"
#import "AlarmTaskList.h"

#define kAlertViewSections		 1
#define kAlertViewRowsPerSection 3

#define kAlertViewSectionTitle	 0
#define kAlertViewSectionAlert	 1
#define kAlertViewSectionCancel	 2


#define kMaxMins				 60


@implementation AlarmViewMinutes

@synthesize pickerView = _pickerView;
@synthesize dep = _dep;

- (void)dealloc {
	self.pickerView = nil;
	self.dep = _dep;
    [super dealloc];
	
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Alert Time";
	}
	return self;
}

#pragma mark TableViewWithToolbar methods



- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Picker methods

// return the picker frame based on its size, positioned at the bottom of the page
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	
	if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
		self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
	{
		CGFloat temp = screenRect.size.height;
		screenRect.size.height = screenRect.size.width;
		screenRect.size.width = temp;
	}
	
	
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - 40.0 - 44.0 - size.height,
								   screenRect.size.width,
								   size.height);
	return pickerRect;
}

- (void)createDatePicker
{	
	self.pickerView = [[[UIPickerView alloc] initWithFrame:CGRectZero] autorelease];
	// self.datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth; //UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	self.pickerView.delegate = self;
	self.pickerView.dataSource = self;
		
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	CGSize pickerSize = [self.pickerView sizeThatFits:CGSizeZero];
	self.pickerView.frame = [self pickerFrameWithSize:pickerSize];
	self.pickerView.showsSelectionIndicator = YES;
	
	AlarmTaskList *taskList = [AlarmTaskList getSingleton];
	
	if ([taskList hasTaskForStopId:self.dep.locid block:self.dep.block])
	{
		int mins = [taskList minsForTaskWithStopId:self.dep.locid block:self.dep.block];
		[self.pickerView selectRow:mins inComponent:0 animated:NO]; 
	}
	
	
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kAlertViewSections;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kAlertViewRowsPerSection;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == kAlertViewSectionTitle)
	{
		return [AlarmCell rowHeight:[self screenWidth]];
	}
	return [self basicRowHeight];
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
	
	if (indexPath.row == kAlertViewSectionTitle)
	{
		static NSString *CellIdentifier = @"block";
		
		AlarmCell *alarmCell = (AlarmCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (alarmCell == nil) {
			alarmCell = [AlarmCell tableviewCellWithReuseIdentifier:CellIdentifier 
															  width:self.screenWidth
															 height:[AlarmCell rowHeight:self.screenWidth]];
		}
		
		[alarmCell populateCellLine1:self.dep.locationDesc line2:self.dep.routeName line2col:[UIColor blueColor]];
		
		alarmCell.imageView.image = [self getActionIcon:kIconAlarm ];
        alarmCell.selectionStyle  = UITableViewCellSelectionStyleNone;
		
		cell = alarmCell;
	}
	else 
	{
		static NSString *CellIdentifier = @"DateType";
		
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		
		switch (indexPath.row)
		{
			case kAlertViewSectionAlert:
				cell.textLabel.text = @"Set alarm for the time below";
				break;
			case kAlertViewSectionCancel:
				cell.textLabel.text = @"Cancel alarm";
				break;
		}
		
		cell.textLabel.font = [self getBasicFont];
	}
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	AlarmTaskList *taskList = [AlarmTaskList getSingleton];
	
	switch (indexPath.row)
	{
		case kAlertViewSectionAlert:
		{
			int mins = [self.pickerView selectedRowInComponent:0];
			
			[taskList addTaskForDeparture:self.dep mins:mins];
            [self.navigationController popViewControllerAnimated:YES];
			
			break;
		}
		case kAlertViewSectionCancel:			
			[taskList cancelTaskForStopId:self.dep.locid block:self.dep.block];
            [self.navigationController popViewControllerAnimated:YES];
			break;
	}
	
	// [self.navigationController popViewControllerAnimated:YES];
	
}


#pragma mark View Methds

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.pickerView removeFromSuperview];
	self.pickerView = nil;
	
	[self createDatePicker];
	[self.view addSubview:self.pickerView];
	
	[self reloadData];
}

-(void)loadView
{
	[super loadView];
	
	[self createDatePicker];
	[self.view addSubview:self.pickerView];
	
}

- (void)viewDidAppear:(BOOL)animated
{
	CGSize pickerSize = [self.pickerView sizeThatFits:CGSizeZero];
	CGRect frame = [self pickerFrameWithSize:pickerSize];
	
	
	self.pickerView.frame = frame;
	
	/*
	 
	 if (self.datePickerView)
	 {
	 [self.datePickerView removeFromSuperview];
	 self.datePickerView = nil;
	 }
	 
	 [self createDatePicker];
	 [self.view addSubview:self.datePickerView];
	 */
	
	[self reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark -
#pragma mark UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	// do nothing for now
}

- (int)startValue
{
	return self.dep.minsToArrival;
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	switch (row)
	{
	case 0:
		return @"when due";
	case 1:
		return @"1 minute before arrival";
	default:
		return [NSString stringWithFormat:@"%d minutes before arrival", (int)row];
	}
	return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{	
	return pickerView.frame.size.width;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [self startValue];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}



@end

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

- (instancetype)init {
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Alert Time", @"screen title");
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
	CGRect screenRect = [UIScreen mainScreen].applicationFrame;
	
    DEBUG_LOG(@"%@", (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) ? @"Portrait" : @"Landscape");


    
    if ([InterfaceOrientation getInterfaceOrientation:self]  == UIInterfaceOrientationLandscapeLeft ||
		[InterfaceOrientation getInterfaceOrientation:self] == UIInterfaceOrientationLandscapeRight)
	{
		CGFloat temp = screenRect.size.height;
		screenRect.size.height = screenRect.size.width;
		screenRect.size.width = temp;
	}
	
    float offset = 20.0;
    	
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - offset - size.height,
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
	
	AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
	
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
		return [AlarmCell rowHeight];
	}
	return [self basicRowHeight];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
	
	if (indexPath.row == kAlertViewSectionTitle)
	{
		AlarmCell *alarmCell = (AlarmCell *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kAlertViewSectionTitle)];
		if (alarmCell == nil) {
			alarmCell = [AlarmCell tableviewCellWithReuseIdentifier:MakeCellId(kAlertViewSectionTitle)];
		}
		
		[alarmCell populateCellLine1:self.dep.locationDesc line2:self.dep.shortSign line2col:[UIColor blueColor]];
		
		alarmCell.imageView.image = [self getActionIcon:kIconAlarm ];
        alarmCell.selectionStyle  = UITableViewCellSelectionStyleNone;
		
		cell = alarmCell;
	}
	else 
	{
		cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kAlertViewSectionAlert)];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kAlertViewSectionAlert)] autorelease];
		}
		
		switch (indexPath.row)
		{
			case kAlertViewSectionAlert:
				cell.textLabel.text = NSLocalizedString(@"Set alarm for the time below", @"button text");
				break;
			case kAlertViewSectionCancel:
				cell.textLabel.text = NSLocalizedString(@"Cancel alarm", @"button text");
				break;
		}
		
		cell.textLabel.font = self.basicFont;
	}
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
	
	switch (indexPath.row)
	{
		case kAlertViewSectionAlert:
		{
			int mins = (int)[self.pickerView selectedRowInComponent:0];
			
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
	
    [super viewDidAppear:animated];
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
        return NSLocalizedString(@"when due", @"alarm option");
	case 1:
        return NSLocalizedString(@"1 minute before arrival", @"alarm option");
	default:
		return [NSString stringWithFormat:NSLocalizedString(@"%d minutes before arrival", @"alarm option"), (int)row];
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

//
//  DayOfTheWeekView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/26/11.
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

#import "DayOfTheWeekView.h"
#import "EditBookMarkView.h"
#import "SegmentCell.h"

#define kCommuteSectionSegAm		0
#define kCommuteSectionSegPm		1

#define kAmOrPmId		@"AmOrPm"
#define kDayOfWeekId	@"DayOfWeek"

@implementation DayOfTheWeekView

@synthesize originalFave = _originalFave;

#define kDaysInWeek 7

static int daysInWeek[] = {
		kDayMon,kDayTue,kDayWed,kDayThu,kDayFri,kDaySat,kDaySun
};

- (void)dealloc {
	self.originalFave = nil;
	
    [super dealloc];
}

- (int)days
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesDayOfWeek];
	
	if (num != nil)
	{
		return [num intValue];
	}
	return kDayNever;
}

- (bool)autoCommuteMorning
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesMorning];
	bool morning = TRUE;
	
	if (num)
	{
		morning = [num boolValue];
	}
	
	return morning;
}


#pragma mark Segmented controls

- (void)amOrPmSegmentChanged:(id)sender
{
	switch (((UISegmentedControl*)sender).selectedSegmentIndex)
	{
		case kCommuteSectionSegAm:
			[self.originalFave setObject:[NSNumber numberWithBool:TRUE]   forKey:kUserFavesMorning];
			break;
		case kCommuteSectionSegPm:
			[self.originalFave setObject:[NSNumber numberWithBool:FALSE]  forKey:kUserFavesMorning];
			break;
	}
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kDaysInWeek+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < kDaysInWeek)
	{
		return [self basicRowHeight];
	}
	return  [SegmentCell segmentCellHeight];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.row < kDaysInWeek)
	{    
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDayOfWeekId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDayOfWeekId] autorelease];
		}
		
		cell.textLabel.text = [NSString stringWithFormat:@"Every %@", [EditBookMarkView daysString:daysInWeek[indexPath.row]]];
		cell.textLabel.font = [self getBasicFont];
		
		if (([self days] & daysInWeek[indexPath.row]) != 0)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		return cell;
	}
	else 
	{
		
		SegmentCell *cell = (SegmentCell*)[tableView dequeueReusableCellWithIdentifier:kAmOrPmId];
		if (cell == nil) {
			cell = [[[SegmentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAmOrPmId] autorelease];
			[cell createSegmentWithContent:[NSArray arrayWithObjects: @"Morning", @"Afternoon", nil] 
									target:self 
									action:@selector(amOrPmSegmentChanged:)];
			cell.isAccessibilityElement = NO;
			// cell.backgroundView = [self clearView];
		}	
		
		cell.segment.selectedSegmentIndex = [self autoCommuteMorning] ? kCommuteSectionSegAm : kCommuteSectionSegPm;
		return cell;	
		
	}
	
	
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int days = [self days];
	
	days = days ^ daysInWeek[indexPath.row];
	
	[self.originalFave setObject:[NSNumber numberWithInt:days] forKey:kUserFavesDayOfWeek];
	
	[self.table deselectRowAtIndexPath:indexPath animated:YES];
	[self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
}

- (void)viewDidLoad 
{
    self.title = @"Days of the week";
}


@end

//
//  DayOfTheWeekView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/26/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DayOfTheWeekView.h"
#import "EditBookMarkView.h"
#import "SegmentCell.h"

#define kCommuteSectionSegAm		0
#define kCommuteSectionSegPm		1

#define kAmOrPmId		@"AmOrPm"
#define kDayOfWeekId	@"DayOfWeek"

@implementation DayOfTheWeekView

@synthesize originalFave = _originalFave;

#define kMorningOrEvening (1)   // 1 is not used!
#define kSection          (0)


- (void)dealloc {
	self.originalFave = nil;
	
    [super dealloc];
}

- (int)days
{
	NSNumber *num = self.originalFave[kUserFavesDayOfWeek];
	
	if (num != nil)
	{
		return num.intValue;
	}
	return kDayNever;
}

- (bool)autoCommuteMorning
{
	NSNumber *num = self.originalFave[kUserFavesMorning];
	bool morning = TRUE;
	
	if (num)
	{
		morning = num.boolValue;
	}
	
	return morning;
}


#pragma mark Segmented controls

- (void)amOrPmSegmentChanged:(id)sender
{
	switch (((UISegmentedControl*)sender).selectedSegmentIndex)
	{
		case kCommuteSectionSegAm:
			self.originalFave[kUserFavesMorning] = @TRUE;
			break;
		case kCommuteSectionSegPm:
			self.originalFave[kUserFavesMorning] = @FALSE;
			break;
	}
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self sections];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
	if ([self rowType:indexPath] != kMorningOrEvening)
	{
		return [self basicRowHeight];
	}
	return  [SegmentCell segmentCellHeight];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSInteger rowType = [self rowType:indexPath];
	if (rowType != kMorningOrEvening)
	{    
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDayOfWeekId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDayOfWeekId] autorelease];
		}
		
		cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Every %@", @"before a list of the days of the week"), [EditBookMarkView daysString:(int)rowType]];
		cell.textLabel.font = self.basicFont;
		
		if ((self.days & rowType) != 0)
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
			[cell createSegmentWithContent:@[NSLocalizedString(@"Morning", @"commuter bookmark option"),
                                                                       NSLocalizedString(@"Afternoon", @"commuter bookmark option")]
									target:self 
									action:@selector(amOrPmSegmentChanged:)];
			cell.isAccessibilityElement = NO;
			// cell.backgroundView = [self clearView];
		}	
		
		cell.segment.selectedSegmentIndex = [self autoCommuteMorning] ? kCommuteSectionSegAm : kCommuteSectionSegPm;
		return cell;	
		
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	unsigned int days = self.days;
    unsigned int rowType = (unsigned int)[self rowType:indexPath];
    
    if (rowType != kMorningOrEvening)
    {
        days = days ^ rowType;
        self.originalFave[kUserFavesDayOfWeek] = @(days);
    }
	
	[self.table deselectRowAtIndexPath:indexPath animated:YES];
	[self.table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
}

- (void)viewDidLoad 
{
    self.title = NSLocalizedString(@"Days of the week", @"screen title");
    
    [self clearSectionMaps];
    [self addSectionType:kSection];
    [self addRowType:kDayMon];
    [self addRowType:kDayTue];
    [self addRowType:kDayWed];
    [self addRowType:kDayThu];
    [self addRowType:kDayFri];
    [self addRowType:kDaySat];
    [self addRowType:kDaySun];
    [self addRowType:kMorningOrEvening];
    
    [super viewDidLoad];
}


@end

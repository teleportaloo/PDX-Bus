//
//  TripPlannerOptions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/15/09.
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

#import "TripPlannerOptions.h"
#import "CellLabel.h"


@implementation TripPlannerOptions

@synthesize walkSegment = _walkSegment;
@synthesize modeSegment = _modeSegment;
@synthesize minSegment = _minSegment;
@synthesize info = _info;

#define kSectionWalk		0
#define kSectionMode		1
#define kSectionMin			2
#define kSectionMinRows		2
#define kSectionRows		1
#define kMinRowSeg			0
#define kMinRowInfo			1
#define kTableSections		3

#define kSegRowWidth		320
#define kSegRowHeight		40
#define kUISegHeight		40
#define kUISegWidth			320

#define kWalkDist0			0.5
#define kWalkDist1			1.0
#define kWalkDist2			1.5
#define kWalkDist3			2.0

- (void)dealloc {
	self.modeSegment	= nil;
	self.walkSegment	= nil;
	self.minSegment		= nil;
	self.info			= nil;
    [super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.title = @"Options";
		self.info = @"Note: \"Shortest walk\" may suggest a long ride to avoid a few steps.";
	}
	return self;
}


- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Segmented controls

- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	[parent addSubview:segmentedControl];
	[parent layoutSubviews];
	[segmentedControl autorelease];
	return segmentedControl;
}

- (void)modeSegmentChanged:(id)sender
{
	self.tripQuery.userRequest.tripMode = self.modeSegment.selectedSegmentIndex;
}

- (void)minSegmentChanged:(id)sender
{
	self.tripQuery.userRequest.tripMin = self.minSegment.selectedSegmentIndex;
}


- (void)walkSegmentChanged:(id)sender
{
	switch (self.walkSegment.selectedSegmentIndex)
	{
		case 0:
			self.tripQuery.userRequest.walk = kWalkDist0;
			break;
		case 1:
			self.tripQuery.userRequest.walk = kWalkDist1;
			break;
		case 2:
			self.tripQuery.userRequest.walk = kWalkDist2;
			break;
		case 3:
			self.tripQuery.userRequest.walk = kWalkDist3;
			break;
	}
}


#pragma mark TableView methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kTableSections;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kSectionMin)
	{
		return kSectionMinRows;
	}
	return kSectionRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section)
	{
		case kSectionWalk:
			return @"Maximum walking distance:";
		case kSectionMode:
			return @"Travel by:";
		case kSectionMin:
			return @"Show me the:";
	}
	return @"";
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	/* TODO accessibility:  say the section header, but how? */
    switch (indexPath.section)
	{
		case kSectionWalk:
		{
			static NSString *segmentId1 = @"segment1";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId1];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:segmentId1] autorelease];
				self.walkSegment = [self createSegmentedControl:
								[NSArray arrayWithObjects: @"0.5 miles", @"1.0 miles", @"1.5 miles", @"2.0 miles", nil] 
													 parent:cell.contentView action:@selector(walkSegmentChanged:)];
				
				 
			
				[cell layoutSubviews];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.isAccessibilityElement = NO;
				
				cell.backgroundView = [self clearView];
			}	
		
			if (self.tripQuery.userRequest.walk < kWalkDist1)
			{
				self.walkSegment.selectedSegmentIndex = 0;
			} else if (self.tripQuery.userRequest.walk < kWalkDist2)
			{
				self.walkSegment.selectedSegmentIndex = 1;
			} 
			else if (self.tripQuery.userRequest.walk < kWalkDist3)
			{
				self.walkSegment.selectedSegmentIndex = 2;
			} 
			else 
			{
				self.walkSegment.selectedSegmentIndex = 3;
			}
			return cell;			
		}
		case kSectionMode:
		{
			static NSString *segmentId2 = @"segment2";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId2];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:segmentId2] autorelease];
				self.modeSegment = [self createSegmentedControl:
									[NSArray arrayWithObjects: @"Bus only", @"Rail only", @"Bus or Rail", nil] 
														 parent:cell.contentView action:@selector(modeSegmentChanged:)];
				
				[cell layoutSubviews];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.isAccessibilityElement = NO;
				cell.backgroundView = [self clearView];
			}	
			
			self.modeSegment.selectedSegmentIndex = self.tripQuery.userRequest.tripMode;
			return cell;	
		}
		case kSectionMin:
		{
			switch (indexPath.row)
			{
			case kMinRowSeg:
				{
					static NSString *segmentId3 = @"segment3";
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId3];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:segmentId3] autorelease];
						self.minSegment = [self createSegmentedControl:
									[NSArray arrayWithObjects: @"Quickest trip", @"Fewest transfers", @"Shortest walk", nil] 
														 parent:cell.contentView action:@selector(minSegmentChanged:)];
				
						[cell layoutSubviews];
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
						cell.isAccessibilityElement = NO;
						cell.backgroundView = [self clearView];
					}
					self.minSegment.selectedSegmentIndex = self.tripQuery.userRequest.tripMin;
					return cell;
				}
				break;
			case kMinRowInfo:
				{
					static NSString *infoId = @"info";
					CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:infoId];
					if (cell == nil) {
						cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:infoId] autorelease];
						cell.view = [self create_UITextView:[UIColor clearColor] font:TableViewBackFont];
					}
					
					[self setBackfont:cell.view];
					cell.view.text = self.info;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.backgroundView = [self clearView];
					
					return cell;
				}
				break;
			}
				
		}
	}
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == kSectionMin && indexPath.row == kMinRowInfo)
	{
		return [self getTextHeight:self.info font:TableViewBackFont];
	}
	return kSegRowHeight;
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

@end

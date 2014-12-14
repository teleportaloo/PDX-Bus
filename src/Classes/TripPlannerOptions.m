//
//  TripPlannerOptions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/15/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
	self.tripQuery.userRequest.tripMode = (TripMode)self.modeSegment.selectedSegmentIndex;
}

- (void)minSegmentChanged:(id)sender
{
	self.tripQuery.userRequest.tripMin = (TripMin)self.minSegment.selectedSegmentIndex;
}


- (void)walkSegmentChanged:(id)sender
{
	self.tripQuery.userRequest.walk = [XMLTrips indexToDistance:(int)self.walkSegment.selectedSegmentIndex];
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
			return @"Maximum walking distance in miles:";
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
				self.walkSegment = [self createSegmentedControl:[XMLTrips distanceMapSingleton]
                                                         parent:cell.contentView
                                                         action:@selector(walkSegmentChanged:)];
				
				 
			
				[cell layoutSubviews];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.isAccessibilityElement = NO;
				
				cell.backgroundView = [self clearView];
			}
            
            self.walkSegment.selectedSegmentIndex = [XMLTrips distanceToIndex:self.tripQuery.userRequest.walk];
            
		
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

@end

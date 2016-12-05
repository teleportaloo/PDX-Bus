//
//  DepartureSortTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureSortTableView.h"
#import "CellLabel.h"
#import "DepartureTimesView.h"

@implementation DepartureSortTableView

#define kSections 2

#define kSectionInfo 0
#define kSectionSeg  1


#define kSegRowWidth		320
#define kSegRowHeight		40
#define kUISegHeight		40
#define kUISegWidth			320

@synthesize sortSegment = _sortSegment;
@synthesize info		= _info;
@synthesize depView		= _depView;

- (void)dealloc {
	self.depView		= nil;
	self.sortSegment	= nil;
	self.info			= nil;
    [super dealloc];
}


- (instancetype) init
{
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Group Arrivals", @"screen title");
		self.info = NSLocalizedString(@"Group by stop: shows arrivals for each stop.\n\n"
					 "Group by trip: follows a particular bus or train as it passes through each stop.\n\n"
					 "Tip: 'Group by trip' is only useful with bookmarks containing several close stops on "
                                      "the same route.", @"description of group feature");
	}
	return self;
}

#pragma mark Helper functions

- (void)sortSegmentChanged:(id)sender
{
	switch (self.sortSegment.selectedSegmentIndex)
	{
		case 0:
			self.depView.blockSort = FALSE;
			break;
		case 1:
			self.depView.blockSort = TRUE;
			break;
	}
	
	if (!_segSetup)
	{
		[self.depView resort];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	
	[parent addSubview:segmentedControl];
	[parent layoutSubviews];
	[segmentedControl autorelease];
	return segmentedControl;
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section)
    {
        case kSectionSeg:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionSeg)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionSeg)] autorelease];
                self.sortSegment = [self createSegmentedControl:@[
                                                                  NSLocalizedString(@"Group by stop", @"button text"),
                                                                  NSLocalizedString(@"Group by trip", @"button text")]
                                                         parent:cell.contentView action:@selector(sortSegmentChanged:)];
                
                [cell layoutSubviews];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.isAccessibilityElement = NO;
                cell.backgroundView = [self clearView];
            }
            
            _segSetup = YES;
            self.sortSegment.selectedSegmentIndex = self.depView.blockSort ? 1 : 0;
            _segSetup = NO;
            return cell;
        }
            break;
        case kSectionInfo:
        {
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionInfo)];
            if (cell == nil) {
                cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionInfo)] autorelease];
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
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == kSectionInfo)
	{
		return [self getTextHeight:self.info font:TableViewBackFont];
	}
	return kSegRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


@end


//
//  WhatsNewView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/10.
//  Copyright 2010. All rights reserved.
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

#import "WhatsNewView.h"
#include "CellLabel.h"


@implementation WhatsNewView

#define kSectionText	    	0
#define kSectionDone			1
#define kSections				2

#define kDoneRows				1



- (void)dealloc {
	[newTextArray release];
	[super dealloc];
}

#pragma mark Helper functions

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (id)init {
	if ((self = [super init]))
	{
		self.title = @"What's new?";
		newTextArray = [[NSArray arrayWithObjects:
                         @"6.0.1: Fixed locate nearby stops so that GPS cannot be left on.",
                         @"6.0: Was a major upgrade - see below:",
                         @"Updated PGE Park to JELD-WEN Field on the map.  Go Timbers!",
						 @"Added 'commuter bookmarks' - any bookmark can be configured to automatically display "
						 @"on your morning or evening commute.",
						 @"Added a proximity alarm to alert you when you get close to a stop (iOS 4.0 and above).",
						 @"Added an arrival alarm to alert you when a bus or train is getting close (iOS 4.0 and above).",
						 @"Added 'Plan trip from here' option to arrival screen.",
						 @"Arrivals have an arrow to expand the rows to include extra menu items for each stop.",
						 @"Locate by route now allows multiple route selection.",
						 @"Updated network error processing.",
                         @"Added in-app settings which are the same as the Settings app settings.",
						 @"Updated many user interface elements, including: reverse button on trip planner.",
						 @"Bug fixes - now loads on iOS5",
                         nil] retain];
	}
	return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == kSectionText)
	{
		return @"PDX Bus got an upgrade! Here's what's new in version " kWhatsNewVersion;
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kSectionText)
	{
		return [newTextArray count];
	}
	return kDoneRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section)
	{
		case kSectionText:
		{
			static NSString *newId = @"about";
			CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:newId];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newId] autorelease];
				cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
			}
			
			cell.view.font =  [self getParagraphFont];
			cell.view.text = [newTextArray objectAtIndex:indexPath.row];
			// printf("width:  %f\n", cell.view.bounds.size.width);
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[self updateAccessibility:cell indexPath:indexPath text:[newTextArray objectAtIndex:indexPath.row] alwaysSaySection:YES];
			// cell.backgroundView = [self clearView];
			return cell;
			break;
		}
		case kSectionDone:
		{
			static NSString *cellId = @"done";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Back to PDX Bus";
				cell.textLabel.textAlignment = UITextAlignmentCenter;
			}
			return cell;
			break;
		}
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == kSectionText)
	{
		return [self getTextHeight:[newTextArray objectAtIndex:indexPath.row] font:[self getParagraphFont]];
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kSectionText)
	{
		[[self navigationController] popViewControllerAnimated:YES];
	}
	else {
		[[self navigationController] popToRootViewControllerAnimated:YES];
	}

}

@end


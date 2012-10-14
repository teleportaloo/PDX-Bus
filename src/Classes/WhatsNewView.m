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
                         @".6.6 - Mostly bug fixes",
                         @"Fixed stop ID 13604 - added NS Line arrivals.",
                         @"Optimized rail maps to use \"tiles\" - reducing crashes due to memory issues.",
                         @"Added additional informational hotspots to streetcar map.",
                         @"Trip planner min walk distances now match web site (1/10, 1/4, 1/2, 3/4, 1 & 2 miles).",
                         @"Commuter bookmarks fixed (startup sequence is different in iOS6).",
                         @"Separated support page from about page.",
                         @".6.5 - New features & fixes",
                         @"Full support for New Portland Streetcar Central Loop Line, including Streetcar map.",
                         @"iOS6: Fixed crash when GPS finds no nearby stops,",
                         @"iOS6: Fixed calendaring.",
                         @"iOS6: Fixed orientation issues.",
                         @"Icon has been tweaked (thanks Rob!), improved launch screens.",
                         @".6.4 - New features",
                         @"Added partial support for new Streetcar Loop. Full support soon!",
                         @"New for iOS 6 - added support for transit routing from Apple's map app.",
                         @"Full screen iPhone 5 support.",
                         @"New retina display launch screens.",
                         @"Dropped support for original iPhone running iOS 3.2. :-(",
                         @"Extended URL scheme to include new keywords: \"nearby\", \"commute\", \"tripplanner\", \"qrcode\", \"bookmarknumber=<number>\"",
                         @".6.3 - New features & fixes:",
                         @"Added QR Code reader (requires camera).",
                         @"New higher resolution rail map with no zones and new PSU stations.",
                         @"Tweet directly from the app, added link to the Streetcar's twitter feed.",
                         @"Extended app URL scheme e.g. pdxbus://365 will launch PDX Bus and show stop 365.  (Useful for app launchers such as 'Icon Project' or 'Launch Center Pro').",
                         @"Removed rail map if running iOS 3.1 - not enough memory (sorry).",
                         // @"Facebook fan pages opens in Facebook app.",  // not any more - FB app doesn't support it!
                         @"Trip planner allows min walking distance of 0.1 miles.",
                         @".6.2 -  Several bug fixes:",
                         @"Fixed VoiceOver issues with segmented controls and buttons.",
                         @"Increased size of 'X' icon to make easier to touch.",
                         @"Caches are more robust.",
                         @"Added additional alert for alarms that are too long to be accurate in the background.",
                         @"Added 'Plan trip from/to here' option on rail station screen.",
                         @"Improved stability & added new debug options.",
                         @".6.1 - New features & fixes:",
                         @"Now caches arrival times, so users can still see arrivals with no network (especially for iPod touch).",
                         @"Night Visibility Flasher can now flash the LED (see settings to enable this).",
                         @"Added Twitter style \"Pull to Refresh\" to arrivals.",
                         @"Added a quick locate toolbar item to the first screen.",
                         @"Fixed many small bugs, including issues discovered with Apple's latest tools.",
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

static NSString *versionId = @"version";
static NSString *itemId = @"item";



- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:versionId])
	{
		cell.backgroundColor = [UIColor grayColor];
	}
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
	
	
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section)
	{
		case kSectionText:
		{
            NSString *text = [newTextArray objectAtIndex:indexPath.row];
            NSString *cellId = itemId;
            bool    center = FALSE;
            
            
            if ([text characterAtIndex:0]=='.')
            {
                text = [text substringFromIndex:1];
                cellId = versionId;
                center = YES;
            }
            
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
				cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
			}
			
			cell.view.font =  [self getParagraphFont];
			cell.view.text = text;
			// printf("width:  %f\n", cell.view.bounds.size.width);
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (center)
            {
                cell.view.textAlignment = UITextAlignmentCenter;
            }
			[self updateAccessibility:cell indexPath:indexPath text:[newTextArray objectAtIndex:indexPath.row] alwaysSaySection:YES];
			// cell.backgroundView = [self clearView];
            cell.view.backgroundColor = [UIColor clearColor];
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


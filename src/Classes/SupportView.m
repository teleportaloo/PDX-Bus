    //
//  SupportView.m
//  TriMetTimes
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

#import "SupportView.h"
#include "CellLabel.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"
#import "AboutView.h"

#define kSectionSupport			0
#define kSectionTips			1
#define kSectionLinks			2
#define kSectionNetwork			3
#define kSectionCache           4



#define kSections               5

#define kLinkRows				3
			
#define kSectionSupportRows		3
#define kSectionSupportRowSupport 0
#define kSectionSupportRowNew	 1
#define kSectionSupportHowToRide 2

#define kSectionLinkRows        4
#define kSectionLinkBlog        0
#define kSectionLinkTwitter     1
#define kSectionLinkFacebook    2
#define kSectionLinkGitHub      3



@implementation SupportView

@synthesize hideButton = _hideButton;

- (void)dealloc {
	[supportText release];
    [tipText release];
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
		self.title = @"Support";
            
		supportText = @"One developer writes PDX Bus as a volunteer effort, with a little help from friends and the local community. He has no affiliation with TriMet, but he happens to ride TriMet on most days. "
                    "\n\nThe arrival data is provided by TriMet and Portland Streetcar and should be same as the transit tracker data. "
                    "Please contact TriMet for issues about late busses or other transit issues as he cannot help. "
                    "\n\nFor app support or feature requests please leave a comment on the blog; alternatively use twitter, Facebook or Github. He is not able to respond to app store reviews, "
                    "so do not use these for support or feature requests. "
                    "He cannot provide an email address for support because of privacy reasons, both yours and his.";
        
        tipText = [[NSArray alloc] initWithObjects:
                   @"There are LOTS of settings for PDXBus - take a look at the settings on the front screen to change colors, move the bookmarks to the top of the screen or change other options.",
                   @"Shake the device to refresh the arrival times.",
                   @"Bookmark a trip from the Current Location to your home and call it \"Take me home!\"",
                   @"Backup your bookmarks by emailing them to yourself.",
                   @"Keep an eye on the toolbar at the bottom - there are maps, options, and other features to explore.",
                   @"At night, TriMet recommends holding up a cell phone or flashing light so the driver can see you.",
                   @"Create bookmarks containing both the start and end stops of your journey, then use the \"Show arrivals with just this trip\" feature"
                   " to see when a particular bus or train will arrive at each stop.",
				   @"Many issues can be solved by deleting the app and reinstalling - be sure to email the bookmarks to yourself first so you can restore them.",
                   nil];
        
        _hideButton = NO;

	}
	return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:@"About"
                                  style:UIBarButtonItemStyleBordered
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
        self.navigationItem.rightBarButtonItem = info;
	}
}

- (void)infoAction:(id)sender
{
	AboutView *infoView = [[AboutView alloc] init];
    
    infoView.hideButton = YES;
	
	// Push the detail view controller
    [[self navigationController] pushViewController:infoView animated:YES];
	[infoView release];
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionSupport:
			return @"PDX Bus - App Support";
        case kSectionTips:
			return @"Tips";
		case kSectionLinks:
			return @"App Support Links";
        case kSectionNetwork:
			return @"Network & Server Connectivity";
		case kSectionCache:
			return @"Route and Stop Data Cache";
			
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionSupport:
			return kSectionSupportRows;
		case kSectionLinks:
			return kSectionLinkRows;
        case kSectionNetwork:
		case kSectionCache:
			return 1;
        case kSectionTips:
			return [tipText count];
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case kSectionNetwork:
		{
			static NSString *networkId = @"network";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:networkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:networkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Check Network Connection";
				cell.imageView.image = [self getActionIcon:kIconNetwork];
				
			}
			return cell;
			break;
		}
		case kSectionCache:
		{
			static NSString *cacheId = @"cache";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cacheId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cacheId] autorelease];
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Delete Cached Routes and Stops";
				cell.textLabel.textAlignment = UITextAlignmentLeft;
				cell.imageView.image = [self getActionIcon:kIconDelete];
			}
			return cell;
			break;
		}
			
		case kSectionSupport:
		{
			if (indexPath.row == kSectionSupportRowSupport)
			{
				static NSString *aboutId = @"about";
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:aboutId];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aboutId] autorelease];
					cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				}
				
				cell.view.font =  [self getParagraphFont];
				cell.view.text =  supportText;
				// printf("width:  %f\n", cell.view.bounds.size.width);
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				[self updateAccessibility:cell indexPath:indexPath text:supportText alwaysSaySection:YES];
				// cell.backgroundView = [self clearView];
				return cell;
			}
			else {
				static NSString *newId = @"newid";
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:newId];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newId] autorelease];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					/*
					 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					
					cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
                
                if (indexPath.row == kSectionSupportHowToRide)
                {
                    cell.textLabel.text = @"How to ride";
                    cell.imageView.image = [self getActionIcon:kIconAbout];
                }
                else 
                {
                    cell.textLabel.text = @"What's new?";
                    cell.imageView.image = [self getActionIcon:@"Icon-Small.png"];
                }
				return cell;
			}

			break;
		}
		case kSectionLinks:
		{
			static NSString *linkId = @"pdxbuslink";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:linkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			
			switch (indexPath.row)
			{
			case kSectionLinkBlog:
				cell.textLabel.text = @"PDX Bus blog & support";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
            case kSectionLinkTwitter:
                cell.textLabel.text = @"@pdxbus on Twitter";
                cell.imageView.image = [self getActionIcon:kIconTwitter];
                break;
            case kSectionLinkGitHub:
                cell.textLabel.text = @"pdxbus on GitHub";
                cell.imageView.image = [self getActionIcon:kIconSrc];
                break;
            case kSectionLinkFacebook:
                cell.textLabel.text = @"Facebook page";
                cell.imageView.image = [self getActionIcon:kIconFacebook];
                break;
            }
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
			return cell;
			break;
		}
        case kSectionTips:
		{
			static NSString *tipsId = @"tips";
			CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:tipsId];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tipsId] autorelease];
				cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
			}
			
			cell.view.font =  [self getParagraphFont];
			cell.view.text = [tipText objectAtIndex:indexPath.row];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[self updateAccessibility:cell indexPath:indexPath text:[tipText objectAtIndex:indexPath.row] alwaysSaySection:YES];
			return cell;
			break;
		}
		default:
			break;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case kSectionSupport:
			if (indexPath.row == kSectionSupportRowSupport)
			{
				return [self getTextHeight:supportText font:[self getParagraphFont]];
			}
			break;
        case kSectionTips:
			return [self getTextHeight:[tipText objectAtIndex:indexPath.row] font:[self getParagraphFont]];
			break;
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionLinks:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
		
			switch (indexPath.row)
			{
				case kSectionLinkBlog:
					[webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil title:@"pdxbus.teleportaloo.org"];
                    [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
					break;
                case kSectionLinkGitHub:
					[webPage setURLmobile:@"http:/github.com/teleportaloo/PDX-Bus" full:nil title:@"GitHub"];
                    [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
					break;
                case kSectionLinkTwitter:
                    self.tweetAt   = @"pdxbus";
                    self.initTweet = @"@pdxbus";
                    [self tweet];
                    break;
                case kSectionLinkFacebook:
                    [self facebook];
                    break;
            }
	
            [webPage release];
			
			break;
		}
		case kSectionNetwork:
			[self networkTips:nil networkError:nil];
            [self clearSelection];
			break;
		case kSectionCache:
		{
			[TriMetXML deleteCacheFile];
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Data Cache"
															   message:@"Cached Routes and Stops have been deleted"
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil ] autorelease];
			[alert show];
			
			break;
		}
		case kSectionSupport:
			if (indexPath.row == kSectionSupportRowSupport)
			{
				[[self navigationController] popViewControllerAnimated:YES];
			}
			else if (indexPath.row == kSectionSupportHowToRide)
            {
                WebViewController *webPage = [[WebViewController alloc] init];
                [webPage setURLmobile:@"http://trimet.org/howtoride/index.htm" full:nil title:@"How to ride"]; 
                [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
                [webPage release];
            }
            else
			{
				WhatsNewView *whatsNew = [[WhatsNewView alloc] init];
				[[self navigationController] pushViewController:whatsNew animated:YES];
				[whatsNew release];
			}
			break;
	}
}

@end


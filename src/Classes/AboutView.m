//
//  About.m
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

#import "AboutView.h"
#include "CellLabel.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"

#define kSectionHelp			0
#define kSectionTips			1
#define kSectionNetwork			2
#define kSectionCache			3
#define kSectionWeb				4
#define kSectionLegal			5
#define kSectionAbout			6
#define kSections				7

#define kRowSite				0
#define kLinkTracker			1
#define kLinkStopIDs			2
#define kRowPortlandTransport   3
#define kRowTriMettiquette		4
#define kRowTriMet				5

#define kLinkRows				6

#define kLegalRows				11
#define kRowCivicApps			0
#define kRowGoogle				1
#define kRowMainIcon			2
#define kRowIcons				3
#define kRowTWG					4
#define kRowSettings            5
#define KRowOtherIcons			6
#define kRowOxygen				7
#define kRowGeoNames			8
#define kRowPolygons			9
#define kRowSrc					10
			
#define kSectionHelpRows		2
#define kSectionHelpRowHelp		0
#define kSectionHelpRowNew		1


@implementation AboutView

- (void)dealloc {
	[aboutText release];
	[tipText release];
	[helpText release];
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
		self.title = @"Tips & About & Links";
		aboutText = [[NSString stringWithFormat:@"Version %@\n\n"
		"Route and arrival data provided by permission of TriMet.\n\n"
		"This app was developed as a volunteer effort to provide a service for TriMet riders. The developer has no affiliation with TriMet, AT&T or Apple.\n\n"
		"Lots of thanks...\n\n"
		"...to http://www.portlandtransport.com for help and advice;\n\n"
		"...to Scott, Tim and Mike for beta testing and suggestions;\n\n"
		"...to Scott (again) for lending me his brand new iPad;\n\n"
		"...to Rob Alan for the stylish icon; and\n\n"
		"...to CivicApps.org for Awarding PDX Bus the \"Most Appealing\" and \"Best in Show\" awards in July 2010.\n\n"
		"Special thanks to Ken for putting up with all this.\n\n"
		"\nCopyright (c)2008-2011\nAndrew Wallace", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] retain];
		
		tipText = [[NSArray alloc] initWithObjects:
			@"There are LOTS of settings for PDXBus - take a look at the Settings application and choose PDXBus to change colors, move the bookmarks to the top of the screen or change other options.", 	   
			@"Shake the device to refresh the arrival times.",
			@"Bookmark a trip from the Current Location to your home and call it \"Take me home!\"",
		    @"Backup your bookmarks by emailing them to yourself.",
			@"Keep an eye on the toolbar at the bottom - there are maps, options, and other features to explore.",
			@"At night, TriMet recommends holding up a cell phone or flashing light so the driver can see you.",
			@"Create bookmarks containing both the start and end stops of your journey, then use the \"Show arrivals with just this trip\" feature"
			" to see when a particular bus or train will arrive at each stop.",
				   nil];
		
		helpText = @"PDX Bus uses real-time tracking information from TriMet to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
			"Every TriMet bus stop and rail station has its own unique Stop ID number, up to five digits.\n\n"
			"Enter the Stop ID to get the arrivals for that stop. You may also browse & search the routes to find a stop, or use a "
			"map of the rail system. The Trip Planner feature uses scheduled times to arrange a journey with several transfers.\n\n"
			"See below for other tips and links, touch here to start using PDX Bus.";
	}
	return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionAbout:
			return @"PDX Bus - Portland Transit Times";
		case kSectionWeb:
			return @"Links";
		case kSectionLegal:
			return @"Attributions and Legal";
		case kSectionTips:
			return @"Tips";
		case kSectionNetwork:
			return @"Network";
		case kSectionCache:
			return @"Route and Stop Data Cache";
		case kSectionHelp:
			return @"Welcome to PDX Bus!";
			
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionAbout:
			return 1;
		case kSectionHelp:
			return kSectionHelpRows;
		case kSectionNetwork:
		case kSectionCache:
			return 1;
		case kSectionWeb:
			return kLinkRows;
		case kSectionLegal:
			return kLegalRows;
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
			
		case kSectionAbout:
		case kSectionHelp:
		{
			if (indexPath.row == kSectionHelpRowHelp)
			{
				static NSString *aboutId = @"about";
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:aboutId];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aboutId] autorelease];
					cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				}
				
				cell.view.font =  [self getParagraphFont];
				cell.view.text = (indexPath.section == kSectionAbout) ? aboutText : helpText;
				// printf("width:  %f\n", cell.view.bounds.size.width);
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				[self updateAccessibility:cell indexPath:indexPath text:((indexPath.section == kSectionAbout) ? aboutText : helpText) alwaysSaySection:YES];
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
				cell.textLabel.text = @"What's new?";
				cell.imageView.image = [self getActionIcon:@"AppIcon-29.png"];
				return cell;
			}

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
		case kSectionWeb:
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
			case kLinkTracker:	
				cell.textLabel.text = @"About TriMet's Transit Tracker";
				cell.imageView.image = [self getActionIcon:kIconLink];
				break;
			case kLinkStopIDs:
				cell.textLabel.text = @"About Stop IDs";
				cell.imageView.image = [self getActionIcon:kIconLink];
				break;
			case kRowSite:
				cell.textLabel.text = @"PDX Bus web site & Support";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
			case kRowTriMet:
				cell.textLabel.text = @"TriMet.org";
				cell.imageView.image = [self getActionIcon:kIconTriMetLink];
				break;
			case kRowTriMettiquette:
				cell.textLabel.text = @"TriMetiquette.com";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
			case kRowPortlandTransport:
				cell.textLabel.text = @"PortlandTransport.com";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
			}
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
			return cell;
			break;
		}
		case kSectionLegal:
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
				case kRowGoogle:
					cell.textLabel.text = @"Google Terms & Conditions";
					cell.imageView.image = [self getActionIcon:kIconEarthMap];
					break;
				case kRowOxygen:
					cell.textLabel.text = @"Some icons from Oxygen-Icons.org";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
				case kRowIcons:
					cell.textLabel.text = @"Icons by Joseph Wain / glyphish.com";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
				case kRowTWG:
					cell.textLabel.text = @"Some toolbar icons by TWG";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
                case kRowSettings:
					cell.textLabel.text = @"Uses code from www.inappsettingskit.com";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case kRowGeoNames:
					cell.textLabel.text = @"Location names from GeoNames.org";
					cell.imageView.image = [self getActionIcon:kIconEarthMap];
					break;	
				case kRowPolygons:
					cell.textLabel.text = @"Polygon code (c) 1970-2003, Wm. Randolph Franklin";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case kRowMainIcon:
					cell.textLabel.text = @"App icon by Rob Alan";
					cell.imageView.image = [self getActionIcon:@"AppIcon-29.png"];
					break;
				case kRowCivicApps:
					cell.textLabel.text = @"Thanks for the Civic App award!";
					cell.imageView.image = [self getActionIcon:kIconAward];
					break;
				case kRowSrc:
					cell.textLabel.text = @"GPL Source Code";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case KRowOtherIcons:
					cell.textLabel.text = @"Some icons by Aha-Soft";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
					
			}
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
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
		case kSectionAbout:
			return [self getTextHeight:aboutText font:[self getParagraphFont]];
			break;
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				return [self getTextHeight:helpText font:[self getParagraphFont]];
			}
			break;
		case kSectionTips:
			return [self getTextHeight:[tipText objectAtIndex:indexPath.row] font:[self getParagraphFont]];
			break;
		case kSectionWeb:
		case kSectionNetwork:
		case kSectionLegal:
			return [self basicRowHeight];
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionWeb:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
		
			switch (indexPath.row)
			{
				case kLinkTracker:	
					[webPage setURLmobile:@"http://trimet.org/transittracker/about.htm" full:nil title:@"Transit Tracker"]; 
					break;
				case kLinkStopIDs:
					[webPage setURLmobile:@"http://trimet.org/transittracker/stopidnumbers.htm" full:nil title:@"Stop IDs"];
					break;
				case kRowSite:	
					[webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil title:@"pdxbus.teleportaloo.org"]; 
					break;
				case kRowTriMet:
					[webPage setURLmobile:@"http://m.trimet.org/" full:@"http://www.trimet.org/" title:@"TriMet.org"];
					break;
				case kRowTriMettiquette:
					[webPage setURLmobile:@"http://trimetiquette.com/" full:nil title:@"trimetiquette.com"];
					webPage.showErrors = NO;
					break;
				case kRowPortlandTransport:
					[webPage setURLmobile:@"http://portlandtransport.com" full:nil title:@"portlandtransport.com"];
					break;
			}
	
			[[self navigationController] pushViewController:webPage animated:YES];
			[webPage release];
			break;
		}
		case kSectionLegal:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
			
			switch (indexPath.row)
			{
				case kRowGoogle:
					[webPage setURLmobile:@"http://www.google.com/intl/en_us/help/terms_maps.html" full:nil title:@"Google Maps/Earth Terms of Service"];
					break;
				case kRowOxygen:
					[webPage setURLmobile:@"http://www.oxygen-icons.org" full:nil title:@"Oxygen Icons"];
					break;
				case kRowIcons:
					[webPage setURLmobile:@"http://glyphish.com/" full:nil title:@"glyphish.com"];
					break;
				case kRowGeoNames:
					[webPage setURLmobile:@"http://geonames.org/" full:nil title:@"GeoNames.org"];
					break;
				case kRowPolygons:
					[webPage setURLmobile:@"http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html" full:nil title:@"pnpoly"];
					break;
				case kRowMainIcon:
					[webPage setURLmobile:@"http://www.robalan.com" full:nil title:@"Rob Alan"];
					break;
				case kRowCivicApps:
					[webPage setURLmobile:@"http://civicapps.org/news/announcing-best-apps-winners-and-runners" full:nil title:@"CivicApps.org"];
					break;
				case kRowSrc:
					[webPage setURLmobile:@"http://www.teleportaloo.org/pdxbus/src" full:nil title:@"GPL Source Code"];
					break;
				case KRowOtherIcons:
					[webPage setURLmobile:@"http://www.small-icons.com/icons.htm" full:nil title:@"Aha-Soft"];
					break;
				case kRowTWG:
					[webPage setURLmobile:@"http://blog.twg.ca/2009/09/free-iphone-toolbar-icons/" full:nil title:@"TWG"];
					break;
                case kRowSettings:
					[webPage setURLmobile:@"http://www.inappsettingskit.com/" full:nil title:@"www.inappsettingskit.com"];
					break;
			}
			
			[[self navigationController] pushViewController:webPage animated:YES];
			[webPage release];
			break;
		}
		case kSectionNetwork:
			[self networkTips:nil networkError:nil];
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
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				[[self navigationController] popViewControllerAnimated:YES];
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


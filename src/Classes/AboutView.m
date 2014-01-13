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
#import "SupportView.h"
#import "debug.h"


#define kSectionHelp			0
#define kSectionWeb				1
#define kSectionLegal			2
#define kSectionAbout			3
#define kSections				4
			
#define kSectionHelpRows		3
#define kSectionHelpRowHelp		0
#define kSectionHelpRowNew		1
#define kSectionHelpHowToRide   2

#define kLinkFull   @"LinkF"
#define kLinkMobile @"LinkM"
#define kPageTitle  @"Page"
#define kIcon       @"Icon"
#define kCellText   @"Title"

@implementation AboutView

@synthesize hideButton = _hideButton;

- (void)dealloc {
	[aboutText release];
	[helpText release];
    [links release];
    [legal release];
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
		self.title = NSLocalizedString(@"About", @"About screen title");
		aboutText = [[NSString stringWithFormat:
                      NSLocalizedString(
                                        @"Version %@\n\n"
                                        "Route and arrival data provided by permission of TriMet.\n\n"
                                        "This app was developed as a volunteer effort to provide a service for TriMet riders. The developer has no affiliation with TriMet, AT&T or Apple.\n\n"
                                        "Lots of thanks...\n\n"
                                        "...to http://www.portlandtransport.com for help and advice;\n\n"
                                        "...to Scott, Tim and Mike for beta testing and suggestions;\n\n"
                                        "...to Scott (again) for lending me his brand new iPad;\n\n"
                                        "...to Rob Alan for the stylish icon; and\n\n"
                                        "...to CivicApps.org for Awarding PDX Bus the \"Most Appealing\" and \"Best in Show\" awards in July 2010.\n\n"
                                        "Special thanks to Ken for putting up with all this.\n\n"
                                        "\nCopyright (c) 2008-2013\nAndrew Wallace\n(See legal section above for other copyright owners and attrbutions).",
                                        @"Dedication text"),
                      
                      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] retain];
		
		helpText =
        NSLocalizedString(
                          @"PDX Bus uses real-time tracking information from TriMet to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
                          "Every TriMet bus stop and rail station has its own unique Stop ID number, up to five digits.\n\n"
                          "Enter the Stop ID to get the arrivals for that stop. You may also scan a QR code (found at some stops), or browse & search the routes to find a stop, or use a "
                          "map of the rail system. The Trip Planner feature uses scheduled times to arrange a journey with several transfers.\n\n"
                          "See below for other tips and links, touch here to start using PDX Bus.", @"Main help description");
        
        
        links = [[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"About TriMet's Transit Tracker", @"Link to TriMet page"),                               kCellText,
                   kIconLink,                                                                                                  kIcon,
                   @"http://trimet.org/transittracker/about.htm",                                                              kLinkMobile,
                   NSLocalizedString(@"Transit Tracker", @"web page title"),                                                   kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"About Stop IDs", @"Link to TriMet page"),                                               kCellText,
                   kIconLink,                                                                                                  kIcon,
                   NSLocalizedString(@"http://trimet.org/transittracker/stopidnumbers.htm", @"web page on stop ids"),          kLinkMobile,
                   NSLocalizedString(@"Transit Tracker", @"web page title"),                                                   kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"PDX Bus web site & Support", @"Link to TriMet page"),                                   kCellText,
                   kIconBlog,                                                                                                  kIcon,
                   @"http:/pdxbus.teleportaloo.org",                                                                           kLinkMobile,
                   @"pdxbus.teleportaloo.org",                                                                                 kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"TriMet.org", @"Link to TriMet page"),                                                   kCellText,
                   kIconTriMetLink,                                                                                            kIcon,
                   NSLocalizedString(@"http://m.trimet.org/", @"mobile web page"),                                             kLinkMobile,
                   NSLocalizedString(@"http://www.trimet.org/", @"full sized web page"),                                       kLinkFull,
                   @"TriMet",                                                                                                  kPageTitle, nil],
                  
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Portland Transport Blog", @"Link to Portland Transport Blog"),                          kCellText,
                   kIconBlog,                                                                                                  kIcon,
                   @"http://portlandtransport.com" ,                                                                           kLinkMobile,
                   @"Portland Transport",                                                                                      kPageTitle, nil],
                  
                  nil] retain];
        
        legal = [[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Thanks for the Civic App award!", @"Link"),                                              kCellText,
                   kIconAward,                                                                                                  kIcon,
                   @"http://civicapps.org/news/announcing-best-apps-winners-and-runners",                                       kLinkMobile,
                   @"CivicApps.org",                                                                                            kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"App icon by Rob Alan", @"Link"),                                                         kCellText,
                   kIconAppIconAction,                                                                                          kIcon,
                   @"http://www.robalan.com",                                                                                   kLinkMobile,
                   @"Rob Alan",                                                                                                 kPageTitle, nil],

/*
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Some icons from Oxygen-Icons.org", @"Link"),                                             kCellText,
                   kIconBrush,                                                                                                  kIcon,
                   @"http://www.oxygen-icons.org",                                                                              kLinkMobile,
                   @"Oxygen Icons",                                                                                             kPageTitle, nil],
*/
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Icons by Joseph Wain / glyphish.com", @"Link"),                                          kCellText,
                   kIconBrush,                                                                                                  kIcon,
                   @"http://glyphish.com/",                                                                                     kLinkMobile,
                   @"glyphish.com",                                                                                             kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Some toolbar icons by TWG", @"Link"),                                                    kCellText,
                   kIconBrush,                                                                                                  kIcon,
                   @"http://blog.twg.ca/2009/09/free-iphone-toolbar-icons/",                                                    kLinkMobile,
                   @"TWG",                                                                                                      kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Open in Chrome from Google", @"Link"),                                                   kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"https://github.com/GoogleChrome/OpenInChrome",                                                             kLinkMobile,
                   @"Open in Chrome",                                                                                           kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Inf Color Picker by InfinitApps", @"Link"),                                              kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"https://github.com/InfinitApps/InfColorPicker",                                                            kLinkMobile,
                   @"InfColorPicker",                                                                                           kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Uses code from www.inappsettingskit.com", @"Link"),                                      kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"http://www.inappsettingskit.com/",                                                                         kLinkMobile,
                   @"www.inappsettingskit.com",                                                                                 kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Location names from GeoNames.org", @"Link"),                                             kCellText,
                   kIconEarthMap,                                                                                               kIcon,
                   @"http://geonames.org/",                                                                                     kLinkMobile,
                   @"GeoNames.org",                                                                                             kPageTitle, nil],
                  
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Polygon code (c) 1970-2003, Wm. Randolph Franklin", @"Link"),                            kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html",                                   kLinkMobile,
                   @"Polygon code",                                                                                             kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Some icons by Aha-Soft", @"Link"),                                                       kCellText,
                   kIconBrush,                                                                                                  kIcon,
                   @"http://www.small-icons.com/icons.htm",                                                                     kLinkMobile,
                   @"Aha-Soft",                                                                                                 kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Pull to Refresh (c) 2010 Leah Culver", @"Link"),                                         kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"https://github.com/leah/PullToRefresh",                                                                    kLinkMobile,
                   @"Pull to Refresh",                                                                                          kPageTitle, nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"QR Scanning from ZXing library", @"Link"),                                               kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"http://code.google.com/p/zxing/",                                                                          kLinkMobile,
                   @"ZXing",                                                                                                    kPageTitle, nil],
                  
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Some icons by Gentleface", @"Link"),                                                     kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"http://gentleface.com/free_icon_set.html",                                                                 kLinkMobile,
                   @"GentleFace",                                                                                               kPageTitle, nil],
                 
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"Source Code", @"Link"),                                                                  kCellText,
                   kIconSrc,                                                                                                    kIcon,
                   @"https://github.com/teleportaloo/PDX-Bus",                                                                  kLinkMobile,
                   @"Source Code",                                                                                              kPageTitle, nil],
                  
                  
                  nil] retain];
        
        _hideButton = NO;
    }
	return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"Help", @"Help button")
                                  style:UIBarButtonItemStyleBordered
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
        self.navigationItem.rightBarButtonItem = info;
	}
}

- (void)infoAction:(id)sender
{
	SupportView *infoView = [[SupportView alloc] init];
	
	// Push the detail view controller
    
    infoView.hideButton = YES;

	[[self navigationController] pushViewController:infoView animated:YES];
	[infoView release];
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionAbout:
			return NSLocalizedString(@"Thanks!", @"Thanks section header");
		case kSectionWeb:
			return NSLocalizedString(@"Links", @"Link section header");
		case kSectionLegal:
			return NSLocalizedString(@"Attributions and Legal", @"Section header");
		case kSectionHelp:
			return NSLocalizedString(@"Welcome to PDX Bus!", @"Section header");
			
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
		case kSectionWeb:
			return links.count;
		case kSectionLegal:
			return legal.count;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellFromDict:(NSDictionary*)item
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
    
    cell.textLabel.text =   [item objectForKey:kCellText];
    cell.imageView.image =  [self getActionIcon:[item objectForKey:kIcon]];
    
    [cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Link to %@", @"Accessibility label"), cell.textLabel.text]];
    
    return cell;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
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
				DEBUG_LOG(@"help width:  %f\n", cell.view.bounds.size.width);
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
                
                if (indexPath.row == kSectionHelpHowToRide)
                {
                    cell.textLabel.text = NSLocalizedString(@"How to ride", @"Link to page");
                    cell.imageView.image = [self getActionIcon:kIconAbout];
                }
                else 
                {
                    cell.textLabel.text = NSLocalizedString(@"What's new?", @"Link to what's new");
                    cell.imageView.image = [self getActionIcon:kIconAppIconAction];
                }
				return cell;
			}

			break;
		}
		case kSectionWeb:
		{
			return [self tableView:tableView cellFromDict:[links objectAtIndex:indexPath.row]];
			break;
		}
		case kSectionLegal:
		{
			
			return [self tableView:tableView cellFromDict:[legal objectAtIndex:indexPath.row]];

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
		case kSectionWeb:
		case kSectionLegal:
			return [self basicRowHeight];
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)gotoDict:(NSDictionary*)dict
{
    WebViewController *webPage = [[WebViewController alloc] init];
    
    [webPage setURLmobile:[dict objectForKey:kLinkMobile]
                     full:[dict objectForKey:kLinkFull]
                    title:[dict objectForKey:kPageTitle]];

    [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
    [webPage release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionWeb:
		{
			[self gotoDict:[links objectAtIndex:indexPath.row]];
			break;
		}
		case kSectionLegal:
		{
            [self gotoDict:[legal objectAtIndex:indexPath.row]];
            break;
		}
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				[[self navigationController] popViewControllerAnimated:YES];
			}
			else if (indexPath.row == kSectionHelpHowToRide)
            {
                WebViewController *webPage = [[WebViewController alloc] init];
                [webPage setURLmobile:NSLocalizedString(@"http://trimet.org/howtoride/index.htm", @"how to ride site") full:nil title:NSLocalizedString(@"How to ride",@"how to ride title")];
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


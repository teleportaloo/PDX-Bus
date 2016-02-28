//
//  About.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AboutView.h"
#include "CellLabel.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"
#import "SupportView.h"
#import "DebugLogging.h"
#import "StringHelper.h"


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
        
#define ATTR(X) [StringHelper formatAttributedString:X font:[self getParagraphFont]]
        
        NSString *text = [NSString stringWithFormat:
                          NSLocalizedString(
                                            @"#bVersion %@ (%d-bit) %@#b\n\n"
                                            "Route and arrival data provided by permission of #B#bTriMet#b#0.\n\n"
                                            "This app was developed as a volunteer effort to provide a service for #B#bTriMet#b#0 riders. The developer has no affiliation with #B#bTriMet#b#0, or Apple.\n\n"
                                            "Lots of #ithanks#i...\n\n"
                                            "...to #ihttp://www.portlandtransport.com#i for help and advice;\n\n"
                                            "...to #iScott#i, #iTim#i and #iMike#i for beta testing and suggestions;\n\n"
                                            "...to #iScott#i (again) for lending me his brand new iPad;\n\n"
                                            "...to #iScott#i (again 😃) for feedback on the watch app;\n\n"
                                            "...to #iRob Alan#i for the stylish icon; and\n\n"
                                            "...to #iCivicApps.org#i for Awarding PDX Bus the #i#bMost Appealing#b#i and #b#iBest in Show#b#i awards in July 2010.\n\n"
                                            "Special thanks to #R#b#iKen#i#b#0 for putting up with all this.\n\n"
                                            "\nCopyright (c) 2008-2016\nAndrew Wallace\n(See legal section above for other copyright owners and attrbutions).",
                                            @"Dedication text"),
                          
                          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                          sizeof(NSInteger) * 8,
                          DEBUG_MODE
                          ];
        
        aboutText = ATTR(text).retain;
        
        helpText = ATTR(@"One developer writes #bPDX Bus#b as a #ivolunteer effort#i, with a little help from friends and the local community. He has no affiliation with #b#BTriMet#b#0, but he happens to ride buses and MAX on most days.\n\n"
                        "This is free because I do it for fun. #i#b#GReally#i#b#0.").retain;
        
        
        links = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-links" ofType:@"plist"]];
        legal = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-legal" ofType:@"plist"]];
        
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
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionHelpRowHelp)];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionHelpRowHelp)] autorelease];
					cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				}
				
				cell.view.font =  [self getParagraphFont];
				cell.view.attributedText = (indexPath.section == kSectionAbout) ? aboutText : helpText;
				DEBUG_LOG(@"help width:  %f\n", cell.view.bounds.size.width);
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				[self updateAccessibility:cell indexPath:indexPath text:cell.view.attributedText.string alwaysSaySection:YES];
				// cell.backgroundView = [self clearView];
				return cell;
			}
			else
            {
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionHelpRowNew)];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionHelpRowNew)] autorelease];
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
			return [self getTextHeight:aboutText.string font:[self getParagraphFont]];
			break;
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				return [self getTextHeight:helpText.string font:[self getParagraphFont]];
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
                     full:[dict objectForKey:kLinkFull]];

    [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
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
                [webPage setURLmobile:NSLocalizedString(@"https://trimet.org/howtoride/index.htm", @"how to ride site") full:nil];
                [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
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


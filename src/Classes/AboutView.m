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


enum SECTIONS {
    kSectionIntro,
    kSectionWeb,
    kSectionLegal,
    kSectionThanks,
    kSections
};
			
enum INTRO_ROWS {
    kSectionIntroRowIntro,
    kSectionIntroRowNew,
    kSectionIntroRows
};

#define kLinkFull   @"LinkF"
#define kLinkMobile @"LinkM"
#define kIcon       @"Icon"
#define kCellText   @"Title"

@implementation AboutView

@synthesize hideButton = _hideButton;

- (void)dealloc {
	[thanksText release];
	[introText release];
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


- (instancetype)init {
	if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"About", @"About screen title");
        
#define ATTR(X) [StringHelper formatAttributedString:X font:self.paragraphFont]
        
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
                          
                          [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"],
                          sizeof(NSInteger) * 8,
                          DEBUG_MODE
                          ];
        
        thanksText = [text formatAttributedStringWithFont:self.paragraphFont].retain;
        
        introText = [@"One developer writes #bPDX Bus#b as a #ivolunteer effort#i, with a little help from friends and the local community. He has no affiliation with #b#BTriMet#b#0, but he happens to ride buses and MAX on most days.\n\n"
                     "This is free because I do it for fun. #i#b#GReally#i#b#0." formatAttributedStringWithFont:self.paragraphFont].retain;
        
        links = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-links" ofType:@"plist"]].retain;
        legal = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-legal" ofType:@"plist"]].retain;
        
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
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
        self.navigationItem.rightBarButtonItem = info;
	}
}

- (void)infoAction:(id)sender
{
    SupportView *infoView = [SupportView viewController];
	
	// Push the detail view controller
    
    infoView.hideButton = YES;

	[self.navigationController pushViewController:infoView animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionThanks:
			return NSLocalizedString(@"Thanks!", @"Thanks section header");
		case kSectionWeb:
			return NSLocalizedString(@"Links", @"Link section header");
		case kSectionLegal:
			return NSLocalizedString(@"Attributions and Legal", @"Section header");
		case kSectionIntro:
			return NSLocalizedString(@"Welcome to PDX Bus!", @"Section header");
			
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionThanks:
			return 1;
		case kSectionIntro:
			return kSectionIntroRows;
		case kSectionWeb:
			return links.count;
		case kSectionLegal:
			return legal.count;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellFromDict:(NSDictionary<NSString*, NSString*>*)item
{
    static NSString *linkId = @"pdxbuslink";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:linkId];
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        /*
         [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
         */
        
        cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
        cell.textLabel.textColor = [UIColor blueColor];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    cell.textLabel.text =   item[kCellText];
    cell.imageView.image =  [self getActionIcon:item[kIcon]];
    
    cell.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Link to %@", @"Accessibility label"), cell.textLabel.text];
    
    return cell;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case kSectionThanks:
		case kSectionIntro:
		{
			if (indexPath.row == kSectionIntroRowIntro)
			{
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionHelpRowHelp)];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionHelpRowHelp)] autorelease];
					cell.view = [self create_UITextView:nil font:self.paragraphFont];
				}
				
				cell.view.font =  self.paragraphFont;
				cell.view.attributedText = (indexPath.section == kSectionThanks) ? thanksText : introText;
                [cell.view setAdjustsFontSizeToFitWidth:NO];
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
					
					cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
                
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
			return [self tableView:tableView cellFromDict:links[indexPath.row]];
			break;
		}
		case kSectionLegal:
		{
			
			return [self tableView:tableView cellFromDict:legal[indexPath.row]];

			break;
		}
	}
	
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case kSectionThanks:
            return [self getAtrributedTextHeight:thanksText] + kCellLabelTotalYInset;
			break;
		case kSectionIntro:
			if (indexPath.row == kSectionIntroRowIntro)
			{
				return [self getAtrributedTextHeight:introText] + kCellLabelTotalYInset;
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

- (void)gotoDict:(NSDictionary<NSString*, NSString*>*)dict
{
    [WebViewController displayPage:dict[kLinkMobile]
                              full:dict[kLinkFull]
                         navigator:self.navigationController
                    itemToDeselect:self
                          whenDone:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionWeb:
		{
			[self gotoDict:links[indexPath.row]];
			break;
		}
		case kSectionLegal:
		{
            [self gotoDict:legal[indexPath.row]];
            break;
		}
		case kSectionIntro:
			if (indexPath.row == kSectionIntroRowIntro)
			{
				[self.navigationController popViewControllerAnimated:YES];
			}
            else
			{
				[self.navigationController pushViewController:[WhatsNewView viewController] animated:YES];
			}
			break;
	}
}

@end


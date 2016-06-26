//
//  WhatsNewView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewView.h"
#include "CellLabel.h"
#import "DepartureTimesView.h"
#import "BlockColorViewController.h"
#import "WebViewController.h"
#import "FlashWarning.h"
#import "AllRailStationView.h"
#import "RailMapView.h"
#import "WhatsNewBasicAction.h"
#import "WhatsNewHeader.h"
#import "WhatsNewSelector.h"
#import "WhatsNewStopIDs.h"
#import "WhatsNewWeb.h"
#import "WhatsNewHighlight.h"
#import "NearestVehiclesMap.h"
#import "StringHelper.h"
#import "DebugLogging.h"


@implementation WhatsNewView

@synthesize settingsView = _settingsView;

#define kSectionText	    	0
#define kSectionDone			1
#define kSections				2

#define kDoneRows				1



- (void)dealloc {
	[_newTextArray release];
    [_specialActions release];
    [_basicAction release];
	[super dealloc];
}

#pragma mark Helper functions

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (id<WhatsNewSpecialAction>)getAction:(NSString*)fullText
{
    NSNumber *key = [NSNumber numberWithChar:[fullText characterAtIndex:0]];
    
    id<WhatsNewSpecialAction> action = [_specialActions objectForKey:key];
    
    if (action == nil)
    {
        action = _basicAction;
    }
    
    return action;
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"What's new?";
		_newTextArray = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"whats-new" ofType:@"plist"]];
        
        _basicAction = [[WhatsNewBasicAction alloc] init];
    
        _specialActions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                [[WhatsNewHeader   alloc] autorelease], [WhatsNewHeader getPrefix],
                                [[WhatsNewSelector alloc] autorelease], [WhatsNewSelector getPrefix],
                                [[WhatsNewStopIDs   alloc] autorelease],[WhatsNewStopIDs getPrefix],
                                [[WhatsNewWeb       alloc] autorelease],[WhatsNewWeb getPrefix],
                                [[WhatsNewHighlight alloc] autorelease],[WhatsNewHighlight getPrefix],
                           
                           nil];
#ifdef DEBUGLOGGING
        NSMutableString *output = [NSMutableString alloc].init.autorelease;
        
        [output appendString:@"\n"];
        
        for (NSString * fullText in _newTextArray)
        {
            id<WhatsNewSpecialAction> action = [self getAction:fullText];

            [output appendFormat:@"%@\n", [action plainText:fullText]];

        }
        NSLog(@"%@\n", output);
#endif
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
		return [_newTextArray count];
	}
	return kDoneRows;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    NSString * fullText = [_newTextArray objectAtIndex:indexPath.row];
    
    id<WhatsNewSpecialAction> action = [self getAction:fullText];
    
    [action tableView:tableView willDisplayCell:cell text:fullText];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section)
	{
		case kSectionText:
		{
            NSString * fullText = [_newTextArray objectAtIndex:indexPath.row];
            
            id<WhatsNewSpecialAction> action = [self getAction:fullText];
            
            NSAttributedString *text = [StringHelper formatAttributedString: [action displayText:fullText] font:[self getParagraphFont]];
            
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionText)];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionText)] autorelease];
				cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
			}
			
			cell.view.font =  [self getParagraphFont];
			cell.view.attributedText =  text;
            [cell.view setAdjustsFontSizeToFitWidth:NO];
            cell.view.backgroundColor = [UIColor clearColor];
			
            [action updateCell:cell tableView:tableView];
            
			[self updateAccessibility:cell indexPath:indexPath text:text.string alwaysSaySection:YES];
           
			return cell;
			break;
		}
		case kSectionDone:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionDone)];
			if (cell == nil)
            {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionDone)] autorelease];
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Back to PDX Bus";
				cell.textLabel.textAlignment = NSTextAlignmentCenter;
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
        NSString * fullText = [_newTextArray objectAtIndex:indexPath.row];
    
        id<WhatsNewSpecialAction> action = [self getAction:fullText];
        
        NSAttributedString *text = [StringHelper formatAttributedString: [action displayText:fullText] font:[self getParagraphFont]];
        
		return [self getAtrributedTextHeight:text] + kCellLabelTotalYInset;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kSectionText)
	{
        NSString * fullText = [_newTextArray objectAtIndex:indexPath.row];
        
        id<WhatsNewSpecialAction> action = [self getAction:fullText];
        
        [action processAction:fullText parent:self];
        
    }
	else {
		[[self navigationController] popToRootViewControllerAnimated:YES];
	}

}

#pragma mark Callback selectors

- (void)railMap
{
    if ([RailMapView RailMapSupported])
    {
        RailMapView *webPage = [[RailMapView alloc] init];
        [[self navigationController] pushViewController:webPage animated:YES];
        [webPage release];
    }
}


- (void)vehicles
{
    NearestVehiclesMap *mapView = [[NearestVehiclesMap alloc] init];
    mapView.title = @"All Vehicles";
    [mapView fetchNearestVehiclesInBackground:self.backgroundTask];
    
    [mapView release];
}


- (void)stations
{
    AllRailStationView *station = [[[AllRailStationView alloc] init] autorelease];
    
    [self.navigationController pushViewController:station animated:YES];
}

- (void)fbTriMet
{
    [self facebookTriMet];
}

- (void)flashWarning
{
    [UserPrefs getSingleton].flashingLightWarning = YES;
    
    FlashWarning *warning = [[FlashWarning alloc] initWithNav:[self navigationController]];
    
    warning.parentBase = self;
    
	[warning release];
}

- (void)settings
{
    self.settingsView = [[[IASKAppSettingsViewController alloc] init] autorelease];
    
    self.settingsView.showDoneButton = NO;
    // Push the detail view controller
    [[self navigationController] pushViewController:self.settingsView animated:YES];
}

-(void)showHighlights
{
    BlockColorViewController *blockTable = [[BlockColorViewController alloc] init];
    [[self navigationController] pushViewController:blockTable animated:YES];
    [blockTable release];
}

@end


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
#import "DepartureTimesView.h"
#import "BlockColorViewController.h"
#import "WebViewController.h"
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
#import "DetoursView.h"

@implementation WhatsNewView


#define kDoneRows                1

+ (NSString *)version
{
    return [NSString stringWithFormat:@"%@ %@",  [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];
}

-(bool)plainStringMatch:(NSString*)markup search:(NSString*)search
{
    id<WhatsNewSpecialAction> action = [self getAction:markup];
    return [[[action displayText:markup] formatAttributedStringWithFont:self.paragraphFont].string hasCaseInsensitiveSubstring:search];
}

- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index
{
    NSMutableArray *results = [NSMutableArray array];
    WHATS_NEW_SECTION *section =  (WHATS_NEW_SECTION *)i;
    
    if (section.count==0 || index==0)
    {
        return nil;
    }
    
    if ([self plainStringMatch:section.firstObject search:searchText])
    {
        return section;
    }

    for (NSString *item in section)
    {
        if (results.count==0)
        {
            [results addObject:item];
        }
        else
        {
            if ([self plainStringMatch:item search:searchText])
            {
                [results addObject:item];
            }
        }
    }
    
    if (results.count > 1)
    {
        return results;
    }
    
    return nil;
}



#pragma mark Helper functions

- (UITableViewStyle) style
{
    return UITableViewStylePlain;
}

#pragma mark Table view methods


- (id<WhatsNewSpecialAction>)getAction:(NSString*)fullText
{
    NSNumber *key = @(fullText.firstUnichar);
    
    id<WhatsNewSpecialAction> action = _specialActions[key];
    
    if (action == nil)
    {
        action = _basicAction;
    }
    
    return action;
}

- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"What's new?", @"page title");
        NSArray *newTextArray = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"whats-new" ofType:@"plist"]];
        
        _basicAction = [[WhatsNewBasicAction alloc] init];
    
        _specialActions = @{
                            [WhatsNewHeader     getPrefix] : [WhatsNewHeader    action],
                            [WhatsNewSelector   getPrefix] : [WhatsNewSelector  action],
                            [WhatsNewStopIDs    getPrefix] : [WhatsNewStopIDs   action],
                            [WhatsNewWeb        getPrefix] : [WhatsNewWeb       action],
                            [WhatsNewHighlight  getPrefix] : [WhatsNewHighlight action]
                           };
#ifdef DEBUGLOGGING
        NSMutableString *output = [NSMutableString string];
        
        [output appendString:@"\n"];
        
        for (NSString * markup in newTextArray)
        {
            id<WhatsNewSpecialAction> action = [self getAction:markup];
            [output appendFormat:@"%@\n", [action plainText:markup]];
        }
        NSLog(@"%@\n", output);
#endif
        self.enableSearch = YES;
        self.searchableItems = [NSMutableArray array];
        
        NSMutableArray *current = [NSMutableArray array];
        [current addObject:@""];
        [current addObject:[NSString stringWithFormat: NSLocalizedString(@"#bPDX Bus got an upgrade! Here's what's new in version #R%@#0.", @"section header"),
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]]];
        
        [self.searchableItems addObject:current];
        
        for (NSString *item in newTextArray)
        {
            if ([WhatsNewHeader matches:item])
            {
                current = [NSMutableArray arrayWithObject:item];
                [self.searchableItems addObject:current];
            }
            else
            {
                [current addObject:item];
            }
        }
    
    }

    return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    
    if (section < items.count)
    {
        WHATS_NEW_SECTION *sectionArray = [self filteredData:tableView][section];
    
        if (sectionArray.firstObject.length > 0)
        {
            return sectionArray.firstObject;
        }
    }
    return nil;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    
    if (section < items.count)
    {
        WHATS_NEW_SECTION *sectionArray = [self filteredData:tableView][section];
        NSString *markup = sectionArray.firstObject;
        
        if (markup.length > 0)
        {
            id<WhatsNewSpecialAction> action = [self getAction:markup];
            
            header.textLabel.adjustsFontSizeToFitWidth = YES;
            
            header.textLabel.attributedText = [[action displayText:markup] formatAttributedStringWithFont:self.basicFont];
            header.accessibilityLabel = header.textLabel.text.phonetic;

            
            int color = [UserPrefs sharedInstance].toolbarColors;
            
            if (color == 0xFFFFFF)
            {
                header.contentView.backgroundColor = [UIColor grayColor];
            }
            else
            {
                header.contentView.backgroundColor = HTML_COLOR(color);
            }
        }
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (tableView == self.table)
    {
        return self.searchableItems.count + 1;
    }
    return [self filteredData:tableView].count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    
    if (section < items.count)
    {
        return items[section].count-1;
    }
    return kDoneRows;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    
    if (indexPath.section < items.count)
    {
        NSString * markup = items[indexPath.section][indexPath.row+1];
        
        id<WhatsNewSpecialAction> action = [self getAction:markup];
        
        [action tableView:tableView willDisplayCell:cell text:markup];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    
    if (indexPath.section < items.count)
    {
        NSString * fullText = [self filteredData:tableView][indexPath.section][indexPath.row+1];
        
        id<WhatsNewSpecialAction> action = [self getAction:fullText];
        
        NSAttributedString *text = [[action displayText:fullText] formatAttributedStringWithFont:self.paragraphFont];
        
        UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionText)];
        
        cell.textLabel.attributedText =  text;
        
        [action updateCell:cell tableView:tableView];
        
        [self updateAccessibility:cell];
        
        return cell;
    }
    else
    {
        UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionDone)];
        cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.text = NSLocalizedString(@"Back to PDX Bus", @"button text");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    if (indexPath.section < items.count)
    {
        return UITableViewAutomaticDimension;
    }
    return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray<WHATS_NEW_SECTION *> *items = [self filteredData:tableView];
    if (indexPath.section < items.count)
    {
        NSString * markup = items[indexPath.section][indexPath.row+1];
        
        id<WhatsNewSpecialAction> action = [self getAction:markup];
        
        [action processAction:markup parent:self];
        
    }
    else
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self safeScrollToTop];    
}

#pragma mark Callback selectors

- (void)railMap
{
    [self.navigationController pushViewController:[RailMapView viewController] animated:YES];
}


- (void)vehicles
{
    NearestVehiclesMap *mapView = [NearestVehiclesMap viewController];
    mapView.title = NSLocalizedString(@"All Vehicles", "page title");
    [mapView fetchNearestVehiclesAsync:self.backgroundTask];
}


- (void)stations
{
    [self.navigationController pushViewController:[AllRailStationView viewController] animated:YES];
}

- (void)detours
{
   [[DetoursView viewController] fetchDetoursAsync:self.backgroundTask];
}


- (void)fbTriMet
{
    [self facebookTriMet];
}

- (void)settings
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(void)showHighlights
{
    [self.navigationController pushViewController:[BlockColorViewController viewController] animated:YES];
}

- (void)tweet
{
    if (self.table.indexPathForSelectedRow!=nil)
    {
        UITableViewCell *cell = [self.table cellForRowAtIndexPath:self.table.indexPathForSelectedRow];
        [self triMetTweetFrom:cell.contentView];
    }
}

@end


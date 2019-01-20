//
//  TripPlannerCacheView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TripPlannerCacheView.h"
#import "TripPlannerResultsView.h"
#import "UserFaves.h"
#import "Detour.h"
#import "Detour+iOSUI.h"
#import "StringHelper.h"
#import "DebugLogging.h"

@implementation TripPlannerCacheView

- (NSMutableArray *)loadItems
{
    return _userData.recentTrips;
}

- (bool)tableView:(UITableView*)tableView isHistorySection:(NSInteger)section
{
    return YES;
}

- (NSString *)noItems
{
    return NSLocalizedString(@"These previously planned trip results are cached and use saved locations, so they require no network access to review.", @"section header");
}

-(NSString*)stringToFilter:(NSObject*)i
{
    NSNumber *item = (NSNumber *)i;
    NSDictionary *trip = self.localRecents[item.integerValue];
    NSString *text = trip[kUserFavesChosenName];
    return text;
}


#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Recent trips", @"page title");
}

#pragma mark  Table View methods

- (NSString *)insertAttributes:(NSString *)string
{
   static NSDictionary<NSString*, NSString*> *replacements = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @{@"From: "               : @"#b#BFrom:#0#b ",
                         @"\nTo:"               : @"\n#B#bTo:#0#b",
                         @"\nDepart after"      : @"\n#B#bDepart after#b#0",
                         @"\nArrive by"         : @"\n#B#bArrive by#b#0",
                         @"\nArrive"            : @"\n#B#bArrive#b#0",
                         @"\nDepart"            : @"\n#B#bDepart#b#0"
                         };
    });
    
    NSMutableString *ms = [NSMutableString string];
    [ms appendString:string];
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* dictionaryKey, NSString* val, BOOL *stop)
     {
         [ms replaceOccurrencesOfString:dictionaryKey
                             withString:val
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, ms.length)];
     }];
    
    return ms;
    
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *trip =[self tableView:tableView filteredDict:indexPath.row];
    NSString *text = trip[kUserFavesChosenName];
    
    UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"Trip"];
    
    cell.textLabel.attributedText = [[self insertAttributes:text] formatAttributedStringWithFont:self.paragraphFont];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.backgroundColor = [UIColor whiteColor];
    cell.accessibilityLabel = text.phonetic;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    // [self chosenEndpoint:self.locList[indexPath.row] ];
    NSNumber *i = [self filteredData:tableView][indexPath.row];

    TripPlannerResultsView *tripResults = [[TripPlannerResultsView alloc] initWithHistoryItem:i.intValue];
    
    // Push the detail view controller
    [self.navigationController pushViewController:tripResults animated:YES];
    
}



@end


//
//  TripPlannerHistoryView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TripPlannerHistoryView.h"
#import "TripPlannerResultsView.h"
#import "UserState.h"
#import "Detour.h"
#import "Detour+iOSUI.h"
#import "NSString+Helper.h"
#import "DebugLogging.h"

@implementation TripPlannerHistoryView

- (NSMutableArray *)loadItems {
    return _userState.recentTrips;
}

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section {
    return YES;
}

- (NSString *)noItems {
    return NSLocalizedString(@"These previously planned trip results are cached and use saved locations, so they require no network access to review.", @"section header");
}

- (NSString *)stringToFilter:(NSObject *)i {
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
#define INDENT @"#>"
#define BACK   @"#<"
#define TITLE  @"#b#U"
#define NORMAL @"#b#D"


- (NSString *)insertAttributes:(NSString *)string {
    static NSDictionary<NSString *, NSString *> *replacements = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        replacements = @{ @"From: ": (TITLE @"From:"          NORMAL @"\n" INDENT),
                          @"\nTo: ": (@"\n" BACK TITLE @"To:"            NORMAL @"\n" INDENT),
                          @"\nDepart after": (@"\n" BACK TITLE @"Depart after:"  NORMAL @"\n" INDENT),
                          @"\nArrive by": (@"\n" BACK TITLE @"Arrive by:"     NORMAL @"\n" INDENT),
                          // @"\nArrive"              : (@"\n" BACK TITLE @"Arrive:"        NORMAL @"\n" INDENT),
                          // @"\nDepart"              : (@"\n" BACK TITLE @"Depart:"        NORMAL @"\n" INDENT)
        };
    });
    
    NSMutableString *ms = [NSMutableString string];
    
    [ms appendString:string];
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString *dictionaryKey, NSString *val, BOOL *stop)
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
    NSDictionary *trip = [self tableView:tableView filteredDict:indexPath.row];
    NSString *text = trip[kUserFavesChosenName];
    
    UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"Trip"];
    
    cell.textLabel.attributedText = FormatTextPara([self insertAttributes:text]);
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

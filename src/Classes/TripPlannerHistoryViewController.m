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


#import "TripPlannerHistoryViewController.h"
#import "DebugLogging.h"
#import "Detour+iOSUI.h"
#import "Detour.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"
#import "TripPlannerResultsViewController.h"
#import "UserParams.h"
#import "UserState.h"

@implementation TripPlannerHistoryViewController

- (NSMutableArray *)loadItems {
    return _userState.recentTrips;
}

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section {
    return YES;
}

- (NSString *)infoText {
    return NSLocalizedString(@"These previously planned trip results are cached and use saved "
                             @"locations, so they require no network access to review.",
                             @"section header");
}

- (NSString *)stringToFilter:(NSObject *)i {
    NSNumber *item = (NSNumber *)i;
    UserParams *trip = self.localRecents[item.integerValue].userParams;
    NSString *text = trip.valChosenName;

    return text;
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Recent trips", @"page title");
}

#pragma mark Table View methods
#define INDENT @"#>\t"
#define BACK @"#<"
#define TITLE @"#b#U"
#define NORMAL @"#b#D"

- (NSString *)insertAttributes:(NSString *)string {
    static NSDictionary<NSString *, NSString *> *replacements = nil;

    DO_ONCE((^{
      replacements = @{
          @"From: " : (TITLE @"From:" NORMAL @"\n" INDENT),
          @"\n\tTo: " : (@"\n" BACK TITLE @"To:" NORMAL @"\n" INDENT),
          @"\n\tDepart after" : (@"\n" BACK TITLE @"Depart after:" NORMAL @"\n" INDENT),
          @"\n\tArrive by" : (@"\n" BACK TITLE @"Arrive by:" NORMAL @"\n" INDENT),
          // @"\nArrive"              : (@"\n" BACK TITLE @"Arrive:" NORMAL
          // @"\n" INDENT),
          // @"\nDepart"              : (@"\n" BACK TITLE @"Depart:" NORMAL
          // @"\n" INDENT)
      };
    }));

    NSMutableString *ms = [NSMutableString string];

    [ms appendString:string];

    [ms replaceOccurrencesOfString:@"\n"
                        withString:@"\n\t"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];

    [replacements enumerateKeysAndObjectsUsingBlock:^void(
                      NSString *dictionaryKey, NSString *val, BOOL *stop) {
      [ms replaceOccurrencesOfString:dictionaryKey
                          withString:val
                             options:NSLiteralSearch
                               range:NSMakeRange(0, ms.length)];
    }];

    return ms;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserParams *trip = [self tableView:tableView filteredDict:indexPath.row].userParams;
    NSString *text = trip.valChosenName;

    return [self multiLine:[self tableView:tableView cellWithReuseIdentifier:@"Trip"]
                      text:[self insertAttributes:text]
                      icon:nil
             accessoryType:UITableViewCellAccessoryDisclosureIndicator
            selectionStyle:UITableViewCellSelectionStyleBlue];
    ;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *i = [self filteredData:tableView][indexPath.row];

    TripPlannerResultsViewController *tripResults =
        [[TripPlannerResultsViewController alloc] initWithHistoryItem:i.intValue];

    // Push the detail view controller
    [self.navigationController pushViewController:tripResults animated:YES];
}

@end

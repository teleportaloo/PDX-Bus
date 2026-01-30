//
//  TableViewControllerWithRefresh.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithToolbar.h"

#define kRefreshText NSLocalizedString(@"Refresh", @"Refresh departure button")

#define kRefreshButton 0x01
#define kRefreshTimer 0x02
#define kRefreshPull 0x04
#define kRefreshShake 0x08
#define kRefreshAll (kRefreshButton | kRefreshTimer | kRefreshPull | kRefreshShake)
#define kRefreshNoTimer (kRefreshButton | kRefreshPull | kRefreshShake)

@interface TableViewControllerWithRefresh<FilteredItemType>
    : TableViewControllerWithToolbar <FilteredItemType>

@property (nonatomic) NSInteger refreshFlags;

- (void)stopTimer;
- (void)startTimer;
- (void)setRefreshButtonText:(NSString *)text
              forceAnimation:(bool)forceAnimation
                 animateNext:(bool)animateNext;
- (void)refreshAction:(id)unused;
- (void)countDownTimer;
- (void)updateRefreshDate:(NSDate *)date;

@end

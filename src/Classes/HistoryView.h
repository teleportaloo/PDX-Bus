//
//  HistoryView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewWithToolbar.h"

NS_ASSUME_NONNULL_BEGIN

@interface HistoryView : TableViewWithToolbar

@property NSMutableArray<NSDictionary *> *localRecents;

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section;
- (NSInteger)historySection:(UITableView *)tableView;
- (NSMutableArray<NSDictionary *> *)loadItems;
- (NSString *)noItems;
- (NSDictionary *)tableView:(UITableView *)tableView filteredDict:(NSInteger)item;

@end

NS_ASSUME_NONNULL_END

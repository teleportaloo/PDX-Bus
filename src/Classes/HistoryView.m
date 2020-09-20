//
//  HistoryView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "HistoryView.h"
#import "UserState.h"


#define kPlainId @"plain"

@implementation HistoryView

- (NSMutableArray *)loadItems {
    return [NSMutableArray array];
}

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section {
    return section == [self historySection:tableView];
}

- (NSInteger)historySection:(UITableView *)tableView {
    return 0;
}

- (NSString *)noItems {
    return @"";
}

- (void)reloadData {
    [self initSearchArray];
    [super reloadData];
}

- (void)initSearchArray {
    self.searchableItems = [NSMutableArray array];
    self.localRecents = [self loadItems];
    
    for (int i = 0; i < self.localRecents.count; i++) {
        [self.searchableItems addObject:@(i)];
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        [self initSearchArray];
        self.enableSearch = YES;
    }
    
    return self;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.table.allowsSelectionDuringEditing = YES;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self safeScrollToTop];
}

- (void)viewDidAppear:(BOOL)animated {
    [self reloadData];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSDictionary *)tableView:(UITableView *)tableView filteredDict:(NSInteger)item {
    NSNumber *i = [self filteredData:tableView][item];
    
    return self.localRecents[i.integerValue];
}

#pragma mark  Table View methods


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView isHistorySection:section]) {
        if (self.localRecents.count == 0) {
            return NSLocalizedString(@"No items in history", @"section title");
        } else if (tableView == self.table) {
            return [self noItems];
        }
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self filteredData:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (_userState)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [self.localRecents removeObjectAtIndex:indexPath.row];
            [self favesChanged];
            [_userState cacheState];
            [self initSearchArray];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
            
            if (self.localRecents.count == 0) {
                [self reloadData];
            }
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self.table setEditing:editing animated:animated];
    // self.table.editing = editing;
    [super setEditing:editing animated:animated];
}

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    if (tableView == self.table && [self tableView:tableView isHistorySection:fromIndexPath.section]
        && [self tableView:tableView isHistorySection:toIndexPath.section]) {
        DEBUG_LOGIP(fromIndexPath);
        DEBUG_LOGIP(toIndexPath);
        
        @synchronized (_userState)
        {
            self.localRecents = [self loadItems];
            NSDictionary *move = self.localRecents[fromIndexPath.row];
            
            if (fromIndexPath.row < toIndexPath.row) {
                [self.localRecents insertObject:move atIndex:toIndexPath.row + 1];
                [self.localRecents removeObjectAtIndex:fromIndexPath.row];
            } else {
                [self.localRecents removeObjectAtIndex:fromIndexPath.row];
                [self.localRecents insertObject:move atIndex:toIndexPath.row];
            }
            
            [_userState cacheState];
            [self favesChanged];
            [self initSearchArray];
        }
    }
    
    DEBUG_LOGLU(_userState.recents.count);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.table && [self tableView:tableView isHistorySection:indexPath.section]) {
        return YES;
    }
    
    return NO;
}

// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if (tableView == self.table && [self tableView:tableView isHistorySection:indexPath.section]) {
        return YES;
    }
    
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (tableView == self.table) {
        if (![self tableView:tableView isHistorySection:proposedDestinationIndexPath.section]) {
            return [NSIndexPath
                    indexPathForRow:0
                    inSection:[self historySection:tableView]];
        }
    }
    
    return proposedDestinationIndexPath;
}

@end

//
//  LocationServicesDebugViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocationServicesDebugViewController.h"
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"

#ifdef DEBUG_ALARMS

@interface LocationServicesDebugViewController ()

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSString *> *taskText;

@end

@implementation LocationServicesDebugViewController

enum {
    kRowText,
    kRowMap,
    kRowCancel,
};

- (id)init {
    if ((self = [super init])) {
        self.title = @"Location data";
    }

    return self;
}

- (void)dealloc {
    _data = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self clearSectionMaps];
    [self addSectionType:kRowText];
    [self addRowType:kRowText count:self.data.internalDataItems];
    [self addSectionType:kRowMap];
    [self addRowType:kRowMap];
    [self addRowType:kRowCancel];

    self.taskText = NSMutableDictionary.dictionary;
}

#pragma mark Helper functions

- (UITableViewStyle)getStyle {
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS LocationServicesDebugViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kRowText

CELL_CONFIG_METHOD(kRowText) {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"text"];

    [self multiLine:cell
                  text:self.taskText[@(indexPath.row)] ?: @"pending"
                  icon:nil
         accessoryType:UITableViewCellAccessoryNone
        selectionStyle:UITableViewCellSelectionStyleNone];

    if (self.taskText[@(indexPath.row)] == nil) {
        [self.data internalData:(int)indexPath.row
                     completion:^(NSString *str) {
                       MAIN_TASK(^{
                         self.taskText[@(indexPath.row)] = str;
                         [self.tableView
                             performBatchUpdates:^{
                               [self.tableView reconfigureRowsAtIndexPaths:@[ indexPath ]];
                             }
                                      completion:nil];
                       });
                     }];
    }

    return cell;
}

STATIC_VTABLE_VC_H(kRowText, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowMap

BASIC_CELL_SELECT(kRowMap, @"Show on map", kIconMap, UITableViewCellAccessoryDisclosureIndicator) {
    [self.data showMap:self.navigationController];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowCancel

BASIC_CELL_SELECT(kRowCancel,
                  @"Cancel task",
                  kIconCancel,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self.data cancelTask];
    CELL_POP();
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kRowText),
    CELL_MAP(kRowMap),
    CELL_MAP(kRowCancel),
};

@end

#endif // ifdef DEBUG_ALARMS

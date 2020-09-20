//
//  LocationServicesDebugView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocationServicesDebugView.h"

#ifdef DEBUG_ALARMS

@interface LocationServicesDebugView ()

@end

@implementation LocationServicesDebugView

#define kSectionText  0
#define kSectionMap   1
#define kSections     2

#define kMapRows      2
#define kMapRowMap    0
#define kMapRowCancel 1

- (void)dealloc {
    self.data = nil;
}

#pragma mark Helper functions

- (UITableViewStyle)getStyle {
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (id)init {
    if ((self = [super init])) {
        self.title = @"Location data";
    }
    
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kSectionMap: return kMapRows;
            
        case kSectionText: return self.data.internalDataItems;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionText: {
            UITableViewCell *cell = [self tableView:self.table multiLineCellWithReuseIdentifier:MakeCellId(kSectionText)];
            
            cell.textLabel.text = [self.data internalData:(int)indexPath.row];
            // printf("width:  %f\n", cell.view.bounds.size.width);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            // [self updateAccessibility:cell indexPath:indexPath text:[self.data internalData:(int)indexPath.row] alwaysSaySection:YES];
            // cell.backgroundView = [self clearView];
            return cell;
            
            break;
        }
            
        case kSectionMap: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionMap)];
            cell.textLabel.font = self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            switch (indexPath.row) {
                case kMapRowMap:        cell.textLabel.text = @"show on map"; break;
                    
                case kMapRowCancel: cell.textLabel.text = @"cancel"; break;
            }
            return cell;
            
            break;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionText) {
        return UITableViewAutomaticDimension;
    }
    
    return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionMap:
            switch (indexPath.row) {
                case kMapRowMap:
                    [self.data showMap:self.navigationController];
                    break;
                    
                case kMapRowCancel:
                    [self.data cancelTask];
                    [self.navigationController popViewControllerAnimated:YES];
                    break;
            }
            break;
            
        case kSectionText:
            break;
    }
}

@end

#endif // ifdef DEBUG_ALARMS

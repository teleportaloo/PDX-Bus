//
//  EditBookMarkViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CellTextField.h"
#import "EditableTableViewCell.h"
#import "ReturnStopIdString.h"
#import "TableViewControllerWithToolbar.h"
#import "TripItemCell.h"
#import "UserState.h"
#import "XMLTrips.h"
#import <IntentsUI/IntentsUI.h>
#import <UIKit/UIKit.h>

@interface EditBookMarkViewController
    : TableViewControllerWithToolbar <EditableTableViewCellDelegate,
                                      ReturnStopIdString>

@property(nonatomic) bool invalidItem;

- (void)timeSegmentChanged:(id)sender;
- (void)editBookMark:(NSMutableDictionary *)fave item:(uint)i;
- (void)addBookMark;
- (void)addTripBookMark;
- (void)addTakeMeHomeBookMark;
- (void)addBookMarkFromStop:(NSString *)desc stopId:(NSString *)stopId;
- (void)addBookMarkFromUserRequest:(XMLTrips *)tripQuery;
- (void)setupArrivalSections;
- (void)setupTripSections;

+ (NSString *)daysString:(int)days;

@end

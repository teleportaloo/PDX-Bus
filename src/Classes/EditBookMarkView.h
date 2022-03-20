//
//  EditBookMarkView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "EditableTableViewCell.h"
#import "ReturnStopIdString.h"
#import "CellTextField.h"
#import "XMLTrips.h"
#import "UserState.h"
#import "TripItemCell.h"
#import <IntentsUI/IntentsUI.h>

@interface EditBookMarkView : TableViewWithToolbar <EditableTableViewCellDelegate, ReturnStopIdString>

@property (nonatomic) bool invalidItem;

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

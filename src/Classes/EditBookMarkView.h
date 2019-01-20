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
#import "ReturnStopId.h"
#import "CellTextField.h"
#import "XMLTrips.h"
#import "TripReturnUserRequest.h"
#import "UserFaves.h"
#import "TripItemCell.h"
#import <IntentsUI/IntentsUI.h>

@interface EditBookMarkView : TableViewWithToolbar <EditableTableViewCellDelegate, ReturnStopId, TripReturnUserRequest, INUIAddVoiceShortcutViewControllerDelegate> {
    bool                    _reloadTrip;
    bool                    _reloadArrival;
    NSInteger               _stopSection;
    bool                    _updateNameFromDestination;
}

@property (nonatomic, copy) NSString *msg;
@property (nonatomic) bool invalidItem;
@property (nonatomic, strong) NSMutableArray *stops;
@property (nonatomic, strong) NSMutableDictionary *originalFave;
@property (nonatomic, strong) UITextField *editWindow;
@property (nonatomic) NSInteger item;
@property (nonatomic, strong) CellTextField *editCell;
@property (nonatomic, strong) TripUserRequest *userRequest;
@property (nonatomic) bool newBookmark;
@property (nonatomic, readonly) bool autoCommuteEnabled;
@property (nonatomic, readonly, copy) NSString *daysString;

-(void) timeSegmentChanged:(id)sender;
-(void) editBookMark:(NSMutableDictionary *)fave item:(uint)i;
-(void) addBookMark;
-(void) addTripBookMark;
-(void) addTakeMeHomeBookMark;
-(void) addBookMarkFromStop:(NSString *)desc location:(NSString *)locid;
-(void) addBookMarkFromUserRequest:(XMLTrips *)tripQuery;
-(void) setupArrivalSections;
-(void) setupTripSections;

+(NSString *)daysString:(int)days;

@end

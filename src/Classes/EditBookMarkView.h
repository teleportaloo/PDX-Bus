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

@interface EditBookMarkView : TableViewWithToolbar <EditableTableViewCellDelegate, ReturnStopId, TripReturnUserRequest> {
	NSMutableDictionary *_originalFave;
	NSMutableArray *_stops;
	UITextField *_editWindow;
	NSInteger _item;
	CellTextField *_editCell;
	bool _reloadTrip;
	bool _reloadArrival;
	NSInteger _stopSection;
	TripUserRequest * _userReq;
}

@property (nonatomic, retain) NSMutableArray *stops;
@property (nonatomic, retain) NSMutableDictionary *originalFave;
@property (nonatomic, retain) UITextField *editWindow;
@property (nonatomic) NSInteger item;
@property (nonatomic, retain) CellTextField *editCell;
@property (nonatomic, retain) TripUserRequest *userRequest;


-(void) timeSegmentChanged:(id)sender;
-(void) editBookMark:(NSMutableDictionary *)fave item:(uint)i;
-(void) addBookMark;
-(void) addTripBookMark;
-(void) addBookMarkFromStop:(NSString *)desc location:(NSString *)locid;
-(void) addBookMarkFromUserRequest:(XMLTrips *)tripQuery;
-(void) setupArrivalSections;
-(void) setupTripSections;
-(bool) autoCommuteEnabled;
+(NSString *)daysString:(int)days;
- (NSString*)daysString;



@end

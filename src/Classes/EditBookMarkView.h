//
//  EditBookMarkView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "EditableTableViewCell.h"
#import "ReturnStopId.h"
#import "CellTextField.h"
#import "XMLTrips.h"
#import "TripReturnUserRequest.h"
#import "UserFaves.h"

#define kEditBookMarkMaxSections	6

@interface EditBookMarkView : TableViewWithToolbar <EditableTableViewCellDelegate, ReturnStopId, TripReturnUserRequest> {
	NSMutableDictionary *_originalFave;
	NSMutableArray *_stops;
	UITextField *_editWindow;
	uint _item;
	CellTextField *_editCell;
	bool _reloadTrip;
	bool _reloadArrival;
	int _sectionMap[kEditBookMarkMaxSections];
	int _stopSection;
	int _sections;
	TripUserRequest * _userReq;
}

@property (nonatomic, retain) NSMutableArray *stops;
@property (nonatomic, retain) NSMutableDictionary *originalFave;
@property (nonatomic, retain) UITextField *editWindow;
@property (nonatomic) uint item;
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

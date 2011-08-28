//
//  TripPlannerEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//

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
#import "XMLTrips.h"
#import "EditableTableViewCell.h"
#import "ReturnStopId.h"
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import "CellTextField.h"
#import "CellTextView.h"
#import "TripReturnUserRequest.h"
#import "TripPlannerBaseView.h"


@interface TripPlannerEndPointView: TripPlannerBaseView <EditableTableViewCellDelegate, ReturnStopId, ABPeoplePickerNavigationControllerDelegate> {
	
	bool _from;
	UITextField *_placeNameField;
	bool keyboardUp;
	CellTextField *_editCell;
	UIViewController *_popBackTo;
	
}

@property (nonatomic) bool from;
@property (nonatomic, retain) UITextField *placeNameField;
@property (nonatomic, retain) CellTextField *editCell;
@property (nonatomic, retain) UIViewController *popBackTo;


- (UITextField *)createTextField_Rounded;
- (void)cellDidEndEditing:(EditableTableViewCell *)cell;
- (void) browseForStop;
- (void) selectFromRailMap;
- (void) selectedStop:(NSString *)stopId;
- (UIViewController*) getController;
- (void)gotPlace:(NSString *)place setUiText:(bool)setText additionalInfo:(NSString *)info;
- (void)cancelAction:(id)sender;
- (TripEndPoint *)endPoint;
- (void)initEndPoint;
- (void)nextScreen;


@end

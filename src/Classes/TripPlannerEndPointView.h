//
//  TripPlannerEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
#import <ContactsUI/ContactsUI.h>
#import "UIPlaceHolderTextView.h"

@interface TripPlannerEndPointView: TripPlannerBaseView <EditableTableViewCellDelegate, ReturnStopId, ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate>
{
    bool                _keyboardUp;
}

@property (nonatomic) bool from;
@property (nonatomic, strong) UIPlaceHolderTextView *placeNameField;
@property (nonatomic, strong) CellTextView *editCell;
@property (nonatomic, strong) UIViewController *popBackTo;
@property (nonatomic, readonly, strong) UIPlaceHolderTextView *createTextField_Rounded;
@property (nonatomic, readonly, strong) UIViewController *controller;
@property (nonatomic, readonly, strong) TripEndPoint *endPoint;

- (void)cellDidEndEditing:(EditableTableViewCell *)cell;
- (void)browseForStop;
- (void)selectFromRailMap;
- (void)selectedStop:(NSString *)stopId;
- (void)gotPlace:(NSString *)place setUiText:(bool)setText additionalInfo:(NSString *)info;
- (void)cancelAction:(id)sender;
- (void)initEndPoint;
- (void)nextScreen;

@end

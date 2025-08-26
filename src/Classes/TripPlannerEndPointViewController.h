//
//  TripPlannerEndPointViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "EditableTableViewCell.h"
#import "ReturnStopIdString.h"
#import "TableViewControllerWithToolbar.h"
#import "XMLTrips.h"
#import <UIKit/UIKit.h>
#if !TARGET_OS_MACCATALYST
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#endif
#import "CellTextField.h"
#import "CellTextView.h"
#import "TripPlannerBaseViewController.h"
#import "UIPlaceHolderTextView.h"
#import <ContactsUI/ContactsUI.h>

@interface TripPlannerEndPointViewController
    : TripPlannerBaseViewController <EditableTableViewCellDelegate,
                                     ReturnStopIdString,
#if !TARGET_OS_MACCATALYST
                                     ABPeoplePickerNavigationControllerDelegate,
#endif
                                     CNContactPickerDelegate>

@property(nonatomic, readonly, strong) UIViewController *controller;
@property(nonatomic) bool from;
@property(nonatomic, strong) UIViewController *popBackTo;

- (void)browseForStop;
- (void)selectFromRailMap;
- (void)gotPlace:(NSString *)place
         setUiText:(bool)setText
    additionalInfo:(NSString *)info;
- (void)cancelAction:(id)sender;
- (void)initEndPoint;
- (void)nextScreen;

@end

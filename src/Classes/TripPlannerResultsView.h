//
//  TripPlannerResultsView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "XMLTrips.h"
#import "TableViewWithToolbar.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "InfColorPickerController.h"
#import <EventKitUI/EventKitUI.h>
#import <IntentsUI/IntentsUI.h>


@interface TripPlannerResultsView : TableViewWithToolbar <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,
InfColorPickerControllerDelegate, EKEventViewDelegate, INUIAddVoiceShortcutViewControllerDelegate>

@property (nonatomic, strong) XMLTrips *tripQuery;
@property (nonatomic, strong) NSUserActivity *userActivity;

- (instancetype)initWithHistoryItem:(int)item;

@end

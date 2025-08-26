//
//  RootViewController.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmTaskList.h"
#import "CellTextField.h"
#import "EditableTableViewCell.h"
#import "ProgressModalView.h"
#import "TableViewControllerWithToolbar.h"
#import "WatchConnectivity/WCSession.h"
#import "WatchConnectivity/WatchConnectivity.h"
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIKit.h>

#define kRootMaxSections 7
#define kVersion @"Version"
#define kAboutVersion @"2"

@class UITextField;

typedef enum InitialActionEnum {
    InitialAction_None,
    InitialAction_Locate,
    InitialAction_Commute,
    InitialAction_TripPlanner,
    InitialAction_QRCode,
    InitialAction_BookmarkIndex,
    InitialAction_UserActivityBookmark,
    InitialAction_UserActivitySearch,
    InitialAction_Map,
    InitialAction_UserActivityAlerts
} InitialAction;

@interface RootViewController
    : TableViewControllerWithToolbar <EditableTableViewCellDelegate,
                                      MFMailComposeViewControllerDelegate,
                                      AlarmObserver, WCSessionDelegate>

@property(nonatomic, strong) NSDictionary *commuterBookmark;
@property(nonatomic, strong) NSDictionary *initialActionArgs;
@property(nonatomic) InitialAction initialAction;
@property(nonatomic, copy) NSString *launchStops;
@property(nonatomic, strong) NSURL *routingURL;
@property(nonatomic, copy) NSString *initialBookmarkName;
@property(nonatomic) int initialBookmarkIndex;
@property(nonatomic, strong) WCSession *session;

@property(null_resettable, nonatomic, strong) IBOutlet UIView *view;

- (void)postEditingAction:(UITextView *)textView;
- (void)commuteAction:(id)sender;
- (void)tripPlanner:(bool)animated;
- (void)launchFromURL;
- (void)executeInitialAction;
- (void)openFave:(int)index allowEdit:(bool)allowEdit;
- (void)helpAction:(id)sender;
- (NSInteger)rowType:(NSIndexPath *)indexPath;

+ (RootViewController *)currentRootViewController;

@end

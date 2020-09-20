//
//  RootViewController.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "EditableTableViewCell.h"
#import "TableViewWithToolbar.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "CellTextField.h"
#import "AlarmTaskList.h"
#import "ProgressModalView.h"
#import  <CoreLocation/CoreLocation.h>
#import "WatchConnectivity/WatchConnectivity.h"
#import "WatchConnectivity/WCSession.h"

#define kRootMaxSections 7
#define kVersion         @"Version"
#define kAboutVersion    @"2"

@class UITextField;

typedef enum InitialAction_tag {
    InitialAction_None,
    InitialAction_Locate,
    InitialAction_Commute,
    InitialAction_TripPlanner,
    InitialAction_QRCode,
    InitialAction_BookmarkIndex,
    InitialAction_UserActivityBookmark,
    InitialAction_UserActivitySearch,
    InitialAction_Map
} InitialAction;


@interface RootViewController : TableViewWithToolbar <EditableTableViewCellDelegate,
    MFMailComposeViewControllerDelegate,
    AlarmObserver,
    WCSessionDelegate>

@property (nonatomic, copy)   NSString *lastArrivalsShown;
@property (nonatomic, strong) NSArray *lastArrivalNames;
@property (nonatomic, strong) NSDictionary *commuterBookmark;
@property (nonatomic, strong) NSDictionary *initialActionArgs;
@property (nonatomic)         InitialAction initialAction;
@property (nonatomic, copy)   NSString *launchStops;
@property (nonatomic, strong) NSURL *routingURL;
@property (nonatomic, copy)   NSString *initialBookmarkName;
@property (nonatomic)         int initialBookmarkIndex;
@property (nonatomic, strong) WCSession *session;

- (void)postEditingAction:(UITextView *)textView;
- (void)commuteAction:(id)sender;
- (void)tripPlanner:(bool)animated;
- (void)launchFromURL;
- (void)executeInitialAction;
- (void)openFave:(int)index allowEdit:(bool)allowEdit;
- (void)helpAction:(id)sender;
- (NSInteger)rowType:(NSIndexPath *)indexPath;

@end

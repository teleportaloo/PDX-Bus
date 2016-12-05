//
//  RootViewController.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "EditableTableViewCell.h"
#import "TableViewWithToolbar.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "CellTextField.h"
#import "CellTextView.h"
#import "AlarmTaskList.h"
#import "ZXingWidgetController.h"
#import "ProgressModalView.h"
#import  <CoreLocation/CoreLocation.h>
#import "WatchConnectivity/WatchConnectivity.h"
#import "WatchConnectivity/WCSession.h"

#define kRootMaxSections 7
#define kVersion		@"Version"
#define kAboutVersion	@"2"

@class UITextField;

typedef enum InitialAction_tag
{
    InitialAction_None,
    InitialAction_Locate,
    InitialAction_Commute,
    InitialAction_TripPlanner,
    InitialAction_QRCode,
    InitialAction_BookmarkIndex,
    InitialAction_UserActivityBookmark,
    InitialAction_UserActivitySearch
} InitialAction;


@interface RootViewController : TableViewWithToolbar <EditableTableViewCellDelegate, 
									MFMailComposeViewControllerDelegate,
									AlarmObserver,
                                    ZXingDelegate,
                                    UIActionSheetDelegate,
                                    WCSessionDelegate>
{
	NSString *_lastArrivalsShown;
	NSArray *_lastArrivalNames;
	NSDictionary *_commuterBookmark;
	UITextField *_editWindow;	
	NSInteger faveSection;
	NSInteger editSection;
	AlarmTaskList *_taskList;
	NSArray *_alarmKeys;
    
	CellTextField *_editCell;
	bool keyboardUp;
	bool showingLast;
    NSString *_launchStops;
        
    // We need to keep hold of this view because of a bug
    // in which the app will crash if this is popped off 
    // the stack.
    ProgressModalView *_progressView;
    NSURL   *_routingURL;
    bool    _delayedInitialAction;
    InitialAction _initialAction;
    NSDictionary *_initialActionArgs;
    NSString *_initalBookmarkName;
    int _initialBookmarkIndex;
    
    UIBarButtonItem *_goButton;
    UIBarButtonItem *_helpButton;
    UIButton *_editBookmarksButton;
    WCSession* _session;
    bool    _updatedWatch;
}

- (void)postEditingAction:(UITextView *)textView;
- (void)commuteAction:(id)sender;
- (void)tripPlanner:(bool)animated;
- (void)launchFromURL;
- (void)executeInitialAction;
- (void)openFave:(int)index allowEdit:(bool)allowEdit;
- (void)helpAction:(id)sender;
- (NSInteger)rowType:(NSIndexPath *)indexPath;


@property (nonatomic, retain) UITextField *editWindow;
@property (nonatomic, copy)   NSString *lastArrivalsShown;
@property (nonatomic, retain) NSArray *lastArrivalNames;
@property (nonatomic, retain) CellTextField *editCell;
@property (nonatomic, retain) NSArray *alarmKeys;
@property (nonatomic, retain) NSDictionary *commuterBookmark;
@property (nonatomic, retain) ProgressModalView *progressView;
@property (nonatomic, copy)   NSString *launchStops;
@property (nonatomic, retain) NSURL *routingURL;
@property (nonatomic)         bool delayedInitialAction;
@property (nonatomic)         InitialAction initialAction;
@property (nonatomic, copy)   NSString *initialBookmarkName;
@property (nonatomic)         int       initialBookmarkIndex;
@property (nonatomic, retain) NSDictionary *initialActionArgs;
@property (nonatomic, retain) UIBarButtonItem *goButton;
@property (nonatomic, retain) UIBarButtonItem *helpButton;
@property (nonatomic, retain) UIButton *editBookmarksButton;
@property (nonatomic, retain) UIButton *emailBookmarksButton;
@property (nonatomic, retain) WCSession *session;

@end

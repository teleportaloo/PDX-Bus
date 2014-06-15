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
#import "IASKAppSettingsViewController.h"
#import "ZXingWidgetController.h"
#import "ProgressModalView.h"

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
    InitialAction_BookmarkIndex
} InitialAction;


@interface RootViewController : TableViewWithToolbar <EditableTableViewCellDelegate, 
									MFMailComposeViewControllerDelegate,
									AlarmObserver,
                                    ZXingDelegate,
                                    UIActionSheetDelegate>
{
	NSString *_lastArrivalsShown;
	NSArray *_lastArrivalNames;
	NSDictionary *_commuterBookmark;
	UITextField *_editWindow;	
	uint sectionMap[kRootMaxSections];
	uint sections;
	uint faveSection;
	uint editSection;
	AlarmTaskList *_taskList;
	NSArray *_alarmKeys;
    NSArray *_triMetRows;
    NSArray *_aboutRows;
    NSArray *_arrivalRows;
   
	
	CellTextField *_editCell;
	bool keyboardUp;
	bool showingLast;
    NSString *_launchStops;
        
    // We need to keep hold of this view because of a bug
    // in which the app will crash if this is popped off 
    // the stack.
    IASKAppSettingsViewController *_settingsView;
    ProgressModalView *_progressView;
    NSURL   *_routingURL;
    bool    _delayedInitialAction;
    InitialAction _initialAction;
    NSDictionary *_initialActionArgs;
    NSString *_initalBookmarkName;
    int _initialBookmarkIndex;
    bool _viewLoaded;
    
    UIBarButtonItem *_goButton;
    UIBarButtonItem *_helpButton;
}

- (void)postEditingAction:(UITextView *)textView;
- (void)commuteAction:(id)sender;
- (void)tripPlanner:(bool)animated;
- (bool)ZXingSupported;
- (void)launchFromURL;
- (void)executeInitialAction;
- (void)openFave:(int)index allowEdit:(bool)allowEdit;
- (void)helpAction:(id)sender;


@property (nonatomic, retain) UITextField *editWindow;
@property (nonatomic, retain) NSString *lastArrivalsShown;
@property (nonatomic, retain) NSArray *lastArrivalNames;
@property (nonatomic, retain) CellTextField *editCell;
@property (nonatomic, retain) NSArray *alarmKeys;
@property (nonatomic, retain) NSDictionary *commuterBookmark;
@property (nonatomic, retain) IASKAppSettingsViewController *settingsView;
@property (nonatomic, retain) ProgressModalView *progressView;
@property (nonatomic, retain) NSArray *triMetRows;
@property (nonatomic, retain) NSArray *aboutRows;
@property (nonatomic, retain) NSArray *arrivalRows;
@property (nonatomic, retain) NSString *launchStops;
@property (nonatomic, retain) NSURL *routingURL;
@property (nonatomic)         bool delayedInitialAction;
@property (nonatomic)         InitialAction initialAction;
@property (nonatomic, retain) NSString *initialBookmarkName;
@property (nonatomic)         int       initialBookmarkIndex;
@property (nonatomic)         bool      viewLoaded;
@property (nonatomic, retain) NSDictionary *initialActionArgs;
@property (nonatomic, retain) UIBarButtonItem *goButton;
@property (nonatomic, retain) UIBarButtonItem *helpButton;

@end

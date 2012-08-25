//
//  RootViewController.h
//  TriMetTimes
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



#define kMaxTweetButtons        4

@class UITextField;


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
    NSString *_tweetAt;
    NSString *_initTweet;
	
	CellTextField *_editCell;
	bool keyboardUp;
	bool showingLast;
    NSString *_launchStops;
    int _tweetButtons[kMaxTweetButtons];
    
    // We need to keep hold of this view because of a bug
    // in which the app will crash if this is popped off 
    // the stack.
    IASKAppSettingsViewController *_settingsView;
    ProgressModalView *_progressView;
    bool    _delayedInitialArrivals;
}

- (void)postEditingAction:(UITextView *)textView;
- (void)commuteAction:(id)sender;
- (void)tripPlanner:(bool)animated;
- (bool)ZXingSupported;
- (bool)RailMapSupported;
- (void)launchFromURL;
- (bool)initialArrivals;


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
@property (nonatomic, retain) NSString *tweetAt;
@property (nonatomic, retain) NSString *initTweet;
@property (nonatomic, retain) NSString *launchStops;
@property (nonatomic)         bool delayedInitialArrivals;

@end

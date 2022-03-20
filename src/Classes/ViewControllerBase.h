//
//  ViewControllerBase.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "BackgroundTaskContainer.h"
#import "ReturnStopIdString.h"
#import "ScreenConstants.h"
#import "UserState.h"

#define kSegNoSelectedIndex     (-1)

#define kNoAction @""

@interface ViewControllerBase : UIViewController <BackgroundTaskDone, UITextViewDelegate> {
    UserState *_userState;
}

// Basic lifecycle
- (bool)initMembers;
- (void)reloadData;
+ (instancetype)viewController;

// Callback with stop ID support
@property (nonatomic, readonly, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) id<ReturnStopIdString> stopIdStringCallback;
@property (nonatomic, readonly) bool forceRedoButton;
@property (nonatomic, readonly, strong) UIViewController *callbackWhenDone;
- (void)backButton:(id)sender;
- (void)backToRootButtons:(NSMutableArray *)toolbarItems;

// XML Debug support
#define XML_DEBUG_RAW_DATA(X)   if (X.rawData) { @synchronized(self) { [self.xml addObject:X]; } }
@property (nonatomic, readonly, strong) UIBarButtonItem *debugXmlButton;
@property (atomic, strong) NSMutableArray<TriMetXML *> *xml;
- (void)appendXmlData:(NSMutableData *)buffer;
- (void)xmlAction:(UIView *)button;
- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems;

// Flash button support
@property (nonatomic, readonly, strong) UIBarButtonItem *flashButton;
@property (nonatomic, readonly, strong) UIBarButtonItem *bigFlashButton;
+ (void)flashScreen:(UINavigationController *)nav button:(UIBarButtonItem *)button;
- (void)maybeAddFlashButtonWithSpace:(bool)space buttons:(NSMutableArray *)array big:(bool)big;

// View Helpers
@property (nonatomic, readonly, strong) UIView *clearView;
- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
- (UIBarButtonItem *)segBarButtonWithItems:(NSArray *)items action:(SEL)action selectedIndex:(NSInteger)selectedIndex;

// Helpers for sizes
@property (nonatomic, readonly) CGFloat heightOffset;
@property (nonatomic, readonly) CGRect middleWindowRect;
@property (nonatomic, readonly) ScreenInfo screenInfo;

// Helpers for fonts
@property (nonatomic, readonly, copy) UIFont *basicFont;
@property (nonatomic, readonly, copy) UIFont *smallFont;

// Video capture
@property (nonatomic, readonly) bool videoCaptureSupported;

// Task manager
@property (nonatomic, strong) BackgroundTaskContainer *backgroundTask;

// Route helpers
- (void)showRouteSchedule:(NSString *)route;
- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding;

// Browser helpers
- (void)facebook;
- (void)facebookTriMet;
- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path;
- (bool)openBrowserFrom:(UIViewController *)view path:(NSString *)path;  // May open chrome
- (void)tweetAt:(NSString *)twitterUser;
- (void)triMetTweetFrom:(UIView *)view;
- (void)buyMeACoffeeCell:(UITableViewCell *)cell;
- (void)buyMeACoffee;

// Toolbar helpers
- (void)updateToolbarItems:(NSMutableArray *)toolbarItems;
- (void)updateToolbar;

// Error handling
- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError;
- (bool)canGoDeeperAlert;


// UI stuff
- (void)displayActionSheet:(UIAlertController *)alert;
- (void)willRotateTo:(UIInterfaceOrientation)orientation;
- (void)clearSelection;
- (void)setTheme;

// Data management
- (void)updateWatch;
- (void)favesChanged;

// Links
- (bool)linkAction:(NSString *)link source:(UIView *)source;

- (void)handleChangeInUserSettingsOnMainThread:(NSNotification *)notfication;


@end

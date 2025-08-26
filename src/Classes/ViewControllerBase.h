//
//  ViewControllerBase.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "ReturnStopIdString.h"
#import "ScreenConstants.h"
#import "UserState.h"
#import <UIKit/UIKit.h>

#define kSegNoSelectedIndex (-1)

#define kNoAction @""

@interface ViewControllerBase
    : UIViewController <BackgroundTaskDone, UITextViewDelegate> {
    UserState *_userState;
}

// Basic lifecycle
- (bool)memberInit;
- (void)reloadData;
+ (instancetype)viewController;

// Callback with stop ID support
@property(nonatomic, readonly, strong) UIBarButtonItem *doneButton;
@property(nonatomic, strong) id<ReturnStopIdString> stopIdStringCallback;
@property(nonatomic, readonly) bool forceRedoButton;
@property(nonatomic, readonly, strong) UIViewController *callbackWhenDone;
- (void)backButton:(id)sender;
- (void)backToRootButtons:(NSMutableArray *)toolbarItems;

// Model done button that does the same as back
- (void)addDoneButtonSameAsBack;

#define XML_DEBUG_INIT()                                                       \
    if (Settings.debugXML) {                                                   \
        self.xml = [NSMutableArray array];                                     \
    } else {                                                                   \
        self.xml = nil;                                                        \
    }

// XML Debug support
#define XML_DEBUG_RAW_DATA(X)                                                  \
    if ((X) && (X).rawData && self.xml != nil) {                               \
        @synchronized(self) {                                                  \
            [self.xml addObject:X];                                            \
        }                                                                      \
    }
@property(nonatomic, readonly, strong) UIBarButtonItem *debugXmlButton;
@property(atomic, strong) NSMutableArray<TriMetXML *> *xml;
- (void)appendXmlData:(NSMutableData *)buffer;
- (void)xmlAction:(UIView *)button;
- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems;

// Flash button support
@property(nonatomic, readonly, strong) UIBarButtonItem *flashButton;
@property(nonatomic, readonly, strong) UIBarButtonItem *bigFlashButton;
+ (void)flashScreen:(UINavigationController *)nav
             button:(UIBarButtonItem *)button;
- (void)maybeAddFlashButtonWithSpace:(bool)space
                             buttons:(NSMutableArray *)array
                                 big:(bool)big;

// View Helpers
@property(nonatomic, readonly, strong) UIView *clearView;
- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
- (UIBarButtonItem *)segBarButtonWithItems:(NSArray *)items
                                    action:(SEL)action
                             selectedIndex:(NSInteger)selectedIndex;

// Helpers for sizes
@property(nonatomic, readonly) CGFloat heightOffset;
@property(nonatomic, readonly) CGRect middleWindowRect;
@property(nonatomic, readonly) ScreenInfo screenInfo;

// Helpers for fonts
@property(nonatomic, readonly, copy) UIFont *basicFont;
@property(nonatomic, readonly, copy) UIFont *smallFont;

// Video capture
@property(nonatomic, readonly) bool videoCaptureSupported;

// Task manager
@property(nonatomic, strong) BackgroundTaskContainer *backgroundTask;

// Route helpers
- (void)showRouteSchedule:(NSString *)route;
- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding;

// Browser helpers
- (void)facebookPDXBus;
- (void)facebookTriMet;
- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path;
- (void)instagramAt:(NSString *)user;
- (void)blueskyAt:(NSString *)user;
- (void)triMetBlueskyFrom:(UIView *)view;
- (void)buyMeACoffeeCell:(UITableViewCell *)cell;
- (void)buyMeACoffee;
- (void)tipJarCell:(UITableViewCell *)cell;
- (void)tipJar;

// Toolbar helpers
- (void)updateToolbarMainThread;
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

- (void)didEnterBackground;
- (void)didBecomeActive;

@end

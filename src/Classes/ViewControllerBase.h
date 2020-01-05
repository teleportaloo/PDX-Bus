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
#import "UIToolbar+Auto.h"
#import "BackgroundTaskContainer.h"
#import "ReturnStopId.h"
#import "ScreenConstants.h"
#import "UserPrefs.h"
#import "UserFaves.h"
#include "Icons.h"
#import "UIColor+DarkMode.h"

@class Detour;

#define kLargeScreenWidth           694

#ifdef PDXBUS_EXTENSION
#define LARGE_SCREEN NO
#else
#define LARGE_SCREEN                ([UIApplication sharedApplication].delegate.window.bounds.size.width >= kLargeScreenWidth)
#endif
#define SMALL_SCREEN                !(LARGE_SCREEN)
#define kRailAwareReloadButton      1
#define TableViewBasicFont          [UIFont systemFontOfSize:kBasicTextViewFontSize]
#define TableViewBackFont           [UIFont boldSystemFontOfSize:16.0]
#define XML_DEBUG_RAW_DATA(X)       if (X.rawData) [self.xml addObject:X];
#define kSegNoSelectedIndex         -1

@protocol DeselectItemDelegate <NSObject>

- (void)deselectItemCallback;

@end

@interface ViewControllerBase : UIViewController <BackgroundTaskDone> {
    SafeUserData *                      _userData;
    UIFont *                            _basicFont;
    UIFont *                            _paragraphFont;
}

@property (nonatomic, readonly, strong) UIBarButtonItem *flashButton;
@property (nonatomic, readonly, strong) UIBarButtonItem *bigFlashButton;
@property (nonatomic, readonly, strong) UIBarButtonItem *doneButton;
@property (nonatomic, readonly, strong) UIBarButtonItem *debugXmlButton;
@property (nonatomic, readonly, strong) UIBarButtonItem *ticketAppButton;
@property (nonatomic, readonly) bool forceRedoButton;
@property (nonatomic, readonly, strong) UIView *clearView;
@property (nonatomic, readonly) CGFloat heightOffset;
@property (nonatomic, readonly) CGRect middleWindowRect;
@property (nonatomic, readonly) ScreenInfo screenInfo;
@property (nonatomic, readonly, copy) UIFont *basicFont;
@property (nonatomic, readonly, copy) UIFont *paragraphFont;
@property (nonatomic, readonly) bool iOS9style;
@property (nonatomic, readonly) bool iOS11style;
@property (nonatomic, readonly) bool videoCaptureSupported;
@property (nonatomic, readonly) bool fullScreen;
@property (nonatomic, readonly, strong) UIViewController *callbackWhenDone;
@property (atomic, strong) NSMutableArray<TriMetXML *> *xml;

@property (nonatomic, strong) BackgroundTaskContainer *backgroundTask;
@property (nonatomic, strong) id<ReturnStopId> callback;

- (void)setBackfont:(UILabel *)label;
- (void)notRailAwareButton:(NSInteger)button;
- (void)showRouteSchedule:(NSString *)route;
- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding;
- (void)backButton:(id)sender;
- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
- (UIImage *)getIcon:(NSString *)name;
- (UIImage *)getModeAwareIcon:(NSString *)name;
- (UIImage *)getFaveIcon:(NSString *)name;
- (void)backToRootButtons:(NSMutableArray *)toolbarItems;
- (void)updateToolbarItems:(NSMutableArray *)toolbarItems;
- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError;
- (void)maybeAddFlashButtonWithSpace:(bool)space buttons:(NSMutableArray *)array big:(bool)big;
- (bool)initMembers;
- (void)setTheme;
- (void)reloadData;
- (void)rotatedTo:(UIInterfaceOrientation)orientation;
- (void)appendXmlData:(NSMutableData *)buffer;
- (void)xmlAction:(UIView *)button;
- (void)updateToolbar;
- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems;
- (void)tweetAt:(NSString *)twitterUser;
- (void)triMetTweetFrom:(UIView*)view;
- (void)clearSelection;
- (void)facebook;
- (void)facebookTriMet;
- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path;
- (bool)openBrowserFrom:(UIViewController *)view path:(NSString *)path;  // May open chrome
- (void)updateWatch;
- (void)favesChanged;
- (void)displayAlert:(UIAlertController*)alert;
- (UIBarButtonItem*)segBarButtonWithItems:(NSArray*)items action:(SEL)action selectedIndex:(NSInteger)selectedIndex;

+ (UIImage *)getIcon:(NSString *)name;
+ (UIImage *)getToolbarIcon:(NSString *)name;
+ (void)flashScreen:(UINavigationController *)nav button:(UIBarButtonItem *)button;
+ (instancetype)viewController;




@end

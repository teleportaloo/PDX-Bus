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
#import "CustomToolbar.h"
#import "BackgroundTaskContainer.h"
#import "ReturnStopId.h"
#import "ScreenConstants.h"
#import "UserPrefs.h"
#import "UserFaves.h"

#define kMaxTweetButtons        6

@protocol DeselectItemDelegate <NSObject>

- (void)deselectItemCallback;

@end

@interface ViewControllerBase : UIViewController <BackgroundTaskDone, UIDocumentInteractionControllerDelegate, UIActionSheetDelegate> {
	BackgroundTaskContainer *           _backgroundTask;
	id<ReturnStopId>                    _callback;
	SafeUserData *                      _userData;
    UIDocumentInteractionController *   _docMenu;
    UIBarButtonItem *                   _xmlButton;
    
    NSString *                          _tweetAt;
    NSString *                          _initTweet;
    
    int                                 _tweetButtons[kMaxTweetButtons];
    
    UIActionSheet *                     _tweetAlert;
}

- (bool)initMembers;
- (void)setTheme;
- (UIBarButtonItem *)autoFlashButton;
- (UIBarButtonItem *)autoBigFlashButton;
- (UIBarButtonItem *)autoDoneButton;
- (UIBarButtonItem*)autoXmlButton;
- (UIBarButtonItem *)autoTicketAppButton;
- (bool)forceRedoButton;
+ (void)flashScreen:(UINavigationController *)nav;
- (void)backToRootButtons:(NSMutableArray *)toolbarItems;
- (void)updateToolbarItems:(NSMutableArray *)toolbarItems;
- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError;
- (void)maybeAddFlashButtonWithSpace:(bool)space buttons:(NSMutableArray *)array big:(bool)big;

- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
- (UIImage *)alwaysGetIcon:(NSString *)name;
- (UIImage *)alwaysGetIcon7:(NSString *)name old:(NSString*)old;
+ (UIImage *)alwaysGetIcon:(NSString *)name;
- (UIImage *)getActionIcon:(NSString *)name;
- (UIImage *)getActionIcon7:(NSString *)name old:(NSString *)old;
+ (UIImage *)getToolbarIcon:(NSString *)name;
+ (UIImage *)getToolbarIcon7:(NSString *)name old:(NSString *)old;
- (UIImage *)getFaveIcon:(NSString *)name;
- (UIView *)clearView;
- (void)setBackfont:(UILabel *)label;
- (void)notRailAwareAlert:(id<UIAlertViewDelegate>) delegate;
- (void)noLocations:(NSString *)title delegate:(id<UIAlertViewDelegate>) delegate;
- (void)notRailAwareButton:(NSInteger)button;
- (NSString *)justNumbers:(NSString *)text;
- (void)showRouteSchedule:(NSString *)route;
- (void)showRouteAlerts:(NSString *)route fullSign:(NSString *)fullSign;
- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding;
- (void)backButton:(id)sender;
- (CGFloat) heightOffset;
- (CGRect)getMiddleWindowRect;
- (ScreenInfo)screenInfo;
- (void)reloadData;
+ (UIColor*)htmlColor:(int)val;
- (void)appendXmlData:(NSMutableData *)buffer;
- (void)xmlAction:(id)arg;
- (void)updateToolbar;
- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems;
- (void)tweet;
- (void)clearSelection;
- (void)facebook;
- (void)facebookTriMet;
- (bool)iOS7style;
- (bool)iOS8style;
+ (bool)iOS7style;
- (bool)iOS9style;
- (bool)ZXingSupported;
- (void)setSegColor:(UISegmentedControl*)seg;
- (bool)ticketApp;
- (bool)fullScreen;
- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path;
- (bool)openBrowserFrom:(UIViewController *)view path:(NSString *)path;  // May open chrome
- (UIViewController*)callbackWhenDone;

@property (nonatomic, retain) UIBarButtonItem *xmlButton;
@property (nonatomic, retain) BackgroundTaskContainer *backgroundTask;
@property (nonatomic, retain) id<ReturnStopId> callback;
@property (nonatomic, retain) UIDocumentInteractionController *docMenu;
@property (nonatomic, retain) NSString *tweetAt;
@property (nonatomic, retain) NSString *initTweet;
@property (nonatomic, retain) UIActionSheet *tweetAlert;

#define kRailAwareReloadButton 1

#define kIconTicket          @"Ticket24.png"
#define kIconDetour			 @"Trackback.png"
#define kIconEarthMap		 @"Earth.png"
#define kIconAlarmFired      @"Alarm.png"
#define kIconAlarm           @"Alarm clock.png"
#define kIconFacebook		 @"Facebook.png"
#define kIconAward			 @"Award.png"
#define kIconSrc			 @"Source.png"
#define kIconBrush			 @"Brush.png"
#define kIconRecent			 @"Clock.png"
#define kIconWiki			 @"wiki.png"
#define kIconFave			 @"Clock.png"
#define kIconEnterStopID	 @"Find.png"
#define kIconAlerts			 @"Warning.png"
#define kIconBlog			 @"Blog.png"
#define kIconLink			 @"Globe.png"
#define kIconTriMetLink		 @"TriMet.png"
#define kIconHome			 @"53-house.png"
#define kIconHome7           @"750-home.png"
#define kIconRedo			 @"02-redo.png"
#define kIconBrowse			 @"List.png"
#define kIconTwitter		 @"Twitter.png"
#define kIconEmail			 @"Message.png"
#define kIconCell			 @"Mobile-phone.png"
#define kIconCal			 @"Calendar.png"
#define kIconCut			 @"Cut.png"
#define kIconTripPlanner	 @"Schedule.png"
#define kIconEdit			 @"Wrench.png"
#define kIconHistory	     @"History.png"
#define kIconContacts		 @"Address book.png"
#define kIconAbout			 @"Info.png"
#define kIconFlash			 @"61-brightness.png"
#define kIconFlash7			 @"861-sun-2.png"
#define kIconBack			 @"icon_arrow_left.png"
#define kIconBack7           @"765-arrow-left.png"
#define kIconForward		 @"icon_arrow_right.png"
#define kIconForward7		 @"766-arrow-right.png"
#define kIconUp				 @"icon_arrow_up.png"
#define kIconLargeUp		 @"arrow_up_64.png"
#define kIconUp7             @"763-arrow-up.png"
#define kIconDown			 @"icon_arrow_down.png"
#define kIconDown7           @"764-arrow-down.png"
#define kIconNetworkOk		 @"Yes.png"
#define kIconNetworkBad		 @"Problem.png"
#define kIconNetwork		 @"Network connection.png"
#define kIconPhone			 @"Phone number.png"
#define kIconLocate			 kIconLargeLocateNear
#define kIconLocate7		 @"845-location-targeta.png"
#define kIconDeleteDatabase  @"Erase.png"
#define kIconDelete			 @"Erase.png"
#define kIconCancel			 @"Erase.png"
#define kIconSort			 @"05-shuffle.png"
#define kIconSort7			 @"891-shuffle.png"
#define kIconMap			 @"103-map.png"
#define kIconMap7			 @"852-map.png"
#define kIconMagnify		 @"magnifier.png"
#define kIconMapAction		 @"103-map.png"
#define kIconMapAction7		 @"852-mapa.png"
#define kIconMaxMap          @"RailSystem.png"
#define kIconStreetcarMap    @"Streetcar.png"
#define KIconRailStations	 @"RailStations.png"
#define kIconReverse		 @"Redo.png"
#define kIconArrivals		 @"Clock.png"
#define kIconAdd			 @"Add.png"
#define kIconExpand			 @"Downdate.png"
#define kIconExpand7		 kIconDown7
#define kIconCollapse		 @"Update.png"
#define kIconCollapse7		 kIconUp7
#define kIconMorning		 @"Sun.png"
#define kIconEvening		 @"Moon.png"
#define kIconCommute		 @"11-clock.png"
#define kIconCommute7		 @"780-building.png"
#define kIconLocateNear      @"74-location.png"
#define kIconLargeLocateNear @"74-locationa.png"
#define kIconLargeLocateNear7 kIconLocateNear7
#define kIconLocateNear7     @"845-location-target.png"
#define kIconFindGps		 @"network-satellite.png"
#define kIconFindCell		 kIconNetwork
#define kIconSettings        @"Settings.png"
#define kIconCamera          @"86-camera.png"
#define kIconCamera7         @"714-camera.png"
#define kIconCameraAction    @"86-camera.png"
#define kIconCameraAction7   @"714-cameraa.png"
#define kIconXml             @"110-bug.png"
#define kIconLocation        @"Location.png"
#define kIconLocationHeading @"LocationHeading.png"
#define kIconAppIconAction   @"ActionIcon.png"
#define kIconEye             @"751-eye.png"


#define TableViewBasicFont	[UIFont systemFontOfSize:kBasicTextViewFontSize]
#define TableViewBackFont	[UIFont boldSystemFontOfSize:16.0]

@end

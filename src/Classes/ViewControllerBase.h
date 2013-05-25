//
//  ViewControllerBase.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
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
#import "CustomToolbar.h"
#import "BackgroundTaskContainer.h"
#import "ReturnStopId.h"
#import "ScreenConstants.h"
#import "UserPrefs.h"
#import "UserFaves.h"


#define kMaxTweetButtons        6

@interface ViewControllerBase : UIViewController <BackgroundTaskDone, UIDocumentInteractionControllerDelegate, UIActionSheetDelegate> {
	BackgroundTaskContainer *_backgroundTask;
	id<ReturnStopId> _callback;
	SafeUserData	*_userData;
    UIDocumentInteractionController *_docMenu;
    UIBarButtonItem *_xmlButton;
    
    NSString *_tweetAt;
    NSString *_initTweet;
    
    int _tweetButtons[kMaxTweetButtons];
    
    UIActionSheet *_tweetAlert;

}

- (bool)initMembers;
- (void)setTheme;
- (UIBarButtonItem *)autoFlashButton;
- (UIBarButtonItem *)autoBigFlashButton;
- (UIBarButtonItem *)autoDoneButton;
- (UIBarButtonItem*)autoXmlButton;
- (bool)forceRedoButton;
+ (void)flashScreen:(UINavigationController *)nav;
- (void)createToolbarItems;
- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError;

- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
- (UIImage *)alwaysGetIcon:(NSString *)name;
+ (UIImage *)alwaysGetIcon:(NSString *)name;
- (UIImage *)getActionIcon:(NSString *)name;
+ (UIImage *)getToolbarIcon:(NSString *)name;
- (UIImage *)getFaveIcon:(NSString *)name;
- (UIView *)clearView;
- (void)setBackfont:(UILabel *)label;
- (void)notRailAwareAlert:(id<UIAlertViewDelegate>) delegate;
- (void)noLocations:(NSString *)title delegate:(id<UIAlertViewDelegate>) delegate;
- (void)notRailAwareButton:(int)button;
- (NSString *)justNumbers:(NSString *)text;
- (void)showRouteSchedule:(NSString *)route;
- (void)showRouteAlerts:(NSString *)route fullSign:(NSString *)fullSign;
- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding;
- (void)backButton:(id)sender;
- (CGFloat) heightOffset;
- (CGRect)getMiddleWindowRect;
- (ScreenType)screenWidth;
- (void)reloadData;
- (UIColor*)htmlColor:(int)val;
- (void)appendXmlData:(NSMutableData *)buffer;
- (void)xmlAction:(id)arg;
- (void)createToolbarItemsWithXml;
- (void)tweet;
- (void)clearSelection;
- (void)facebook;


@property (nonatomic, retain) UIBarButtonItem *xmlButton;
@property (nonatomic, retain) BackgroundTaskContainer *backgroundTask;
@property (nonatomic, retain) id<ReturnStopId> callback;
@property (nonatomic, retain) UIDocumentInteractionController *docMenu;
@property (nonatomic, retain) NSString *tweetAt;
@property (nonatomic, retain) NSString *initTweet;
@property (nonatomic, retain) UIActionSheet *tweetAlert;



#define kRailAwareReloadButton 1

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
#define kIconTriMetLink		 @"visittrimeticon.gif"
#define kIconHome			 @"53-house.png"
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
#define kIconBack			 @"icon_arrow_left.png"
#define kIconForward		 @"icon_arrow_right.png"
#define kIconUp				 @"icon_arrow_up.png"
#define kIconDown			 @"icon_arrow_down.png"
#define kIconNetworkOk		 @"Yes.png"
#define kIconNetworkBad		 @"Problem.png"
#define kIconNetwork		 @"Network connection.png"
#define kIconPhone			 @"Phone number.png"
#define kIconLocate			 kIconLocateNear
#define kIconDeleteDatabase  @"Erase.png"
#define kIconDelete			 @"Erase.png"
#define kIconCancel			 @"Erase.png"
#define kIconSort			 @"05-shuffle.png"
#define kIconMap			 @"103-map.png"
#define kIconMagnify		 @"magnifier.png"
#define kIconMapAction		 @"103-map.png"
#define kIconMaxMap          @"RailSystem.png"
#define kIconStreetcarMap    @"Streetcar.png"
#define KIconRailStations	 @"RailStations.png"
#define kIconReverse		 @"Redo.png"
#define kIconArrivals		 @"Clock.png"
#define kIconAdd			 @"Add.png"
#define kIconExpand			 @"Downdate.png"
#define kIconCollapse		 @"Update.png"
#define kIconMorning		 @"Sun.png"
#define kIconEvening		 @"Moon.png"
#define kIconCommute		 @"11-clock.png"
#define kIconLocateNear      @"74-location.png"
#define kIconFindGps		 @"network-satellite.png"
#define kIconFindCell		 kIconNetwork
#define kIconSettings        @"Settings.png"
#define kIconCamera          @"86-camera.png"
#define kIconXml             @"110-bug.png"
#define kIconLocation        @"Location.png"
#define kIconLocationHeading @"LocationHeading.png"





#define TableViewBasicFont	[UIFont systemFontOfSize:kBasicTextViewFontSize]
#define TableViewBackFont	[UIFont boldSystemFontOfSize:16.0]

@end

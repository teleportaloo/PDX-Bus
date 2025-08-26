//
//  Icons.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MemoryCaches.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kIconAppIconAction @"ActionIcon.png"
#define kIconBluesky @"Bluesky_Logo.png"
#define kIconBuyMeACoffee @"BuyMeACoffee.png"
#define kIconCollapse7 kIconUp7
#define kIconExpand7 kIconDown7
#define kIconFacebook @"Facebook.png"
#define kIconFindCell kIconNetwork
#define kIconGitHub @"GitHub"
#define kIconInstagram @"Instagram"
#define kIconMaxMap @"RailSystem.png"
#define kIconRailStations @"RailStations.png"
#define kIconSiri @"Siri.png"
#define kIconStreetcar @"Portland_Streetcar_logo.png"
#define kIconTriMetLink @"TriMet.png"
#define kIconUp @"icon_arrow_up.png"
#define kIconUp2x @"icon_arrow_up@2x.png"
#define kIconUpHead @"icon_arrow_up_head.png"
#define kIconUpHead2x @"icon_arrow_up_head@2x.png"
#define kSFIconAbout @"info.circle"
#define kSFIconAdd @"plus.circle.fill"
#define kSFIconAddTint [UIColor greenColor]
#define kSFIconAlarm @"alarm"
#define kSFIconAlarmFired @"alarm.waves.left.and.right"
#define kSFIconArrivals @"clock.badge.checkmark"
#define kSFIconAward @"trophy"
#define kSFIconBack @"arrowshape.backward"
#define kSFIconBrowse @"rectangle.and.text.magnifyingglass"
#define kSFIconCal @"calendar.badge.plus"
#define kSFIconCancel @"exclamationmark.octagon.fill"
#define kSFIconCancelTint [UIColor redColor]
#define kSFIconChevronDown @"chevron.down"
#define kSFIconChevronUp @"chevron.up"
#define kSFIconCommute @"briefcase"
#define kSFIconContacts @"person.2"
#define kSFIconCopy @"document.on.document"
#define kSFIconDelete @"minus.circle.fill"
#define kSFIconDeleteTint [UIColor redColor]
#define kSFIconDetour @"exclamationmark.triangle"
#define kSFIconDownload @"arrow.down.circle"
#define kSFIconEmail @"mail"
#define kSFIconEnterStopID @"magnifyingglass"
#define kSFIconEvening @"moon.fill"
#define kSFIconEveningTint [UIColor orangeColor]
#define kSFIconEye @"eye"
#define kSFIconFave kSFIconArrivals
#define kSFIconFlash @"flashlight.on.fill"
#define kSFIconHome @"house"
#define kSFIconLocateMe @"location.magnifyingglass"
#define kSFIconLocateNow @"location.fill"
#define kSFIconLocateNearby @"magnifyingglass.circle"
#define kSFIconMagnify @"plus.magnifyingglass"
#define kSFIconMap @"map"
#define kSFIconMorning @"sun.min.fill"
#define kSFIconMorningTint [UIColor orangeColor]
#define kSFIconNetwork @"network"
#define kSFIconNetworkBad @"xmark.circle.fill"
#define kSFIconNetworkBadTint [UIColor redColor]
#define kSFIconNetworkOk @"checkmark.circle.fill"
#define kSFIconNetworkOkTint [UIColor greenColor]
#define kSFIconPhone @"phone"
#define kSFIconQR @"qrcode.viewfinder"
#define kSFIconRecent kSFIconArrivals
#define kSFIconReverse @"arrow.uturn.backward"
#define kSFIconSettings @"gear"
#define kSFIconSMS @"message.fill"
#define kSFIconSort @"shuffle"
#define kSFIconSource @"doc.plaintext"
#define kSFIconTick @"checkmark.circle"
#define kSFIconTickTint [UIColor greenColor]
#define kSFIconTripPlanner @"point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill"
#define kSFIconWebBack @"arrowshape.left"
#define kSFIconWebForward @"arrowshape.right"
#define kSFIconXml @"ladybug"

@interface Icons : NSObject

+ (UIImage *)characterIcon:(NSString *)text;
+ (UIImage *)characterIcon:(NSString *)text
               placeholder:(UIImage *_Nullable)placeholder;

+ (void)getDelayedIcon:(NSString * _Nullable)name
            completion:(void (^ _Nonnull)(UIImage * _Nonnull image))completion;

+ (Icons *)sharedInstance;

@end

NS_ASSUME_NONNULL_END

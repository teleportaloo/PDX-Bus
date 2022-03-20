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


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kIconDetour           @"Trackback.png"
#define kIconEarthMap         @"Earth.png"
#define kIconAlarmFired       @"Alarm.png"
#define kIconAlarm            @"Alarm clock.png"
#define kIconFacebook         @"Facebook.png"
#define kIconBuyMeACoffee     @"BuyMeACoffee.png"
#define kIconAward            @"Award.png"
#define kIconSrc              @"Source.png"
#define kIconBrush            @"Brush.png"             // Used only in pLists
#define kIconRecent           @"Clock.png"
#define kIconFave             @"Clock.png"
#define kIconEnterStopID      @"Find.png"
#define kIconBlog             @"Blog.png"
#define kIconLink             @"Globe.png"
#define kIconTriMetLink       @"TriMet.png"
#define kIconHome7            @"750-home.png"
#define kIconRedo             @"02-redo.png"
#define kIconBrowse           @"List.png"
#define kIconTwitter          @"Twitter.png"
#define kIconEmail            @"Message.png"
#define kIconCell             @"Mobile-phone.png"
#define kIconCal              @"Calendar.png"
#define kIconCut              @"Cut.png"
#define kIconTripPlanner      @"Schedule.png"
#define kIconHistory          @"History.png"
#define kIconContacts         @"Address book.png"
#define kIconAbout            @"Info.png"
#define kIconFlash7           @"861-sun-2.png"
#define kIconBack7            @"765-arrow-left.png"
#define kIconForward7         @"766-arrow-right.png"
#define kIconUp               @"icon_arrow_up.png"
#define kIconUp2x             @"icon_arrow_up@2x.png"
#define kIconUpHead           @"icon_arrow_up_head.png"
#define kIconUpHead2x         @"icon_arrow_up_head@2x.png"
#define kIconUp7              @"763-arrow-up.png"
#define kIconDown7            @"764-arrow-down.png"
#define kIconNetworkOk        @"Yes.png"
#define kIconNetworkBad       @"Problem.png"
#define kIconNetwork          @"Network connection.png"
#define kIconPhone            @"Phone number.png"
#define kIconLocate7          @"845-location-targeta.png"
#define kIconDelete           @"Erase.png"
#define kIconCancel           @"Erase.png"
#define kIconSort7            @"891-shuffle.png"
#define kIconMap7             @"852-map.png"
#define kIconMagnify          @"magnifier.png"
#define kIconMapAction7       @"852-mapa.png"
#define kIconMaxMap           @"RailSystem.png"
#define kIconRailStations     @"RailStations.png"
#define kIconReverse          @"Redo.png"
#define kIconArrivals         @"Clock.png"
#define kIconAdd              @"Add.png"
#define kIconExpand7          kIconDown7
#define kIconCollapse7        kIconUp7
#define kIconMorning          @"Sun.png"
#define kIconEvening          @"Moon.png"
#define kIconCommute7         @"780-building.png"
#define kIconLocateNear7      @"845-location-target.png"
#define kIconFindCell         kIconNetwork
#define kIconSettings         @"19-gear.png"
#define kIconCamera7          @"714-camera.png"
#define kIconCameraAction7    @"714-cameraa.png"
#define kIconXml              @"110-bug.png"
#define kIconLocationHeading  @"LocationHeading.png"
#define kIconAppIconAction    @"ActionIcon.png"
#define kIconEye              @"751-eye.png"
#define kIconSiri             @"Siri.png"

@interface Icons : NSObject

+ (UIImage *)getIcon:(NSString *)name;
+ (UIImage *)characterIcon:(NSString *)text;
+ (UIImage *)characterIcon:(NSString *)text placeholder:(UIImage * _Nullable)placeholder;
+ (UIImage *)getToolbarIcon:(NSString *)name;
+ (UIImage *)getModeAwareIcon:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

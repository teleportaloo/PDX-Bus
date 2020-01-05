//
//  WatchDepartureUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/12/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "Departure.h"
#import <WatchKit/WatchKit.h>
#import "WatchPinColor.h"

#define kStaleTime   (45)

@interface Departure (watchOSUI) <WatchPinColor>

@property (nonatomic, readonly, copy) UIColor *fontColor;
@property (nonatomic, readonly, strong) UIImage *routeColorImage;
@property (nonatomic, readonly, copy) NSString *formattedMinsToArrival;
@property (nonatomic, readonly) bool hasRouteColor;
@property (nonatomic, readonly, strong) UIImage *blockImageColor;
@property (nonatomic, readonly, copy) NSAttributedString *headingWithStatus;
@property (nonatomic, readonly, copy) NSString *exception;
@property (nonatomic, readonly) bool stale;


@property (nonatomic, readonly) WKInterfaceMapPinColor pinColor;
@property (nonatomic, readonly, copy) UIColor *pinTint;
@property (nonatomic, readonly) bool hasBearing;
@property (nonatomic, readonly) double doubleBearing;
@property (nonatomic, readonly) CLLocationCoordinate2D coord;



@end

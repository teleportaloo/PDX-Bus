//
//  WatchDepartureUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/12/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "DepartureData.h"
#import <WatchKit/WatchKit.h>
#import "WatchPinColor.h"

@interface WatchDepartureUI <WatchPinColor>: NSObject
{
    DepartureData *_data;
}

@property (nonatomic, retain) DepartureData *data;

- (id)initWithData:(DepartureData*)data;
+ (WatchDepartureUI *)createFromData:(DepartureData*)data;

- (UIColor*)getFontColor;
- (UIImage*)getRouteColorImage;
- (NSString*)minsToArrival;
- (bool)hasRouteColor;
- (UIImage*)getBlockImageColor;
- (NSAttributedString *)headingWithStatus;
- (NSString *)exception;


- (WKInterfaceMapPinColor)getPinColor;
- (UIColor*)getPinTint;
- (bool)hasBearing;
- (double)bearing;
- (CLLocationCoordinate2D)coord;



@end

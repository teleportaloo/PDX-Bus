//
//  DepartureCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/1/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "RouteColorBlobView.h"
#import "CanceledBusOverlay.h"
#import "ScreenConstants.h"
#import "BlockColorView.h"

#define kDepartureCellHeight         55
#define kLargeDepartureCellHeight    85
#define kLargeWidth                  kLargeScreenWidth

#define DEPARTURE_CELL_USE_LARGE     LARGE_SCREEN
#define DEPARTURE_CELL_HEIGHT        (DEPARTURE_CELL_USE_LARGE ? kLargeDepartureCellHeight : kDepartureCellHeight)


@interface DepartureCell : UITableViewCell
{

}

@property (nonatomic, readonly) UILabel *routeLabel;
@property (nonatomic, readonly) UILabel *timeLabel;
@property (nonatomic, readonly) UILabel *minsLabel;
@property (nonatomic, readonly) UILabel *unitLabel;
@property (nonatomic, readonly) RouteColorBlobView *routeColorView;
@property (nonatomic, readonly) UILabel *scheduledLabel;
@property (nonatomic, readonly) UILabel *detourLabel;
@property (nonatomic, readonly) BlockColorView *blockColorView;
@property (nonatomic, readonly) CanceledBusOverlay *cancelledOverlayView;
@property (nonatomic, readonly) bool large;

+ (instancetype)cellWithReuseIdentifier:(NSString *)identifier;
+ (instancetype)genericWithReuseIdentifier:(NSString *)identifier;

- (DepartureCell *)initWithReuseIdentifier:(NSString *)identifier;
- (DepartureCell *)initGenericWithReuseIdentifier:(NSString *)identifier;



@end

//
//  DepartureCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/1/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "RouteColorBlobView.h"
#import "CanceledBusOverlay.h"
#import "ScreenConstants.h"
#import "BlockColorView.h"

#define kDepartureCellHeight      55
#define kLargeDepartureCellHeight 85
#define kLargeWidth               kLargeScreenWidth

#define DEPARTURE_CELL_USE_LARGE  LARGE_SCREEN

@interface DepartureCell : UITableViewCell

@property (weak, nonatomic, readonly) UILabel *routeLabel;
@property (weak, nonatomic, readonly) UILabel *timeLabel;
@property (weak, nonatomic, readonly) UILabel *minsLabel;
@property (weak, nonatomic, readonly) UILabel *unitLabel;
@property (weak, nonatomic, readonly) RouteColorBlobView *routeColorView;
@property (weak, nonatomic, readonly) UILabel *scheduledLabel;
@property (weak, nonatomic, readonly) UILabel *detourLabel;
@property (weak, nonatomic, readonly) UILabel *fullLabel;
@property (weak, nonatomic, readonly) BlockColorView *blockColorView;
@property (weak, nonatomic, readonly) CanceledBusOverlay *cancelledOverlayView;
@property (nonatomic, readonly) bool large;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

// - (DepartureCell *)initWithReuseIdentifier:(NSString *)identifier tallRouteLabel:(bool)tallRouteTable;
- (DepartureCell *)initGenericWithReuseIdentifier:(NSString *)identifier;

+ (instancetype)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)identifier tallRouteLabel:(bool)tallRouteTable;
+ (instancetype)tableView:(UITableView *)tableView genericWithReuseIdentifier:(NSString *)identifier;

+ (CGFloat)cellHeightWithTallRouteLabel:(bool)tallRouteLabel;

- (void)resetConstraints;

@end

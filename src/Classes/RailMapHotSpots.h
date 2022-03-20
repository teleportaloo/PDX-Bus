//
//  RailMapHotSpots.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/1/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "HotSpot.h"

@interface RailMapHotSpots : UIView

@property (nonatomic, strong) UIView *mapView;
@property (nonatomic) bool showAll;

- (instancetype)initWithImageView:(UIView *)imgView map:(RailMap *)map;
- (void)fadeOut;
- (void)selectItem:(int)i;
- (void)touchAtPoint:(CGPoint)point;

@end

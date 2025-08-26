//
//  RailMapHotSpotsView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/1/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "HotSpot.h"
#import <UIKit/UIKit.h>

@interface RailMapHotSpotsView : UIView

@property(nonatomic, strong) UIView *mapView;
@property(nonatomic) bool showAll;

- (instancetype)initWithImageView:(UIView *)imgView map:(PtrConstRailMap)map;
- (void)fadeOut;
- (void)selectItem:(int)i;
- (void)touchAtPoint:(CGPoint)point;

+ (bool)touched:(PtrConstHotSpot)hs;
+ (void)touch:(PtrConstHotSpot)hs;

@end

//
//  RailMapViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DeselectItemDelegate.h"
#import "HotSpot.h"
#import "SimpleAnnotation.h"
#import "Stop.h"
#import "ViewControllerBase.h"
#import "XMLStops.h"
#import <UIKit/UIKit.h>
#import "TilingView.h"

#define NO_HOTSPOT_FOUND (-1)

@interface RailMapViewController
    : ViewControllerBase <ReturnStopObject, UIScrollViewDelegate,
                          DeselectItemDelegate, UIGestureRecognizerDelegate>

@property(nonatomic) bool from;
@property(nonatomic) bool showNextOnAppearance;

+ (int)findHotSpotInMap:(PtrConstRailMap)map
                   tile:(const RailMapTile *)tile
                  point:(CGPoint)tapPoint;
+ (PtrConstRailMap)railMap:(int)n;

@end

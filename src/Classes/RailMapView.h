//
//  RailMapView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ReturnStopId.h"
#import "TapDetectingImageView.h"
#import "SimpleAnnotation.h"
#import "Stop.h"
#import "ViewControllerBase.h"
#import "XMLStops.h"
#import "HotSpot.h"
#import "DeselectItemDelegate.h"

@interface RailMapView : ViewControllerBase <ReturnStop, UIScrollViewDelegate, TapDetectingImageViewDelegate, DeselectItemDelegate>

@property (nonatomic) bool from;
@property (nonatomic) bool showNextOnAppearance;

+ (void)     initHotspotData;

+ (int)      nHotspotRecords;
+ (HOTSPOT *)hotspotRecords;

@end

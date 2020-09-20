//
//  SimpleAnnotation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/24/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "MapPinColor.h"


@interface SimpleAnnotation : NSObject <MapPinColor> {
    bool _hasBearing;
    double _bearing;
}

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic) MapPinColorValue pinColor;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) bool showActionMenu;
@property (nonatomic, copy) NSString *pinTitle;
@property (nonatomic, copy) NSString *pinSubtitle;
@property (nonatomic, copy) UIColor *pinTint;
@property (nonatomic, copy) UIColor *pinSubTint;

- (void)setDoubleBearing:(double)bearing;

+ (instancetype)annotation;
@end

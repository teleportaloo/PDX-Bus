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
	NSString *              _pinTitle;
	NSString *              _pinSubtitle;
	MKPinAnnotationColor    _pinColor;
	CLLocationCoordinate2D  _coordinate;
    UIColor *               _pinTint;
    UIColor *               _pinSubTint;
    double                  _bearing;
    bool                    _hasBearing;
}

+ (instancetype)annotation;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic) MKPinAnnotationColor pinColor;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) bool showActionMenu;
- (void)setDoubleBearing:(double)bearing;
@property (nonatomic, copy) NSString *pinTitle;
@property (nonatomic, copy) NSString *pinSubtitle;
@property (nonatomic, copy) UIColor *pinTint;
@property (nonatomic, copy) UIColor *pinSubTint;






@end

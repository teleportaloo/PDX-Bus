//
//  UIImage+Tint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/2/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Tint)

- (UIImage *)rotatedImageByDegreesFromNorth:(double)degrees;
- (UIImage *)tintImageWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END

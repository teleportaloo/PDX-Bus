//
//  UIColor+MoreDarkMode.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/10/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSString+Convenience.h"
#import "UIColor+DarkMode.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef PDXBUS_WATCH
#define IOS_DARK_MODE (false)
#else
#define IOS_DARK_MODE                                                                              \
    ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
#endif // IOS_DARK_MODE

@interface UIColor (MoreDarkMode)

+ (UIColor *)modeAwareFrequentBusColor;
+ (UIColor *)modeAwareBusColor;
+ (UIColor *)modeAwareSystemWideAlertBackground;
+ (UIColor *)modeAwareSystemWideAlertText;
+ (UIColor *)modeAwareGrayBackground;
+ (UIColor *)modeAwareDisclaimerBackground;
+ (UIColor *)modeAwareCellBackground;
+ (UIColor *)modeAwareAppBackground;
+ (UIColor *)modeAwareBusText;
+ (UIColor *)modeAwarePurple;

- (NSString *)string;

/// Return a variant better suited for dark backgrounds by ensuring a minimum HSV "brightness".
/// - Parameters:
///   - minBrightness: Floor for brightness/value in [0,1]. 0.72–0.80 is a good range; try 0.75.
/// - Returns: Adjusted color with same hue/saturation, boosted brightness.
- (UIColor *)modeAwareVariantWithMinBrightness:(CGFloat)minBrightness;

/// Convenience default (minBrightness = 0.75).
- (UIColor *)modeAwareVariant;

@end
NS_ASSUME_NONNULL_END

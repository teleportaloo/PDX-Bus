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
#define IOS_DARK_MODE                                                          \
    ([UIScreen mainScreen].traitCollection.userInterfaceStyle ==               \
     UIUserInterfaceStyleDark)
#endif

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

@end
NS_ASSUME_NONNULL_END

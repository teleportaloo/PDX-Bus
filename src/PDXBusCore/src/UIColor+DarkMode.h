//
//  UIColor+DarkMode.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/10/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define IOS_DARK_MODE ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)


#define COL_HTML_R(V)  (((CGFloat)(((V) >> 16  ) & 0xFF))/255.0)
#define COL_HTML_G(V)  (((CGFloat)(((V) >> 8   ) & 0xFF))/255.0)
#define COL_HTML_B(V)  (((CGFloat) ((V)          & 0xFF))/255.0)

#define HTML_COLOR(V) [UIColor colorWithRed:COL_HTML_R(V)           \
                                      green:COL_HTML_G(V)           \
                                       blue:COL_HTML_B(V) alpha:1.0]

@interface UIColor (DarkMode)

+ (UIColor *)modeAwareBusColor;
+ (UIColor *)modeAwareSystemWideAlertBackground;
+ (UIColor *)modeAwareSystemWideAlertText;
+ (UIColor *)modeAwareGrayBackground;
+ (UIColor *)modeAwareDisclaimerBackground;
+ (UIColor *)modeAwareCellBackground;
+ (UIColor *)modeAwareAppBackground;
+ (UIColor *)modeAwareText;
+ (UIColor *)modeAwareBlue;
+ (UIColor *)modeAwarePurple;

- (NSString *)string;

@end
NS_ASSUME_NONNULL_END

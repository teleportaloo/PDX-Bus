//
//  MainFonts.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/8/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIFont+Utility.h"
#import <UIKit/UIKit.h>

@implementation UIFont (Utility)

static UIFont *smallFont;
static UIFont *basicFont;

+ (UIFont *)smallFont
{
    return smallFont;
}

+ (void)setSmallFont:(UIFont*)font
{
    smallFont = font;
}

+ (UIFont *)basicFont
{
    return basicFont;
}

+ (void)setBasicFont:(UIFont*)font
{
    basicFont = font;
}


+ (UIFont *)monospacedDigitSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightRegular];
}

+ (UIFont *)boldMonospacedDigitSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightBold];
}

@end

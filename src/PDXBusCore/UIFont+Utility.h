//
//  MainFonts.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/8/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface UIFont (Utility)

// The purpose of this is to have these accesses atomic and to separate the fonts from the
// strings

@property (class, atomic, strong) UIFont *smallFont;
@property (class, atomic, strong) UIFont *basicFont;

+ (UIFont *)monospacedDigitSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)boldMonospacedDigitSystemFontOfSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END

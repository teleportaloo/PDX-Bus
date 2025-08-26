//
//  UIBarButtonItem+Icons.h
//  PDX Bus
//
//  Created by Andy Wallace on 4/7/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (Icons)

+ (instancetype)withNamedImage:(nullable NSString *)image
                         style:(UIBarButtonItemStyle)style
                        target:(nullable id)target
                        action:(nullable SEL)action;

+ (instancetype)withSystemImage:(nullable NSString *)name
                          style:(UIBarButtonItemStyle)style
                         target:(nullable id)target
                         action:(nullable SEL)action;

@end

NS_ASSUME_NONNULL_END

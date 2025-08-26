//
//  UITableViewCell+Icons.h
//  PDX Bus
//
//  Created by Andy Wallace on 3/24/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewCell (Icons)

- (void)setNamedIcon:(NSString *__nullable)name;
- (void)setSystemIcon:(NSString *)name;
- (void)systemIcon:(NSString *)name tint:(UIColor *)tint;

@end

NS_ASSUME_NONNULL_END

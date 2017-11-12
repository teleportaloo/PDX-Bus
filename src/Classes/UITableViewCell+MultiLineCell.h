//
//  UITableViewCell+MultiLineCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@interface UITableViewCell (MultiLineCell)

+ (UITableViewCell *)cellWithMultipleLines:(NSString *)identifier font:(UIFont*)font;
+ (UITableViewCell *)cellWithMultipleLines:(NSString *)identifier;


@end

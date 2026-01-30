//
//  UIBarButtonItem+Icons.m
//  PDX Bus
//
//  Created by Andy Wallace on 4/7/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BoxedIcon.h"
#import "Icons.h"
#import "UIBarButtonItem+Auto.h"
#import "UIBarButtonItem+Icons.h"

@implementation UIBarButtonItem (Icons)

+ (instancetype)withIcon:(nullable BoxedIcon *)icon
                  target:(nullable id)target
                  action:(nullable SEL)action {
    return [UIBarButtonItem imageButton:icon.image target:target action:action];
}

@end

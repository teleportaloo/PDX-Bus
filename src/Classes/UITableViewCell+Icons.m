//
//  UITableViewCell+Icons.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/24/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BoxedIcon.h"
#import "Icons.h"
#import "UITableViewCell+Icons.h"

@implementation UITableViewCell (Icons)

- (void)setIcon:(BoxedIcon *)icon {
    if (icon == nil) {
        self.imageView.image = nil;
        self.imageView.tintColor = nil;
        return;
    }

    self.imageView.image = icon.image;
    self.imageView.tintColor = icon.tint;
}

@end

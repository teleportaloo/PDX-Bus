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


#import "Icons.h"
#import "UITableViewCell+Icons.h"

@implementation UITableViewCell (Icons)

- (void)setNamedIcon:(NSString *)name {
    [Icons getDelayedIcon:name
               completion:^(UIImage *image) {
                 self.imageView.image = image;
                 [self setNeedsLayout];
               }];
}

- (void)setSystemIcon:(NSString *)name {
    self.imageView.image = [UIImage systemImageNamed:name];
    self.imageView.tintColor = nil;
}

- (void)systemIcon:(NSString *)name tint:(UIColor *)tint {
    self.imageView.image = [UIImage systemImageNamed:name];
    self.imageView.tintColor = tint;
}

@end

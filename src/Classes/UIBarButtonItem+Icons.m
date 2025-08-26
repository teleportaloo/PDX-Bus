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


#import "Icons.h"
#import "UIBarButtonItem+Icons.h"

@implementation UIBarButtonItem (Icons)

+ (instancetype)withSystemImage:(nullable NSString *)name
                          style:(UIBarButtonItemStyle)style
                         target:(nullable id)target
                         action:(nullable SEL)action {

    
    UIImage *image = [UIImage systemImageNamed:name];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:style
                                                            target:target
                                                            action:action];

    return item;
}

+ (instancetype)withNamedImage:(nullable NSString *)name
                         style:(UIBarButtonItemStyle)style
                        target:(nullable id)target
                        action:(nullable SEL)action {

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:nil
                                                             style:style
                                                            target:target
                                                            action:action];

    [Icons getDelayedIcon:name
               completion:^(UIImage *image) {
                 item.image = image;
               }];

    return item;
}

@end

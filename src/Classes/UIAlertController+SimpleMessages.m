//
//  UIAlertController+SimpleMessages.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/12/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RootViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

@implementation UIAlertController (SimpleMessages)

+ (void)simpleOkWithTitle:(NSString *)title
                  message:(NSString *)message
           viewController:(UIViewController *)viewControlller
               completion:(void (^__nullable)(void))completion {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [viewControlller presentViewController:alert animated:YES completion:completion];
}

@end

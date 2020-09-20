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


#import "UIAlertController+SimpleMessages.h"
#import "PDXBusAppDelegate+Methods.h"

@implementation UIAlertController (SimpleMessages)

+ (UIAlertController *)simpleOkWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
     
    return alert;
}

- (void)showAlert
{
    UIViewController *top = PDXBusAppDelegate.sharedInstance.navigationController.topViewController;
     
    [top presentViewController:self animated:YES completion:nil];
}

@end

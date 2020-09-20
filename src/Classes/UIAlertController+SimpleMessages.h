//
//  UIAlertController+SimpleMessages.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/12/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kAlertViewOK        NSLocalizedString(@"OK",        @"Alert OK button")
#define kAlertViewCancel    NSLocalizedString(@"Cancel",    @"Alert Cancel button")

@interface UIAlertController (SimpleMessages)

+ (UIAlertController *)simpleOkWithTitle:(nullable NSString *)title
                                 message:(nullable NSString *)message;


- (void)showAlert;

@end

NS_ASSUME_NONNULL_END

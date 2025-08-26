//
//  UIApplication+Compat.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/13/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (Compat)

@property(nonatomic, readonly) CGRect compatStatusBarFrame;

@property(nonatomic, readonly, class) CGRect compatApplicationFrame;

+ (UIWindow *__nullable)firstKeyWindow;

- (void)compatOpenURL:(NSURL *)url;

@property(readonly, nonatomic)
    UIInterfaceOrientation compatStatusBarOrientation;

+ (UIViewController *__nullable)topViewController;
+ (UIViewController *__nullable)rootViewController;
+ (CGRect)appRect;

@end

NS_ASSUME_NONNULL_END

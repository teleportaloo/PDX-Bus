//
//  UIApplication+Compat.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/13/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIApplication+Compat.h"

@implementation UIApplication (Compat)

#if !TARGET_OS_MACCATALYST

- (CGRect)compatStatusBarFrame {
    CGRect statusBarFrame = CGRectZero;

    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            statusBarFrame = windowScene.statusBarManager.statusBarFrame;
            break;
        }
    }

    return statusBarFrame;
}

+ (CGRect)compatApplicationFrame {
    CGRect rect = UIApplication.firstKeyWindow.frame;

    if (UIApplication.firstKeyWindow.frame.size.width == 0.0 &&
        UIApplication.firstKeyWindow.frame.size.height == 0.0) {
        rect = [UIScreen mainScreen].bounds;
    }

    rect.size.height -=
        [UIApplication firstKeyWindow]
            .windowScene.statusBarManager.statusBarFrame.size.height;

    return rect;
}

+ (CGRect)appRect {
    CGRect windowBounds = CGRectZero;

    UIWindow *keyWindow = self.firstKeyWindow;

    if (keyWindow) {
        windowBounds = keyWindow.bounds;
    }

    return windowBounds;
}

+ (UIViewController *)rootViewController {
    UIWindow *keyWindow = self.firstKeyWindow;

    if (keyWindow) {
        return ((UINavigationController *)keyWindow.rootViewController)
            .viewControllers.firstObject;
    }

    return nil;
}

+ (UIViewController *)topViewController {
    UIViewController *rootViewController = self.rootViewController;

    if (rootViewController) {
        return rootViewController.navigationController.topViewController;
    }

    return nil;
}

+ (UIWindow *)firstKeyWindow {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

- (void)compatOpenURL:(NSURL *)url {
    // Right now we just say it worked!
    [self openURL:url
                  options:@{}
        completionHandler:^(BOOL success){
        }];
}

- (UIInterfaceOrientation)compatStatusBarOrientation {
    return [UIApplication firstKeyWindow].windowScene.interfaceOrientation;
}

#else // if !TARGET_OS_MACCATALYST

- (BOOL)compatNetworkActivityIndicatorVisible {
    return NO;
}

- (void)setCompatNetworkActivityIndicatorVisible:(BOOL)visable {
}

- (CGRect)compatStatusBarFrame {
    return [UIApplication firstKeyWindow]
        .windowScene.statusBarManager.statusBarFrame;
}

+ (CGRect)compatApplicationFrame {
    CGRect rect = UIApplication.firstKeyWindow.frame;

    if (UIApplication.firstKeyWindow.frame.size.width == 0.0 &&
        UIApplication.firstKeyWindow.frame.size.height == 0.0) {
        rect = [UIScreen mainScreen].bounds;
    }

    rect.size.height -=
        [UIApplication firstKeyWindow]
            .windowScene.statusBarManager.statusBarFrame.size.height;

    return rect;
}

+ (UIWindow *)firstKeyWindow {
    return [UIApplication.sharedApplication.windows
               filteredArrayUsingPredicate:[NSPredicate
                                               predicateWithBlock:^BOOL(
                                                   UIWindow *object,
                                                   NSDictionary *bindings) {
                                                 return object.isKeyWindow;
                                               }]]
        .firstObject;
}

- (void)compatOpenURL:(NSURL *)url {
    // Right now we just say it worked!
    [self openURL:url
                  options:@{}
        completionHandler:^(BOOL success){
        }];
}

- (UIInterfaceOrientation)compatStatusBarOrientation {
    return [UIApplication firstKeyWindow].windowScene.interfaceOrientation;
}

#endif // if !TARGET_OS_MACCATALYST

@end

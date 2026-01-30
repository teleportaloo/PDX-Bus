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
        return ((UINavigationController *)keyWindow.rootViewController).viewControllers.firstObject;
    }

    return nil;
}

+ (UIWindowScene *)activeWindowScene {
    // Prefer a foreground-active scene
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:UIWindowScene.class]) {
            return (UIWindowScene *)scene;
        }
    }
    // Fallback: any scene with windows
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.windows.count > 0)
                return ws;
        }
    }
    return nil;
}

+ (UIViewController *)topViewController {
    UIWindowScene *scene = [self activeWindowScene];
    if (!scene)
        return nil;

    // Find a key window first; otherwise take the first non-hidden window with a rootVC
    UIWindow *targetWindow = nil;
    for (UIWindow *w in scene.windows) {
        if (w.isKeyWindow) {
            targetWindow = w;
            break;
        }
    }
    if (!targetWindow) {
        for (UIWindow *w in scene.windows) {
            if (!w.isHidden && w.alpha > 0.0 && w.rootViewController) {
                targetWindow = w;
                break;
            }
        }
    }
    if (!targetWindow)
        return nil;

    UIViewController *top = targetWindow.rootViewController;
    if (!top)
        return nil;

    // Walk presented stack
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    // If it's a nav controller, use the visible VC
    if ([top isKindOfClass:UINavigationController.class]) {
        top = ((UINavigationController *)top).visibleViewController ?: top;
    }
    // If it's a tab controller, use the selected VC
    if ([top isKindOfClass:UITabBarController.class]) {
        UIViewController *sel = ((UITabBarController *)top).selectedViewController;
        if (sel)
            top = sel;
    }
    return top;
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

#else // if !TARGET_OS_MACCATALYST

- (BOOL)compatNetworkActivityIndicatorVisible {
    return NO;
}

- (void)setCompatNetworkActivityIndicatorVisible:(BOOL)visable {
}

+ (UIWindow *)firstKeyWindow {
    return
        [UIApplication.sharedApplication.windows
            filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(
                                                         UIWindow *object, NSDictionary *bindings) {
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

#endif // if !TARGET_OS_MACCATALYST

@end

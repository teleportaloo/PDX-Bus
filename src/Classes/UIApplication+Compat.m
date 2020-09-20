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

- (BOOL)compatNetworkActivityIndicatorVisible {
    return self.networkActivityIndicatorVisible;
}

- (void)setCompatNetworkActivityIndicatorVisible:(BOOL)visable {
    self.networkActivityIndicatorVisible = visable;
}

- (CGRect)compatStatusBarFrame {
    return [self statusBarFrame];
}

+ (CGRect)compatApplicationFrame {
    CGRect rect = UIApplication.firstKeyWindow.frame;
    
    if (UIApplication.firstKeyWindow.frame.size.width == 0.0 && UIApplication.firstKeyWindow.frame.size.height == 0.0) {
        rect = [UIScreen mainScreen].bounds;
    }
    
    if (@available(iOS 13.0, *)) {
        rect.size.height -= [UIApplication firstKeyWindow].windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        rect.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    return rect;
}

+ (UIWindow *)firstKeyWindow {
    return UIApplication.sharedApplication.keyWindow;
}

- (void)compatOpenURL:(NSURL *)url {
    // Right now we just say it worked!
    [self openURL:url options:@{} completionHandler:^(BOOL success) { }];
}

- (UIInterfaceOrientation)compatStatusBarOrientation {
    return self.statusBarOrientation;
}

#else // if !TARGET_OS_MACCATALYST

- (BOOL)compatNetworkActivityIndicatorVisible {
    return NO;
}

- (void)setCompatNetworkActivityIndicatorVisible:(BOOL)visable {
}

- (CGRect)compatStatusBarFrame {
    return [UIApplication firstKeyWindow].windowScene.statusBarManager.statusBarFrame;
}

+ (CGRect)compatApplicationFrame {
    CGRect rect = UIApplication.firstKeyWindow.frame;
    
    if (UIApplication.firstKeyWindow.frame.size.width == 0.0 && UIApplication.firstKeyWindow.frame.size.height == 0.0) {
        rect = [UIScreen mainScreen].bounds;
    }
    
    rect.size.height -= [UIApplication firstKeyWindow].windowScene.statusBarManager.statusBarFrame.size.height;
    
    return rect;
}

+ (UIWindow *)firstKeyWindow {
    return [UIApplication.sharedApplication.windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (UIWindow *object, NSDictionary *bindings) {
        return object.isKeyWindow;
    }]].firstObject;
}

- (void)compatOpenURL:(NSURL *)url {
    // Right now we just say it worked!
    [self openURL:url options:@{} completionHandler:^(BOOL success) { }];
}

- (UIInterfaceOrientation)compatStatusBarOrientation {
    return [UIApplication firstKeyWindow].windowScene.interfaceOrientation;
}

#endif // if !TARGET_OS_MACCATALYST

@end

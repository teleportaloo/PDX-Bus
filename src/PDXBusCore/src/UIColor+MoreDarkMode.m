//
//  UIColor+DarkMode.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/10/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "UIColor+MoreDarkMode.h"
#import "DebugLogging.h"
#import "UIColor+HTML.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@implementation UIColor (MoreDarkMode)

- (NSString *)string {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;

    [self getRed:&r green:&g blue:&b alpha:&a];

    return [NSString stringWithFormat:@"rgb %f %f %f %f", r, g, b, a];
}

+ (UIColor *)modeAwareFrequentBusColor {
    if (IOS_DARK_MODE) {
        return HTML_COLOR(0x99D6FF);
    } else {
        return HTML_COLOR(0x2a558a);
    }
}

+ (UIColor *)modeAwareBusColor {
    if (IOS_DARK_MODE) {
        return [UIColor whiteColor];
    } else {
        return HTML_COLOR(0x5d7aa6);
    }
}

+ (UIColor *)modeAwareSystemWideAlertBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor quaternarySystemFillColor];
    }
#endif
    return HTML_COLOR(0xFFFF99);
}

+ (UIColor *)modeAwareSystemWideAlertText {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return HTML_COLOR(0xFFFF99);
    }
#endif
    return [UIColor blackColor];
}

+ (UIColor *)modeAwareGrayBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor quaternarySystemFillColor];
    }
#endif
    return [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
}

+ (UIColor *)modeAwareDisclaimerBackground {
    return UIColor.modeAwareCellBackground;
}

+ (UIColor *)modeAwareCellBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor blackColor];
    }
#endif
    return [UIColor whiteColor];
}

+ (UIColor *)modeAwareAppBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor secondarySystemBackgroundColor];
    }
#endif
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}

+ (UIColor *)modeAwareBusText {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor blueColor];
    }
#endif
    return [UIColor whiteColor];
}

+ (UIColor *)modeAwarePurple {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor systemPurpleColor];
    }
#endif
    return [UIColor purpleColor];
}

@end

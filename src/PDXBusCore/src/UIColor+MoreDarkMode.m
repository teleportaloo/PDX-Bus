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


#import "DebugLogging.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "UIColor+HTML.h"
#import "UIColor+MoreDarkMode.h"

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
#endif // !PDXBUS_WATCH
    return HTML_COLOR(0xFFFF99);
}

+ (UIColor *)modeAwareSystemWideAlertText {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return HTML_COLOR(0xFFFF99);
    }
#endif // !PDXBUS_WATCH
    return [UIColor blackColor];
}

+ (UIColor *)modeAwareGrayBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor quaternarySystemFillColor];
    }
#endif // !PDXBUS_WATCH
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
#endif // !PDXBUS_WATCH
    return [UIColor whiteColor];
}

+ (UIColor *)modeAwareAppBackground {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor secondarySystemBackgroundColor];
    }
#endif // !PDXBUS_WATCH
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}

+ (UIColor *)modeAwareBusText {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor blueColor];
    }
#endif // !PDXBUS_WATCH
    return [UIColor whiteColor];
}

+ (UIColor *)modeAwarePurple {
#ifndef PDXBUS_WATCH
    if (IOS_DARK_MODE) {
        return [UIColor systemPurpleColor];
    }
#endif // !PDXBUS_WATCH
    return [UIColor purpleColor];
}

- (UIColor *)modeAwareVariant {
    return [self modeAwareVariantWithMinBrightness:0.75];
}

- (UIColor *)modeAwareVariantWithMinBrightness:(CGFloat)minBrightness {

    if (!IOS_DARK_MODE) {
        return self;
    }

    minBrightness = MAX(0.0, MIN(1.0, minBrightness));

    CGFloat h = 0, s = 0, b = 0, a = 0;

    // Try HSB decomposition first
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        if (b < minBrightness) {
            b = minBrightness;
        }
        return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
    }

    // Fallback for grayscale colorspaces
    CGFloat white = 0;
    if ([self getWhite:&white alpha:&a]) {
        // If it's a dark gray, lift it to the floor; else leave as-is.
        if (white < minBrightness) {
            white = minBrightness;
        }
        return [UIColor colorWithWhite:white alpha:a];
    }

    /*
    // Last resort: convert to sRGB then try again
    UIColor *srgb = [self colorUsingColorSpaceName:NULL]; // no-op on iOS; keep for API symmetry
    if ([srgb getHue:&h saturation:&s brightness:&b alpha:&a]) {
        if (b < minBrightness) {
            b = minBrightness;
        }
        return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
    }
     */

    return self; // If all else fails, return original.
}

@end

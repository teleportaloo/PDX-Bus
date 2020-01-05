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


#import "UIColor+DarkMode.h"
#import "TriMetInfo.h"

@implementation UIColor (DarkMode)


+ (UIColor *)modeAwareBusColor
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor whiteColor];
        }
    }
#endif
    return [UIColor grayColor];
}

+ (UIColor *)modeAwareSystemWideAlertBackground
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor quaternarySystemFillColor];
        }
    }
#endif
    return HTML_COLOR(0xFFFF99);
}

+ (UIColor *)modeAwareSystemWideAlertText
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return HTML_COLOR(0xFFFF99);
        }
    }
#endif
    return [UIColor blackColor];
}



+ (UIColor *)modeAwareGrayBackground
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor quaternarySystemFillColor];
        }
    }
#endif
    return [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
}

+ (UIColor *)modeAwareDisclaimerBackground
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor quaternarySystemFillColor];
        }
    }
#endif
    return [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
}

+ (UIColor *)modeAwareCellBackground
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor quaternarySystemFillColor];
        }
    }
#endif
    return [UIColor whiteColor];
}

+ (UIColor *)modeAwareAppBackground
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor secondarySystemBackgroundColor];
        }
    }
#endif
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}

+ (UIColor *)modeAwareText
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        return [UIColor labelColor];
    }
#endif
    return [UIColor blackColor];
}


+ (UIColor *)modeAwareBlue
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            // These colors are based in the "information icon" (i) color
            return HTML_COLOR(0x0099FF);
        }
    }
#endif
    return HTML_COLOR(0x0066FF);
}


+ (UIColor *)modeAwarePurple
{
#ifndef PDXBUS_WATCH
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [UIColor systemPurpleColor];
        }
    }
#endif
    return [UIColor purpleColor];
}

@end

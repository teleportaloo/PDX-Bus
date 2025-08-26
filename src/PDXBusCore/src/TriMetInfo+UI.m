//
//  TriMetInfo+UI.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "UIColor+HTML.h"

@implementation TriMetInfo (UI)

+ (UIColor *)colorForRoute:(NSString *)route {
    PtrConstRouteInfo routeInfo = [TriMetInfo infoForRoute:route];

    if (routeInfo == nil) {
        return nil;
    }

    return HTML_COLOR(routeInfo->html_color);
}

+ (UIColor *)colorForLine:(TriMetInfo_ColoredLines)line {
    PtrConstRouteInfo routeInfo = [TriMetInfo infoForLine:line];

    if (routeInfo == nil) {
        return nil;
    }

    return HTML_COLOR(routeInfo->html_color);
}

@end

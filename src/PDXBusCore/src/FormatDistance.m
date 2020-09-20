//
//  FormatDistance.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/31/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FormatDistance.h"

@implementation FormatDistance


+ (NSString *)formatFeet:(double)feet {
    return [FormatDistance formatMiles:(feet / kFeetInAMile)];
}

+ (NSString *)formatMetres:(double)metres {
    return [FormatDistance formatMiles:(metres / kMetresInAMile)];
}

+ (NSString *)formatMiles:(double)miles {
    NSString *english = nil;
    
    if (miles < 0) {
        return NSLocalizedString(@"Unknown distance", @"Information text when invalid distance is calculated.");
    }
    
    if (miles > 0.1) {
        english = [NSString stringWithFormat:NSLocalizedString(@"%.1f miles", @"Distance in miles"), miles];
    } else {
        english = [NSString stringWithFormat:NSLocalizedString(@"%d feet", @"distance in feet"), (int)((miles * (float)kFeetInAMile) + 0.5)];
    }
    
    NSString *metric = nil;
    float metres = kMetresInAMile * miles;
    
    if (metres >= 1000.0) {
        metric = [NSString stringWithFormat:NSLocalizedString(@"%.1f km", @"distance in kilometres"), metres / 1000];
    } else {
        metric = [NSString stringWithFormat:NSLocalizedString(@"%.0f meters", @"distance in metres"), metres + 0.5];
    }
    
    return [NSString stringWithFormat:@"%@ (%@)", english, metric];
}

@end

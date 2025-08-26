//
//  StopDistanceUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "FormatDistance.h"
#import "NSString+MoreMarkup.h"
#import "StopDistance+iOSUI.h"

@implementation StopDistance (iOSUI)

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (bool)pinActionMenu {
    return YES;
}

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    NSString *dir = @"";

    if (self.dir != nil) {
        dir = self.dir;
    }

    return [NSString
        stringWithFormat:NSLocalizedString(@"Stop ID %@ %@",
                                           @"TriMet Stop identifer <number>"),
                         self.stopId, dir];
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (NSString *)pinMarkedUpType {
    return nil;
}

- (NSString *)pinMarkedUpSubtitle {
    NSString *dir = @"";

    if (self.dir != nil) {
        dir = self.dir;
    }

    NSMutableString *result = [NSMutableString
        stringWithFormat:NSLocalizedString(@"%@ %@",
                                           @"TriMet Stop identifer <number>"),
                         self.stopId.markedUpLinkToStopId, dir];

    NSString *distance = [NSString
        stringWithFormat:NSLocalizedString(@"\nDistance %@", @"stop distance"),
                         [FormatDistance formatMetres:self.distanceMeters]];

    [result appendString:distance];

    if (self.routes) {
        [result appendString:@"#>"];
        for (Route *route in self.routes) {
            if (route.directions == nil && route.directions.count == 0) {
                [result appendFormat:@"\n·\t%@", route.desc];
            } else {
                for (Direction *direction in route.directions.allValues) {
                    [result appendFormat:@"\n·\t%@ #i%@#i", route.desc,
                                         direction.desc];
                }
            }
        }
        [result appendString:@"#<"];
    }
    DEBUG_LOG_NSString(result);
    return result;
}

@end

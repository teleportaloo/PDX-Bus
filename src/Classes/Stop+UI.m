//
//  Stop+UI.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop+UI.h"

@implementation Stop (UI)

@dynamic pinTint;

- (MapPinColorValue)pinColor {
    if (self.timePoint) {
        return MAP_PIN_COLOR_BLUE;
    }
    return MAP_PIN_COLOR_PURPLE;
}

- (bool)pinHasBearing {
    return NO;
}

- (bool)pinActionMenu {
    return YES;
}

- (bool)pinAction:(id<TaskController>)progress {
    [self.stopObjectCallback returnStopObject:self progress:progress];
    return YES;
}

- (NSString *)pinActionText {
    return [self.stopObjectCallback returnStopObjectActionText];
}

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    if (self.dir == nil) {
        return
            [NSString stringWithFormat:NSLocalizedString(
                                           @"Stop ID %@",
                                           @"TriMet Stop identifer <number>"),
                                       self.stopId];
    }

    return [NSString stringWithFormat:@"%@ ID %@", self.dir, self.stopId];
}

- (NSString *)pinMarkedUpSubtitle {
    NSString *tp = @"";

    if (self.timePoint) {
        tp = @"\n#Linfo:timepoint Time point#T";
    }

    if (self.dir == nil) {
        return [NSString
            stringWithFormat:NSLocalizedString(
                                 @"#D%@", @"TriMet Stop identifer <number>"),
                             tp];
    }

    return [NSString stringWithFormat:@"#D%@%@", self.dir, tp];
}

- (UIColor *)pinTint {
    return nil;
}

- (NSString *)pinStopId {
    return self.stopId;
}

- (NSString *)pinMarkedUpType {
    return nil;
}

@end

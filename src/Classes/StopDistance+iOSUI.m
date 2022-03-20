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
    
    return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ %@", @"TriMet Stop identifer <number>"), self.stopId, dir];
}

- (NSString *)pinStopId {
    return self.stopId;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (NSString *)pinMarkedUpType
{
    return nil;
}

@end

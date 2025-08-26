//
//  DetourLocation+DetourLocation_iOSUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourLocation+iOSUI.h"
#import "NSString+MoreMarkup.h"

@implementation DetourLocation (iOSUI)

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    if (self.noServiceFlag) {
        return [NSString
            stringWithFormat:@"No service at Stop ID %@", self.stopId];
    }

    return [NSString stringWithFormat:@"Stop ID %@", self.stopId];
}

// From MapPin
- (MapPinColorValue)pinColor {
    if (self.noServiceFlag) {
        return MAP_PIN_COLOR_RED;
    }

    return MAP_PIN_COLOR_GREEN;
}

- (bool)pinActionMenu {
    return YES;
}

- (NSString *)pinStopId {
    return self.stopId;
}

- (NSString *)pinMarkedUpStopId {
    if (self.noServiceFlag) {
        return [NSString stringWithFormat:@"#DNo service at %@",
                                          self.stopId.markedUpLinkToStopId];
    }

    return
        [NSString stringWithFormat:@"#D%@", self.stopId.markedUpLinkToStopId];
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (double)pinBearing {
    return 0.0;
}

- (NSString *)pinMarkedUpType {
    return nil;
}

@end

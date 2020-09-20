//
//  WatchDetour.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchDetour.h"
#import "XMLDepartures.h"

@implementation WatchDetour


+ (NSString *)identifier {
    return @"Detour";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure *> *)deps {
    Detour *det = deps.firstObject.sortedDetours.allDetours[self.index];
    
    if (det.infoLinkUrl) {
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (See iPhone for link)", @"detour text"),
                           det.detourDesc];
    } else {
        self.label.text = det.detourDesc;
    }
}

@end

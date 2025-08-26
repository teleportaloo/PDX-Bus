//
//  WatchDetourHeader.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 8/13/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchDetourHeader.h"
#import "Settings.h"
#import "XMLDepartures.h"

@implementation WatchDetourHeader

+ (NSString *)identifier {
    return @"DetourHeader";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure *> *)deps {
    self.label.text = [NSString
        stringWithFormat:NSLocalizedString(@"%@ %d %@", @"Hide system alert"),
                         Settings.hideWatchDetours
                             ? NSLocalizedString(@"▽ Show", @"detour")
                             : NSLocalizedString(@"△ Hide", @"detour"),
                         (int)self.index.integerValue,
                         self.index.integerValue > 1
                             ? NSLocalizedString(@"deours", @"detours")
                             : NSLocalizedString(@"detour", @"detour")];
}

- (WatchSelectAction)select:(XMLDepartures *)xml
                       from:(WKInterfaceController *)from
                    context:(WatchArrivalsContext *)context
                    canPush:(bool)push {
    Settings.hideWatchDetours = !Settings.hideWatchDetours;
    return WatchSelectAction_RefreshUI;
}

@end

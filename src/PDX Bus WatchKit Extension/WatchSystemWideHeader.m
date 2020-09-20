//
//  WatchSystemWideHeader.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/27/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchSystemWideHeader.h"
#import "XMLDepartures.h"
#import "Settings.h"

@implementation WatchSystemWideHeader


+ (NSString *)identifier {
    return @"SWH";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure *> *)deps {
    Detour *det = xml.detourSorter.allDetours[self.index];
    
    if (![Settings isHiddenSystemWideDetour:det.detourId]) {
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"△ %@", @"Hide system alert"), det.headerText];
    } else {
        self.label.text = NSLocalizedString(@"▽ ⚠️System Alert", @"Hide system alert");
    }
}

- (WatchSelectAction)select:(XMLDepartures *)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext *)context canPush:(bool)push {
    [Settings toggleHiddenSystemWideDetour:xml.detourSorter.allDetours[self.index].detourId];
    
    return WatchSelectAction_RefreshUI;
}

@end

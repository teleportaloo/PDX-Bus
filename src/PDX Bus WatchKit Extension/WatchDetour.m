//
//  WatchDetour.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchDetour.h"
#import "XMLDepartures.h"

@implementation WatchDetour


+ (NSString*)identifier
{
    return @"Detour";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    Detour *det = deps.firstObject.allDetours[self.index];
    self.label.text = det.detourDesc;
}
    
@end

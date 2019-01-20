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


#import "WatchSystemWideDetour.h"
#import "XMLDepartures.h"

@implementation WatchSystemWideDetour


+ (NSString*)identifier
{
    return @"SWD";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    Detour *det = deps.firstObject.allDetours[self.index];
    self.label.text = det.detourDesc;
}

@end

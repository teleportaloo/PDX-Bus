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

@implementation WatchSystemWideHeader


+ (NSString*)identifier
{
    return @"SWH";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    Detour *det = xml.allDetours[self.index];
    self.label.text = det.headerText;
}

@end

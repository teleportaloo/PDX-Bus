//
//  WatchArrivalMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalMap.h"
#import "XMLDepartures.h"
#import "WatchMapHelper.h"
#import "DepartureData+watchOSUI.h"

@implementation WatchArrivalMap


+ (NSString*)identifier
{
    return @"Map";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    [WatchMapHelper displayMap:self.map purplePin:xml.loc otherPins:deps];
}

@end

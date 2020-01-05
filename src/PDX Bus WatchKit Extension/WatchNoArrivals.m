//
//  WatchNoArrivals.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/18/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchNoArrivals.h"
#import "XMLDepartures.h"

@implementation WatchNoArrivals


+ (NSString *)identifier
{
    return @"None";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure*>*)deps
{
    if (xml.gotData)
    {
        if (deps.count == 0)
        {
            self.label.text = @"No departures";
        }
        else if (deps.count>0 && deps.firstObject.errorMessage!=nil)
        {
            self.label.text = deps.firstObject.errorMessage;
        }
        else
        {
            self.label.text = @"Internal error";
        }
    }
    else
    {
        self.label.text = @"Network timeout";
    }
}

@end

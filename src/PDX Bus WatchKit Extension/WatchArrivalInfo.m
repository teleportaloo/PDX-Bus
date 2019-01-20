//
//  WatchArrivalInfo.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalInfo.h"
#import "XMLDepartures.h"

@implementation WatchArrivalInfo


+ (NSString*)identifier
{
    return @"Info";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    if (xml.gotData)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    // NSString *shortDir = [StopNameCacheManager shortDirection:newDepartures.locDir];
    
    
        if (xml.locDir.length > 0)
        {
            self.label.text = [NSString stringWithFormat:@"🆔%@\n⤵️%@\n➡️%@", xml.locid, [dateFormatter stringFromDate:xml.cacheTime], xml.locDir];
        }
        else
        {
            self.label.text = [NSString stringWithFormat:@"🆔%@\n⤵️%@", xml.locid, [dateFormatter stringFromDate:xml.cacheTime]];
        }
    }
    else
    {
        self.label.text = [NSString stringWithFormat:@"🆔%@", xml.locid];
    }
}

@end

//
//  WatchRow.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/26/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchRow.h"

@implementation WatchRow


+ (NSString *)identifier
{
    return @"None";
}


- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure*>*)deps
{
    
}

- (WatchSelectAction)select:(XMLDepartures*)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext*)context canPush:(bool)push
{
    return WatchSelectAction_None;
}
@end

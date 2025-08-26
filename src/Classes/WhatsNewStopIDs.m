//
//  WhatsNewStopIDs.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewStopIDs.h"
#import "DepartureTimesViewController.h"

@implementation WhatsNewStopIDs

+ (void)load {
    [[self class] addAction];
}

+ (NSNumber *)getPrefix {
    return @'-';
}

- (void)processAction:(NSString *)text parent:(ViewControllerBase *)parent {
    NSString *stopIds = [self prefix:text restOfText:nil];

    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];

    departureViewController.displayName = @"";
    [departureViewController fetchTimesForLocationAsync:parent.backgroundTask
                                                 stopId:stopIds];
}

@end

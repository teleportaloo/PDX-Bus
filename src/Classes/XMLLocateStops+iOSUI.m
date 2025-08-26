//
//  XMLLocateStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/13/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FormatDistance.h"
#import "RouteDistance.h"
#import "XMLLocateStops+iOSUI.h"

@implementation XMLLocateStops (iOSUI)

#pragma mark Error check

- (bool)displayErrorIfNoneFound:(id<TaskController>)progress {
    NSThread *thread = [NSThread currentThread];

    if (self.count == 0 && !self.gotData) {
        if (!thread.cancelled) {
            [progress taskCancel];
            [progress
                taskSetErrorMsg:NSLocalizedString(
                                    @"Network problem: please try again later.",
                                    @"error message")];

            return true;
        }
    } else if (self.count == 0) {
        if (!thread.cancelled) {
            [progress taskCancel];

            NSArray *modes =
                @[ @"bus stops", @"train stops", @"bus or train stops" ];

            [progress
                taskSetErrorMsg:
                    [NSString
                        stringWithFormat:@"No %@ were found within %@.",
                                         modes[self.mode],
                                         [FormatDistance
                                             formatMetres:self.minDistance]]];
            return true;
        }
    }

    return false;
}

@end

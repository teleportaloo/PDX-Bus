//
//  ViewControllerBase+DetourTableViewCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase+DetourTableViewCell.h"

#import "DepartureTimesViewController.h"
#import "DirectionViewController.h"
#import "MapViewControllerWithDetourStops.h"
#import "TripPlannerSummaryViewController.h"

@implementation ViewControllerBase (DetourTableViewCell)

- (bool)detourLink:(NSString *)link
            detour:(Detour *)detour
            source:(UIView *)view {
    if ([self linkAction:link source:view]) {
        if ([link isEqualToString:@"detourmap:"]) {
            if ([self canGoDeeperAlert]) {
                [[MapViewControllerWithDetourStops viewController]
                    fetchLocationsMaybeAsync:self.backgroundTask
                                     detours:[NSArray arrayWithObject:detour]
                                         nav:self.navigationController];
            }
            return NO;
        } else {
            return YES;
        }
    }

    return NO;
}

- (DetourUrlAction)detourActionCalback {
    __weak __typeof__(self) weakSelf = self;

    return ^bool(DetourTableViewCell *cell, NSString *url) {
      return [weakSelf detourLink:url detour:cell.detour source:cell];
    };
}

@end

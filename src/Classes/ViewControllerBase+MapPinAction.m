//
//  ViewControllerBase+MapPinAction.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/15/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase+MapPinAction.h"
#import "DepartureDetailView.h"

@implementation ViewControllerBase (MapPinAction)

- (bool (^__nullable)(id<MapPin>, NSURL *url, UIView *source))linkActionForPin {
    __weak __typeof__(self) weakSelf = self;
    return ^bool (id<MapPin> pin, NSURL *url, UIView *source) {
        if ([url.absoluteString hasPrefix:@"action:tap"]) {
            if ([pin respondsToSelector:@selector(pinAction:)]) {
                [pin pinAction:weakSelf.backgroundTask];
            }
            return NO;
        } else {
            return [weakSelf linkAction:url.absoluteString source:source];
        }
    };
}

@end

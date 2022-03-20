//
//  ViewControllerBase+LinkCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase+LinkCell.h"
#import "DepartureTimesView.h"


@implementation ViewControllerBase (LinkCell)

- (UrlAction)urlActionCalback {
    __weak __typeof__(self) weakSelf = self;
    
    return ^bool (LinkCell *cell, NSString *url) {
        return [weakSelf linkAction:url source:cell];
    };
}

@end

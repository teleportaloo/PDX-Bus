//
//  WatchArrivalInfo.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalInfo.h"

@implementation WatchArrivalInfo

- (void)dealloc
{
    self.arrivalInfoText = nil;
    [super dealloc];
}

@end

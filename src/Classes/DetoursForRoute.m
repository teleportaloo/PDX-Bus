//
//  DetoursForRoute.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/19/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetoursForRoute.h"

@implementation DetoursForRoute

- (instancetype)init
{
    if (self = [super init])
    {
        self.detours = [NSMutableArray array];
    }
    return self;
}


@end

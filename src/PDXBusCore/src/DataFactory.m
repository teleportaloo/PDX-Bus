//
//  DataFactory.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/13/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DataFactory.h"

@implementation DataFactory

+ (instancetype)data
{
    return [[[self class] alloc] init];
}

@end

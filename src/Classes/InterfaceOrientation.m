//
//  DeviceOrientation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/27/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "InterfaceOrientation.h"
#import "UIApplication+Compat.h"

@implementation InterfaceOrientation

+ (UIInterfaceOrientation)getInterfaceOrientation:(UIViewController *)controller {
    return [UIApplication sharedApplication].compatStatusBarOrientation;
}

@end

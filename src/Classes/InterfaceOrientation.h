//
//  InterfaceOrientation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/27/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@interface InterfaceOrientation : NSObject

+ (UIInterfaceOrientation)getInterfaceOrientation:
    (UIViewController *)controller;

@end

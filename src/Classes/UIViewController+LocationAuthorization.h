//
//  UIViewController+LocationAuthorization.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/6/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

@interface UIViewController (LocationAuthorization)


- (bool)locationAuthorizedOrNotDeterminedAlertWithBackground:(bool)backgroundRequired;
+ (bool)locationAuthorizedOrNotDeterminedWithBackground:(bool)backgroundRequired;

@end

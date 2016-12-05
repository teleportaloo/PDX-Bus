//
//  TripReturnUserRequest.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "XMLTrips.h"

@protocol TripReturnUserRequest <NSObject>
- (void)userRequest:(TripUserRequest *)userRequest;
@property (nonatomic, getter=getController, readonly, strong) UIViewController *controller;
@end

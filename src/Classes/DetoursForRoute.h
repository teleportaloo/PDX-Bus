//
//  DetoursForRoute.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/19/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"
#import "Route.h"

@interface DetoursForRoute : NSObject

@property(nonatomic, strong) NSMutableArray<Detour *> *detours;
@property(nonatomic, strong) Route *route;

@end

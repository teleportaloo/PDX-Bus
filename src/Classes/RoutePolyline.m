//
//  RoutePolyline.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RoutePolyline.h"

@implementation RoutePolyline

@synthesize color = _color;
@synthesize direct = _direct;

- (void)dealloc
{
    self.color = nil;
    
    [super dealloc];
}



@end

//
//  MapViewWithDetourStops.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour+iOSUI.h"
#import "MapViewControllerWithRoutes.h"
#import "XMLDepartures.h"

@interface MapViewControllerWithDetourStops
    : MapViewControllerWithRoutes <UITextViewDelegate>

- (void)fetchLocationsMaybeAsync:(id<TaskController>)taskController
                         detours:(NSArray<Detour *> *)detours
                             nav:(UINavigationController *)nav;

@end

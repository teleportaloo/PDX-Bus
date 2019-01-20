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


#import "MapViewWithRoutes.h"
#import "XMLDepartures.h"
#import "Detour+iOSUI.h"

@interface MapViewWithDetourStops : MapViewWithRoutes
{
    NSMutableArray<XMLDepartures*> *_stopData;
}

@property (nonatomic, strong) NSArray<Detour*> *detours;
@property (nonatomic, strong) UITextView *detourText;

- (void)fetchLocationsMaybeAsync:(id<BackgroundTaskController>)task detours:(NSArray<Detour *>*)detours nav:(UINavigationController *)nav;

@end

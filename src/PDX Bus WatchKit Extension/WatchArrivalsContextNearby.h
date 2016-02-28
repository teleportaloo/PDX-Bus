//
//  WatchArricalsContextNearby.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/10/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContext.h"
#import "XMLLocateStops.h"

@interface WatchArrivalsContextNearby : WatchArrivalsContext

@property (nonatomic, retain) XMLLocateStops *      stops;
@property (nonatomic)         NSInteger             index;

+ (WatchArrivalsContextNearby*)contextFromNearbyStops:(XMLLocateStops *)stops index:(NSInteger)index;


@end

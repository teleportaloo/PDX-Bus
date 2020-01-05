//
//  AlarmFetchArrivalsTask.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/29/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "XMLDepartures.h"
#import "AlarmTask.h"

#define DEBUG_BACKGROUND_FETCH



@interface AlarmFetchArrivalsTask : AlarmTask

@property (nonatomic, strong) NSDate *queryTime;
@property (nonatomic, copy)   NSString *block;
@property (nonatomic, strong) XMLDepartures *departures;
@property (nonatomic) uint minsToAlert;
@property (strong) Departure *lastFetched;
@property (nonatomic, copy)   NSString *display;

- (void) startTask;

@end

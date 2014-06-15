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

// @interface AlarmFetchArrivalsTask;


#define DEBUG_BACKGROUND_FETCH



@interface AlarmFetchArrivalsTask : AlarmTask  {

	NSString *_block;
	
	
	XMLDepartures *_departures;
	Departure	  *_lastFetched;
	TriMetTime _queryTime;
	
	uint _minsToAlert;	
}


@property (nonatomic, retain) NSString * block;
@property (nonatomic, retain) XMLDepartures * departures;
@property (nonatomic) uint minsToAlert;
@property (retain) Departure	  *lastFetched;

- (void) startTask;

@end

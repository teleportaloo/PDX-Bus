//
//  NearestStopsMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 12/1/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NearestStopsMap.h"
#import "XMLLocateStops.h"


@implementation NearestStopsMap


- (void)fetchNearestStops:(XMLLocateStops*) locator
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	

	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting locations"];
		
	[locator findNearestStops];
		
	if (![locator displayErrorIfNoneFound:self.backgroundTask.callbackWhenFetching])
	{
		for (int i=0; i< [locator safeItemCount] && ![thread isCancelled]; i++)
		{
			[self addPin:[locator.itemArray objectAtIndex:i]];
		}
	}
   	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	[pool release];
}

- (void)fetchNearestStopsInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
	self.backgroundTask.callbackWhenFetching = background;
	
	XMLLocateStops *locator = [[[XMLLocateStops alloc] init] autorelease];
	
	locator.maxToFind = max;
	locator.location = here;
	locator.mode = mode;
	locator.minDistance = min;
	
	[NSThread detachNewThreadSelector:@selector(fetchNearestStops:) toTarget:self withObject:locator];
	
}


@end

//
//  NearestStopsMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 12/1/10.
//  Copyright 2010. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "NearestStopsMap.h"
#import "XMLLocateStops.h"


@implementation NearestStopsMap

- (void)fetchNearestStops:(XMLLocateStops*) locator
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching BackgroundThread:thread];
	

	[self.backgroundTask.callbackWhenFetching BackgroundStart:1 title:@"getting locations"];
		
	[locator findNearestStops];
		
	if (![locator displayErrorIfNoneFound])
	{
		for (int i=0; i< [locator safeItemCount] && ![thread isCancelled]; i++)
		{
			[self addPin:[locator.itemArray objectAtIndex:i]];
		}
	}
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
	
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

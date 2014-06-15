//
//  TripPlannerMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerMap.h"

#define kBusyText @"getting route details"

@implementation TripPlannerMap
@synthesize it = _it;

- (void)fetchShape:(void *)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)[self.it legCount] title:kBusyText];
	
	NSMutableArray *lineCoords = [[[NSMutableArray alloc] init] autorelease];
	
	int i;
	
	for (i=0; i< [self.it legCount]; i++)
	{
		TripLeg *leg = [self.it getLeg:i];
		if (leg.legShape)
		{
			[leg.legShape fetchCoords];
			
			[lineCoords addObjectsFromArray:leg.legShape.shapeCoords];
			[lineCoords addObject:[ShapeCoord makeEnd]];
			[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
		}
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	self.lineCoords = lineCoords;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	[pool release];
	
}

- (bool)fetchShapesInBackground:(id<BackgroundTaskProgress>)background
{
	int i;
	bool fetch = false;
	for (i=0; i< [self.it legCount] && !fetch; i++)
	{
		TripLeg *leg = [self.it getLeg:i];
		if (leg.legShape !=nil && leg.legShape.shapeCoords == nil)
		{
			fetch = true;
		}
	}
	
	if (fetch)
	{
		self.backgroundTask.callbackWhenFetching = background;
		[NSThread detachNewThreadSelector:@selector(fetchShape:) toTarget:self withObject:nil];		
	}
	
	return fetch;

}


@end

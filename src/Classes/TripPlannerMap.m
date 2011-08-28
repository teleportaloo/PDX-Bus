//
//  TripPlannerMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
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

#import "TripPlannerMap.h"

#define kBusyText @"getting route details"

@implementation TripPlannerMap
@synthesize it = _it;

- (void)fetchShape:(void *)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching BackgroundThread:thread];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
	[self.backgroundTask.callbackWhenFetching BackgroundStart:[self.it legCount] title:kBusyText];
	
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
			[self.backgroundTask.callbackWhenFetching BackgroundItemsDone:i+1];
		}
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	self.lineCoords = lineCoords;
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
	
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

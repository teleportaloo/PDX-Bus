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
#import "TriMetRouteColors.h"
#import "MapAnnotationImage.h"

#define kBusyText @"getting route details"

@implementation TripPlannerMap
@synthesize it = _it;

- (void)dealloc
{
    self.it = nil;
    
    [super dealloc];
}

- (UIColor*)colorForRoute:(NSString *)route
{
    if (route == nil)
    {
        return [UIColor cyanColor];
    }

    UIColor *col = [TriMetRouteColors colorForRoute:route];
    
    if (col == nil)
    {
        col = kMapAnnotationBusColor;
    }
        
    return col;
}

- (void)workerToFetchShape:(void *)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)self.it.legCount title:kBusyText];
	
    NSMutableArray *lineCoords = [NSMutableArray array];
	
	int i;
	
	for (i=0; i< self.it.legCount; i++)
	{
		TripLeg *leg = [self.it getLeg:i];
		if (leg.legShape)
		{
			[leg.legShape fetchCoords];
    
			[lineCoords addObjectsFromArray:leg.legShape.shapeCoords];
            [lineCoords addObject:[ShapeCoordEnd makeDirect:NO color:[self colorForRoute:leg.xinternalNumber]]];
			[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
		}
        
        if(leg.legShape==nil || leg.legShape.shapeCoords==nil || leg.legShape.shapeCoords.count==0)
        {
            ShapeCoord *start = [ShapeCoord data];
            
            start.latitude  = leg.from.xlat.doubleValue;
            start.longitude = leg.from.xlon.doubleValue;
            
            ShapeCoord *end = [ShapeCoord data];
            end.latitude  = leg.to.xlat.doubleValue;
            end.longitude = leg.to.xlon.doubleValue;
            
            [lineCoords addObject:start];
            [lineCoords addObject:end];
            [lineCoords addObject:[ShapeCoordEnd makeDirect:YES color:[self colorForRoute:leg.xinternalNumber]]];
            
            self.msgText = @"Detailed paths not all available.";
        }
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	self.lineCoords = lineCoords;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	[pool release];
	
}

- (void)fetchShapesAsync:(id<BackgroundTaskProgress>)background
{
    self.backgroundTask.callbackWhenFetching = background;
    [NSThread detachNewThreadSelector:@selector(workerToFetchShape:) toTarget:self withObject:nil];
}


@end

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
#import "TriMetInfo.h"
#import "MapAnnotationImage.h"

#define kBusyText @"getting route details"

@implementation TripPlannerMap



- (void)fetchShapesAsync:(id<BackgroundTaskController>)task
{
    [task taskRunAsync:^{
        [task taskStartWithItems:self.it.legCount title:kBusyText];
        
        NSMutableArray<ShapeRoutePath *> *lineCoords = [NSMutableArray array];
        
        int i;
        
        for (i=0; i< self.it.legCount; i++)
        {
            TripLeg *leg = [self.it getLeg:i];
            if (leg.legShape)
            {
                if (leg.legShape.segment.coords.count == 0)
                {
                    [leg.legShape fetchCoords];
                }
                
                if (leg.legShape.segment)
                {
                    ShapeRoutePath *path =  [ShapeRoutePath data];
                    ShapeCompactSegment *seg = leg.legShape.segment.compact;
                    
                    [path.segments addObject:seg];
                    
                    if (leg.xinternalNumber == nil)
                    {
                        path.route = kShapeNoRoute;
                        path.desc = leg.xname;
                    }
                    else
                    {
                        path.route = leg.xinternalNumber.integerValue;
                        path.desc = leg.xname;
                    }
                
                    [lineCoords addObject:path];
                }
                [task taskItemsDone:i+1];
            }
            
            if(leg.legShape==nil || leg.legShape.segment==nil || leg.legShape.segment.coords.count==0)
            {
                ShapeRoutePath *path =  [ShapeRoutePath data];
                ShapeMutableSegment *seg = [ShapeMutableSegment data];
                
                ShapeCoord *start = [ShapeCoord data];
                
                start.latitude  = leg.from.coordinate.latitude;
                start.longitude = leg.from.coordinate.longitude;
                
                ShapeCoord *end = [ShapeCoord data];
                end.latitude  = leg.to.coordinate.latitude;
                end.longitude = leg.to.coordinate.longitude;
                
                [seg.coords addObject:start];
                [seg.coords addObject:end];
                
         
                [path.segments addObject:seg.compact];
                
                if (leg.xinternalNumber == nil)
                {
                    path.route = kShapeNoRoute;
                }
                else
                {
                    path.route = leg.xinternalNumber.integerValue;
                }
                
                if (leg.xname!=nil)
                {
                    path.desc = leg.xname;
                }
                else
                {
                    path.desc = [leg createFromText:NO textType:TripTextTypeMap];
                }
                
                path.direct = YES;
                
                [lineCoords addObject:path];
                
                self.msgText = @"Detailed paths not all available.";
            }
        }
        
        self.lineCoords = lineCoords;
        
        return (UIViewController *)self;
    }];
}


@end

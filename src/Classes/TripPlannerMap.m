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
#import "MapAnnotationImageFactory.h"
#import "TaskState.h"

#define kBusyText @"getting route details"

@implementation TripPlannerMap

- (void)subTaskFetchLegShape:(TripLeg *)leg lineCoords:(NSMutableArray<ShapeRoutePath *> *)lineCoords taskState:(TaskState *)taskState {
    if (leg.legShape.segment.coords.count == 0) {
        [leg.legShape fetchCoords];
    }
    
    if (leg.legShape.segment) {
        ShapeRoutePath *path = [ShapeRoutePath new];
        ShapeCompactSegment *seg = leg.legShape.segment.compact;
        
        [path.segments addObject:seg];
        
        if (leg.internalRouteNumber == nil) {
            path.route = kShapeNoRoute;
            path.desc = leg.routeName;
        } else {
            path.route = leg.internalRouteNumber.integerValue;
            path.desc = leg.routeName;
        }
        
        [lineCoords addObject:path];
    }
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)createStraightLineLeg:(TripLeg *)leg lineCoords:(NSMutableArray<ShapeRoutePath *> *)lineCoords {
    ShapeRoutePath *path = [ShapeRoutePath new];
    ShapeMutableSegment *seg = [ShapeMutableSegment new];
    
    ShapeCoord *start = [ShapeCoord new];
    
    start.latitude  = leg.from.coordinate.latitude;
    start.longitude = leg.from.coordinate.longitude;
    
    ShapeCoord *end = [ShapeCoord new];
    end.latitude  = leg.to.coordinate.latitude;
    end.longitude = leg.to.coordinate.longitude;
    
    [seg.coords addObject:start];
    [seg.coords addObject:end];
    
    
    [path.segments addObject:seg.compact];
    
    if (leg.internalRouteNumber == nil) {
        path.route = kShapeNoRoute;
    } else {
        path.route = leg.internalRouteNumber.integerValue;
    }
    
    if (leg.routeName != nil) {
        path.desc = leg.routeName;
    } else {
        path.desc = [leg createFromText:NO textType:TripTextTypeMap];
    }
    
    path.direct = YES;
    
    [lineCoords addObject:path];
    
    self.msgText = @"Detailed paths not all available.";
}

- (void)fetchShapesAsync:(id<TaskController>)taskController {
    [taskController taskRunAsync:^(TaskState *taskState) {
        
        [taskState taskStartWithTotal:self.it.legCount title:kBusyText];
        
        NSMutableArray<ShapeRoutePath *> *lineCoords = [NSMutableArray array];
        
        int i;
        
        for (i = 0; i < self.it.legCount; i++) {
            TripLeg *leg = [self.it getLeg:i];
            
            if (leg.legShape != nil) {
                [self subTaskFetchLegShape:leg lineCoords:lineCoords taskState:taskState];
            }
            
            if (leg.legShape == nil || leg.legShape.segment == nil || leg.legShape.segment.coords.count == 0) {
                [self createStraightLineLeg:leg lineCoords:lineCoords];
            }
        }
        
        self.lineCoords = lineCoords;
        
        return (UIViewController *)self;
    }];
}

@end

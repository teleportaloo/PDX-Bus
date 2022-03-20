//
//  MapViewWithStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewWithStops.h"
#import "DebugLogging.h"
#import "TaskState.h"

#define kGettingStops @"getting stops"

@interface MapViewWithStops ()

@property (nonatomic, strong) XMLStops *stopData;

@end

@implementation MapViewWithStops

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addStops:(id<ReturnStopObject>)returnStop {
    for (Stop *stop in self.stopData.items) {
        stop.stopObjectCallback = returnStop;
        [self addPin:stop];
    }
}

- (void)fetchStopsAsync:(id<TaskController>)taskController
                  route:(NSString *)routeid
              direction:(NSString *)dir
             returnStop:(id<ReturnStopObject>)returnStop {
    self.stopData = [XMLStops xml];
    
    if (!self.backgroundRefresh && [self.stopData getStopsForRoute:routeid
                                                         direction:dir
                                                       description:@""
                                                       cacheAction:TriMetXMLCheckRouteCache]) {
        [self addStops:returnStop];
        [taskController taskCompleted:self];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
            [taskState startAtomicTask:kGettingStops];
            
            [self.stopData getStopsForRoute:routeid
                                  direction:dir
                                description:@""
                                cacheAction:TriMetXMLForceFetchAndUpdateRouteCache];
            
            [self addStops:returnStop];
            [taskState atomicTaskItemDone];
            
            return (UIViewController *)self;
        }];
    }
}

@end

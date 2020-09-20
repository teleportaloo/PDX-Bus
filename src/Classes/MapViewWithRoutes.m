//
//  MapViewWithRoutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/8/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewWithRoutes.h"
#import "KMLRoutes.h"
#import "TaskState.h"

@implementation MapViewWithRoutes


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (bool)fitAnnotation:(id<MapPinColor>)pin {
    if (self.pinClassesToFit == nil) {
        return YES;
    }
    
    if ([self.pinClassesToFit containsObject:[pin class]]) {
        return YES;
    }
    
    return NO;
}

- (void)fetchRoutesAsync:(id<TaskController>)taskController
                  routes:(NSArray<NSString *> *)routes
              directions:(NSArray<NSString *> *)directions
         additionalTasks:(NSInteger)tasks
                    task:(void (^)(TaskState *taskState))action {
    bool getKml = Settings.kmlRoutes;
    
    if (tasks > 0 || getKml) {
        [taskController taskRunAsync:^(TaskState *taskState) {
            [taskState taskStartWithTotal:(getKml ? 1 : 0) + tasks title:NSLocalizedString(@"getting details", @"progress message")];
            
            if (tasks > 0) {
                action(taskState);
            }
            
            if (getKml || (routes && routes.count > 0)) {
                KMLRoutes *kml = [KMLRoutes xmlWithOneTimeDelegate:taskState];
                self.lineCoords = [NSMutableArray array];
           
                [taskState taskSubtext:NSLocalizedString(@"started to get route shapes", @"progress message")];
                [kml fetchInBackground:NO];
                
                if (directions) {
                    for (int i = 0; i < routes.count && i < directions.count; i++) {
                        NSString *r = routes[i];
                        NSString *d = directions[i];
                        
                        ShapeRoutePath *path = [kml lineCoordsForRoute:r direction:d];
                        
                        if (path) {
                            [self.lineCoords addObject:path];
                        }
                    }
                } else {
                    for (int i = 0; i < routes.count; i++) {
                        NSString *r = routes[i];
                        
                        ShapeRoutePath *path = [kml lineCoordsForRoute:r direction:kKmlFirstDirection];
                        
                        if (path != nil) {
                            [self.lineCoords addObject:path];
                        }
                        
                        path = [kml lineCoordsForRoute:r direction:kKmlOptionalDirection];
                        
                        if (path) {
                            [self.lineCoords addObject:path];
                        }
                    }
                }
            }
            
            [taskState taskItemsDone:tasks + 1];
            self.lineOptions = MapViewNoFitLines;
            return (UIViewController *)self;
        }];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
            return self;
        }];
    }
}

@end

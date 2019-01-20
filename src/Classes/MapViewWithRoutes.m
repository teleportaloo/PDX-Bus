//
//  MapViewWithRoutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/8/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewWithRoutes.h"
#import "KMLRoutes.h"

@implementation MapViewWithRoutes


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (bool)fitAnnotation:(id<MapPinColor>)pin
{
    if (self.pinClassesToFit == nil)
    {
        return YES;
    }
    
    if ([self.pinClassesToFit containsObject:[pin class]])
    {
        return YES;
    }
    
    return NO;
}

  
- (void)fetchRoutesAsync:(id<BackgroundTaskController>)task routes:(NSArray<NSString*>*)routes directions:(NSArray<NSString*>*)directions
         additionalTasks:(NSInteger)tasks
                    task:(void (^)( id<BackgroundTaskController> background )) block
{

    bool getKml = [UserPrefs sharedInstance].kmlRoutes;
    
    if (tasks > 0 || getKml)
    {
        [task taskRunAsync:^{
            [task taskStartWithItems:(getKml?1:0)+tasks title:@"getting details"];
            
            if (tasks > 0)
            {
                block(task);
            }
            
            if (getKml)
            {
                KMLRoutes *kml = [KMLRoutes xml];
                self.lineCoords = [NSMutableArray array];
                kml.oneTimeDelegate = task;
                
                [task taskSubtext:@"getting route shapes"];
                [kml fetch];
                
                if (directions)
                {
                    for (int i=0; i<routes.count && i<directions.count; i++)
                    {
                        NSString *r = routes[i];
                        NSString *d = directions[i];
    
                        ShapeRoutePath* path = [kml lineCoordsForRoute:r direction:d];
                        if (path)
                        {
                            [self.lineCoords addObject:path];
                        }
                    }
                }
                else
                {
                    for (int i=0; i<routes.count; i++)
                    {
                        NSString *r = routes[i];
                        
                        ShapeRoutePath* path = [kml lineCoordsForRoute:r direction:kKmlFirstDirection];
                        if (path!=nil)
                        {
                            [self.lineCoords addObject:path];
                        }
                        
                        path = [kml lineCoordsForRoute:r direction:kKmlOptionalDirection];
                        if (path)
                        {
                            [self.lineCoords addObject:path];
                        }
                    }
                }
            }
            
            [task taskItemsDone:tasks+1];
            self.lineOptions = MapViewNoFitLines;
            return  (UIViewController*)self;
        }];
        
    }
    else
    {
        [task taskRunAsync:^{
            return self;
        }];
    }
}


@end

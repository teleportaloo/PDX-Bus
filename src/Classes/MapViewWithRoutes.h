//
//  MapViewWithRoutes.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/8/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import "XMLDepartures.h"
#import "BackgroundTaskController.h"

@interface MapViewWithRoutes : MapViewController

@property (nonatomic, strong) NSSet *pinClassesToFit;

- (void)fetchRoutesAsync:(id<BackgroundTaskController>)task
                  routes:(NSArray<NSString*>*)routes
              directions:(NSArray<NSString*>*)directions
         additionalTasks:(NSInteger)tasks
                    task:(void (^)( id<BackgroundTaskController> background )) block;


@end

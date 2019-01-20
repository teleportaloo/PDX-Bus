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

#define kGettingStops @"getting stops"

@implementation MapViewWithStops



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addStops:(id<ReturnStop>)returnStop
{
    for (Stop *stop in self.stopData.items)
    {
        if (![stop.locid isEqualToString:self.locId])
        {
            stop.callback = returnStop;
            [self addPin:stop];
        }
    }
}

- (void)fetchStopsAsync:(id<BackgroundTaskController>)task route:(NSString*)routeid direction:(NSString*)dir
                    returnStop:(id<ReturnStop>)returnStop
{
    self.stopData = [XMLStops xml];
    
    if (!self.backgroundRefresh && [self.stopData getStopsForRoute:routeid
                                                         direction:dir
                                                       description:@""
                                                       cacheAction:TriMetXMLCheckCache])
    {
        [self addStops:returnStop];
        [task taskCompleted:self];
    }
    else
    {
        [task taskRunAsync:^{
            [task taskStartWithItems:1 title:kGettingStops];
            
            [self.stopData getStopsForRoute:routeid
                                  direction:dir
                                description:@""
                                cacheAction:TriMetXMLForceFetchAndUpdateCache];
            
            [self addStops:returnStop];
            
            return (UIViewController*)self;
        }];
    }
}


@end

//
//  MapViewWithStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewWithStops.h"
#import "DebugLogging.h"

#define kGettingStops @"getting stops"

@implementation MapViewWithStops

@synthesize stopData = _stopData;
@synthesize locId    = _locId;

- (void)dealloc
{
    self.stopData = nil;
    self.locId    = nil;
    [super dealloc];
}


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
    for (Stop *stop in self.stopData.itemArray)
    {
        if (![stop.locid isEqualToString:self.locId])
        {
            stop.callback = returnStop;
            [self addPin:stop];
        }
    }
}

- (void)workerToFetchStops:(NSArray*) args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingStops];
    
	
    NSString *routeid           = args[0];
	NSString *dir               = args[1];
    id<ReturnStop> returnStop   = args[2];
	
	[self.stopData getStopsForRoute:routeid
						  direction:dir
						description:@""
						cacheAction:TriMetXMLForceFetchAndUpdateCache];
	
    [self addStops:returnStop];
    
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    
	[pool release];
}


- (void)fetchStopsAsync:(id<BackgroundTaskProgress>) callback route:(NSString*)routeid direction:(NSString*)dir
                    returnStop:(id<ReturnStop>)returnStop
{
	self.backgroundTask.callbackWhenFetching = callback;
    self.stopData = [XMLStops xml];
	
	if (!self.backgroundRefresh && [self.stopData getStopsForRoute:routeid
														 direction:dir
													   description:@""
													   cacheAction:TriMetXMLCheckCache])
	{
        [self addStops:returnStop];
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	}
	else
	{
		[NSThread detachNewThreadSelector:@selector(workerToFetchStops:)
								 toTarget:self
							   withObject:@[routeid, dir, returnStop]];
	}
}


@end

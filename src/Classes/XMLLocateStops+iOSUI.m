//
//  XMLLocateStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/13/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "XMLLocateStops+iOSUI.h"
#import "RouteDistanceData.h"
#import "FormatDistance.h"


@implementation XMLLocateStops (iOSUI)


#pragma mark Error check 


- (bool)displayErrorIfNoneFound:(id<BackgroundTaskProgress>)progress
{
	NSThread *thread = [NSThread currentThread]; 
	
	if (self.count == 0 && !self.gotData)
	{
		
		if (!thread.cancelled) 
		{
			[thread cancel];
			//UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
			//												   message:@"Network problem: please try again later."
			//												  delegate:delegate
			//										 cancelButtonTitle:@"OK"
			//										 otherButtonTitles:nil] autorelease];
			//[delegate retain];
            //[alert show];
            
            [progress backgroundSetErrorMsg:@"Network problem: please try again later."];
            
			return true;
		}	
		
	}
	else if (self.count == 0)
	{
		if (!thread.cancelled) 
		{
			[thread cancel];
            
            NSArray *modes = @[@"bus stops", @"train stops", @"bus or train stops"];
        
            [progress backgroundSetErrorMsg:[NSString stringWithFormat:@"No %@ were found within %@.",
                                             modes[_mode],
                                             [FormatDistance formatMetres:self.minDistance]]];
			//UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
			//												   message:[NSString stringWithFormat:@"No stops were found within %0.1f miles",
			//															self.minDistance / 1609.344]
			//
			//												  delegate:delegate
			//										 cancelButtonTitle:@"OK"
			//										 otherButtonTitles:nil] autorelease];
			//[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
           // [alert show];
			return true;
		}
	}
	
	return false;
	
}

@end

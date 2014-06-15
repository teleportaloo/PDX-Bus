//
//  AlarmFetchArrivalsTask.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/29/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmFetchArrivalsTask.h"
#import "DebugLogging.h"
#import "DepartureTimesView.h"


#define kTolerance	30



@implementation AlarmFetchArrivalsTask

@synthesize block		= _block;
@synthesize departures	= _departures;
@synthesize minsToAlert = _minsToAlert;
@synthesize lastFetched = _lastFetched;

- (void)dealloc
{
	
	self.block			= nil;
	self.departures		= nil;
	self.lastFetched	= nil;
	self.observer		= nil;
	
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
		self.alarmState = AlarmStateFetchArrivals;
	}
	return self;
}

- (NSDate *)fetch
{
	NSError *error			= nil;
	bool taskDone			= NO;
	NSDate *departureDate	= nil;
	NSTimeInterval waitTime;
	NSDate *	next		= nil;
	
	[self.departures getDeparturesForLocation:self.stopId block:self.block parseError:&error];
    
	if ([self.departures gotData] && self.departures.safeItemCount >0)
	{
		@synchronized (self.lastFetched)
		{
			self.lastFetched = [self.departures itemAtIndex:0];
		}
		_queryTime = self.departures.queryTime;
	} 
	else if (self.lastFetched == nil)
	{
		[self alert:NSLocalizedString(@"PDX Bus was not able to get the time for this arrival", @"arrival alarm error")
		   fireDate:nil
			 button:nil
		   userInfo:nil
	   defaultSound:YES];
		taskDone = YES;
	}
	else 
	{
        departureDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.lastFetched.departureTime)];

        
		// No new data here - the bus has probably come by this point.  If it has then this is the time to stop.
		if (departureDate == nil || [departureDate compare:[NSDate date]] != NSOrderedDescending)
		{
			taskDone = YES;
		}
	}

	if (!taskDone)
	{
		departureDate	= [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.lastFetched.departureTime)];
		waitTime		= [departureDate timeIntervalSinceNow];
		
#ifdef DEBUG_ALARMS
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		
		DEBUG_LOG(@"Dep time %@\n", [dateFormatter stringFromDate:departureDate]);
#endif
		
		if (self.observer)
		{
			[self.observer taskUpdate:self];
		}
		
		// Update the alert with the time we have
		NSDate *alarmTime = [departureDate dateByAddingTimeInterval:(NSTimeInterval)(-(NSTimeInterval)(self.minsToAlert * 60.0 + 30.0))];
		NSString *alertText = nil;
		
		if (self.minsToAlert <= 0)
		{
			alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" is due at %@", @"alarm message"),
						 self.lastFetched.routeName,
						 self.lastFetched.locationDesc
						 ];
		}
		else if (self.minsToAlert == 1)
		{
			alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" 1 minute way from %@", @"alarm message"),
						 self.lastFetched.routeName,
						 self.lastFetched.locationDesc
						 ];
		}
		else 
		{
			alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" is %d minutes away from %@", @"alarm message"),
						 self.lastFetched.routeName,
						 self.minsToAlert,
						 self.lastFetched.locationDesc
						 ];
		}
		
		// if (self.alarm == nil) //  || ![self.alarm.fireDate isEqualToDate:alarmTime]) 
		{
			[self alert:alertText 
			   fireDate:alarmTime
				 button:NSLocalizedString(@"Show arrivals", @"alert text")
			   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						 self.stopId,							kStopIdNotification,
						 self.block,							kAlarmBlock,
						 nil]
		   defaultSound:NO];
		}
		
		
		int secs = (waitTime - (self.minsToAlert * 60));
		
		if (secs > 8*60)
		{
			next = [NSDate dateWithTimeIntervalSinceNow:4 * 60];
		}
		else if (secs > 120)
		{
			next = [NSDate dateWithTimeIntervalSinceNow:secs/2];
			
		}
		else if (secs > 60)
		{
			// suspend until the actual time
			next = [NSDate dateWithTimeIntervalSinceNow:30];
		}
		else if (secs > 0)
		{
			next = alarmTime;
			self.alarmState = AlarmStateNearlyArrived;
		}
        else
        {
            next = nil;
            self.alarmState = AlarmFired;
        }
        
        
	}
	
	if (taskDone)
	{
		next = nil;
        self.alarmState = AlarmFired;
	}
    
#ifdef DEBUG_ALARMS
#define kLastFetched @"LF"
#define kNextFetch @"NF"
#define kAppState @"AppState"
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          self.lastFetched, kLastFetched, 
                          (next ? next : [NSDate date]),   kNextFetch,
                          [self appState],  kAppState,
                          nil];
    [self.dataReceived addObject:dict];
#endif


	return next;
}

- (void)startTask
{
	self.departures = [[[XMLDepartures alloc] init] autorelease];
	self.departures.giveUp = 30;  // the background task must never be blocked for more that 30 seconds.
	
	if (self.observer)
	{
		[self.observer taskStarted:self];
	}
}


- (NSString *)key
{
	return [NSString stringWithFormat:@"%@+%@", self.stopId, self.block];
}

- (void)cancelTask
{
	[self cancelNotification];
	[self.observer taskDone:self];
	self.observer = nil;
}

#ifdef DEBUG_ALARMS
- (int)internalDataItems
{
	return self.dataReceived.count+1;
}

- (NSString *)internalData:(int)item
{
	NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
	
	
	if (item == 0)
	{
		UIApplication*    app = [UIApplication sharedApplication];
		[str appendFormat:@"alerts: %d", app.scheduledLocalNotifications.count];
	}
	else 
	{
        NSDictionary *dict = [self.dataReceived objectAtIndex:item-1];
		Departure *dep = [dict objectForKey:kLastFetched];
        
	
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
	
		[str appendFormat:@"%@\n", dep.routeName];
		[str appendFormat:@"mins %d\n", dep.minsToArrival];
		[str appendFormat:@"secs %d\n", dep.secondsToArrival];
	
		[str appendFormat:@"QT %@\n", [dateFormatter stringFromDate:
									[NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(dep.queryTime)]]];
        
        NSDate *departureDate	= [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(dep.departureTime)];
        NSDate *alarmTime = [departureDate dateByAddingTimeInterval:(NSTimeInterval)(-(NSTimeInterval)(self.minsToAlert * 60.0 + 30.0))];
        
        [str appendFormat:@"DT %@\n", [dateFormatter stringFromDate: departureDate ]];
        [str appendFormat:@"AT %@\n", [dateFormatter stringFromDate: alarmTime ]];
        [str appendFormat:@"NF %@\n", [dateFormatter stringFromDate: [dict objectForKey:kNextFetch]]];
        [str appendFormat:@"AS %@\n", [dict objectForKey:kAppState]];        
	}
	return str;

}
#endif

- (void)showToUser:(BackgroundTaskContainer *)backgroundTask
{
	DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
	[departureViewController fetchTimesForLocationInBackground:backgroundTask loc:self.stopId block:self.block];
	[departureViewController release];
}

- (NSString *)cellToGo
{
	NSString *str = @"";
	@synchronized (self.lastFetched)
	{
		
		if (self.lastFetched !=nil)
		{
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateStyle:NSDateFormatterNoStyle];
			[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			NSDate *departureDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.lastFetched.departureTime)];
			
			NSTimeInterval secs = ((double)self.minsToAlert * (-60.0));
			
			NSDate *alarmDate = [NSDate dateWithTimeInterval:secs sinceDate:departureDate];
            if (self.alarmState == AlarmFired)
            {
                str = [NSString stringWithFormat:NSLocalizedString(@"Alarm done: %@", @"Alarm was done at time {time}"), [dateFormatter stringFromDate: alarmDate]];
            }
            else
            {
                str = [NSString stringWithFormat:NSLocalizedString(@"Alarm time: %@", @"Alarm wil be done at time {time}"), [dateFormatter stringFromDate: alarmDate]];
            }
		}
	}
	return str;
}

- (int)threadReferenceCount
{
	return 1;
}

@end




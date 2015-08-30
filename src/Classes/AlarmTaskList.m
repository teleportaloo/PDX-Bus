//
//  AlarmTaskList.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/29/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmTaskList.h"
#import "AlarmAccurateStopProximity.h"
#import "DebugLogging.h"
#import <objc/runtime.h>

#ifdef PEBBLE_SUPPORT
#import "PebbleSportsDisplay.h"
#endif

#define kLoopTimeSecs 20

@implementation AlarmTaskList

@synthesize observer			= _observer;
@synthesize backgroundThread	= _backgroundThread;

-(void)dealloc
{
	[_backgroundTasks release];	
    [_orderedTaskKeys release];
    [_newTaskKeys     release];
	self.observer = nil;
	self.backgroundThread = nil;
    [_externalDisplays release];

	[super dealloc];
}

+ (AlarmTaskList*)getSingleton
{
	static AlarmTaskList * taskList = nil;
	
	if (taskList == nil)
	{
		taskList = [[AlarmTaskList alloc] init];
	}
	
	return taskList;
}


+ (bool)supported
{
	UIDevice* device = [UIDevice currentDevice];
	BOOL backgroundSupported = NO;
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
		backgroundSupported = device.multitaskingSupported;
	
	return backgroundSupported;
}

+ (bool)proximitySupported
{
	
	Class locManClass = (NSClassFromString(@"CLLocationManager"));
    
	return [AlarmTaskList supported] 
						&& locManClass!=nil 
						&& [locManClass respondsToSelector:@selector(significantLocationChangeMonitoringAvailable)]
						&& [locManClass significantLocationChangeMonitoringAvailable];
}

- (void)updateBadge
{
	@synchronized(_backgroundTasks)
	{
        int count = 0;
        
        NSArray *keys = [self taskKeys];
        
        for (NSString *key in keys)
        {
            AlarmTask *task = [self taskForKey:key];
            
            if (task && task.alarmState == AlarmFired)
            {
                count++;
            }
        }
        
		[UIApplication sharedApplication].applicationIconBadgeNumber = count;
	}
}

- (void)removeTask:(NSString*)taskKey fromArray:(NSMutableArray *)array 
{
    for (int i=0; i < array.count; i++)
    {
        NSString *arrayTaskKey = [array objectAtIndex:i];
        if ([arrayTaskKey isEqualToString:taskKey])
        {
            [array removeObjectAtIndex:i];
            break;
        }
    }
}

- (id)init
{
	if ((self = [super init]))
	{
		_backgroundTasks    = [[NSMutableDictionary alloc] init];
        _orderedTaskKeys    = [[NSMutableArray alloc] init];
        _newTaskKeys        = [[NSMutableArray alloc] init];
        _taskId             = 0; // UIBackgroundTaskInvalid cannot be used in 3.2 OS
        _atomicTaskRunning  = NO;
        _externalDisplays = [[NSArray arrayWithObjects:
#ifdef PEBBLE_SUPPORT
                              [[[PebbleSportsDisplay alloc] init] autorelease],
#endif
                              nil] retain];
        
		[self updateBadge];
        
       
	}
	return self;
}


- (NSString *)keyForStopId:(NSString *)stopId block:(NSString *)block
{
	return [NSString stringWithFormat:@"%@+%@", stopId, block];
}

- (void)cancelTaskForKey:(NSString *)key
{
	@synchronized(_backgroundTasks)
	{
		AlarmTask *task = [_backgroundTasks objectForKey:key];
	
		if (task !=nil)
		{
			[task cancelTask];
            
            
		}
	}
}

- (void)checkForMute
{
    // Cannot check for mute so just warn the user!
    if (self.taskCount == 0)
    {
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"New Alarm",@"alarm pop-up title")
                                                           message:NSLocalizedString(@"Note: The alarm will not sound if the device is muted.", @"alarm warning")
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"OK",@"OK button")
                                                 otherButtonTitles:nil] autorelease];
        [alert show];
    }
    
}

- (void)addTaskForDeparture:(DepartureData *)dep mins:(uint)mins
{
	@synchronized(_backgroundTasks)
	{
		AlarmFetchArrivalsTask *newTask = [[[AlarmFetchArrivalsTask alloc] init] autorelease];
	
		newTask.stopId = dep.locid;
		newTask.block  = dep.block;
		newTask.minsToAlert = mins;
		newTask.observer = self;
		
		if (mins ==0)
		{
			newTask.desc = [NSString stringWithFormat:@"%@", dep.routeName];
		}
		else if (mins == 1)
		{
			newTask.desc = [NSString stringWithFormat:NSLocalizedString(@"1 min before %@", @"single minute alarm description"),  dep.routeName];
		}
		else 
		{
			newTask.desc = [NSString stringWithFormat:NSLocalizedString(@"%d mins before %@", @"plural minyes alarm description"), mins, dep.routeName];
		}
		newTask.lastFetched = dep;
        
        [self checkForMute];

		[self cancelTaskForKey:newTask.key];
	
		[_backgroundTasks setObject:newTask forKey:newTask.key];
        [_orderedTaskKeys addObject:newTask.key];
        [_newTaskKeys     addObject:newTask.key];
	 
		[newTask startTask];
	}
}
	 
- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block
{
	@synchronized(_backgroundTasks)
	{
		return [_backgroundTasks objectForKey:[self keyForStopId:stopId block:block]] != nil;
	}
}

- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block
{
	@synchronized(_backgroundTasks)
	{
		AlarmFetchArrivalsTask *task = [_backgroundTasks objectForKey:[self keyForStopId:stopId block:block]];
	
		if (task == nil)
		{
			return 0;
		}
	
		return (int)task.minsToAlert;
	}
}
	 
- (void)cancelTaskForStopId:(NSString *)stopId block:(NSString *)block
{
	NSString *key = [self keyForStopId:stopId block:block];
	[self cancelTaskForKey:key];
}

- (void)taskUpdate:(id)task
{
	if (self.observer)
	{
		[(NSObject*)self.observer performSelectorOnMainThread:@selector(taskUpdate:) withObject:task waitUntilDone:NO];
	}
    
    
    
    
    AlarmTask *realTask = (AlarmTask *)task;
    
    if (realTask.alarmState == AlarmFired)
    {
        [self updateBadge];
    }
	_batchUpdate = YES;
}

- (void)taskStarted:(id)task
{
	@synchronized (_backgroundTasks)
	{
		if (self.observer)
		{
			[(NSObject*)self.observer performSelectorOnMainThread:@selector(taskStarted:) withObject:task waitUntilDone:NO];
		}
	
		[self runTask];
		[self updateBadge];
	}
	_batchUpdate = YES;
}

- (void)taskDone:(id)task
{
	@synchronized(_backgroundTasks)
	{
		AlarmTask *realTask = (AlarmTask*)task;
		NSString *key = realTask.key;
	
		[realTask retain];
	
		for (NSString *obj in _backgroundTasks)
		{
			if ([obj isEqualToString:key])
			{
				[_backgroundTasks removeObjectForKey:key];
				break;
			}
		}
        
        [self removeTask:key fromArray:_newTaskKeys];
        [self removeTask:key fromArray:_orderedTaskKeys];
        
        
        
		if (self.observer)
		{
			[(NSObject*)self.observer performSelectorOnMainThread:@selector(taskDone:) withObject:task waitUntilDone:NO];
		}
        
        for (ExternalDisplayDevice *display in _externalDisplays)
        {
            [display displayEnded:task];
        }
	
		[realTask release];
		[self updateBadge];
	}
	_batchUpdate = YES;
}

- (void)resumeOnActivate
{
    @synchronized(_backgroundTasks)
    {
        if (!_atomicTaskRunning && _backgroundTasks.count > 0)
        {
            [_newTaskKeys removeAllObjects];
            for (NSString *taskKey in _backgroundTasks)
            {
                AlarmTask *task = [_backgroundTasks objectForKey:taskKey];
                switch (task.alarmState)
                {
                    default:
                    case AlarmStateAccurateInitiallyThenInaccurate:
                    case AlarmFired:
                    case AlarmStateAccurateLocationNeeded:
                    case AlarmStateInaccurateLocationNeeded:
                        break;
                    case AlarmStateFetchArrivals:
                    case AlarmStateNearlyArrived:
                        [_newTaskKeys addObject:task.key];
                        break;
                }
            }
            [self runTask];
        }
    }
}


- (void)checkForLongAlarms
{
        
    @synchronized(_backgroundTasks)
    {
        UIApplication *app = [UIApplication sharedApplication];
        NSTimeInterval remaining = app.backgroundTimeRemaining;
        bool alertRequired = NO;
        if (_backgroundTasks.count > 0 && [UserPrefs getSingleton].alarmInitialWarning)
        {
            NSArray *keys = [self taskKeys];
            
            for (NSString *key in keys)
            {
                AlarmTask *task = [self taskForKey:key];
                
                if (task && task.alarm && task.alarm.fireDate != 0 && !task.alarmWarningDisplayed
                    && [task.alarm.fireDate timeIntervalSinceNow] >= remaining)
                {
                        alertRequired              = YES;
                        task.alarmWarningDisplayed = YES;
                }
    
            }
            
            if (alertRequired)
            {
                AlarmTask *alertTask = [[[AlarmTask alloc] init] autorelease];
                
                NSDictionary *ignore = [NSDictionary dictionaryWithObjectsAndKeys:
                                        kDoNotDisplayIfActive, kDoNotDisplayIfActive,
                                        nil];
                
                int mins = ((remaining + 30) / 60.0);
                [alertTask alert:[NSString stringWithFormat:NSLocalizedString(@"PDX Bus checks arrivals in the background for only %d mins - then you will be alerted to restart PDX Bus.",
                                                                              @"alarm alert warning"),
                                   mins]
                        fireDate:nil 
                          button:NSLocalizedString(@"To PDX Bus", @"button test to launch PDX BUS from alert")
                        userInfo:ignore
                    defaultSound:YES];
            }
        }
    }
}


-(void)taskLoopEnded:(id)unused
{
    for (ExternalDisplayDevice *display in _externalDisplays)
    {
        [display displayEnded:nil];
         display.delegate = nil;
    }
}

- (void)addTaskForStopIdProximity:(NSString *)stopId 
							  lat:(NSString *)lat 
							  lng:(NSString *)lng 
							 desc:(NSString *)desc
						 accurate:(bool)accurate
{
	@synchronized (_backgroundTasks)
	{
		AlarmAccurateStopProximity *newTask = [[[AlarmAccurateStopProximity alloc] initWithAccuracy:accurate] autorelease];
	
		[newTask setStop:stopId lat:lat lng:lng desc:desc];
		newTask.observer = self;
	
        [self checkForMute];
        
		[self cancelTaskForKey:newTask.key];
	
	
		[_backgroundTasks setObject:newTask forKey:newTask.key];
        [_orderedTaskKeys addObject:newTask.key];
		
		[newTask startTask];
	}
}

- (bool)hasTaskForStopIdProximity:(NSString *)stopId
{
	@synchronized (_backgroundTasks)
	{
		return [_backgroundTasks objectForKey:stopId] != nil;
	}
}
- (void)cancelTaskForStopIdProximity:(NSString*)stopId
{
	[self cancelTaskForKey:stopId];
}

- (void)taskLoop
{
	DEBUG_LOG(@"taskLoop\n");
	// NSRunLoop* runLoop		= [NSRunLoop currentRunLoop];
	self.backgroundThread	= [NSThread currentThread];
	
	bool		done		= false;
	AlarmTask *	task		= nil;
	NSDate    * nextAlert   = nil;
    NSMutableArray *taskKeys = [[[NSMutableArray alloc] init]  autorelease];
    NSMutableArray *doneTasks = [[[NSMutableArray alloc] init]  autorelease];
		
	while (!done)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Here is where we check if new tasks have been added or remevoed
        @synchronized (_backgroundTasks)
        {
            // Add items from the new tasks into my active list
            [taskKeys addObjectsFromArray:_newTaskKeys];
            [_newTaskKeys removeAllObjects];
            
            // Check to see that each key still has a task as it may have
            // been cancelled by the user
            for (int i=0;  i<taskKeys.count; )
            {
                if ([self taskForKey:[taskKeys objectAtIndex:i]]==nil)
                {
                    [taskKeys removeObjectAtIndex:i];
                }
                else
                {
                    i++;
                }
            }
            
            if (taskKeys.count == 0 || [self.backgroundThread isCancelled])
            {
                // Setting _atomicTaskRunning to NO will mean another thread can 
                // start processing while we tidy up.
                _atomicTaskRunning = NO;
                self.backgroundThread = nil;
                done = YES;
            }
        }
		
		nextAlert = [NSDate distantFuture];
		
		// DEBUG_LOG(@"Alarm loop starting\n");
		
		for (NSString *key in taskKeys)
		{
			task =  [self taskForKey:key];
			
			// DEBUG_LOG(@"Task: %@ %p\n", key, task);
			
			if (task)
			{
				switch (task.alarmState)
				{
					case AlarmStateNearlyArrived:
						if (task.nextFetch == nil || [task.nextFetch compare:[NSDate date]] != NSOrderedDescending)
						{
#ifndef DEBUG_ALARMS
							// [self taskDone:task];
#endif
                            task.alarmState = AlarmFired;
                            [doneTasks addObject:key];
                            [self taskUpdate:task];
						}
						break;
					case AlarmStateFetchArrivals:
						if (task.nextFetch == nil || [task.nextFetch compare:[NSDate date]] != NSOrderedDescending)
						{
							// DEBUG_LOG(@"Fetching...");
                            task.nextFetch = [task fetch:self];
                            [self taskUpdate:task];
						}
						break;
                    default:
                        break;
				}
				nextAlert = [task earlierAlert:nextAlert];
			}
		}
		
		// DEBUG_LOG(@"Tasks processed\n");
		
        for (NSString *key in doneTasks)
        {
            [self removeTask:key fromArray:taskKeys];
        }
        
        [doneTasks removeAllObjects];
	
		if (!done && ![self.backgroundThread isCancelled] && taskKeys.count > 0)
		{
			NSDate *waitUntil = [NSDate dateWithTimeIntervalSinceNow:kLoopTimeSecs];
						
			// [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:kLoopTimeSecs]];
			// [self waitWithRunLoop:runLoop period:kLoopTimeSecs];
			[NSThread sleepUntilDate:[waitUntil earlierDate:nextAlert]];
		}
        
		
		// DEBUG_LOG(@"Reloop\n");
		
		[pool release];
	}
    
    [(NSObject*)self performSelectorOnMainThread:@selector(taskLoopEnded:) withObject:nil waitUntilDone:NO];
	    
	DEBUG_LOG(@"taskLoop done\n");
}


- (void)scheduleAgain:(id)arg
{
	DEBUG_LOG(@"scheduleAgain\n");
	// NSDate *soon = [NSDate dateWithTimeIntervalSinceNow:5.0];
	
	// NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.0 target:self selector:@selector(restartThread:) userInfo:nil repeats:NO] autorelease];
	
	// [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[self runTask];
}



- (void)rawRunTask
{
	DEBUG_LOG(@"runTask\n");

	UIApplication*    app = [UIApplication sharedApplication];
    
    for (ExternalDisplayDevice *display in _externalDisplays)
    {
        display.delegate = self;
        [display getSupportAndStartCallbacks];
    }
    
   
	_taskId = [app beginBackgroundTaskWithExpirationHandler:^{
		DEBUG_LOG(@"Expiration Handler\n");
		
		NSDictionary *ignore = [NSDictionary dictionaryWithObjectsAndKeys:
								kDoNotDisplayIfActive, kDoNotDisplayIfActive,
								nil];
		
		
		AlarmTask *alertTask = [[[AlarmTask alloc] init] autorelease];
		
		[alertTask alert:NSLocalizedString(@"iOS has stopped PDX Bus from checking arrivals. "
                         @"Please restart PDX Bus so it can update the arrival alarms.", @"alarm alert")
				fireDate:nil 
				  button:NSLocalizedString(@"Back to PDX Bus", @"Button to return to PDX Bus")
				userInfo:ignore
			defaultSound:NO];
		
		// cancel the task thread - it will get backgrounded - the cancelation may not run until later.
		[self.backgroundThread cancel];
		
		[app endBackgroundTask:_taskId];
		
	}];
    
    
	
	// Start the long-running task and return immediately.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self taskLoop];
        [app endBackgroundTask:_taskId];
	});
	DEBUG_LOG(@"runTask done\n");
}

- (void)runTask
{
    @synchronized (_backgroundTasks)
	{
        if (!_atomicTaskRunning)
        {
            _atomicTaskRunning = YES;
            [self rawRunTask];
        }
    }
}


- (NSInteger)taskCount
{
	@synchronized (_backgroundTasks)
	{
		return _backgroundTasks.count;
	}
	
}
- (NSArray *)taskKeys
{
	@synchronized (_backgroundTasks)
	{
		return [[_orderedTaskKeys copy] autorelease];
	}
}
- (AlarmTask *)taskForKey:(NSString *)key
{
	@synchronized (_backgroundTasks)
	{
		return [[[_backgroundTasks objectForKey:key] retain] autorelease];
	}
}

- (void)userAlertForProximity:(id<UIAlertViewDelegate>) delegate
{
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Proximity Alarm", @"alarm alert title")
													   message:[NSString stringWithFormat:
                                                                NSLocalizedString(@"PDX Bus can use accurate GPS or low-power cell-towers to"
                                                                                  " determine your location and alert"
                                                                                  " you when you get within %@ of the stop.",
                                                                                  @"alert question"),
																kUserDistanceProximity]
													  delegate:delegate
											 cancelButtonTitle:NSLocalizedString(@"Cancel", @"button text")
											 otherButtonTitles:NSLocalizedString(@"Use accurate GPS", @"button text"),
                                                               NSLocalizedString(@"Use low-power cell-towers", @"button text"), nil] autorelease];
	[alert show];
}

- (bool)userAlertForProximityAction:(NSInteger)button stopId:(NSString *)stopId lat:(NSString *)lat lng:(NSString *)lng desc:(NSString *)desc
{
	if (button != 0)
	{
		AlarmTaskList *taskList = [AlarmTaskList getSingleton];
		
		[taskList addTaskForStopIdProximity:stopId lat:lat lng:lng desc:desc accurate:button==1];
		return true;
	}
	return false;
}

// External Display Delegate Methods
- (void)displayAvailable:(ExternalDisplayDevice*)display
{
    
}
- (void)displayGone:(ExternalDisplayDevice*)display
{
    
}

- (void)updateSent:(ExternalDisplayDevice*)display
{
    NSString *key = display.taskKey;
    
    if (key)
    {
        AlarmTask *task =  [self taskForKey:key];
        
        [self taskUpdate:task];
        
    }
}

- (bool)updateAllExternalDisplays:(AlarmFetchArrivalsTask *)task
{
    bool externalDisplay = NO;

    for (ExternalDisplayDevice *display in _externalDisplays)
    {
        [display updateDisplay:task];
    
        externalDisplay |= [display running];
    }
    return externalDisplay;
    
}

- (void)endExternalDisplayForTask:(AlarmFetchArrivalsTask *)task
{
    for (ExternalDisplayDevice *display in _externalDisplays)
    {
        [display displayEnded:task];
    }
}

//NSDictionary *myPebbleDict = @{ PBSportsTimeKey : [PBSportsUpdate timeStringFromFloat:self.lastFetched.minsToArrival],
//            PBSportsDistanceKey : [NSString stringWithFormat:@"%2.02f", busDistanceMiles],
//            PBSportsDataKey :[NSString stringWithFormat:@"%.0f", [self.lastFetched.route floatValue]],
//            };



@end

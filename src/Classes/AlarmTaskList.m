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
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "MainQueueSync.h"

#define kLoopTimeSecs 20

@implementation AlarmTaskList


+ (AlarmTaskList*)sharedInstance
{
    static AlarmTaskList * taskList = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskList = [[AlarmTaskList alloc] init];
    });
    
    return taskList;
}


+ (bool)supported
{
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = device.multitaskingSupported;
    return backgroundSupported;
}

+ (bool)proximitySupported
{
    
    Class locManClass = (NSClassFromString(@"CLLocationManager"));
    
    return [AlarmTaskList supported] 
                        && locManClass!=nil 
                        && [locManClass significantLocationChangeMonitoringAvailable];
}


#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


- (BOOL)checkNotificationType:(UIUserNotificationType)type
{
    __block UIUserNotificationSettings *currentSettings = nil;
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking: ^{
        currentSettings = [UIApplication sharedApplication].currentUserNotificationSettings;
    }];
    
    return (currentSettings.types & type);
}


- (void)setApplicationBadgeNumber:(NSInteger)badgeNumber
{
    UIApplication *application = [UIApplication sharedApplication];
    
    if (application == nil)
    {
        DEBUG_LOG(@"failed to get app");

    }
    else if(SYSTEM_VERSION_LESS_THAN(@"8.0"))
    {
        application.applicationIconBadgeNumber = badgeNumber;
    }
    else
    {
        if ([self checkNotificationType:UIUserNotificationTypeBadge])
        {
            DEBUG_LOG(@"badge number changed to %d", (int)badgeNumber);
            application.applicationIconBadgeNumber = badgeNumber;
        }
        else
        {
            DEBUG_LOG(@"access denied for UIUserNotificationTypeBadge");
        }
    }

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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setApplicationBadgeNumber:count];
        });
        
        // [UIApplication sharedApplication].applicationIconBadgeNumber = count;
    }
}

- (void)removeTask:(NSString*)taskKey fromArray:(NSMutableArray *)array 
{
    for (int i=0; i < array.count; i++)
    {
        NSString *arrayTaskKey = array[i];
        if ([arrayTaskKey isEqualToString:taskKey])
        {
            [array removeObjectAtIndex:i];
            break;
        }
    }
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _backgroundTasks    = [[NSMutableDictionary alloc] init];
        _orderedTaskKeys    = [[NSMutableArray alloc] init];
        _newTaskKeys        = [[NSMutableArray alloc] init];
        _taskId             = 0; // UIBackgroundTaskInvalid cannot be used in 3.2 OS
        self.atomicTaskRunning  = NO;
        
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
        AlarmTask *task = _backgroundTasks[key];
    
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
        UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"New Alarm",@"alarm pop-up title")
                                                           message:NSLocalizedString(@"Note: The alarm will not sound if the device is muted.", @"alarm warning")
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"OK",@"OK button")
                                                 otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void)addTaskForDeparture:(Departure *)dep mins:(uint)mins
{
    @synchronized(_backgroundTasks)
    {
        AlarmFetchArrivalsTask *newTask = [[AlarmFetchArrivalsTask alloc] init];
    
        newTask.stopId = dep.locid;
        newTask.block  = dep.block;
        newTask.minsToAlert = mins;
        newTask.observer = self;
        newTask.desc = dep.shortSign;
        newTask.lastFetched = dep;
        
        [self checkForMute];

        [self cancelTaskForKey:newTask.key];
    
        _backgroundTasks[newTask.key] = newTask;
        [_orderedTaskKeys addObject:newTask.key];
        [_newTaskKeys     addObject:newTask.key];
     
        [newTask startTask];
    }
}
     
- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block
{
    @synchronized(_backgroundTasks)
    {
        return _backgroundTasks[[self keyForStopId:stopId block:block]] != nil;
    }
}

- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block
{
    @synchronized(_backgroundTasks)
    {
        AlarmFetchArrivalsTask *task = _backgroundTasks [[self keyForStopId:stopId block:block]];
    
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
        
        [self updateBadge];
    }
    _batchUpdate = YES;
}

- (void)resumeOnActivate
{
    @synchronized(_backgroundTasks)
    {
        if (!self.atomicTaskRunning && _backgroundTasks.count > 0)
        {
            [_newTaskKeys removeAllObjects];
            for (NSString *taskKey in _backgroundTasks)
            {
                AlarmTask *task = _backgroundTasks[taskKey];
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
#if 0
    @synchronized(_backgroundTasks)
    {
        UIApplication *app = [UIApplication sharedApplication];
        NSTimeInterval remaining = app.backgroundTimeRemaining;
        bool alertRequired = NO;
        if (_backgroundTasks.count > 0 && [UserPrefs sharedInstance].alarmInitialWarning)
        {
            NSArray *keys = [self taskKeys];
            NSTimeInterval shortestLongAlarm = DBL_MAX;
            
            for (NSString *key in keys)
            {
                AlarmTask *task = [self taskForKey:key];
                
                if (task && task.alarm && task.alarm.fireDate != 0 && !task.alarmWarningDisplayed
                    && task.alarm.fireDate.timeIntervalSinceNow >= remaining)
                {
                        alertRequired              = YES;
                        task.alarmWarningDisplayed = YES;
                }
                
                if (task && task.alarm && task.alarm.fireDate != 0  && task.alarm.fireDate.timeIntervalSinceNow >= remaining &&  task.alarm.fireDate.timeIntervalSinceNow < shortestLongAlarm)
                {
                    shortestLongAlarm = task.alarm.fireDate.timeIntervalSinceNow;
                }
                
                
    
            }
        
            
            if (alertRequired)
            {
                AlarmTask *alertTask = [AlarmTask data];
                
                NSDictionary *ignore = @{kDoNotDisplayIfActive : kDoNotDisplayIfActive};
                int mins = ((remaining + 30) / 60.0);
                [alertTask alert:[NSString stringWithFormat:NSLocalizedString(@"PDX Bus checks departure in the background for only %d mins - then you will be alerted to restart PDX Bus.",
                                                                              @"alarm alert warning"),
                                   mins]
                        fireDate:nil 
                          button:NSLocalizedString(@"To PDX Bus", @"button test to launch PDX BUS from alert")
                        userInfo:ignore
                    defaultSound:YES
                      thisThread:NO];
            }
        }
    }
#endif
}


-(void)taskLoopEnded:(id)unused
{
    
}

- (void)addTaskForStopIdProximity:(NSString *)stopId 
                              loc:(CLLocation *)loc
                             desc:(NSString *)desc
                         accurate:(bool)accurate
{
    @synchronized (_backgroundTasks)
    {
        AlarmAccurateStopProximity *newTask = [[AlarmAccurateStopProximity alloc] initWithAccuracy:accurate];
    
        [newTask setStop:stopId loc:loc desc:desc];
        newTask.observer = self;
    
        [self checkForMute];
        
        [self cancelTaskForKey:newTask.key];
    
    
        _backgroundTasks[newTask.key] = newTask;
        [_orderedTaskKeys addObject:newTask.key];
        
        [newTask startTask];
    }
}

- (bool)hasTaskForStopIdProximity:(NSString *)stopId
{
    @synchronized (_backgroundTasks)
    {
        return _backgroundTasks[stopId] != nil;
    }
}
- (void)cancelTaskForStopIdProximity:(NSString*)stopId
{
    [self cancelTaskForKey:stopId];
}


- (void)startUpdatingLocation:(CLLocationManager *)manager
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    if (status == kCLAuthorizationStatusDenied)
    {
        NSLog(@"Location services are disabled in settings.");
    }
    else
    {
        // for iOS 8
        if ([manager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [manager requestAlwaysAuthorization];
        }
        // for iOS 9
        if ([manager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)])
        {
            [manager setAllowsBackgroundLocationUpdates:YES];
        }

        [manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
#ifdef DEBUG_LOGGING
    CLLocation *mostRecentLocation = locations.lastObject;
    DEBUG_LOG(@"Current location: %@ %@", @(mostRecentLocation.coordinate.latitude), @(mostRecentLocation.coordinate.longitude));
#endif
}


- (void)taskLoop
{
    DEBUG_FUNC();
    // NSRunLoop* runLoop        = [NSRunLoop currentRunLoop];
    self.backgroundThread    = [NSThread currentThread];
    
    bool done = false;
    AlarmTask *task = nil;
    NSDate *nextFetch = nil;
    NSMutableArray *taskKeys = [NSMutableArray array];
    NSMutableArray *doneTasks = [NSMutableArray array];
    
    bool useGps = [UserPrefs sharedInstance].useGpsForAllAlarms;
    
    CLLocationManager *manager = nil;
    
    if (useGps)
    {
        manager = [[CLLocationManager alloc] init];
        manager.delegate = self;
        manager.allowsBackgroundLocationUpdates = YES;
        manager.desiredAccuracy = kCLLocationAccuracyKilometer;
        manager.pausesLocationUpdatesAutomatically = NO;
        [self startUpdatingLocation:manager];
    }
    

    while (!done)
    {
        @autoreleasepool {
            
            
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
                    if ([self taskForKey:taskKeys[i]]==nil)
                    {
                        [taskKeys removeObjectAtIndex:i];
                    }
                    else
                    {
                        i++;
                    }
                }
                
                if (taskKeys.count == 0 || self.backgroundThread.cancelled)
                {
                    // Setting _atomicTaskRunning to NO will mean another thread can
                    // start processing while we tidy up.
                    self.atomicTaskRunning = NO;
                    [self.backgroundThread cancel];
                    self.backgroundThread = nil;
                    done = YES;
                    
                    if (taskKeys.count == 0)
                    {
                        self.nextFetch = nil;
                    }
                }
            }
            
            nextFetch = [NSDate distantFuture];
            
            bool wakeUpAlertRequired = YES;
            
            // DEBUG_LOG(@"Alarm loop starting\n");
            
            if (!done)
            {
                for (NSString *key in taskKeys)
                {
                    task =  [self taskForKey:key];
                    
                    // DEBUG_LOG(@"Task: %@ %p\n", key, task);
                    
                    if (task)
                    {
                        switch (task.alarmState)
                        {
                            case AlarmFired:
                                [doneTasks addObject:key];
                                break;
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
                        nextFetch = [task earlierAlert:nextFetch];
                        
                        if (task.alarmState == AlarmStateNearlyArrived)
                        {
                            wakeUpAlertRequired = NO;
                        }
                    }
                }
                
                
                // DEBUG_LOG(@"Tasks processed\n");
                
                for (NSString *key in doneTasks)
                {
                    [self removeTask:key fromArray:taskKeys];
                }
                
                [doneTasks removeAllObjects];
            }
            
            if (!done && !self.backgroundThread.cancelled && taskKeys.count > 0)
            {
                NSDate *waitUntil = [NSDate dateWithTimeIntervalSinceNow:kLoopTimeSecs];
                
                __block  NSTimeInterval remaining = 0;
                UIApplication *app = [UIApplication sharedApplication];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    remaining = app.backgroundTimeRemaining;
                });
                
                NSDate *sleepUntil = [waitUntil earlierDate:nextFetch];
                NSTimeInterval waitTime = [sleepUntil timeIntervalSinceNow];
                
                DEBUG_LOGF(remaining);
                DEBUG_LOGF(waitTime);
                
                const NSTimeInterval gap = 10.0;
                
                self.nextFetch = nextFetch;
                
                bool okToWait = useGps || (waitTime + gap) < remaining;
                
                if (okToWait)
                {
                    [NSThread sleepUntilDate:sleepUntil];
                }
                
                if (!okToWait || self.backgroundThread.cancelled)
                {
                    DEBUG_LOGB(self.backgroundThread.cancelled);
                    DEBUG_LOG(@"We must go to sleep. :-(");
                    
                    [self.backgroundThread cancel];
                    self.atomicTaskRunning = NO;
                    self.backgroundThread = nil;
                    done = YES;
                    
                    if (wakeUpAlertRequired)
                    {
                        [self createAlertToWakeUpApp];
                    }
                    else
                    {
                        DEBUG_LOG(@"No wakeup alarm required");
                    }
                }
            }
        }
    }
    
    if (manager!=nil)
    {
        [manager stopUpdatingLocation];
        manager.delegate = nil;
    }
    [(NSObject*)self performSelectorOnMainThread:@selector(taskLoopEnded:) withObject:nil waitUntilDone:NO];
        
    DEBUG_FUNCEX();
}


- (void)scheduleAgain:(id)unused
{
    DEBUG_LOG(@"scheduleAgain\n");
    // NSDate *soon = [NSDate dateWithTimeIntervalSinceNow:5.0];
    
    // NSTimer *timer = [[NSTimer alloc] initWithFireDate:soon interval:0.0 target:self selector:@selector(restartThread:) userInfo:nil repeats:NO];
    
    // [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [self runTask];
}

- (void)createAlertToWakeUpApp
{
    if (self.nextFetch)
    {
        AlarmTask *alertTask = [AlarmTask data];
        
        NSDictionary *ignore = @{kDoNotDisplayIfActive :kDoNotDisplayIfActive};
        
        DEBUG_LOG(@"Alert in %f", [self.nextFetch timeIntervalSinceNow]);
        
        [alertTask alert:NSLocalizedString(@"iOS has stopped PDX Bus from checking departures, making alarms inaccurate. "
                                           @"Please restart PDX Bus so it can update the departure alarms.", @"alarm alert")
                fireDate:self.nextFetch
                  button:NSLocalizedString(@"Back to PDX Bus", @"Button to return to PDX Bus")
                userInfo:ignore
            defaultSound:NO
              thisThread:NO];
        
        self.nextFetch = nil;
    }
}

- (void)rawRunTask
{
    DEBUG_FUNC();
    
    UIApplication*    app = [UIApplication sharedApplication];
    
    _taskId = [app beginBackgroundTaskWithExpirationHandler:^{
        DEBUG_LOG(@"Expiration Handler\n");
        
        DEBUG_LOGF(app.backgroundTimeRemaining);
        
        if (self.backgroundThread)
        {
            [self.backgroundThread cancel];
        }
        
        [self createAlertToWakeUpApp];
        
    }];
    
    
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self taskLoop];
        [app endBackgroundTask:self->_taskId];
    });
    DEBUG_FUNCEX();
}

- (void)runTask
{
    @synchronized (_backgroundTasks)
    {
        if (!self.atomicTaskRunning)
        {
            self.atomicTaskRunning = YES;
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
        return [_orderedTaskKeys copy];
    }
}
- (AlarmTask __strong *)taskForKey:(NSString *)key
{
    @synchronized (_backgroundTasks)
    {
        return _backgroundTasks[key];
    }
}

- (void)userAlertForProximity:(UIViewController *)parent source:(UIView *)source completion:(void (^)(bool cancelled, bool accurate))completionHandler
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Proximity Alarm", @"alarm alert title")
                                                                   message:[NSString stringWithFormat:
                                                                            NSLocalizedString(@"PDX Bus will track your locaton "
                                                                                              " and alert"
                                                                                              " you when you get within %@ of the stop.",
                                                                                              @"alert question"),
                                                                            kUserDistanceProximity]
                                                            preferredStyle:UIAlertControllerStyleAlert];
        
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"button text") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
        completionHandler(FALSE, NO);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:^(UIAlertAction* action){
        completionHandler(YES, NO);
    }]];
    
    
    
    // Make a small rect in the center, just 10,10
    const CGFloat side = 10;
    CGRect frame = source.frame;
    CGRect sourceRect = CGRectMake((frame.size.width - side)/2.0, (frame.size.height-side)/2.0, side, side);
    
    alert.popoverPresentationController.sourceView = source;
    alert.popoverPresentationController.sourceRect = sourceRect;
    
    
    [parent presentViewController:alert animated:YES completion:nil];
    
}

@end

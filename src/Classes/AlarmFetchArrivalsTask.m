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
#import "AlarmTaskList.h"
#import "DepartureData+iOSUI.h"


#define kTolerance    30

@implementation AlarmFetchArrivalsTask

- (void)dealloc
{
    
    self.observer        = nil;
    
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.alarmState = AlarmStateFetchArrivals;
    }
    return self;
}



- (NSDate *)fetch:(AlarmTaskList*)parent
{
    bool taskDone            = NO;
    NSDate *departureDate    = nil;
    NSTimeInterval waitTime;
    NSDate *    next        = nil;
    
    [self.departures getDeparturesForLocation:self.stopId block:self.block];
    
    if (self.departures.gotData && self.departures.count >0)
    {
        @synchronized (self.lastFetched)
        {
            self.lastFetched = self.departures[0];
        }
        _queryTime = self.departures.queryTime;
    }
    else if (self.lastFetched == nil)
    {
        [self alert:NSLocalizedString(@"PDX Bus was not able to get the time for this arrival", @"arrival alarm error")
           fireDate:nil
             button:nil
           userInfo:nil
       defaultSound:YES
         thisThread:NO];
        taskDone = YES;
    }
    else
    {
        departureDate = self.lastFetched.departureTime;
        
        
        // No new data here - the bus has probably come by this point.  If it has then this is the time to stop.
        if (departureDate == nil || [departureDate compare:[NSDate date]] != NSOrderedDescending)
        {
            taskDone = YES;
        }
    }
    
    if (!taskDone)
    {
        departureDate    = self.lastFetched.departureTime;
        waitTime        = departureDate.timeIntervalSinceNow;
        
#ifdef DEBUG_ALARMS
        DEBUG_LOG(@"Dep time %@\n", [NSDateFormatter localizedStringFromDate:departureDate
                                                                   dateStyle:NSDateFormatterMediumStyle
                                                                   timeStyle:NSDateFormatterLongStyle]);
#endif
        
        if (self.observer)
        {
            self.display = nil;
            [self.observer taskUpdate:self];
        }
        
        // Update the alert with the time we have
        NSDate *alarmTime = [departureDate dateByAddingTimeInterval:(NSTimeInterval)(-(NSTimeInterval)(self.minsToAlert * 60.0 + 30.0))];
        NSString *alertText = nil;
        
        if (self.minsToAlert <= 0)
        {
            alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" is due at %@", @"alarm message"),
                         self.lastFetched.shortSign,
                         self.lastFetched.locationDesc
                         ];
        }
        else if (self.minsToAlert == 1)
        {
            alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" 1 minute way from %@", @"alarm message"),
                         self.lastFetched.shortSign,
                         self.lastFetched.locationDesc
                         ];
        }
        else
        {
            alertText = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" is %d minutes away from %@", @"alarm message"),
                         self.lastFetched.shortSign,
                         self.minsToAlert,
                         self.lastFetched.locationDesc
                         ];
        }
        
        // if (self.alarm == nil) //  || ![self.alarm.fireDate isEqualToDate:alarmTime])
        {
            [self alert:alertText
               fireDate:alarmTime
                 button:NSLocalizedString(@"Show arrivals", @"alert text")
               userInfo:@{
                          kStopIdNotification   : self.stopId,
                          kAlarmBlock           : self.block }
           defaultSound:NO
             thisThread:NO];
        }
        
        
        int secs = (waitTime - (self.minsToAlert * 60));
        bool late = NO;
        
        if (self.lastFetched && self.lastFetched.notToSchedule)
        {
            DEBUG_LOG(@"not to schedule");
            NSDate *scheduled = self.lastFetched.scheduledTime;
            
            NSTimeInterval scheduledWait = scheduled.timeIntervalSinceNow;
            
            int scheduledSecs = scheduledWait - self.minsToAlert;
            
            if (scheduledSecs > 0)  // Scheduled time is in the future.
            {
                if (scheduledSecs < secs)  // Vehicle is late!
                {
                    DEBUG_LOG(@"using scheduled time as vehicle is late");
                    secs = scheduledSecs;     // Use the scheduled time of the vehicle is late as it may catch up.
                }
                else
                {
                    DEBUG_LOG(@"using estimated time as vehicle is early");
                }
            }
            else if (secs > 0)
            {
                late = YES;         // it is after the scheduled time so it is actually late now.
                DEBUG_LOG(@"vehicle is now late");
            }
        }
        
        DEBUG_LOGL(secs);
        
#define secs_in_mins(x) ((x)*60.0)
#define UPPER_MINS (20.0)
        
        // There is an upper limit to how long we will wait before checking.
        // That time is the UPPER_MINS/2.
        // Between 2 mins and the UPPER_MINS we wait a time proportional to how long we have left, but if
        // the vehicle is actually late already we wait an even shorter time as it may
        // catch up.
        
        if (secs > secs_in_mins(UPPER_MINS))
        {
            if (late)
            {
                next = [NSDate dateWithTimeIntervalSinceNow:secs_in_mins(UPPER_MINS/3)];
            }
            else
            {
                next = [NSDate dateWithTimeIntervalSinceNow:secs_in_mins(UPPER_MINS/2)];
            }
        }
        else if (secs > secs_in_mins(2))
        {
            // 2 to 15 mins late
            if (late)
            {
                // check a little earlier if it is late as it might catch up.
                next = [NSDate dateWithTimeIntervalSinceNow:secs/3];
            }
            else
            {
                next = [NSDate dateWithTimeIntervalSinceNow:secs/2];
            }
        }
        else if (secs > secs_in_mins(1))
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
    
    DEBUG_LOGO(next);
    
#ifdef DEBUG_ALARMS
#define kLastFetched @"LF"
#define kNextFetch @"NF"
#define kAppState @"AppState"
    NSDictionary *dict = @{
                           kLastFetched     : self.lastFetched,
                           kNextFetch       : (next ? next : [NSDate date]),
                           kAppState        : [self appState] };
    [self.dataReceived addObject:dict];
#endif
    
    
    return next;
}

- (void)startTask
{
    self.departures = [XMLDepartures xml];
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
    return (int)self.dataReceived.count+1;
}

- (NSString *)internalData:(int)item
{
    NSMutableString *str = [NSMutableString string];
    
    
    if (item == 0)
    {
        UIApplication*    app = [UIApplication sharedApplication];
        [str appendFormat:@"alerts: %u", (int)app.scheduledLocalNotifications.count];
    }
    else
    {
        NSDictionary *dict = self.dataReceived[item-1];
        DepartureData *dep = dict[kLastFetched];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
        
        [str appendFormat:@"%@\n", dep.routeName];
        [str appendFormat:@"mins %d\n", dep.minsToArrival];
        [str appendFormat:@"secs %lld\n", dep.secondsToArrival];
        
        [str appendFormat:@"QT %@\n", [dateFormatter stringFromDate:TriMetToNSDate(dep.queryTime)]];
        
        NSDate *departureDate    = TriMetToNSDate(dep.departureTime);
        NSDate *alarmTime = [departureDate dateByAddingTimeInterval:(NSTimeInterval)(-(NSTimeInterval)(self.minsToAlert * 60.0 + 30.0))];
        
        [str appendFormat:@"DT %@\n", [dateFormatter stringFromDate: departureDate ]];
        [str appendFormat:@"AT %@\n", [dateFormatter stringFromDate: alarmTime ]];
        [str appendFormat:@"NF %@\n", [dateFormatter stringFromDate: dict[kNextFetch]]];
        [str appendFormat:@"AS %@\n", dict[kAppState]];
    }
    return str;
    
}
#endif

- (void)showToUser:(BackgroundTaskContainer *)backgroundTask
{
    [[DepartureDetailView viewController] fetchDepartureAsync:backgroundTask location:self.stopId block:self.block backgroundRefresh:NO];
}

- (NSString *)cellToGo
{
    NSString *str = @"";
    @synchronized (self.lastFetched)
    {
        
        if (self.lastFetched !=nil)
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
            dateFormatter.timeStyle = NSDateFormatterShortStyle;
            NSDate *departureDate = self.lastFetched.departureTime;
            
            NSTimeInterval secs = ((double)self.minsToAlert * (-60.0));
            
            NSDate *alarmDate = [NSDate dateWithTimeInterval:secs sinceDate:departureDate];
            if (self.alarmState == AlarmFired)
            {
                str = [NSString stringWithFormat:NSLocalizedString(@"Alarm sounded at %@", @"Alarm was done at time {time}"), [dateFormatter stringFromDate: alarmDate]];
            }
            else
            {
                switch (self.minsToAlert)
                {
                    case 0:
                        str = [NSString stringWithFormat:NSLocalizedString(@"Arrival at %@", @"Alarm will be done at time {time}"), [dateFormatter stringFromDate: departureDate]];
                        break;
                    case 1:
                        str = [NSString stringWithFormat:NSLocalizedString(@"1 min before arrival at %@", @"Alarm will be done at time {time}"), [dateFormatter stringFromDate: departureDate], self.display];
                        break;
                    default:
                        str = [NSString stringWithFormat:NSLocalizedString(@"%d mins before arrival at %@", @"Alarm will be done at time {time}"), self.minsToAlert, [dateFormatter stringFromDate: departureDate]];
                        break;
                }
                
                if (self.display)
                {
                    str = [str stringByAppendingFormat:@" (%@)", self.display];
                }
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




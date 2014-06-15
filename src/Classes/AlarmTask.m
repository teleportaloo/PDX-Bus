//
//  AlarmTask.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "AlarmTask.h"
#import "RootViewController.h"
#import "DepartureTimesView.h"
#import "AlarmNotification.h"
#import "DebugLogging.h"
#import "AlarmCell.h"
#import "ViewControllerBase.h"



@implementation AlarmTask

@synthesize desc                    = _desc;
@synthesize alarmState              = _alarmState;
@synthesize stopId                  = _stopId;
@synthesize observer                = _observer;
@synthesize alarm                   = _alarm;
@synthesize nextFetch               = _nextFetch;
@synthesize alarmWarningDisplayed   = _alarmWarningDisplayed;
@dynamic    threadReferenceCount;

#ifdef DEBUG_ALARMS
@synthesize dataReceived	= _dataReceived;
#endif



- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	return;
}

- (void)dealloc
{
	self.stopId			= nil;
	self.desc			= nil;
	self.alarm			= nil;
	self.nextFetch		= nil;
	
#ifdef DEBUG_ALARMS
	self.dataReceived	= nil;
#endif
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
#ifdef DEBUG_ALARMS
		self.dataReceived = [[NSMutableArray alloc] init];
#endif
        self.alarmWarningDisplayed = NO;
	}
	return self;
}

- (NSString *)key
{
	return @"";
}

- (void)cancelTask
{
	
}

- (void)startTask
{
	[self.observer taskStarted:self];
}

- (void)dumpAlerts:(NSString *)dump
{
#ifdef DEBUGLOGGING
	DEBUG_LOG(@"Alerts: %@\n", dump);
	
	UIApplication*    app = [UIApplication sharedApplication];
	
	NSArray *alerts = [app scheduledLocalNotifications];
	
	if (alerts)
	{
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		
		DEBUG_LOG(@"Notifications %lu\n", (unsigned long)(unsigned long)alerts.count);
	
		for (UILocalNotification *notif in alerts)
		{
			DEBUG_LOG(@"Notif %@ %@\n", notif.alertBody, [dateFormatter stringFromDate:notif.fireDate]);
		}
	}
#endif
}

- (void)cancelNotification
{
	UIApplication*    app = [UIApplication sharedApplication];
	
#ifdef DEBUGLOGGING 
	[self dumpAlerts:@"before!"];
#endif

	if (self.alarm != nil)
	{
		DEBUG_LOG(@"Attempting to cancel %@\n", self.alarm.alertBody);
		[app cancelLocalNotification:self.alarm];
		
		NSArray *notifications = [app scheduledLocalNotifications];
		
		for (UILocalNotification *notif in notifications)
		{
			if ([notif.alertBody isEqualToString:self.alarm.alertBody])
			{
				[app cancelLocalNotification:notif];
			}
		}
	}
#ifdef DEBUGLOGGING 
	[self dumpAlerts:@"deleted!"];
#endif	
	
}

- (void)alert:(NSString *)string 
	 fireDate:(NSDate*)fireDate button:(NSString *)button userInfo:(NSDictionary *)userInfo 
 defaultSound:(bool)defaultSound;
{
	UIApplication*    app = [UIApplication sharedApplication];
    UserPrefs   *prefs = [UserPrefs getSingleton];

	
	[self cancelNotification];
	
	DEBUG_LOG(@"Alert: %@ \nuserInfo %d \nbutton %@ \ndefault sound %d\n",
			  string, userInfo !=nil, button, defaultSound);
    
    NSDateFormatter *alertDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [alertDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [alertDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSDate *displayDate = fireDate;
    
    if (displayDate == nil)
    {
        displayDate = [NSDate date];
    }
    
    NSString *approx = @"";
    
    if ([displayDate timeIntervalSinceNow] > (10.0 * 60.0))
    {
        approx = NSLocalizedString(@"Approximately ", "aproximately prefix before a date");
    }
	
	// Create a new notification
	self.alarm = [[[UILocalNotification alloc] init] autorelease];
	self.alarm.fireDate						= fireDate;
	self.alarm.timeZone						= [NSTimeZone defaultTimeZone];
	self.alarm.repeatInterval				= 0;
	self.alarm.repeatCalendar				= nil;
	self.alarm.soundName					= defaultSound ? UILocalNotificationDefaultSoundName : [prefs alarmSoundFile] ;
	self.alarm.alertBody					= [NSString stringWithFormat:@"%@%@ %@",
                                               approx,
                                               [alertDateFormatter stringFromDate:displayDate], 
                                               string];
	self.alarm.hasAction					= (userInfo != nil) || (button !=nil);
	self.alarm.userInfo						= userInfo;
	self.alarm.alertAction					= button;
	self.alarm.applicationIconBadgeNumber	= 0;
	
	if (fireDate == nil)
	{
		[app presentLocalNotificationNow:self.alarm];
	}
	else 
	{
#ifdef DEBUG_ALARMS
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		
		DEBUG_LOG(@"Alert time %@\n", [dateFormatter stringFromDate:fireDate]);
#endif
		
		[app scheduleLocalNotification:self.alarm];
	}
	
	[self dumpAlerts:@"done!"];
}

- (NSString *)cellDescription
{
#if 0
	NSString *locStr = nil;
	switch(self.locationNeeded)
	{
		case AlarmNoLocationNeeded:
			locStr = @"N";
			break;
		case AlarmAccurateLocationNeeded:
			locStr = @"A";
			break;
		case AlarmInaccurateLocationNeeded:
			locStr = @"I";
			break;
		case AlarmFired:
			locStr = @"F";
			break;
	}
	return [NSString stringWithFormat:@"%@ %@", locStr, self.desc];
#else
	return self.desc;
#endif
}

- (NSString *)cellToGo
{
	return @"";
}


- (int)internalDataItems
{
	return 0;
}

- (NSString *)internalData:(int)item
{
	return nil;
}

- (NSDate *)fetch
{
	return nil;
}

- (void)showToUser:(BackgroundTaskContainer *)backgroundTask
{
	
}

- (NSString *)icon
{
	switch (self.alarmState)
	{
		case AlarmStateFetchArrivals:
		case AlarmStateNearlyArrived:
		case AlarmStateAccurateLocationNeeded:
		case AlarmStateAccurateInitiallyThenInaccurate:
		case AlarmStateInaccurateLocationNeeded:
            return kIconAlarm;
		case AlarmFired:
			return kIconAlarmFired;
	}
	return nil;
}

- (UIColor *)color
{
	switch (self.alarmState)
	{
		case AlarmStateFetchArrivals:
		case AlarmStateNearlyArrived:
			return [UIColor blueColor];
		case AlarmStateAccurateLocationNeeded:
		case AlarmStateAccurateInitiallyThenInaccurate:
			return [UIColor orangeColor];
		case AlarmStateInaccurateLocationNeeded:
		case AlarmFired:
			return [UIColor redColor];
	}
	return nil;
	
}

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
	return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

- (void)accessoryButtonTapped:(UIButton *)button withEvent:(UIControlEvents)event
{
    [self.observer taskDone:self];
}

- (void)populateCell:(AlarmCell *)cell
{
    if (self.alarmState == AlarmFired)
    {
        cell.fired = YES;
        
        
        UIImage *image = [ViewControllerBase alwaysGetIcon:kIconDelete];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        button.frame = frame;
        [button setBackgroundImage:image forState:UIControlStateNormal];

        [button addTarget: self
                   action: @selector(accessoryButtonTapped:withEvent:)
         forControlEvents: UIControlEventTouchUpInside];
            

#ifdef DEBUG_ALARMS
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#else
        cell.accessoryView = button;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif

    }
    else
    {
        cell.fired = NO;
        cell.accessoryView = nil;
#ifdef DEBUG_ALARMS
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#else
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

#endif
    }
    
	[cell populateCellLine1:self.cellDescription line2:self.cellToGo line2col:[self color]];

}

- (int)threadReferenceCount
{
	return 0;
}

- (NSDate *)earlierAlert:(NSDate *)alert
{
	if (self.alarm && self.alarm.fireDate  && self.nextFetch)
	{
		return [[alert earlierDate:self.alarm.fireDate] earlierDate:self.nextFetch];
	}
	
	return alert;
}

- (void)showMap:(UINavigationController *)navController
{
    
}

- (NSString*)appState
{
    NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
#define CASE_ENUM_TO_STR(X)  case X: [str appendFormat:@"%s", #X]; break
    UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    
    switch (appState)
    {
            CASE_ENUM_TO_STR(UIApplicationStateActive);
            CASE_ENUM_TO_STR(UIApplicationStateInactive);
            CASE_ENUM_TO_STR(UIApplicationStateBackground);
        default:
            [str appendFormat:@"%d\n", (int)appState];
    }
    
    return str;
    
}


@end

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
#import "MainQueueSync.h"
#import "Icons.h"
#import <UserNotifications/UserNotifications.h>

#define CatString(X) @ #X

@interface AlarmTask ()

@property (strong)                   UNNotificationRequest *alarm;
@property (readonly, nonatomic)      int threadReferenceCount;
@property (nonatomic)                bool alarmWarningDisplayed;
@property (nonatomic, readonly, copy) NSString *cellDescription;
@property (nonatomic, readonly, copy) NSString *cellToGo;

@property (nonatomic, readonly, copy) UIColor *color;

@end

@implementation AlarmTask

@dynamic    threadReferenceCount;

- (void)dealloc {
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    return;
}

- (instancetype)init {
    if ((self = [super init])) {
#ifdef DEBUG_ALARMS
        self.dataReceived = [[NSMutableArray alloc] init];
#endif
        self.alarmWarningDisplayed = NO;
    }
    
    return self;
}

- (NSString *)key {
    return @"";
}

- (void)cancelTask {
}

- (void)startTask {
    [self.observer taskStarted:self];
}

- (NSString *)buttonText:(AlarmButton)button
{
    switch (button)
    {
        default:
        case AlarmButtonNone:
            return nil;
            break;
        case AlarmButtonMap:
            return NSLocalizedString(@"Show map", @"Back text");
        case AlarmButtonBack:
            return NSLocalizedString(@"Back to PDX Bus", @"Button to return to PDX Bus");
        case AlarmButtonDepartures:
            return NSLocalizedString(@"Show departures", @"alert text");
    }
}

- (NSString *)buttonCat:(AlarmButton)button
{
    switch (button)
    {
        default:
        case AlarmButtonNone:           return nil;
        case AlarmButtonMap:            return CatString(AlarmButtonMap);
        case AlarmButtonBack:           return CatString(AlarmButtonBack);
        case AlarmButtonDepartures:     return CatString(AlarmButtonDepartures);
    }
}

- (void)dumpAlerts:(NSString *)dump {
#ifdef DEBUGLOGGING
    DEBUG_LOG(@"Alerts: %@\n", dump);
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        if (requests) {
            DEBUG_LOG(@"Notifications %lu\n", (unsigned long)requests.count);
            
            for (UNNotificationRequest *notif in requests) {
                if ( [notif.trigger isKindOfClass:[UNTimeIntervalNotificationTrigger class]])
                {
                
                    UNTimeIntervalNotificationTrigger *trigger = (UNTimeIntervalNotificationTrigger *)notif.trigger;
                
                    DEBUG_LOG(@"Notif %@ %@\n", notif.content.body,
                          [NSDateFormatter localizedStringFromDate:trigger.nextTriggerDate
                                                         dateStyle:NSDateFormatterMediumStyle
                                                         timeStyle:NSDateFormatterLongStyle]);
                }
            }
        }
    }];
#endif
}


- (void)cancelNotification {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

#ifdef DEBUGLOGGING
    [self dumpAlerts:@"before!"];
#endif
    
    if (self.alarm != nil) {
        [center removePendingNotificationRequestsWithIdentifiers:[NSArray arrayWithObject:self.alarm.identifier]];
    }
        
#ifdef DEBUGLOGGING
        [self dumpAlerts:@"deleted!"];
#endif
}

- (UNNotificationCategory *)catForButton:(AlarmButton)button
{
    return [UNNotificationCategory categoryWithIdentifier:[self buttonCat:button]
                                                  actions:@[[UNNotificationAction
                                                             actionWithIdentifier:[self buttonCat:button]
                                                             title:[self buttonText:button]
                                                             options:UNNotificationActionOptionForeground]]
                                        intentIdentifiers:@[]
                                                  options:UNNotificationCategoryOptionNone];
}

- (void)   alert:(NSString *)string
        fireDate:(NSDate *)fireDate
          button:(AlarmButton)button
        userInfo:(NSDictionary *)userInfo
    defaultSound:(bool)defaultSound
      thisThread:(bool)thisThread {
    DEBUG_FUNC();
    DEBUG_LOGB(thisThread);
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *catagories = [NSMutableSet set];
        
            [catagories addObject:[self catForButton:AlarmButtonBack]];
            [catagories addObject:[self catForButton:AlarmButtonMap]];
            [catagories addObject:[self catForButton:AlarmButtonDepartures]];
        });
        
        [self cancelNotification];
        
        DEBUG_LOG(@"Alert: %@ \nuserInfo %d \nbutton %d \ndefault sound %d\n",
                  string, userInfo != nil, button, defaultSound);
        
        NSDate *displayDate = fireDate;
        
        if (displayDate == nil) {
            displayDate = [NSDate date];
        }
        
        NSString *approx = @"";
        
        // Create a new notification
        
        // nil case is now
        UNTimeIntervalNotificationTrigger *trigger = nil;
        
        if (fireDate != nil)
        {
            NSTimeInterval fireTime = [fireDate timeIntervalSinceNow];
            DEBUG_LOGF(fireTime);
            trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(fireTime > 0 ? fireTime : 1.0 )repeats:NO];
        }
        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        
        //  content.sound = defaultSound ? UILocalNotificationDefaultSoundName : Settings.alarmSoundFile;
        
        content.body = [NSString stringWithFormat:@"%@%@ %@",
                        approx,
                        [NSDateFormatter localizedStringFromDate:displayDate
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterShortStyle],
                        string];

        content.userInfo = userInfo;
        content.badge = nil;
        
        if (@available(iOS 12.0, *)) {
            content.sound = defaultSound            ? UNNotificationSound.defaultCriticalSound
                                                    : [UNNotificationSound criticalSoundNamed:Settings.alarmSoundFile];
        } else {
            // Fallback on earlier versions
            content.sound =  defaultSound           ? UNNotificationSound.defaultSound
                                                    : [UNNotificationSound soundNamed:Settings.alarmSoundFile];
            
        }
        
        content.categoryIdentifier = [self buttonCat:button];
        
        NSString *identifier = [NSString stringWithFormat:@"org.teleportaloo.PDXBus %p", self];
        
        self.alarm                              = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        // self.alarm.hasAction                    = (userInfo != nil) || (button != nil);
        // self.alarm.alertAction                  = button;
        
        [center addNotificationRequest:self.alarm withCompletionHandler:^(NSError * _Nullable error) {
            
        }];
        
    
        
        [self dumpAlerts:@"done!"];
    }];
    
    DEBUG_FUNCEX();
}

- (NSString *)cellDescription {
#if 0
    NSString *locStr = nil;
    switch (self.locationNeeded) {
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
    
#else // if 0
    return self.desc;
    
#endif // if 0
}

- (NSString *)cellToGo {
    return @"";
}

- (int)internalDataItems {
    return 0;
}

- (NSString *)internalData:(int)item {
    return nil;
}

- (NSDate *)fetch:(AlarmTaskList *)parent; {
    return nil;
}

- (void)showToUser:(BackgroundTaskContainer *)backgroundTask {
}

- (NSString *)icon {
    switch (self.alarmState) {
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

- (UIColor *)color {
    switch (self.alarmState) {
        case AlarmStateFetchArrivals:
        case AlarmStateNearlyArrived:
            return [UIColor modeAwareBlue];
            
        case AlarmStateAccurateLocationNeeded:
        case AlarmStateAccurateInitiallyThenInaccurate:
            return [UIColor orangeColor];
            
        case AlarmStateInaccurateLocationNeeded:
        case AlarmFired:
            return [UIColor redColor];
    }
    return nil;
}

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width {
    return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

- (void)accessoryButtonTapped:(UIButton *)button withEvent:(UIControlEvents)event {
    [self.observer taskDone:self];
}

- (void)populateCell:(AlarmCell *)cell {
    if (self.alarmState == AlarmFired) {
        cell.fired = YES;
        
        
        UIImage *image = [Icons getIcon:kIconDelete];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        button.frame = frame;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        
        [button    addTarget:self
                      action:@selector(accessoryButtonTapped:withEvent:)
            forControlEvents:UIControlEventTouchUpInside];
        
        
#ifdef DEBUG_ALARMS
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#else
        cell.accessoryView = button;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
    } else {
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

- (int)threadReferenceCount {
    return 0;
}

- (NSDate *)earlierAlert:(NSDate *)alert {
    
    if (self.alarm && self.alarm.trigger && self.nextFetch)
    {
        if ([self.alarm.trigger isKindOfClass:[UNTimeIntervalNotificationTrigger class]]) {
            UNTimeIntervalNotificationTrigger *trigger = (UNTimeIntervalNotificationTrigger *)self.alarm.trigger;
            
            return [[alert earlierDate:trigger.nextTriggerDate] earlierDate:self.nextFetch];
        }
    }
    
    return alert;
}

- (void)showMap:(UINavigationController *)navController {
}

- (NSString *)appState {
    NSMutableString *str = [NSMutableString string];
    
#define CASE_ENUM_TO_STR(X) case X:[str appendFormat:@"%s", #X]; break
    
    __block UIApplicationState appState;
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        appState = [UIApplication sharedApplication].applicationState;
    }];
    
    switch (appState) {
            CASE_ENUM_TO_STR(UIApplicationStateActive);
            CASE_ENUM_TO_STR(UIApplicationStateInactive);
            CASE_ENUM_TO_STR(UIApplicationStateBackground);
            
        default:
            [str appendFormat:@"%d\n", (int)appState];
    }
    
    return str;
}

@end

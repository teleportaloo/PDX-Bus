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


#define DEBUG_LEVEL_FOR_FILE LogAlarms

#import "AlarmTask.h"
#import "AlarmCell.h"
#import "AlarmNotification.h"
#import "DebugLogging.h"
#import "DepartureTimesViewController.h"
#import "Icons.h"
#import "MainQueueSync.h"
#import "RootViewController.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "UIAlertController+SimpleMessages.h"
#import "ViewControllerBase.h"
#import <UserNotifications/UserNotifications.h>

#define CatString(X) @ #X

@interface AlarmTask ()

@property (strong) UNNotificationRequest *notifReq;
@property (readonly, nonatomic) int threadReferenceCount;
@property (nonatomic) bool alarmWarningDisplayed;
@property (nonatomic, readonly, copy) NSString *cellDescription;
@property (nonatomic, readonly, copy) NSString *cellToGo;

@property (nonatomic, readonly, copy) UIColor *color;

@end

@implementation AlarmTask

@dynamic threadReferenceCount;

- (instancetype)init {
    if ((self = [super init])) {
#ifdef DEBUG_ALARMS
        _dataReceived = [[NSMutableArray alloc] init];
#endif // DEBUG_ALARMS
        _alarmWarningDisplayed = NO;
    }

    return self;
}

- (void)dealloc {
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    return;
}

- (NSString *)key {
    return @"";
}

- (void)cancelTask {
}

- (void)startTask {
    [self.observer taskStarted:self];
}

- (NSString *)buttonText:(AlarmButton)button {
    switch (button) {
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

- (NSString *)buttonCat:(AlarmButton)button {
    switch (button) {
    default:
    case AlarmButtonNone:
        return nil;
    case AlarmButtonMap:
        return CatString(AlarmButtonMap);
    case AlarmButtonBack:
        return CatString(AlarmButtonBack);
    case AlarmButtonDepartures:
        return CatString(AlarmButtonDepartures);
    }
}

- (void)dumpAlerts:(NSString *)dump {
#ifdef DEBUGLOGGING
    DEBUG_LOG(@"Alerts: %@\n", dump);

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center getPendingNotificationRequestsWithCompletionHandler:^(
                NSArray<UNNotificationRequest *> *_Nonnull requests) {
      if (requests) {
          DEBUG_LOG(@"Notifications %lu\n", (unsigned long)requests.count);

          for (UNNotificationRequest *notif in requests) {
              if ([notif.trigger isKindOfClass:[UNTimeIntervalNotificationTrigger class]]) {

                  UNTimeIntervalNotificationTrigger *trigger =
                      (UNTimeIntervalNotificationTrigger *)notif.trigger;

                  DEBUG_LOG(@"Notif %@ %@\n",
                            notif.content.body,
                            [NSDateFormatter localizedStringFromDate:trigger.nextTriggerDate
                                                           dateStyle:NSDateFormatterMediumStyle
                                                           timeStyle:NSDateFormatterLongStyle]);
              }
          }
      }
    }];
#endif // DEBUGLOGGING
}

- (void)cancelNotification {

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

#ifdef DEBUGLOGGING
    [self dumpAlerts:@"before!"];
#endif // DEBUGLOGGING

    if (self.notifReq != nil) {
        DEBUG_LOG_NSString(self.notifReq.identifier);
        [center removePendingNotificationRequestsWithIdentifiers:@[ self.notifReq.identifier ]];
        self.notifReq = nil;
    }

#ifdef DEBUGLOGGING
    [self dumpAlerts:@"deleted!"];
#endif // DEBUGLOGGING
}

- (UNNotificationCategory *)catForButton:(AlarmButton)button {
    return [UNNotificationCategory
        categoryWithIdentifier:[self buttonCat:button]
                       actions:@[ [UNNotificationAction
                                   actionWithIdentifier:[self buttonCat:button]
                                                  title:[self buttonText:button]
                                                options:UNNotificationActionOptionForeground] ]
             intentIdentifiers:@[]
                       options:UNNotificationCategoryOptionNone];
}

- (void)alert:(NSString *)string
        fireDate:(NSDate *)fireDate
          button:(AlarmButton)button
        userInfo:(NSDictionary *)userInfo
    defaultSound:(bool)defaultSound
      thisThread:(bool)thisThread {
    DEBUG_FUNC();
    DEBUG_LOG_BOOL(thisThread);

    MAIN_TASK((^{
      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

      [self cancelNotification];

      DEBUG_LOG(@"Alert: %@ \nuserInfo %d \nbutton %d \ndefault sound %d\n",
                string,
                userInfo != nil,
                button,
                defaultSound);

      NSDate *displayDate = fireDate;

      if (displayDate == nil) {
          displayDate = [NSDate date];
      }

      NSString *approx = @"";

      // Create a new notification

      // nil case is now
      UNTimeIntervalNotificationTrigger *trigger = nil;

      if (fireDate != nil) {
          NSTimeInterval fireTime = [fireDate timeIntervalSinceNow];
          DEBUG_LOG_double(fireTime);
          trigger = [UNTimeIntervalNotificationTrigger
              triggerWithTimeInterval:(fireTime > 0 ? fireTime : 1.0)
                              repeats:NO];
      }

      UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];

      content.body = [NSString
          stringWithFormat:@"%@%@ %@",
                           approx,
                           [NSDateFormatter localizedStringFromDate:displayDate
                                                          dateStyle:NSDateFormatterNoStyle
                                                          timeStyle:NSDateFormatterShortStyle],
                           string];

      content.userInfo = userInfo;
      content.badge = nil;

      content.sound = defaultSound
                          ? UNNotificationSound.defaultCriticalSound
                          : [UNNotificationSound criticalSoundNamed:Settings.alarmSoundFile];

      content.categoryIdentifier = [self buttonCat:button];

      content.interruptionLevel = UNNotificationInterruptionLevelTimeSensitive;

      NSString *identifier = [NSString stringWithFormat:@"org.teleportaloo.PDXBus %p", self];

      self.notifReq = [UNNotificationRequest requestWithIdentifier:identifier
                                                           content:content
                                                           trigger:trigger];

      [center addNotificationRequest:self.notifReq
               withCompletionHandler:^(NSError *_Nullable error){

               }];

      [self dumpAlerts:@"done!"];
    }));

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

- (void)internalData:(int)item completion:(void (^)(NSString *))completionHandler {
    completionHandler(nil);
}

- (NSDate *)fetch:(AlarmTaskList *)parent;
{ return nil; }

- (void)showToUser:(BackgroundTaskContainer *)backgroundTask {
}

- (BoxedIcon *)icon {
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

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(CGFloat)width {
    return [NSString stringWithFormat:@"%@-%f", identifier, width];
}

- (void)accessoryButtonTapped:(UIButton *)button withEvent:(UIControlEvents)event {
    [self.observer taskDone:self];
}

- (void)populateCell:(AlarmCell *)cell {
    if (self.alarmState == AlarmFired) {
        cell.fired = YES;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

        UIImage *image = kIconDelete.image;
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        button.frame = frame;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        button.tintColor = kIconDelete.tint;

        [button addTarget:self
                      action:@selector(accessoryButtonTapped:withEvent:)
            forControlEvents:UIControlEventTouchUpInside];

#ifdef DEBUG_ALARMS
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#else
        cell.accessoryView = button;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif // DEBUG_ALARMS
    } else {
        cell.fired = NO;
        cell.accessoryView = nil;
#ifdef DEBUG_ALARMS
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#else
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

#endif // DEBUG_ALARMS
    }

    [cell populateCellLine1:self.cellDescription line2:self.cellToGo line2col:[self color]];
}

- (int)threadReferenceCount {
    return 0;
}

- (NSDate *)earlierAlert:(NSDate *)alert {
    if (self.notifReq && self.notifReq.trigger && self.nextFetch) {
        if ([self.notifReq.trigger isKindOfClass:[UNTimeIntervalNotificationTrigger class]]) {
            UNTimeIntervalNotificationTrigger *trigger =
                (UNTimeIntervalNotificationTrigger *)self.notifReq.trigger;

            return [[(alert ?: NSDate.distantFuture) earlierDate:trigger.nextTriggerDate]
                earlierDate:self.nextFetch];
        }
    }

    return alert;
}

- (void)showMap:(UINavigationController *)navController {
    [UIAlertController simpleOkWithTitle:@"No map"
                                 message:@"No map to show"
                          viewController:navController
                              completion:nil];
}

- (NSString *)appState {
    NSMutableString *str = [NSMutableString string];

#define CASE_ENUM_TO_STR(X)                                                                        \
    case X:                                                                                        \
        [str appendFormat:@"%s", #X];                                                              \
        break

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

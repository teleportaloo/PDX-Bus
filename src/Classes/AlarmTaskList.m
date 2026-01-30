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


#define DEBUG_LEVEL_FOR_FILE LogAlarms

#import "AlarmTaskList.h"
#import "AlarmAccurateStopProximity.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"
#import "PDXBusAppDelegate+Methods.h"
#import "TaskDispatch.h"
#import "UIAlertController+SimpleMessages.h"
#import <objc/runtime.h>

#if TARGET_OS_MACCATALYST
#import <UserNotifications/UserNotifications.h>
#endif // TARGET_OS_MACCATALYST

#define kExtraTimeForNotifcation 10

@interface AlarmTaskList () {
    NSMutableDictionary *_rawBackgroundTasks;
    NSMutableArray *_rawOrderedTaskKeys;
    NSMutableArray *_rawNewTaskKeys;
    AlarmTask *_rawWakeUpAlarm;
    NSMutableArray *_rawActiveTaskKeys;

    UIBackgroundTaskIdentifier _taskId;
    bool _batchUpdate;
    dispatch_queue_t _syncQueue;
}

@property (nonatomic, retain) CLLocationManager *manager;
@property (atomic, retain) dispatch_source_t pollTimer;

- (void)taskUpdate:(id)task;
- (void)taskDone:(id)task;
- (void)taskStarted:(id)task;

@end

@implementation AlarmTaskList

+ (AlarmTaskList *)sharedInstance {
    static AlarmTaskList *taskList = nil;

    DO_ONCE(^{
      taskList = [[AlarmTaskList alloc] init];
    });

    return taskList;
}

+ (bool)supported {
    UIDevice *device = [UIDevice currentDevice];
    BOOL backgroundSupported = device.multitaskingSupported;

    return backgroundSupported;
}

+ (bool)proximitySupported {
#if !TARGET_OS_MACCATALYST
    Class locManClass = (NSClassFromString(@"CLLocationManager"));

    return [AlarmTaskList supported] && locManClass != nil &&
           [locManClass significantLocationChangeMonitoringAvailable];

#else
    return NO;

#endif // !TARGET_OS_MACCATALYST
}

+ (NSString *)keyForStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir {
    return [NSString stringWithFormat:@"%@+%@+%@", stopId, block, dir];
}

- (instancetype)init {
    if ((self = [super init])) {
        _rawBackgroundTasks = NSMutableDictionary.dictionary;
        _rawOrderedTaskKeys = NSMutableArray.array;
        _rawNewTaskKeys = NSMutableArray.array;
        _taskId = 0; // UIBackgroundTaskInvalid cannot be used in 3.2 OS
        _rawActiveTaskKeys = NSMutableArray.array;
        _syncQueue = dispatch_queue_create("org.teleportaloo.pdxbus.alarmtask.sync",
                                           DISPATCH_QUEUE_CONCURRENT);

        [self updateBadge];
    }

    return self;
}

- (void)setApplicationBadgeNumber:(NSInteger)badgeNumber {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center
        getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
          if (settings.badgeSetting == UNNotificationSettingEnabled) {
              MAIN_TASK(^{
                UIApplication *application = [UIApplication sharedApplication];
                application.applicationIconBadgeNumber = badgeNumber;
              });
          }
        }];
}

- (void)updateBadge {
    int count = 0;

    NSArray *keys = [self taskKeys];

    for (NSString *key in keys) {
        AlarmTask *task = [self taskForKey:key];

        if (task && task.alarmState == AlarmFired) {
            count++;
        }
    }

    MAIN_TASK(^{
      [self setApplicationBadgeNumber:count];
    });
}

- (void)removeTask:(NSString *)taskKey fromArray:(NSMutableArray *)array {
    dispatch_barrier_async(_syncQueue, ^{
      for (int i = 0; i < array.count; i++) {
          NSString *arrayTaskKey = array[i];

          if ([arrayTaskKey isEqualToString:taskKey]) {
              [array removeObjectAtIndex:i];
              break;
          }
      }
    });
}

- (void)cancelTaskForKey:(NSString *)key {
    AlarmTask *task = [self taskForKey:key];

    if (task != nil) {
        [task cancelTask];
    }
}

- (void)checkForMute:(UIViewController *)controller {
    // Cannot check for mute so just warn the user!
    if (self.taskCount == 0) {
        [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"New Alarm", @"alarm pop-up title")
                      message:NSLocalizedString(@"Note: The alarm will not sound if the "
                                                @"device is muted.",
                                                @"alarm warning")
               viewController:controller
                   completion:nil];
    }
}

- (void)addTaskForDeparture:(Departure *)dep
                       mins:(uint)mins
                 controller:(UIViewController *)controller {
    AlarmFetchArrivalsTask *newTask = [[AlarmFetchArrivalsTask alloc] init];

    newTask.stopId = dep.stopId;
    newTask.block = dep.block;
    newTask.dir = dep.dir;
    newTask.minsToAlert = mins;
    newTask.observer = self;
    newTask.desc = dep.shortSign;
    newTask.lastFetched = dep;

    [self checkForMute:controller];

    [self cancelTaskForKey:newTask.key];

    dispatch_barrier_async(_syncQueue, ^{
      self->_rawBackgroundTasks[newTask.key] = newTask;
      [self->_rawOrderedTaskKeys addObject:newTask.key];
      [self->_rawNewTaskKeys addObject:newTask.key];
    });

    [newTask startTask];

    // Force a poll now to add the new task - it will rescehdule the next poll
    [self runTask];
}

- (bool)hasTaskForStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir {
    AlarmTask *task = [self taskForKey:[AlarmTaskList keyForStopId:stopId block:block dir:dir]];

    DEBUG_LOG_NSString(stopId);
    DEBUG_LOG_NSString(block);

    return task != nil;
}

- (int)minsForTaskWithStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir {
    AlarmTask *task = [self taskForKey:[AlarmTaskList keyForStopId:stopId block:block dir:dir]];

    if (task == nil || ![task isKindOfClass:[AlarmFetchArrivalsTask class]]) {
        return 0;
    }
    AlarmFetchArrivalsTask *arrivalsTask = (AlarmFetchArrivalsTask *)task;
    return (int)arrivalsTask.minsToAlert;
}

- (void)cancelTaskForStopId:(NSString *)stopId block:(NSString *)block dir:(NSString *)dir {
    NSString *key = [AlarmTaskList keyForStopId:stopId block:block dir:dir];

    [self cancelTaskForKey:key];
}

- (void)taskUpdate:(id)task {
    if (self.observer) {
        MAIN_TASK(^{
          [self.observer taskUpdate:task];
        });
    }

    AlarmTask *realTask = (AlarmTask *)task;

    if (realTask.alarmState == AlarmFired) {
        [self updateBadge];
    }

    _batchUpdate = YES;
}

- (void)taskStarted:(id)task {
    if (self.observer) {
        MAIN_TASK(^{
          [self.observer taskStarted:task];
        });
    }

    [self runTask];
    [self updateBadge];

    _batchUpdate = YES;
}

- (void)taskDone:(id)task {
    AlarmTask *realTask = (AlarmTask *)task;
    NSString *key = realTask.key;

    dispatch_barrier_async(_syncQueue, ^{
      [self->_rawBackgroundTasks removeObjectForKey:key];
    });

    [self removeTask:key fromArray:_rawNewTaskKeys];
    [self removeTask:key fromArray:_rawOrderedTaskKeys];

    if (self.observer) {
        MAIN_TASK(^{
          [self.observer taskDone:task];
        });
    }

    [self updateBadge];
    _batchUpdate = YES;
}

- (void)resumeOnActivate {
    dispatch_barrier_sync(_syncQueue, ^{
      if (self->_rawBackgroundTasks.count > 0) {
          [self->_rawNewTaskKeys removeAllObjects];

          for (NSString *taskKey in self->_rawBackgroundTasks) {
              AlarmTask *task = self->_rawBackgroundTasks[taskKey];
              switch (task.alarmState) {
              default:
              case AlarmStateAccurateInitiallyThenInaccurate:
              case AlarmStateAccurateLocationNeeded:
              case AlarmStateInaccurateLocationNeeded:
                  break;

              case AlarmStateFetchArrivals:
              case AlarmStateNearlyArrived:
              case AlarmFired:
                  [self->_rawNewTaskKeys addObject:task.key];
                  break;
              }
          }
      }
    });

    if (self.taskCount > 0) {
        [self runTask];
    }
}

- (void)addTaskForStopIdProximity:(NSString *)stopId
                              loc:(CLLocation *)loc
                             desc:(NSString *)desc
                         accurate:(bool)accurate
                       controller:(UIViewController *)controller {
    AlarmAccurateStopProximity *newTask =
        [[AlarmAccurateStopProximity alloc] initWithAccuracy:accurate];

    [newTask setStop:stopId loc:loc desc:desc];
    newTask.observer = self;

    [self checkForMute:controller];
    [self cancelTaskForKey:newTask.key];

    dispatch_barrier_async(_syncQueue, ^{
      self->_rawBackgroundTasks[newTask.key] = newTask;
      [self->_rawOrderedTaskKeys addObject:newTask.key];
    });

    [newTask startTask];
}

- (bool)hasTaskForStopIdProximity:(NSString *)stopId {
    return [self taskForKey:stopId] != nil;
}

- (void)cancelTaskForStopIdProximity:(NSString *)stopId {
    [self cancelTaskForKey:stopId];
}

- (void)startUpdatingLocation:(CLLocationManager *)manager {
    CLAuthorizationStatus status = [manager authorizationStatus];

    if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"Location services are disabled in settings.");
    } else {
        // for iOS 8

        [manager requestAlwaysAuthorization];
        [manager setAllowsBackgroundLocationUpdates:YES];

        [manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
#ifdef DEBUGLOGGING
    CLLocation *mostRecentLocation = locations.lastObject;
    DEBUG_LOG(@"Current location: %@ %@",
              @(mostRecentLocation.coordinate.latitude),
              @(mostRecentLocation.coordinate.longitude));
#endif // DEBUGLOGGING
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

    LOG_NSError(error);
}

- (NSDate *)poll {
    @autoreleasepool {
        NSDate *nextFetch = nil;
        [self startGps];

        __block NSArray *pollActiveTaskKeys = nil;
        NSMutableArray *doneTasks = NSMutableArray.array;

        // Here is where we check if new tasks have been added or removed
        dispatch_barrier_sync(_syncQueue, ^{
          // Add items from the new tasks into my active list
          [self->_rawActiveTaskKeys addObjectsFromArray:self->_rawNewTaskKeys];
          [self->_rawNewTaskKeys removeAllObjects];

          // Check to see that each key still has a task as it may have
          // been cancelled by the user
          for (int i = 0; i < self->_rawActiveTaskKeys.count;) {
              if (self->_rawBackgroundTasks[self->_rawActiveTaskKeys[i]] == nil) {
                  [self->_rawActiveTaskKeys removeObjectAtIndex:i];
              } else {
                  i++;
              }
          }

          pollActiveTaskKeys = self->_rawActiveTaskKeys.copy;

          [self->_rawWakeUpAlarm cancelNotification];
        });

        bool wakeUpAlertRequired = NO;

        for (NSString *key in pollActiveTaskKeys) {
            AlarmTask *task = [self taskForKey:key];

            if (task) {
                switch (task.alarmState) {
                case AlarmFired:
                    [doneTasks addObject:key];
                    [self taskUpdate:task];
                    break;

                case AlarmStateNearlyArrived:
                    if (task.nextFetch == nil ||
                        [task.nextFetch compare:[NSDate date]] != NSOrderedDescending) {
                        task.alarmState = AlarmFired;
                        [doneTasks addObject:key];
                        [self taskUpdate:task];
                    }

                    break;

                case AlarmStateFetchArrivals:
                    if (task.nextFetch == nil ||
                        [task.nextFetch compare:[NSDate date]] != NSOrderedDescending) {
                        task.nextFetch = [task fetch:self];
                        if (task.alarmState == AlarmFired) {
                            [doneTasks addObject:key];
                        }
                        [self taskUpdate:task];
                    }
                    break;

                default:
                    break;
                }
                nextFetch = [task earlierAlert:nextFetch];

                if (task.alarmState == AlarmStateFetchArrivals) {
                    wakeUpAlertRequired = YES;
                }
            }
        }

        for (NSString *key in doneTasks) {
            [self removeTask:key fromArray:self->_rawActiveTaskKeys];
        }

        __block NSInteger activeCount = 0;
        dispatch_sync(_syncQueue, ^{
          activeCount = self->_rawActiveTaskKeys.count;
        });

        if (activeCount > 0 && nextFetch) {
            if (wakeUpAlertRequired) {
                [self createAlertToWakeUpApp:nextFetch];
            } else {
                DEBUG_LOG(@"No wakeup alarm required");
            }
        } else {
            dispatch_barrier_async(_syncQueue, ^{
              [self->_rawWakeUpAlarm cancelNotification];
              self->_rawWakeUpAlarm = nil;
            });
        }

        if (activeCount == 0) {
            [self stopGps];
        }

        DEBUG_LOG_double([nextFetch timeIntervalSinceNow]);
        return nextFetch;
    }
}

- (void)createAlertToWakeUpApp:(NSDate *)nextFetch {
    if (nextFetch) {
        NSDictionary *ignore = @{kDoNotDisplayIfActive : kDoNotDisplayIfActive};

        DEBUG_LOG(@"Alert in %f", [nextFetch timeIntervalSinceNow]);

        dispatch_barrier_async(_syncQueue, ^{
          if (self->_rawWakeUpAlarm == nil) {
              self->_rawWakeUpAlarm = [AlarmTask new];
          }
          [self->_rawWakeUpAlarm
                     alert:NSLocalizedString(@"iOS has stopped PDX Bus from checking "
                                             @"departures, making alarms inaccurate. "
                                             @"Please restart PDX Bus so it can update the "
                                             @"departure alarms.",
                                             @"alarm alert")
                  fireDate:[nextFetch dateByAddingTimeInterval:kExtraTimeForNotifcation]
                    button:AlarmButtonBack
                  userInfo:ignore
              defaultSound:NO
                thisThread:NO];
        });
    }
}

- (void)schedulePollIn:(NSTimeInterval)interval {
    // Tear down any previous timer
    if (self.pollTimer) {
        dispatch_source_cancel(self.pollTimer);
        self.pollTimer = nil;
    }

    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                              DISPATCH_TIME_FOREVER,
                              0);
    dispatch_source_set_event_handler(timer, ^{
      if (self.pollTimer) {
          dispatch_source_cancel(self.pollTimer);
          self.pollTimer = nil;
      }
      NSDate *next = [self poll];
      if (next != nil) {
          [self schedulePollIn:[next timeIntervalSinceNow]];
      }
    });
    dispatch_resume(timer);
    self.pollTimer = timer; // keep a strong reference
}

- (void)startGps {
    if (self.manager == nil) {
        DEBUG_HERE();
        self.manager = [[CLLocationManager alloc] init];
        self.manager.delegate = self;
        self.manager.allowsBackgroundLocationUpdates = YES;
        self.manager.desiredAccuracy = kCLLocationAccuracyKilometer;
        self.manager.pausesLocationUpdatesAutomatically = NO;
        self.manager.activityType = CLActivityTypeOtherNavigation;
        [self startUpdatingLocation:self.manager];
    }
}

- (void)stopGps {
    if (self.manager != nil) {
        DEBUG_HERE();
        [self.manager stopUpdatingLocation];
        self.manager.delegate = nil;
        self.manager = nil;
    }
}

- (void)runTask {
    [self schedulePollIn:0];
}

- (NSInteger)taskCount {
    __block NSInteger result = 0;
    dispatch_sync(_syncQueue, ^{
      result = _rawBackgroundTasks.count;
    });
    return result;
}

- (NSArray *)taskKeys {
    __block NSArray *result = nil;
    dispatch_sync(_syncQueue, ^{
      result = [self->_rawOrderedTaskKeys copy];
      ;
    });
    return result;
}

- (AlarmTask __strong *)taskForKey:(NSString *)key {
    __block AlarmTask *result = nil;
    dispatch_sync(_syncQueue, ^{
      result = self->_rawBackgroundTasks[key];
    });
    return result;
}

- (void)userAlertForProximity:(ViewControllerBase *)parent
                       source:(UIView *)source
                   completion:(void (^)(bool cancelled, bool accurate))completionHandler {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Proximity Alarm", @"alarm alert title")
                         message:[NSString stringWithFormat:NSLocalizedString(
                                                                @"PDX Bus will track your locaton "
                                                                 " and alert"
                                                                 " you when you get within %@ of "
                                                                 "the stop.",
                                                                @"alert question"),
                                                            kUserDistanceProximity]
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                              completionHandler(FALSE, NO);
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                              completionHandler(YES, NO);
                                            }]];

    [parent displayPopover:alert view:source completion:nil];
}

@end

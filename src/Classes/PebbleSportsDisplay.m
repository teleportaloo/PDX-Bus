#ifdef PEBBLE_SUPPORT

//
//  PebbleSportsDisplay.m
//  PDX Bus
//
//  Created by Andrew Wallace on 12/29/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PebbleSportsDisplay.h"
#import <objc/runtime.h>
#import "DebugLogging.h"
#import "AlarmFetchArrivalsTask.h"
#include "DebugLogging.h"

@implementation PebbleSportsDisplay

@synthesize watchAppState       = _watchAppState;
@synthesize watchCallback       = _watchCallback;
@synthesize watch               = _watch;


-(void)dealloc
{

    if (self.watch)
    {
        self.watch.delegate = nil;
    }
    self.watch = nil;
    _watchCallback      = nil;
    
    
    
    [super dealloc];
}

- (id)init
{
    if ((self = [super init]))
    {
        _watchCallback      = nil;
        self.watch          = nil;
        self.watchAppState = WatchApp_NotRunning;
    }
    return self;
}

- (void)setTargetWatch:(PBWatch *)watch
{
    DEBUG_LOG(@"Watch %@\n", watch.name);
    @synchronized (self.watch)
    {
        if (watch != nil)
        {
            if (![watch respondsToSelector:@selector(sportsGetIsSupported:)])
            {
                self.watch = nil;
                
                int i=0;
                unsigned int mc = 0;
                Method * mlist = class_copyMethodList([watch class], &mc);
                DEBUG_LOG(@"%d methods", mc);
                for(i=0;i<mc;i++)
                    DEBUG_LOG(@"Method no #%d: %s", i, sel_getName(method_getName(mlist[i])));
                
                self.watchAppState = WatchApp_NotRunning;
                
            }
            else
            {
                self.watch = watch;
                self.watch.delegate = self;
                self.watchAppState = WatchApp_Pending;
                
                [[PBPebbleCentral defaultCentral] setAppUUID:PBSportsUUID];
            }
        }
        else
        {
            if (self.watch)
            {
                if (_watchCallback!=nil)
                {
                    [self.watch sportsAppRemoveUpdateHandler:_watchCallback];
                    _watchCallback = nil;
                };
                
                [self.watch sportsAppKill:^(PBWatch *watch, NSError *error) {
                    [watch closeSession:^{ }];
                }];
                
                self.watch.delegate = nil;
                self.watch = nil;
                self.watchAppState = WatchApp_NotRunning;
                self.taskKey = nil;
                [self.delegate displayGone:self];
            }
        }
    }
}


- (void)getSupportAndStartCallbacks
{
    [self setTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];
}
             
             
- (void)updateWatch:(AlarmFetchArrivalsTask*)task
{
    [[PBPebbleCentral defaultCentral] setAppUUID:PBSportsUUID];
    
    
    float busDistanceMiles = task.lastFetched.blockPositionFeet / 5280.0;
    
    NSDictionary *myPebbleDict = @{
                PBSportsTimeKey : [PBSportsUpdate timeStringFromFloat:task.lastFetched.minsToArrival],
                PBSportsDistanceKey : [NSString stringWithFormat:@"%2.02f", busDistanceMiles],
                PBSportsDataKey :[NSString stringWithFormat:@"%.0f", [task.lastFetched.route floatValue]],
                };
#define LOG_ITEM(X) DEBUG_LOG(@"%s %@\n"," "#X, [myPebbleDict objectForKey:X]);
    LOG_ITEM(PBSportsTimeKey);
    LOG_ITEM(PBSportsDistanceKey);
    LOG_ITEM(PBSportsDataKey);
    
    
    
    DEBUG_LOG(@"PBSportsTimeKey %@\n",[myPebbleDict objectForKey:PBSportsTimeKey]);
    
    // send data to the sportsApp
    [self.watch sportsAppUpdate:myPebbleDict onSent:^(PBWatch *watch, NSError *error) {
        if (error) {
            DEBUG_LOG(@"Failed sending update.  Error:%@\n",error);
        } else {
            DEBUG_LOG(@"Update sent.\n");
            task.display = watch.name;
            [self.delegate updateSent:self];
        }
    }];
}

- (void)updateDisplay:(AlarmFetchArrivalsTask *)task
{
    if (self.watch && self.watchAppState != WatchApp_NotRunning)
    {
        if (self.taskKey == nil)
        {
            self.taskKey = task.key;
        }
        
        if ([self.taskKey isEqualToString:task.key])
        {
            [(NSObject*)self performSelectorOnMainThread:@selector(mainThreadUpdate:) withObject:task waitUntilDone:NO];
        }
       
    }
}

- (void)displayEnded:(AlarmFetchArrivalsTask *)task
{
    if (task == nil || self.taskKey== nil)
    {
        [self setTargetWatch:nil];
    }
    else if ([self.taskKey isEqualToString:task.key])
    {
        self.taskKey = nil;
    }
}

- (void)mainThreadUpdate:(AlarmFetchArrivalsTask*)task
{
    @synchronized(self.watch)
    {
        if (self.watch)
        {
            switch (self.watchAppState)
            {
                case WatchApp_NotRunning:
                case WatchApp_Launching:
                    break;
                case WatchApp_Pending:
                    self.watchAppState = WatchApp_Launching;
                    [[PBPebbleCentral defaultCentral] setAppUUID:PBSportsUUID];
                    
                    [self.watch sportsGetIsSupported:^(PBWatch *watch, BOOL isSportsSupported) {
                         if (isSportsSupported)
                         {
                             [self.delegate displayAvailable:self];
                             
                             [self.watch sportsAppLaunch:^(PBWatch *watch, NSError *error) {
                                  if (error)
                                  {
                                      DEBUG_LOG(@"Failed launching.  Error: %@\n",error);
                                      [self setTargetWatch:nil];
                                  }
                                  else
                                  {
                                      self.watchAppState = WatchApp_Launched;
                                      
                                      NSString *fileName =  @"watch.png";
                                      UIImage *icon = [UIImage imageNamed:fileName];
                                      [self.watch sportsSetTitle:@"PDX Bus" icon:icon onSent:^(PBWatch *watch, NSError *error) {
                                          DEBUG_LOG(@"%@\n", error ? [error description] : @"Icon + Title set!");
                                      }];
                                      
                                      self.watchCallback = [watch sportsAppAddReceiveUpdateHandler:^BOOL(PBWatch *watch, SportsAppActivityState state) {
                                          
                                          DEBUG_LOG(@"Watch bump %d", state);
                                          return YES;
                                      }];
                                      
                                      [self updateWatch:task];
                                  }
                              }];
                             
                         }
                         else
                         {
                             DEBUG_LOG(@"Sports App not suported\n");
                             [self setTargetWatch:nil];
                         }
                     }];
                    break;
                case WatchApp_Launched:
                    [self updateWatch:task];
            }
        }
    }
}


- (bool)running
{
    return self.watchAppState >= WatchApp_Pending;
}



/*
 *  PBPebbleCentral delegate methods
 */

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    [self setTargetWatch:watch];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected!" message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self setTargetWatch:nil];
}


@end

#endif

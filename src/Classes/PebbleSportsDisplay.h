#ifdef PEBBLE_SUPPORT

//
//  PebbleSportsDisplay.h
//  PDX Bus
//
//  Created by Andrew Wallace on 12/29/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ExternalDisplayDevice.h"
#import <PebbleKit/PebbleKit.h>

typedef enum _watch_app_state
{
    WatchApp_NotRunning = 0,
    WatchApp_Pending,
    WatchApp_Launching,
    WatchApp_Launched
} WATCH_APP_STATE;


@interface PebbleSportsDisplay : ExternalDisplayDevice <PBWatchDelegate>
{
    PBWatch *           _watch;
    id                  _watchCallback;
    WATCH_APP_STATE     _watchAppState;
}

@property (atomic)         WATCH_APP_STATE watchAppState;
@property (assign)         id watchCallback;
@property (assign)         PBWatch *watch;

- (void)getSupportAndStartCallbacks;

@end
#endif

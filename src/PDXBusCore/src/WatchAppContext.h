//
//  WatchAppContext.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 7/16/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "WatchConnectivity/WatchConnectivity.h"
#import "WatchConnectivity/WCSession.h"
#import "MemoryCaches.h"

@interface WatchAppContext : NSObject
{
 
}

+ (WatchAppContext *)sharedInstance;
+ (void)updateWatch:(WCSession *)session;
+ (bool)writeAppContext:(NSDictionary *)appContext;
+ (bool)gotBookmarks:(bool)update;

@end

//
//  WatchAppContext.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 7/16/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MemoryCaches.h"
#import "WatchConnectivity/WCSession.h"
#import "WatchConnectivity/WatchConnectivity.h"
#import <Foundation/Foundation.h>

@interface WatchAppContext : NSObject {
}

+ (bool)writeAppContext:(NSDictionary *)appContext;
+ (void)updateWatch:(WCSession *)session API_AVAILABLE(ios(9.0));
+ (WatchAppContext *)sharedInstance;
+ (bool)gotBookmarks:(bool)update;

@end

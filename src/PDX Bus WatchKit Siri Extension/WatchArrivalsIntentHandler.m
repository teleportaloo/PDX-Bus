//
//  WatchArrivalsIntentHandler.m
//  PDXBus Siri Watch Extension
//
//  Created by Andrew Wallace on 10/18/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsIntentHandler.h"
#import "UserFaves.h"
#import "DebugLogging.h"
#import "ArrivalsResponseFactory.h"

@implementation WatchArrivalsIntentHandler


- (void)handleArrivals:(ArrivalsIntent *)intent completion:(void (^)(ArrivalsIntentResponse *response))completion
{
    DEBUG_FUNC();
    if (@available(watchOS 5.0, *)) {
        ArrivalsIntentResponse * response = [ArrivalsResponseFactory responseForStops:intent.stops];
        completion(response);
    } else {
        // Fallback on earlier versions
    }
    
    
}

#ifdef DEBUGLOGGING
- (bool)respondsToSelector:(SEL)aSelector
{
    bool responds = [super respondsToSelector:aSelector];
    
    DEBUG_LOGS(NSStringFromSelector(aSelector));
    DEBUG_LOGB(responds);
    
    return responds;
}
#endif

@end

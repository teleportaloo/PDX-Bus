//
//  WatchArrivalsIntentHandler.m
//  PDXBus Siri Watch Extension
//
//  Created by Andrew Wallace on 10/18/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogIntents

#import "WatchArrivalsIntentHandler.h"
#import "UserState.h"
#import "DebugLogging.h"
#import "ArrivalsResponseFactory.h"
#import "ArrivalsAtStopIdResponseFactory.h"

@implementation WatchArrivalsIntentHandler


- (void)handleArrivals:(ArrivalsIntent *)intent completion:(void (^)(ArrivalsIntentResponse *response))completion {
    DEBUG_FUNC();
    
    if (@available(watchOS 5.0, *)) {
        ArrivalsIntentResponse *response = [ArrivalsResponseFactory responseForStops:intent.stops];
        completion(response);
    } else {
        // Fallback on earlier versions
    }
}

- (void)handleArrivalsAtStopId:(ArrivalsAtStopIdIntent *)intent completion:(void (^)(ArrivalsAtStopIdIntentResponse *response))completion {
    DEBUG_FUNC();
    
    if (intent.stop == nil) {
        completion([ArrivalsAtStopIdResponseFactory arrivalsRespond:ArrivalsAtStopIdIntentResponseCodeFailure]);
        return;
    }
    
    completion([ArrivalsAtStopIdResponseFactory responseForStop:intent.stop]);
    return;
}

#ifdef DEBUGLOGGING
- (bool)respondsToSelector:(SEL)aSelector {
    bool responds = [super respondsToSelector:aSelector];
    
    DEBUG_LOGS(NSStringFromSelector(aSelector));
    DEBUG_LOGB(responds);
    
    return responds;
}

#endif

@end

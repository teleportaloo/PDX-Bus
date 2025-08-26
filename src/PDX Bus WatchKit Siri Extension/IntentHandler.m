//
//  IntentHandler.m
//  PDXBus Siri Watch Extension
//
//  Created by Andrew Wallace on 10/18/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogIntents

#import "IntentHandler.h"
#import "DebugLogging.h"
#import "WatchAlertsIntentHandler.h"
#import "WatchArrivalsIntentHandler.h"
#import "WatchLocateStopsIntentHandler.h"
#import "WatchRoutesAtStopIdIntentHandler.h"
#import "WatchStopLocationIntentHandler.h"

@interface IntentHandler ()

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent API_AVAILABLE(watchos(3.2)) {
    // This is the default implementation.  If you want different objects to
    // handle different intents, you can override this and return the handler
    // you want for that particular intent.

#define RETURN_INTENT_HANDER(INTENT_CLASS, HANDLER_CLASS)                      \
    if ([intent isKindOfClass:[INTENT_CLASS class]]) {                         \
        return [[HANDLER_CLASS alloc] init];                                   \
    }

    if (@available(watchOS 5.0, *)) {
        RETURN_INTENT_HANDER(ArrivalsIntent, WatchArrivalsIntentHandler);
        RETURN_INTENT_HANDER(ArrivalsAtStopIdIntent,
                             WatchArrivalsIntentHandler);
        RETURN_INTENT_HANDER(AlertsForRouteIntent, WatchAlertsIntentHandler);
        RETURN_INTENT_HANDER(SystemWideAlertsIntent, WatchAlertsIntentHandler);
        RETURN_INTENT_HANDER(LocateStopsIntent, WatchLocateStopsIntentHandler);
        RETURN_INTENT_HANDER(RoutesAtStopIdIntent,
                             WatchRoutesAtStopIdIntentHandler);
        RETURN_INTENT_HANDER(StopLocationIntent,
                             WatchStopLocationIntentHandler);
    } else {
        // Fallback on earlier versions
    }

    return self;
}

@end

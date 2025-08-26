//
//  IntentHandler.m
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogIntents

#import "IntentHandler.h"

#import "AlertsIntentHandler.h"
#import "ArrivalsAtStopIdIntent.h"
#import "ArrivalsIntent.h"
#import "ArrivalsIntentHandler.h"
#import "LocateStopsIntentHandler.h"
#import "RoutesAtStopIdIntentHandler.h"
#import "StopLocationIntentHandler.h"

#import "DebugLogging.h"

@interface IntentHandler ()

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    DEBUG_LOG_description([intent class]);

#define RETURN_INTENT_HANDER(INTENT_CLASS, HANDLER_CLASS)                      \
    if ([intent isKindOfClass:[INTENT_CLASS class]]) {                         \
        return [[HANDLER_CLASS alloc] init];                                   \
    }

    // Each Intent Class has a class with the same name followed by Handler.

    RETURN_INTENT_HANDER(ArrivalsIntent, ArrivalsIntentHandler);
    RETURN_INTENT_HANDER(ArrivalsAtStopIdIntent, ArrivalsIntentHandler);
    RETURN_INTENT_HANDER(AlertsForRouteIntent, AlertsIntentHandler);
    RETURN_INTENT_HANDER(SystemWideAlertsIntent, AlertsIntentHandler);
    RETURN_INTENT_HANDER(LocateStopsIntent, LocateStopsIntentHandler);
    RETURN_INTENT_HANDER(RoutesAtStopIdIntent, RoutesAtStopIdIntentHandler);
    RETURN_INTENT_HANDER(StopLocationIntent, StopLocationIntentHandler);
    return self;
}

@end

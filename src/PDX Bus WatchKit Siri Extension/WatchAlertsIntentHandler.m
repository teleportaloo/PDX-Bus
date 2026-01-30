//
//  WatchAlertsIntentHandler.m
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogIntents

#import "WatchAlertsIntentHandler.h"
#import "AlertsResponseFactory.h"
#import "DebugLogging.h"

@implementation WatchAlertsIntentHandler

- (void)handleAlertsForRoute:(AlertsForRouteIntent *)intent
                  completion:(void (^)(AlertsForRouteIntentResponse *response))completion {
    DEBUG_FUNC();

    if (intent.routeNumber == nil) {
        completion([AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeFailure]);
        return;
    }

    bool systemWide =
        (intent.includeSystemWideAlerts != nil) ? intent.includeSystemWideAlerts.boolValue : true;

    completion([AlertsResponseFactory alertsForRoute:intent.routeNumber systemWide:systemWide]);
}

- (void)handleSystemWideAlerts:(SystemWideAlertsIntent *)intent
                    completion:(void (^)(SystemWideAlertsIntentResponse *response))completion {

    DEBUG_FUNC();

    completion([AlertsResponseFactory systemWideAlerts]);
}

@end

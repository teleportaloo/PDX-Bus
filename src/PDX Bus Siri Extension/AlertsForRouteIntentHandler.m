//
//  LocateArrivalsIntentHandler.m
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertsForRouteIntentHandler.h"
#import "AlertsForRouteResponseFactory.h"
#import "DebugLogging.h"

@implementation AlertsForRouteIntentHandler

- (void)handleAlertsForRoute:(AlertsForRouteIntent *)intent completion:(void (^)(AlertsForRouteIntentResponse *response))completion API_AVAILABLE(ios(12.0)) {
    DEBUG_FUNC();
    
    if (intent.routeNumber == nil) {
        completion([AlertsForRouteResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeFailure]);
        return;
    }
    
    completion([AlertsForRouteResponseFactory alertsForRoute:intent.routeNumber]);
}

@end

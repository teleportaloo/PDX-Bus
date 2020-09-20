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


#import "IntentHandler.h"

#import "ArrivalsIntent.h"
#import "ArrivalsIntentHandler.h"
#import "ArrivalsAtStopIdIntent.h"
#import "ArrivalsAtStopIdIntentHandler.h"
#import "AlertsForRouteIntentHandler.h"
#import "LocateStopsIntentHandler.h"
#import "RoutesAtStopIdIntentHandler.h"
#import "StopLocationIntentHandler.h"

#import "DebugLogging.h"

@interface IntentHandler ()

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    DEBUG_LOGO([intent class])
    
    if (@available(iOS 12.0, *)) {
        if ([intent isKindOfClass:[ArrivalsIntent class]]) {
            DEBUG_LOG(@"Yaaaas 2");
            return [[ArrivalsIntentHandler alloc] init];
        } else if ([intent isKindOfClass:[ArrivalsAtStopIdIntent class]]) {
            DEBUG_LOG(@"Yaaaas 3");
            return [[ArrivalsAtStopIdIntentHandler alloc] init];
        } else if ([intent isKindOfClass:[AlertsForRouteIntent class]]) {
            DEBUG_LOG(@"Yaaaas 3");
            return [[AlertsForRouteIntentHandler alloc] init];
        } else if ([intent isKindOfClass:[LocateStopsIntent class]]) {
            DEBUG_LOG(@"Yaaaas 3");
            return [[LocateStopsIntentHandler alloc] init];
        } else if ([intent isKindOfClass:[RoutesAtStopIdIntent class]]) {
            DEBUG_LOG(@"Yaaaas 3");
            return [[RoutesAtStopIdIntentHandler alloc] init];
        } else if ([intent isKindOfClass:[StopLocationIntent class]]) {
            DEBUG_LOG(@"Yaaaas 3");
            return [[StopLocationIntentHandler alloc] init];
        }
    } else {
        // Fallback on earlier versions
    }
    
    return self;
}

@end

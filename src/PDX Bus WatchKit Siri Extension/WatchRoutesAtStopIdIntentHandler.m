//
//  WatchRoutesAtStopIdIntentHandler.m
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogIntents

#import "WatchRoutesAtStopIdIntentHandler.h"
#import "ArrivalsAtStopIdResponseFactory.h"
#import "DebugLogging.h"

@implementation WatchRoutesAtStopIdIntentHandler

- (void)handleRoutesAtStopId:(RoutesAtStopIdIntent *)intent
                  completion:(void (^)(RoutesAtStopIdIntentResponse *response))
                                 completion {
    DEBUG_FUNC();

    if (intent.stop == nil) {
        completion([ArrivalsAtStopIdResponseFactory
            routesRespond:RoutesAtStopIdIntentResponseCodeFailure]);
        return;
    }

    completion([ArrivalsAtStopIdResponseFactory responseByRoute:intent.stop]);

    return;
}

@end

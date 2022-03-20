//
//  WatchStopLocationIntentHandler.m
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogIntents

#import "WatchStopLocationIntentHandler.h"
#import "DebugLogging.h"
#import "ArrivalsAtStopIdResponseFactory.h"

@implementation WatchStopLocationIntentHandler

- (void)handleStopLocation:(StopLocationIntent *)intent
                completion:(void (^)(StopLocationIntentResponse *response))completion API_AVAILABLE(ios(12.0)) {
    DEBUG_FUNC();
    
    if (intent.stop == nil) {
        completion([ArrivalsAtStopIdResponseFactory locationRespond:StopLocationIntentResponseCodeFailure]);
        return;
    }
    
    completion([ArrivalsAtStopIdResponseFactory stopLocation:intent.stop]);
    
    return;
}

@end

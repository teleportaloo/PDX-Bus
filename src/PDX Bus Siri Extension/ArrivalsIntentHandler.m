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


#import "ArrivalsIntentHandler.h"
#import "ArrivalsResponseFactory.h"

@implementation ArrivalsIntentHandler



- (void)handleArrivals:(ArrivalsIntent *)intent completion:(void (^)(ArrivalsIntentResponse *response))completion
{
    DEBUG_FUNC();
    if (intent.stops == nil)
    {
        completion([ArrivalsResponseFactory arrivalsRespond:ArrivalsIntentResponseCodeFailure]);
        return;
    }
    
    completion ([ArrivalsResponseFactory responseForStops:intent.stops]);
    
}

@end

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


#define DEBUG_LEVEL_FOR_FILE LogIntents

#import "LocateStopsIntentHandler.h"
#import "DebugLogging.h"
#import "LocateStopsResponseFactory.h"

@implementation LocateStopsIntentHandler

- (void)handleLocateStops:(LocateStopsIntent *)intent
               completion:
                   (void (^)(LocateStopsIntentResponse *response))completion {
    DEBUG_FUNC();

    if (intent.location == nil) {
        completion([LocateStopsResponseFactory
            locateRespond:LocateStopsIntentResponseCodeNoLocation]);
        return;
    }

    completion([LocateStopsResponseFactory locate:intent.location.location]);
}

@end

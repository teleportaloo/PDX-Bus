//
//  LocateArrivalsIntentHandler.m
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

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

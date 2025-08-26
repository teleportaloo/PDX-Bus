//
//  AlertsForRouteResponseFactory.m
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocateStopsResponseFactory.h"
#import "FormatDistance.h"
#import "LocateStopsIntentHandler.h"
#import "XMLLocateStops.h"

@implementation LocateStopsResponseFactory

+ (LocateStopsIntentResponse *)locateRespond:(LocateStopsIntentResponseCode)code
    API_AVAILABLE(ios(12.0)) {
    return [[LocateStopsIntentResponse alloc] initWithCode:code
                                              userActivity:nil];
}

+ (LocateStopsIntentResponse *)locate:(CLLocation *)location {
    XMLLocateStops *locator = [XMLLocateStops xml];

    locator.maxToFind = 6;
    locator.minDistance = kMetresInAMile;
    locator.mode = TripModeAll;
    locator.location = location;
    locator.includeRoutesInStops = YES;

    [locator findNearestStops];

    if (locator.gotData) {
        NSMutableArray<NSString *> *results = [NSMutableArray array];

        for (StopDistance *stop in locator) {
            [results addObject:stop.stopId];
        }

        LocateStopsIntentResponse *response = [[LocateStopsIntentResponse alloc]
            initWithCode:LocateStopsIntentResponseCodeSuccess
            userActivity:nil];

        response.stopIds = results;

        return response;
    }

    return [LocateStopsResponseFactory
        locateRespond:LocateStopsIntentResponseCodeFailure];
}

@end

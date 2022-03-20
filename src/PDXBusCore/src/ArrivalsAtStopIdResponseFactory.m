//
//  ArrivalsResponseFactory.m
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "ArrivalsAtStopIdResponseFactory.h"
#import "StopLocationIntentHandler.h"
#import "XMLLocateStops.h"
#import "XMLMultipleDepartures.h"
#import "NSString+Helper.h"
#import "Departure.h"
#import "UserState.h"

#import "ArrivalsResponseFactory.h"

// #import <Contacts/Contacts.h>

@implementation ArrivalsAtStopIdResponseFactory


+ (StopLocationIntentResponse *)locationRespond:(StopLocationIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[StopLocationIntentResponse alloc] initWithCode:code userActivity:nil];
}


+ (StopLocationIntentResponse *)stopLocation:(NSNumber *)stopId API_AVAILABLE(ios(12.0)) {
    NSString *stopString = [NSString stringWithFormat:@"%ld", (long)stopId.integerValue];
    
    DEBUG_HERE();
    // There will be only 1 batch here
    XMLDepartures *deps = [XMLDepartures xml];
    
    [deps getDeparturesForStopId:stopString];
    
    if (deps.gotData) {
        if (deps.loc) {
            StopLocationIntentResponse *response = [[StopLocationIntentResponse alloc] initWithCode:StopLocationIntentResponseCodeSuccess userActivity:nil];
            
            response.location = [CLPlacemark placemarkWithLocation:deps.loc name:nil postalAddress:nil];
            return response;
        }
        
        return [ArrivalsAtStopIdResponseFactory locationRespond:StopLocationIntentResponseCodeUnknownStop];
    }
    
    return [ArrivalsAtStopIdResponseFactory locationRespond:StopLocationIntentResponseCodeFailure];
}

+ (ArrivalsAtStopIdIntentResponse *)arrivalsRespond:(ArrivalsAtStopIdIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[ArrivalsAtStopIdIntentResponse alloc] initWithCode:code userActivity:nil];
}


+ (RoutesAtStopIdIntentResponse *)routesRespond:(RoutesAtStopIdIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[RoutesAtStopIdIntentResponse alloc] initWithCode:code userActivity:nil];
}

+ (RoutesAtStopIdIntentResponse *)responseByRoute:(NSNumber *)stopId {
    NSString *stopString = [NSString stringWithFormat:@"%ld", (long)stopId.integerValue];
    
    DEBUG_HERE();
    // There will be only 1 batch here
    XMLDepartures *deps = [XMLDepartures xml];
    
    deps.keepRawData = YES;
    
    DEBUG_HERE();
    
    NSArray<NSString *> *lines = [ArrivalsResponseFactory arrivals:deps stopId:stopString];
    
    
    if (deps.gotData && deps.loc != nil) {
        DEBUG_HERE();
        
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"org.teleportaloo.pdxbus.xmlarrivals"];
        
        activity.userInfo = @{ @"xml": deps.rawData, @"locs": stopString };
        
        
        NSString *stopName;
        
        if (deps.locDir && deps.locDir.length > 0) {
            stopName = [NSString stringWithFormat:@"%@, %@", deps.locDesc, deps.locDir];
        } else {
            stopName = [NSString stringWithFormat:@"%@", deps.locDesc];
        }
        
        stopName = [XMLDepartures fixLocationForSpeaking:stopName];
        
        UserState *state = UserState.sharedInstance;
        
        [state addToRecentsWithStopId:deps.stopId
                            description:stopName];
        
        NSMutableArray<NSString *> *times = [NSMutableArray array];
        
        [times addObject:stopName];
        
        [times addObjectsFromArray:lines];
        
        RoutesAtStopIdIntentResponse *response = [[RoutesAtStopIdIntentResponse alloc] initWithCode:RoutesAtStopIdIntentResponseCodeSuccess userActivity:nil];
        
        response.routes = times;
        response.userActivity = activity;
        
        return response;
    } else if (deps.loc == nil) {
        DEBUG_HERE();
        return ([ArrivalsAtStopIdResponseFactory routesRespond:RoutesAtStopIdIntentResponseCodeUnknownStop]);
    } else {
        DEBUG_HERE();
        return ([ArrivalsAtStopIdResponseFactory routesRespond:RoutesAtStopIdIntentResponseCodeNoData]);
    }
}

+ (ArrivalsAtStopIdIntentResponse *)responseForStop:(NSNumber *)stopId {
    NSString *stopString = [NSString stringWithFormat:@"%ld", (long)stopId.integerValue];
    
    DEBUG_HERE();
    // There will be only 1 batch here
    XMLDepartures *deps = [XMLDepartures xml];
    
    deps.keepRawData = YES;
    
    DEBUG_HERE();
    
    [deps getDeparturesForStopId:stopString];
    
    if (deps.gotData && deps.loc != nil) {
        DEBUG_HERE();
        
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"org.teleportaloo.pdxbus.xmlarrivals"];
        
        activity.userInfo = @{ @"xml": deps.rawData, @"locs": stopString };
        
        
        NSString *stopName;
        
        if (deps.locDir && deps.locDir.length > 0) {
            stopName = [NSString stringWithFormat:@"%@, %@", deps.locDesc, deps.locDir];
        } else {
            stopName = [NSString stringWithFormat:@"%@", deps.locDesc];
        }
        
        stopName = [XMLDepartures fixLocationForSpeaking:stopName];
        
        UserState *state = UserState.sharedInstance;
        
        [state addToRecentsWithStopId:deps.stopId
                            description:stopName];
        
        NSMutableArray<NSString *> *times = [NSMutableArray array];
        
        [times addObject:stopName];
        
        for (Departure *d in deps) {
            NSMutableString *routeArrival = [NSMutableString string];
            
            
            [routeArrival appendString:d.shortSign];
            [routeArrival appendString:@", "];
            
            if (d.minsToArrival == 0 && d.status == ArrivalStatusScheduled) {
                [routeArrival appendString:NSLocalizedString(@"scheduled for now", @"Siri text")];
            } else if (d.minsToArrival == 0) {
                [routeArrival appendString:NSLocalizedString(@"due now", @"Siri text")];
            } else if (d.minsToArrival == 1) {
                [routeArrival appendFormat:NSLocalizedString(@"%@1 min", @"Siri text"), (d.status == ArrivalStatusScheduled) ? NSLocalizedString(@"scheduled in ", @"Siri text") : @""];
            } else if (d.minsToArrival < 60) {
                [routeArrival appendFormat:@"%@%d mins", (d.status == ArrivalStatusScheduled) ? NSLocalizedString(@"scheduled in ", @"Siri text") : @"",  d.minsToArrival];
            } else {
                ArrivalWindow arrivalWindow;
                NSDateFormatter *dateFormatter = [d dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormatWeekday arrivalWindow:&arrivalWindow];
                
                NSString *timeText = @"";
                
                if (arrivalWindow == ArrivalSoon) {
                    timeText = NSLocalizedString(@"scheduled at ", @"Siri text");
                } else {
                    timeText = NSLocalizedString(@"scheduled on ", @"Siri text");
                }
                
                [routeArrival appendFormat:@"%@%@", timeText, [dateFormatter stringFromDate:d.departureTime]];
            }
            
            [times addObject:routeArrival];
        }
        
        ArrivalsAtStopIdIntentResponse *response = [[ArrivalsAtStopIdIntentResponse alloc] initWithCode:ArrivalsAtStopIdIntentResponseCodeSuccess userActivity:nil];
        
        response.arrivals = times;
        response.userActivity = activity;
        
        return response;
    } else if (deps.loc == nil) {
        DEBUG_HERE();
        return ([ArrivalsAtStopIdResponseFactory arrivalsRespond:ArrivalsAtStopIdIntentResponseCodeUnknownStop]);
    } else {
        DEBUG_HERE();
        return ([ArrivalsAtStopIdResponseFactory arrivalsRespond:ArrivalsAtStopIdIntentResponseCodeNoData]);
    }
}

@end

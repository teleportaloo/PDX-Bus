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

#import "ArrivalsResponseFactory.h"
#import "ArrivalsIntentHandler.h"
#import "XMLLocateStops.h"
#import "XMLMultipleDepartures.h"
#import "NSString+Helper.h"
#import "Departure.h"
#import "UserState.h"

@implementation ArrivalsResponseFactory

+ (ArrivalsIntentResponse *)arrivalsRespond:(ArrivalsIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[ArrivalsIntentResponse alloc] initWithCode:code userActivity:nil];
}

+ (NSMutableArray<NSString *> *)arrivals:(XMLDepartures *)dep stopId:(NSString *)stopId {
    NSMutableArray<NSString *> *arrivals = [NSMutableArray array];
    
    DEBUG_HERE();
    
    [dep getDeparturesForStopId:stopId];
    
    if (dep.gotData && dep.loc != nil) {
        DEBUG_HERE();
        
        bool detours = (dep.detourSorter.allDetours && dep.detourSorter.allDetours.count > 0);
        bool allHaveDetours = YES;
        
        NSString *stopName;
        
        if (dep.locDir && dep.locDir.length > 0) {
            stopName = [NSString stringWithFormat:@"%@, %@", dep.locDesc, dep.locDir];
        } else {
            stopName = [NSString stringWithFormat:@"%@", dep.locDesc];
        }
        
        stopName = [XMLDepartures fixLocationForSpeaking:stopName];
        
        UserState *state = UserState.sharedInstance;
        
        [state addToRecentsWithStopId:dep.stopId
                            description:stopName];
        
        NSMutableArray *routes = [NSMutableArray array];
        NSMutableDictionary *times = [NSMutableDictionary dictionary];
        
        for (Departure *d in dep) {
            bool found = NO;
            
            if (!d.detour) {
                allHaveDetours = NO;
            }
            
            for (NSString *route in routes) {
                if ([route isEqualToString:d.shortSign]) {
                    found = YES;
                    break;
                }
            }
            
            if (!found) {
                [routes addObject:d.shortSign];
                times[d.shortSign] = [NSMutableArray array];
            }
            
            NSMutableArray *routeTimes = times[d.shortSign];
            [routeTimes addObject:d];
        }
        
        NSInteger routesSpoken = 0;
        
        if (routes.count == 0) {
            return nil;
        } else {
            for (NSString *route in routes) {
                NSMutableString *routeArrivals = [NSMutableString string];
                
                NSArray *routeTimes = times[route];
                
                int i = 0;
                
                for (Departure *d in routeTimes) {
                    i++;
                    
                    if (routeArrivals.length > 0) {
                        [routeArrivals appendString:@", "];
                        
                        if (i == routeTimes.count) {
                            [routeArrivals appendString:NSLocalizedString(@" and ", @"Siri and")];
                        }
                    }
                    
                    if (d.minsToArrival == 0 && d.status == ArrivalStatusScheduled) {
                        [routeArrivals appendString:NSLocalizedString(@"scheduled for now", @"Siri text")];
                    } else if (d.minsToArrival == 0) {
                        [routeArrivals appendString:NSLocalizedString(@"due now", @"Siri text")];
                    } else if (d.minsToArrival == 1) {
                        [routeArrivals appendFormat:NSLocalizedString(@"%@1 min", @"Siri text"), (d.status == ArrivalStatusScheduled) ? NSLocalizedString(@"scheduled in ", @"Siri text") : @""];
                    } else if (d.minsToArrival < 60) {
                        [routeArrivals appendFormat:@"%@%d mins", (d.status == ArrivalStatusScheduled) ? NSLocalizedString(@"scheduled in ", @"Siri text") : @"",  d.minsToArrival];
                    } else {
                        ArrivalWindow arrivalWindow;
                        NSDateFormatter *dateFormatter = [d dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormatWeekday arrivalWindow:&arrivalWindow];
                        
                        NSString *timeText = @"";
                        
                        if (arrivalWindow == ArrivalSoon) {
                            timeText = NSLocalizedString(@"scheduled at ", @"Siri text");
                        } else {
                            timeText = NSLocalizedString(@"scheduled on ", @"Siri text");
                        }
                        
                        [routeArrivals appendFormat:@"%@%@", timeText, [dateFormatter stringFromDate:d.departureTime]];
                    }
                }
                
                routesSpoken++;
                [arrivals addObject:[NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Siri text"), route, routeArrivals]];
            }
            
            if (detours) {
                if (routes.count > 1) {
                    if (allHaveDetours) {
                        [arrivals addObject:NSLocalizedString(@"All routes have alerts, check PDX Bus for details", @"Siri text")];
                    } else {
                        [arrivals addObject:NSLocalizedString(@"There are alerts for some of these routes, check PDX Bus for details", @"Siri text")];
                    }
                } else {
                    [arrivals addObject:NSLocalizedString(@"\nThere's an alert for this route, check PDX Bus for details", @"Siri text")];
                }
            }
        }
    } else {
        DEBUG_HERE();
        return nil;
    }
    
    return arrivals;
}

+ (ArrivalsIntentResponse *)responseForStops:(NSString *)stopsString {
    NSArray<NSString*> *stopIdArray = stopsString.mutableArrayFromCommaSeparatedString;
    
    DEBUG_HERE();
    // There will be only 1 batch here
    XMLDepartures *deps = [XMLDepartures xml];
    
    deps.keepRawData = YES;
    
    DEBUG_HERE();
    
    NSArray *lines = [ArrivalsResponseFactory arrivals:deps stopId:stopIdArray.firstObject];
    
    
    if (deps.gotData) {
        DEBUG_HERE();
        
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"org.teleportaloo.pdxbus.xmlarrivals"];
        
        activity.userInfo = @{ @"xml": deps.rawData, @"locs": stopIdArray.firstObject };
        
        if (lines == nil) {
            ArrivalsIntentResponse *response = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeNoArrivals userActivity:nil];
            
            response.stopName = [XMLDepartures fixLocationForSpeaking:stopsString];
            
            activity.userInfo = @{ @"locs": stopIdArray.firstObject };
            
            response.userActivity = activity;
            
            return response;
        } else {
            ArrivalsIntentResponse *response = nil;
            
            NSMutableString *arrivals = [NSMutableString stringWithString:@":\n\n"];
            
            
            [arrivals appendString:[NSString textSeparatedStringFromEnumerator:lines selToGetString:@selector(self) separator:@".\n\n"]];
            
            [arrivals appendString:@".\n"];
            
            if (lines.count >= kMaxRoutesToSpeak) {
                response = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeBigSuccess userActivity:nil];
                response.numberOfRoutes = [NSString stringWithFormat:NSLocalizedString(@"There are many routes here, this may take a while. ", @"Siri text")];
            } else {
                response = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeSuccess userActivity:nil];
            }
            
            response.stopName = [XMLDepartures fixLocationForSpeaking:deps.locDesc];
            
            
            response.arrivals = arrivals;
            
            response.userActivity = activity;
            
            return response;
        }
    } else {
        DEBUG_HERE();
        return ([ArrivalsResponseFactory arrivalsRespond:ArrivalsIntentResponseCodeQueryFailure]);
    }
}

@end

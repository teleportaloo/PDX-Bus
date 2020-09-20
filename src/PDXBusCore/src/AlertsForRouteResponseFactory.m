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


#import "AlertsForRouteResponseFactory.h"
#import "AlertsForRouteIntentHandler.h"
#import "XMLDetours.h"
#import "NSString+Helper.h"
#import "Departure.h"
#import "UserState.h"
#import "TriMetInfo.h"

@implementation AlertsForRouteResponseFactory

+ (AlertsForRouteIntentResponse *)alertsRespond:(AlertsForRouteIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[AlertsForRouteIntentResponse alloc] initWithCode:code userActivity:nil];
}

+ (AlertsForRouteIntentResponse *)alertsForRoute:(NSString *)route {
    NSString *routeNumber = [route justNumbers];
    
    if (routeNumber.length == 0) {
        const ROUTE_INFO *info = [TriMetInfo infoForKeyword:route];
        
        if (info != nil) {
            routeNumber = [NSString stringWithFormat:@"%ld", (long)info->route_number];
        }
    }
    
    if (routeNumber.length == 0) {
        return ([AlertsForRouteResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeUnknownRoute]);
    }
    
    XMLDetours *detours = [XMLDetours xml];
    
    [detours getDetoursForRoute:routeNumber];
    
    NSMutableArray<NSString *> *alerts = [NSMutableArray array];
    
    
    
    for (Detour *detour in detours) {
        NSString *text = detour.detourDesc;
        
        if (detour.headerText && detour.headerText.length!=0 && ![detour.detourDesc hasPrefix:detour.headerText])
        {
            text = [NSString stringWithFormat:@"%@: %@", detour.headerText, detour.detourDesc];
        }
        
        if (detour.infoLinkUrl) {
            [alerts addObject:[NSString stringWithFormat:NSLocalizedString(@"%@ (See app for link)", @"detour text"),
                               text]];
        } else {
            [alerts addObject:text];
        }
    }
    
    AlertsForRouteIntentResponse *response = [[AlertsForRouteIntentResponse alloc] initWithCode:AlertsForRouteIntentResponseCodeSuccess userActivity:nil];
    
    response.alerts = alerts;
    
    return response;
}

@end

//
//  AlertsResponseFactory.m
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertsResponseFactory.h"
#import "AlertsIntentHandler.h"
#import "XMLDetours.h"
#import "NSString+Helper.h"
#import "Departure.h"
#import "UserState.h"
#import "TriMetInfo.h"

@implementation AlertsResponseFactory


+ (void)enumerateDetours:(XMLDetours *)detours systemWide:(bool)systemWide block:(void (^)(Detour *detour))block {
    for (Detour *detour in detours) {
        if (systemWide || !detour.systemWide) {
            block(detour);
        }
    }
}

+ (NSMutableArray<NSString *> *)processAlerts:(XMLDetours *)detours systemWide:(bool)systemWide {
    NSMutableArray<NSString *> *alerts = [NSMutableArray array];
    
    __block NSInteger items = 0;
    
    [AlertsResponseFactory enumerateDetours:detours systemWide:systemWide block:^(Detour *detour) {
        items++;
    }];
    
    __block NSInteger item = 0;
    
    [AlertsResponseFactory enumerateDetours:detours systemWide:systemWide block:^(Detour *detour) {
        NSString *text = detour.detourDesc;
        
        if (detour.headerText && detour.headerText.length != 0 && ![detour.detourDesc hasPrefix:detour.headerText]) {
            text = [NSString stringWithFormat:@"%@: %@", detour.headerText, detour.detourDesc];
        }
        
        NSString *alert = nil;
        
        if (detour.infoLinkUrl) {
            NSString *trimmed = text.stringByTrimmingWhitespace;
            NSString *linkText = nil;
            
            if (trimmed.length > 0) {
                switch (trimmed.lastUnichar) {
                    case ':':
                    case ',':
                    case '-':
                        linkText = NSLocalizedString(@" see app for link.", @"link text");
                        break;
                        
                    case '!':
                    case '?':
                    case '.':
                        linkText = NSLocalizedString(@" See app for link.", @"link text");
                        break;
                        
                    default:
                        linkText = NSLocalizedString(@". See app for link.", @"link text");
                        break;
                }
            } else {
                linkText = detour.infoLinkUrl;
            }
            
            alert = [NSString stringWithFormat:NSLocalizedString(@"%@%@", @"detour text"),
                     text, linkText];
        } else {
            alert = text;
        }
        
        if (items > 1 && item > 0) {
            NSString *previous = alerts[item - 1];
            
            if (previous.length > 0 && previous.lastUnichar == '.') {
                previous = [previous substringToIndex:previous.length - 1];
            }
            
            alerts[item - 1] = previous;
            
            alerts[item] = [NSString stringWithFormat:@"\n\n%@", alert];
        } else {
            alerts[item] = alert;
        }
        
        item++;
    }];
    
    
    return alerts;
}

+ (void)tidyAlerts:(NSMutableArray<NSString *> *)alerts {
    NSInteger item = 0;
    
    for (NSString *alert in alerts) {
        if (alerts.count > 1) {
            if (item > 0) {
                NSString *previous = alerts[item - 1];
                
                NSString *trimmed = previous.stringByTrimmingWhitespace;
                
                if (trimmed.length > 0 && [trimmed characterAtIndex:trimmed.length - 1] == '.') {
                    trimmed = [trimmed substringToIndex:trimmed.length - 2];
                }
                
                alerts[item - 1] = trimmed;
                
                alerts[item] = [NSString stringWithFormat:@"\n\n%@", alert];
            }
        }
        
        item++;
    }
}

+ (AlertsForRouteIntentResponse *)alertsRespond:(AlertsForRouteIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[AlertsForRouteIntentResponse alloc] initWithCode:code userActivity:nil];
}

+ (AlertsForRouteIntentResponse *)alertsForRoute:(NSString *)route systemWide:(bool)systemWide {
    NSString *routeNumber = [TriMetInfo routeNumberFromInput:route];
    
    XMLDetours *detours = [XMLDetours xml];
    
    detours.noEmojis = YES;
    
    if (routeNumber == nil) {
        if ([route localizedCaseInsensitiveContainsString:kUserInfoAlertSystem]) {
            [detours getSystemWideDetours];
            systemWide = YES;
        } else {
            return ([AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeUnknownRoute]);
        }
    } else {
        [detours getDetoursForRoute:routeNumber];
    }
    
    if (detours.gotData) {
        NSMutableArray<NSString *> *alerts = [AlertsResponseFactory processAlerts:detours systemWide:systemWide];
        
        const RouteInfo *info = [TriMetInfo infoForRoute:routeNumber];
        
        if (info != nil) {
            routeNumber = info->short_name;
        } else {
            routeNumber = [NSString stringWithFormat:@"Route %@", routeNumber];
        }
        
        if (alerts.count == 0) {
            AlertsForRouteIntentResponse * response = [AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeNone];
            response.alerts = alerts;
            response.route = routeNumber;
            return response;
        } else if (alerts.count <= 2) {
            AlertsForRouteIntentResponse *response = [AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeSuccess];
            response.alerts = alerts;
            response.route = routeNumber;
            return response;
        } else {
            AlertsForRouteIntentResponse * response = [AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeBigSuccess];
            response.alerts = alerts;
            response.route = routeNumber;
            return response;
        }
    }
    
    return [AlertsResponseFactory alertsRespond:AlertsForRouteIntentResponseCodeFailure];
}

+ (SystemWideAlertsIntentResponse *)systemWideAlertsRespond:(SystemWideAlertsIntentResponseCode)code API_AVAILABLE(ios(12.0)) {
    return [[SystemWideAlertsIntentResponse alloc] initWithCode:code userActivity:nil];
}

+ (SystemWideAlertsIntentResponse *)systemWideAlerts API_AVAILABLE(ios(12.0)) {
    XMLDetours *detours = [XMLDetours xml];
    
    detours.noEmojis = YES;
    [detours getSystemWideDetours];
    
    if (detours.gotData) {
        NSMutableArray<NSString *> *alerts = [AlertsResponseFactory processAlerts:detours systemWide:YES];
        
        if (alerts.count != 0) {
            SystemWideAlertsIntentResponse *response = [AlertsResponseFactory systemWideAlertsRespond:SystemWideAlertsIntentResponseCodeSuccess];
            response.alerts = alerts;
            return response;
        } else {
            SystemWideAlertsIntentResponse *response = [AlertsResponseFactory systemWideAlertsRespond:SystemWideAlertsIntentResponseCodeNone];
            response.alerts = alerts;
            return response;
        }
    }
    
    return [AlertsResponseFactory systemWideAlertsRespond:SystemWideAlertsIntentResponseCodeFailure];
}

@end

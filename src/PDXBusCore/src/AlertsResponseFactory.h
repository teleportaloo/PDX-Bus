//
//  AlertsResponseFactory.h
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertsForRouteIntent.h"
#import "SystemWideAlertsIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlertsResponseFactory : NSObject

+ (AlertsForRouteIntentResponse *)alertsRespond:(AlertsForRouteIntentResponseCode)code;
+ (AlertsForRouteIntentResponse *)alertsForRoute:(NSString *)route systemWide:(bool)systemWide;

+ (SystemWideAlertsIntentResponse *)systemWideAlertsRespond:
    (SystemWideAlertsIntentResponseCode)code;
+ (SystemWideAlertsIntentResponse *)systemWideAlerts;

@end

NS_ASSUME_NONNULL_END

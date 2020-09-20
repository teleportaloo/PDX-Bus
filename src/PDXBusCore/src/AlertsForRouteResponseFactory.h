//
//  ArrivalsResponseFactory.h
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertsForRouteIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlertsForRouteResponseFactory : NSObject

+ (AlertsForRouteIntentResponse *)alertsRespond:(AlertsForRouteIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (AlertsForRouteIntentResponse *)alertsForRoute:(NSString *)route API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END

//
//  ArrivalsIntentHandler.h
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "AlertsForRouteIntent.h"
#import "SystemWideAlertsIntent.h"

@interface AlertsIntentHandler<AlertsForRouteIntentHandling, SystemWideAlertsIntentHandling> : NSObject

- (void)handleAlertsForRoute:(AlertsForRouteIntent *)intent
                  completion:(void (^)(AlertsForRouteIntentResponse *response))completion API_AVAILABLE(ios(13.0), macos(10.16), watchos(6.0));

- (void)handleSystemWideAlerts:(SystemWideAlertsIntent *)intent
            completion:(void (^)(SystemWideAlertsIntentResponse *response))completion API_AVAILABLE(ios(12.0));

@end

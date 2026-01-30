//
//  WatchAlertsIntentHandler.h
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertsForRouteIntent.h"
#import "SystemWideAlertsIntent.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WatchAlertsIntentHandler<AlertsForRouteIntentHandling, SystemWideAlertsIntentHandling>
    : NSObject

- (void)handleAlertsForRoute:(AlertsForRouteIntent *)intent
                  completion:(void (^)(AlertsForRouteIntentResponse *response))completion;

- (void)handleSystemWideAlerts:(SystemWideAlertsIntent *)intent
                    completion:(void (^)(SystemWideAlertsIntentResponse *response))completion;

@end

NS_ASSUME_NONNULL_END

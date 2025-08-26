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


#import "ArrivalsAtStopIdIntent.h"
#import "RoutesAtStopIdIntent.h"
#import "StopLocationIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArrivalsAtStopIdResponseFactory : NSObject

+ (StopLocationIntentResponse *)locationRespond:
    (StopLocationIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (StopLocationIntentResponse *)stopLocation:(NSNumber *)stopId
    API_AVAILABLE(ios(12.0));

+ (ArrivalsAtStopIdIntentResponse *)arrivalsRespond:
    (ArrivalsAtStopIdIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (ArrivalsAtStopIdIntentResponse *)responseForStop:(NSNumber *)stopId
    API_AVAILABLE(ios(12.0));

+ (RoutesAtStopIdIntentResponse *)routesRespond:
    (RoutesAtStopIdIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (RoutesAtStopIdIntentResponse *)responseByRoute:(NSNumber *)stopId
    API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END

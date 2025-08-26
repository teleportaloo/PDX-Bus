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


#import "ArrivalsIntent.h"

@class XMLDepartures;

NS_ASSUME_NONNULL_BEGIN

@interface ArrivalsResponseFactory : NSObject

+ (ArrivalsIntentResponse *_Nullable)arrivalsRespond:
    (ArrivalsIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (ArrivalsIntentResponse *)responseForStops:(NSString *)stopsString
    API_AVAILABLE(ios(12.0));
+ (NSMutableArray<NSString *> *_Nullable)arrivals:(XMLDepartures *)dep
                                           stopId:(NSString *)stopId;

@end

NS_ASSUME_NONNULL_END

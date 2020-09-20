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


#import "LocateStopsIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface LocateStopsResponseFactory : NSObject

+ (LocateStopsIntentResponse *)locateRespond:(LocateStopsIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (LocateStopsIntentResponse *)locate:(CLLocation *)location API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END

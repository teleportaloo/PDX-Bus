//
//  ArrivalsResponseFactory.h
//  PDX Bus Siri Extension
//
//  Created by Andrew Wallace on 11/16/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ArrivalsIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArrivalsResponseFactory : NSObject

+ (ArrivalsIntentResponse *)arrivalsRespond:(ArrivalsIntentResponseCode)code API_AVAILABLE(ios(12.0));
+ (ArrivalsIntentResponse *)responseForStops:(NSString*)stopsString API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END

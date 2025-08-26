//
//  ArrivalsAtStopIdIntentHandler.h
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopLocationIntent.h"
#import <Foundation/Foundation.h>

@interface StopLocationIntentHandler<StopLocationIntentHandling> : NSObject

- (void)handleStopLocation:(StopLocationIntent *)intent
                completion:
                    (void (^)(StopLocationIntentResponse *response))completion
    API_AVAILABLE(ios(12.0));

@end

//
//  IntentHandler.m
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "IntentHandler.h"

#import "ArrivalsIntent.h"
#import "ArrivalsIntentHandler.h"

#include "DebugLogging.h"

@interface IntentHandler ()

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    
    if (@available(iOS 12.0, *)) {
        if ([intent isKindOfClass:[ArrivalsIntent class]])
        {
            DEBUG_LOG(@"Yaaaas 2");
            return [[ArrivalsIntentHandler alloc] init];
        }
    } else {
        // Fallback on earlier versions
    }
    
    return self;
}

@end

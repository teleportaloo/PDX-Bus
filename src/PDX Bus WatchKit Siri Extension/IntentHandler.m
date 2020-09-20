//
//  IntentHandler.m
//  PDXBus Siri Watch Extension
//
//  Created by Andrew Wallace on 10/18/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "IntentHandler.h"
#import "WatchArrivalsIntentHandler.h"
#import "DebugLogging.h"

@interface IntentHandler ()

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent  API_AVAILABLE(watchos(3.2)) {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.
    
    if (@available(watchOS 5.0, *)) {
        if ([intent isKindOfClass:[ArrivalsIntent class]]) {
            DEBUG_HERE();
            return [[WatchArrivalsIntentHandler alloc] init];
        }
    } else {
        // Fallback on earlier versions
    }
    
    return self;
}

@end

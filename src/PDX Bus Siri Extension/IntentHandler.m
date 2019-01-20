//
//  IntentHandler.m
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

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

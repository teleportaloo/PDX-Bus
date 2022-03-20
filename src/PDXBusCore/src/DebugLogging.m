//
//  DebugLogging.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/13/20.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DebugLogging.h"

#ifdef DEBUGLOGGING

#define LOG(s, ...)              { NSLog(@"%@", [NSString stringWithFormat:(s), ## __VA_ARGS__]); }

#define LOG_1(X)   self.logLevel |= kLog ## X;   LOG(@"    Log 0x%04x %@", kLog ## X, @#X); { if (mutablelevelString.length > 0) { [mutablelevelString appendString:@", "]; } [mutablelevelString appendString:@#X]; }
#define LOG_0(X)


@implementation DebugLogging

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.logLevel = 0;
        
        NSMutableString *mutablelevelString = [NSMutableString string];
        
        LOG(@"Debug Logging Initializing");
        
        LOG_0(Settings);
        LOG_0(Networking);
        LOG_0(XML);
        LOG_0(Parsing);
        LOG_0(Task);
        LOG_0(UserInterface);
        LOG_0(DataManagement);
        LOG_1(Tests);
        LOG_1(TestFiles);
        LOG_1(Intents);
        LOG_1(Alarms);
        LOG_1(Web);
        
        self.logLevelString = mutablelevelString;
        
    }
    
    return self;
}

+ (instancetype)sharedInstance
{
    static DebugLogging *singleton = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[DebugLogging alloc] init];
    });
    
    return singleton;
}

@end

#endif


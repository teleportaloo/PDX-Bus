//
//  WatchAppContext.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 7/16/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchAppContext.h"
#import "BlockColorDb.h"
#import "UserState.h"
#import "DebugLogging.h"

#define kAppData    @"AppData"
#define kUUID       @"UUID"
#define kBlockColor @"bcdb"

@implementation WatchAppContext


+ (WatchAppContext *)sharedInstance {
    static WatchAppContext *singleton = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[WatchAppContext alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

#ifndef PDXBUS_WATCH
- (void)updateWatch:(WCSession *)session API_AVAILABLE(ios(9.0)) {
    NSDictionary *blockColorData = [BlockColorDb sharedInstance].db;
    NSDictionary *appData = UserState.sharedInstance.rawData;
    
    if (session != nil && session.isWatchAppInstalled) {
        Class uuidClass = (NSClassFromString(@"NSUUID"));
        NSString *UUID = nil;
        NSError *error = nil;
        
        if (uuidClass) {
            UUID = [NSUUID UUID].UUIDString;
        } else {
            UUID = [NSDate date].description;
        }
        
        // Dictionary needs a unique item so it will get passed accross otherwise it will not.
        NSDictionary *appContext = @{ kAppData: appData,
                                      kBlockColor: blockColorData,
                                      kUUID: UUID };
        
        bool sent = [session updateApplicationContext:appContext error:&error];
        
        if (!sent || error != nil) {
            ERROR_LOG(@"Failed to push bookmarks to watch %@\n", error.description);
        }
    }
}
#else // ifndef PDXBUS_WATCH

- (void)updateWatch:(WCSession *)session {
}

#endif // ifndef PDXBUS_WATCH




- (void)safeWrite:(NSDictionary *)dict fileName:(NSString *)fileName {
    bool written = false;
    
    @try {
        written = [dict writeToFile:fileName atomically:YES];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason);
    }
    
    if (!written) {
        ERROR_LOG(@"Failed to write to %@\n", fileName);
    }
}

- (bool)gotBookmarks:(bool)update {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fileName = @"bookmarkupdated.plist";
    
    DEBUG_LOGS(documentsDirectory);
    
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSMutableDictionary *dict = nil;
    bool gotBookmarks = NO;
    
    if (update) {
        if ([fileManager fileExistsAtPath:fullPath] == NO) {
            dict = [NSMutableDictionary dictionary];
            dict[@"version"] = @"1.0";
            
            [self safeWrite:dict fileName:fullPath];
            
            gotBookmarks = YES;
        }
    } else {
        if ([fileManager fileExistsAtPath:fullPath]) {
            gotBookmarks = YES;
        }
    }
    
    return gotBookmarks;
}

+ (bool)gotBookmarks:(bool)update {
    return [[WatchAppContext sharedInstance] gotBookmarks:update];
}

- (bool)writeAppContext:(NSDictionary *)appContext {
    bool updatedBookmarks = NO;
    
    if (appContext.count != 0) {
        NSDictionary *bcdb = appContext[kBlockColor];
        NSDictionary *appData = appContext[kAppData];
        
        UserState *state = UserState.sharedInstance;
        
        if (appData) {
            [self gotBookmarks:YES];
            NSDate *savedLastRun = state.lastRun;
            
            state.rawData = [NSMutableDictionary dictionaryWithDictionary:appData];
            
            state.lastRun = savedLastRun;
            
            
            state.readOnly = NO;
            [state cacheState];
            state.readOnly = YES;
            
            updatedBookmarks = YES;
        }
        
        BlockColorDb *colorDb = [BlockColorDb sharedInstance];
        
        if (bcdb && ![colorDb.db isEqualToDictionary:bcdb]) {
            [colorDb setDb:bcdb];
        }
    }
    
    return updatedBookmarks;
}

+ (void)updateWatch:(WCSession *)session {
    [[WatchAppContext sharedInstance] updateWatch:session];
}

+ (bool)writeAppContext:(NSDictionary *)appContext {
    return [[WatchAppContext sharedInstance] writeAppContext:appContext];
}

@end

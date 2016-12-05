//
//  WatchAppContext.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 7/16/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "WatchAppContext.h"
#import "BlockColorDb.h"
#import "UserFaves.h"
#import "DebugLogging.h"

#define kAppData    @"AppData"
#define kUUID       @"UUID"
#define kBlockColor @"bcdb"

@implementation WatchAppContext


- (void)dealloc
{
    [super dealloc];
}

+ (WatchAppContext *)singleton
{
    static WatchAppContext *singleton = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[WatchAppContext alloc] init];
    });
    
    return [[singleton retain] autorelease];
}

- (instancetype)init
{
    
    if ((self = [super init]))
    {

    }
    
    return self;
}

#ifndef PDXBUS_WATCH


- (void)updateWatch:(WCSession *)session
{
    
    NSDictionary *appData = [SafeUserData singleton].appData;
    NSDictionary *blockColorData = [BlockColorDb singleton].getDB;
    
    
    if (session != nil && session.isWatchAppInstalled)
    {
        NSError *error=nil;
        
        Class uuidClass = (NSClassFromString(@"NSUUID"));
        
        NSString *UUID = nil;
        
        if (uuidClass)
        {
            UUID = [NSUUID UUID].UUIDString;
        }
        else
        {
            UUID = [NSDate date].description;
        }
        
        // Dictionary needs a unique item so it will get passed accross otherwise it will not.
        NSDictionary *appContext = @{kAppData       : appData,
                                     kBlockColor    : blockColorData,
                                     kUUID          : UUID};
        
        bool sent = [session updateApplicationContext:appContext error:&error];
        
        if (!sent || error!=nil)
        {
            ERROR_LOG(@"Failed to push bookmarks to watch %@\n",error.description);
        }
    }
    
    
}





#else

- (void)updateWatch:(WCSession*)session
{
    
}

#endif




-(void)safeWrite:(NSDictionary *)dict fileName:(NSString*)fileName
{
    bool written = false;
    
    @try {
        written = [dict writeToFile:fileName atomically:YES];
    }
    @catch (NSException *exception)
    {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason );
    }
    
    if (!written)
    {
        ERROR_LOG(@"Failed to write to %@\n", fileName);
    }
}


- (bool)gotBookmarks:(bool)update
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *fileName = @"bookmarkupdated.plist";
    
    DEBUG_LOGS(documentsDirectory);
    
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSMutableDictionary *dict = nil;
    bool gotBookmarks = NO;
    
    if (update)
    {
        if ([fileManager fileExistsAtPath:fullPath] == NO) {
            dict = [NSMutableDictionary dictionary];
            dict[@"version"] = @"1.0";
            
            [self safeWrite:dict fileName:fullPath];
            
            gotBookmarks = YES;
        }
    }
    else
    {
        
        if ([fileManager fileExistsAtPath:fullPath]) {
            
            gotBookmarks = YES;
        }
    }
    
    return gotBookmarks;
}

+ (bool)gotBookmarks:(bool)update
{
    return [[WatchAppContext singleton] gotBookmarks:update];
}


- (bool)writeAppContext:(NSDictionary *)appContext
{
    bool updatedBookmarks = NO;
    
    if (appContext.count !=0)
    {
        NSDictionary *bcdb      = appContext[kBlockColor];
        NSDictionary *appData   = appContext[kAppData];
        
        SafeUserData *faves = [SafeUserData singleton];
        
        if (appData)
        {
            [self gotBookmarks:YES];
            NSDate *savedLastRun = faves.lastRun.retain;
            
            faves.appData = [[[NSMutableDictionary alloc] initWithDictionary:appData] autorelease];
            
            faves.lastRun = savedLastRun;
            
            [savedLastRun release];
            
            faves.readOnly = NO;
            [faves cacheAppData];
            faves.readOnly = YES;
            
            updatedBookmarks = YES;
        }
        
        BlockColorDb *colorDb = [BlockColorDb singleton];
        
        if (bcdb && ![colorDb.getDB isEqualToDictionary:bcdb])
        {
            [colorDb setDB:bcdb];
        }
    }
    
    return updatedBookmarks;
}


+ (void)updateWatch:(WCSession *)session
{
    [[WatchAppContext singleton] updateWatch:session];
}

+ (bool)writeAppContext:(NSDictionary *)appContext
{
    return [[WatchAppContext singleton] writeAppContext:appContext];
}







@end

//
//  WatchAppContext.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 7/16/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WatchConnectivity/WatchConnectivity.h"
#import "WatchConnectivity/WCSession.h"
#import "MemoryCaches.h"

@interface WatchAppContext : NSObject
{
 
}

+ (WatchAppContext *)singleton;
+ (void)updateWatch:(WCSession *)session;
+ (bool)writeAppContext:(NSDictionary *)appContext;
+ (bool)gotBookmarks:(bool)update;

@end

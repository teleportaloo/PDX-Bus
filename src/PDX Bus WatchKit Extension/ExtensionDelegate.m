//
//  ExtensionDelegate.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/30/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "WatchBookmarksInterfaceController.h"
#import "DebugLogging.h"

@implementation ExtensionDelegate

- (void)dealloc
{
    self.wakeDelegate = nil;
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching
{
    self.justLaunched = YES;
    
    DEBUG_LOG(@"Watch: %d-bit",(int)(sizeof(NSInteger) * 8));
}

- (void)applicationDidBecomeActive
{
    DEBUG_FUNC();
    WKExtension *extension = [WKExtension sharedExtension];
    
    if (extension.rootInterfaceController != nil)
    {
        WatchBookmarksInterfaceController *root = (WatchBookmarksInterfaceController*)extension.rootInterfaceController;
        
        [root applicationDidBecomeActive];
    }
    
    self.backgrounded = NO;
    
    if (self.wakeDelegate)
    {
        DEBUG_LOG(@"Found a wake delegate");
        [_wakeDelegate extentionForgrounded];
        self.wakeDelegate = nil;
    }
}

- (void)applicationWillResignActive
{
    DEBUG_FUNC();
    self.backgrounded = YES;
}

- (void)applicationWillEnterForeground
{
   DEBUG_FUNC();
}

- (void)applicationDidEnterBackground
{
    DEBUG_FUNC();
    self.backgrounded = YES;
}

@end

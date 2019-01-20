//
//  ExtensionDelegate.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/30/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ExtensionDelegate.h"
#import "WatchBookmarksInterfaceController.h"
#import "DebugLogging.h"
#import "ArrivalsIntent.h"
#import "AlertInterfaceController.h"
#import "StringHelper.h"

@implementation ExtensionDelegate


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


- (void)handleActivity:(NSUserActivity *)userActivity
{
    DEBUG_FUNC();
    if (@available(watchOS 5.0, *)) {
    
    
        WKExtension *extension = [WKExtension sharedExtension];
    
        INInteraction *interaction = userActivity.interaction;
        INIntent *intent = nil;
        
        WatchBookmarksInterfaceController *root = (WatchBookmarksInterfaceController*)extension.rootInterfaceController;
        
        DEBUG_LOGO(userActivity.userInfo);
        
        if (interaction)
        {
            intent = interaction.intent;
        }
        
        
        if (intent && [intent isKindOfClass:[ArrivalsIntent class]])
        {
            ArrivalsIntent *arrivals = (ArrivalsIntent *) intent;
            root.userActivity = [[NSUserActivity alloc] initWithActivityType:kHandoffUserActivityBookmark];
            root.userActivity.userInfo = @{ kUserFavesLocation: arrivals.stops, kUserFavesChosenName: arrivals.locationName  };
            [root processUserActivity];
        }
        else if ([userActivity.activityType isEqualToString:kHandoffUserActivityBookmark])
        {
            if (userActivity.userInfo && userActivity.userInfo[kUserFavesTrip]!=nil)
            {
                [root pushControllerWithName:kAlertScene context:
                 [@"#b#WSorry, the PDX Bus watch app does not support Trip Planing." formatAttributedStringWithFont:[UIFont systemFontOfSize:16]]];
            }
            else
            {
                root.userActivity = userActivity;
                [root processUserActivity];
            }
        }
        else if ([userActivity.activityType isEqualToString:kHandoffUserActivityLocation])
        {
            root.userActivity = userActivity;
            [root processUserActivity];
        }
        
    } else {
        // Fallback on earlier versions
    }
}


- (void)handleIntent:(INIntent *)intent completionHandler:(void(^)(INIntentResponse *intentResponse))completionHandler
{
    
    
}

@end

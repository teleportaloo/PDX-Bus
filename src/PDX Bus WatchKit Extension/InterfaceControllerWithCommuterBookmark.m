//
//  InterfaceControllerWithCommuterBookmark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/6/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "InterfaceControllerWithCommuterBookmark.h"
#import "UserFaves.h"
#import "WatchBookmarksContext.h"
#import "WatchArrivalsContextBookmark.h"
#import "StringHelper.h"
#import "DebugLogging.h"
#import  "AlertInterfaceController.h"
#import <UIKit/UIKit.h>


@implementation InterfaceControllerWithCommuterBookmark

static NSDictionary *singleCommuterBookmark;

@synthesize faves = _faves;

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.faves = [SafeUserData singleton];
    self.faves.readOnly = YES;
}

- (void)dealloc
{
    self.faves = nil;
    [super dealloc];
}

- (bool)autoCommute
{
    return [self runCommuterBookmarkOnlyOnce:YES];
}

- (void)forceCommute
{
    if (![self runCommuterBookmarkOnlyOnce:NO])
    {
        NSMutableAttributedString *string = [NSMutableAttributedString alloc].init.autorelease;
        NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
        NSAttributedString *subString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No commuter bookmark was found for the current day of the week and time.\n\n", @"commuter bookmark error") attributes:attributes].autorelease;
        [string appendAttributedString:subString];
        
        attributes = @{ NSForegroundColorAttributeName: [UIColor cyanColor] };
        subString =  [[NSAttributedString alloc] initWithString:NSLocalizedString(@"To create a commuter bookmark, go to the iPhone to edit a bookmark to set which days to use it for the morning or evening commute.", @"Commuter bookmark info")
                                                                                  attributes:attributes].autorelease;
        [string appendAttributedString:subString];
        
        [self pushControllerWithName:kAlertScene context:string];
    }
}

- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce
{
    ExtensionDelegate  *extensionDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
    
    NSDictionary *bookmark = nil;
    
    if (!extensionDelegate.backgrounded)
    {
        
        bookmark = [[SafeUserData singleton] checkForCommuterBookmarkShowOnlyOnce:onlyOnce];
        
        bool atRoot = NO;
        
        
        WKExtension *sharedExtention = [WKExtension sharedExtension];
        WKInterfaceController *rootInterfaceController = sharedExtention.rootInterfaceController;
        
        if ([rootInterfaceController isKindOfClass:[self class]])
        {
            if (rootInterfaceController == self)
            {
                atRoot = YES;
            }
        }
        
        
        DEBUG_LOG(@"runCommuterBookmarkOnlyOnce:%d atRoot:%d ->\n%@\n", onlyOnce, atRoot, bookmark.description);
        
        if (bookmark)
        {
            if (singleCommuterBookmark)
            {
                [singleCommuterBookmark release];
                singleCommuterBookmark = nil;
            }
            singleCommuterBookmark = bookmark.retain;
            
            if (!atRoot)
            {
                [self popToRootController];
                DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: popped\n");
            }
            else
            {
                [self delayedDisplayOfCommuterBookmark];
                DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: at home\n");
            }
        }
        
    }
    else
    {
        DEBUG_LOG(@"No commuter bookmark as backgrounded\n");
    }
    
    return (bookmark !=nil);
    
}


- (bool)delayedDisplayOfCommuterBookmark
{
    if (singleCommuterBookmark != nil)
    {
        NSDictionary * bookmark = singleCommuterBookmark;
        singleCommuterBookmark = nil;
        
        NSString *location = bookmark[kUserFavesLocation];
        NSString *title    = bookmark[kUserFavesChosenName];
        NSArray *stops     = location.arrayFromCommaSeparatedString;
        
        WatchBookmarksContext * context = [WatchBookmarksContext contextWithBookmark:stops title:title locationString:location];
        context.oneTimeShowFirst = YES;
        
        DEBUG_LOG(@"delayedDisplayOfCommuterBookmark: delayed push\n");
        [self delayedPush:context];
        // self.delayedPush = context;
        // [context delayedPushFrom:self];
        
        [bookmark release];
        return YES;
    }
    
    return NO;
}

@end

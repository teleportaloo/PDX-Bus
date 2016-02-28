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


@implementation InterfaceControllerWithCommuterBookmark

static NSDictionary *singleCommuterBookmark;

@synthesize faves = _faves;

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.faves = [SafeUserData getSingleton];
    self.faves.readOnly = YES;
}

- (void)dealloc
{
    self.faves = nil;
    [super dealloc];
}

- (bool)autoCommuteAlreadyHome:(bool)alreadyHome
{
    if ([UserPrefs getSingleton].watchAutoCommute)
    {
        return [self runCommuterBookmarkOnlyOnce:YES alreadyHome:alreadyHome];
    }
    
    return NO;
}

- (void)forceCommuteAlreadyHome:(bool)alreadyHome
{
    if (![self runCommuterBookmarkOnlyOnce:NO alreadyHome:alreadyHome])
    {
        NSMutableAttributedString *string = [NSMutableAttributedString alloc].init.autorelease;
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *subString = [[NSAttributedString alloc] initWithString:@"No commuter bookmark was found for the current day of the week and time.\n\n" attributes:attributes].autorelease;
        [string appendAttributedString:subString];
        
        attributes = [NSDictionary dictionaryWithObject:[UIColor cyanColor] forKey:NSForegroundColorAttributeName];
        subString =  [[NSAttributedString alloc] initWithString:@"To create a commuter bookmark, go to the iPhone to edit a bookmark to set which days to use it for the morning or evening commute." attributes:attributes].autorelease;
        [string appendAttributedString:subString];
        
        [self pushControllerWithName:kAlertScene context:string];
    }
}

- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce alreadyHome:(bool)alreadyHome
{
    
    NSDictionary *bookmark = [[SafeUserData getSingleton] checkForCommuterBookmarkShowOnlyOnce:onlyOnce];
    
    
    DEBUG_LOG(@"runCommuterBookmarkOnlyOnce:%d alreadyHome:%d ->\n%@\n", onlyOnce, alreadyHome, bookmark.description);
    
    if (bookmark)
    {
        if (singleCommuterBookmark)
        {
            [singleCommuterBookmark release];
            singleCommuterBookmark = nil;
        }
        singleCommuterBookmark = bookmark.retain;
        
        if (!alreadyHome)
        {
            [self popToRootController];
            DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: popped\n");
        }
        else
        {
            [self maybeDisplayCommuterBookmark];
            DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: at home\n");
        }
    }
    
    return (bookmark !=nil);

}


- (bool)maybeDisplayCommuterBookmark
{
    if (singleCommuterBookmark != nil)
    {
        NSDictionary * bookmark = singleCommuterBookmark;
        singleCommuterBookmark = nil;
        
        NSString *location = [bookmark valueForKey:kUserFavesLocation];
        NSString *title    = [bookmark valueForKey:kUserFavesChosenName];
        NSArray *stops = [StringHelper arrayFromCommaSeparatedString:location];
        
        WatchBookmarksContext * context = [WatchBookmarksContext contextWithBookmark:stops title:title locationString:location];
        
        if (![UserPrefs getSingleton].watchBookmarksDisplayStopList)
        {
            context.oneTimeShowFirst = YES;
        }
        
        DEBUG_LOG(@"maybeDisplayCommuterBookmark: delayed push\n");
        [context delayedPushFrom:self];
        
        [bookmark release];
        return YES;
    }
    
    return NO;
}

@end

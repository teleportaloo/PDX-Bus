//
//  WatchArrivalsContextBookmark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/10/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContextBookmark.h"
#import "UserFaves.h"

@implementation WatchArrivalsContextBookmark

+ (WatchArrivalsContextBookmark*)contextFromBookmark:(WatchBookmarksContext *)bookmarksContext index:(NSInteger)index
{
    {
        WatchArrivalsContextBookmark *context = [[[WatchArrivalsContextBookmark alloc] init] autorelease];
        
        context.locid            = [bookmarksContext.singleBookmark objectAtIndex:index];
        context.showMap          = NO;
        context.showDistance     = NO;
        context.bookmarksContext = bookmarksContext;
        context.index            = index;
        
        context.navText          = @"Next in bookmark";
        
        return context;
    }
}


+ (WatchArrivalsContextBookmark*)contextFromRecents:(WatchBookmarksContext *)bookmarksContext index:(NSInteger)index
{
    {
        WatchArrivalsContextBookmark *context = [WatchArrivalsContextBookmark contextFromBookmark:bookmarksContext index:index];
        
        context.navText         = @"Next recent";
        
        return context;
    }
}

- (id)init
{
    if ((self = [super init]))
    {
        self.sceneName  = kArrivalsScene;
    }
    return self;
}

- (bool)hasNext
{
    return self.index < (self.bookmarksContext.singleBookmark.count-1);
}

- (WatchArrivalsContext *)getNext
{
    WatchArrivalsContext *next = nil;
    if (self.hasNext)
    {
        next = [WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext index:self.index+1];
        
        next.navText = self.navText;
    }
    return next;
}

- (void)updateUserActivity:(WKInterfaceController *)controller
{
    if (!self.bookmarksContext.recents)
    {
        NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
        
        [info setObject:self.bookmarksContext.title forKey:kUserFavesChosenName];
        [info setObject:self.bookmarksContext.location forKey:kUserFavesLocation];
        [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:nil];
    }
}

@end

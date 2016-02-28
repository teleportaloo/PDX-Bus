//
//  WatchBookmarksContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchBookmarksContext.h"
#import "UserFaves.h"

@implementation WatchBookmarksContext

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray *)bookmark title:(NSString *)title locationString:(NSString *)location
{
    WatchBookmarksContext *result = [[[WatchBookmarksContext alloc] init] autorelease];
    result.singleBookmark = bookmark;
    result.title = title;
    result.location = location;
    
    return result;
}

+ (WatchBookmarksContext *)contextForRecents
{
    WatchBookmarksContext *result = [[[WatchBookmarksContext alloc] init] autorelease];
    
    result.recents = YES;
    return result;
}

- (void)updateUserActivity:(WKInterfaceController *)controller
{
    if (!self.recents)
    {
        NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
    
        [info setObject:self.title forKey:kUserFavesChosenName];
        [info setObject:self.location forKey:kUserFavesLocation];
        [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:nil];
    }
    
}

- (id)init
{
    if ((self = [super init]))
    {
        self.sceneName  = kBookmarksScene;
    }
    return self;
}


@end

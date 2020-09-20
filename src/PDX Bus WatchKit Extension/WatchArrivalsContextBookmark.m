//
//  WatchArrivalsContextBookmark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/10/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContextBookmark.h"
#import "UserState.h"

@interface WatchArrivalsContextBookmark ()

@property (nonatomic, strong) WatchBookmarksContext *bookmarksContext;
@property (nonatomic)         NSInteger index;

@end

@implementation WatchArrivalsContextBookmark

+ (WatchArrivalsContextBookmark *)contextFromBookmark:(WatchBookmarksContext *)bookmarksContext index:(NSInteger)index {
    {
        WatchArrivalsContextBookmark *context = [[WatchArrivalsContextBookmark alloc] init];
        
        context.stopId = bookmarksContext.singleBookmark[index];
        context.showMap = NO;
        context.showDistance = NO;
        context.bookmarksContext = bookmarksContext;
        context.index = index;
        
        if (bookmarksContext.dictated) {
            context.navText = @"Next dictated swipe ←";
        } else {
            context.navText = @"Next stop swipe ←";
        }
        
        return context;
    }
}

+ (WatchArrivalsContextBookmark *)contextFromRecents:(WatchBookmarksContext *)bookmarksContext index:(NSInteger)index {
    {
        WatchArrivalsContextBookmark *context = [WatchArrivalsContextBookmark contextFromBookmark:bookmarksContext index:index];
        
        context.navText = @"Next recent swipe ←";
        
        return context;
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        self.sceneName = kArrivalsScene;
    }
    
    return self;
}

- (bool)hasNext {
    return self.index < (self.bookmarksContext.singleBookmark.count - 1);
}

- (WatchArrivalsContext *)next {
    WatchArrivalsContext *next = nil;
    
    if (self.hasNext) {
        next = [WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext index:self.index + 1];
        
        next.navText = self.navText;
    }
    
    return next;
}

- (WatchArrivalsContext *)clone {
    WatchArrivalsContext *clone = nil;
    
    if (self.hasNext) {
        clone = [WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext index:self.index];
        
        clone.navText = self.navText;
    }
    
    return clone;
}

- (void)updateUserActivity:(WKInterfaceController *)controller {
    if (!self.bookmarksContext.recents) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        info[kUserFavesChosenName] = self.bookmarksContext.title;
        info[kUserFavesLocation] = self.bookmarksContext.location;
        [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:nil];
    }
}

@end

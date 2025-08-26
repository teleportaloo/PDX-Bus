//
//  WatchBookmarksContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchBookmarksContext.h"
#import "UserParams.h"
#import "UserState.h"

@interface WatchBookmarksContext ()

@end

@implementation WatchBookmarksContext

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray<NSString *> *)bookmark
                                         title:(NSString *)title
                                locationString:(NSString *)location {
    WatchBookmarksContext *result = [[WatchBookmarksContext alloc] init];

    result.singleBookmark = bookmark;
    result.title = title;
    result.location = location;

    return result;
}

+ (WatchBookmarksContext *)contextForRecents {
    WatchBookmarksContext *result = [[WatchBookmarksContext alloc] init];

    result.recents = YES;
    return result;
}

- (void)updateUserActivity:(WKInterfaceController *)controller {
    if (!self.recents) {
        MutableUserParams *info =
            [MutableUserParams withChosenName:self.title
                                     location:self.location];

        NSUserActivity *userActivity = [[NSUserActivity alloc]
            initWithActivityType:kHandoffUserActivityBookmark];
        userActivity.userInfo = info.dictionary;
        userActivity.webpageURL = nil;
        [controller updateUserActivity:userActivity];
    }
}

- (instancetype)init {
    if ((self = [super initWithSceneName:kBookmarksScene])) {
    }
    return self;
}

@end

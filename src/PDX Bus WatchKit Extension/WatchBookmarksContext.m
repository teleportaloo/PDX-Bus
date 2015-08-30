//
//  WatchBookmarksContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "WatchBookmarksContext.h"

@implementation WatchBookmarksContext

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray *)bookmark title:(NSString *)title
{
    WatchBookmarksContext *result = [[[WatchBookmarksContext alloc] init] autorelease];
    
    result.singleBookmark = bookmark;
    result.title = title;
    
    return result;
}
+ (WatchBookmarksContext *)contextForRecents
{
    WatchBookmarksContext *result = [[[WatchBookmarksContext alloc] init] autorelease];
    
    result.recents = YES;
    
    return result;
}

@end

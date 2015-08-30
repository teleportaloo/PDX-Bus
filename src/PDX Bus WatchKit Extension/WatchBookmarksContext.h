//
//  WatchBookmarksContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WatchBookmarksContext : NSObject

@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray  *singleBookmark;
@property (nonatomic)         bool recents;

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray *)bookmark title:(NSString *)title;
+ (WatchBookmarksContext *)contextForRecents;


@end

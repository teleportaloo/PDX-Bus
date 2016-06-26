//
//  WatchBookmarksContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "WatchContext.h"

#define kBookmarksScene @"Bookmarks"

@interface WatchBookmarksContext : WatchContext

@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray  *singleBookmark;
@property (nonatomic)         bool recents;
@property (nonatomic)         bool dictated;
@property (retain, nonatomic) NSString *location;
@property (nonatomic)         bool oneTimeShowFirst;

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray *)bookmark title:(NSString *)title locationString:(NSString *)location;
+ (WatchBookmarksContext *)contextForRecents;
- (void)updateUserActivity:(WKInterfaceController*)controller;



@end

//
//  WatchBookmarksContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "WatchContext.h"

#define kBookmarksScene @"Bookmarks"

@interface WatchBookmarksContext : WatchContext

@property (strong, nonatomic) NSArray *singleBookmark;
@property (nonatomic)         bool dictated;
@property (copy, nonatomic)   NSString *title;
@property (nonatomic)         bool recents;
@property (copy, nonatomic)   NSString *location;
@property (nonatomic)         bool oneTimeShowFirst;

- (void)updateUserActivity:(WKInterfaceController *)controller;

+ (WatchBookmarksContext *)contextWithBookmark:(NSArray *)bookmark title:(NSString *)title locationString:(NSString *)location;
+ (WatchBookmarksContext *)contextForRecents;

@end

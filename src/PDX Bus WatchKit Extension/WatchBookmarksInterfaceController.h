//
//  WatchBookmarksInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "UserFaves.h"
#import "WatchBookmarksContext.h"
#import "InterfaceControllerWithCommuterBookmark.h"

@interface WatchBookmarksInterfaceController : InterfaceControllerWithCommuterBookmark
{
    WatchBookmarksContext   *_bookmarksContext;
    NSArray                 *_displayedItems;
}
@property (strong, nonatomic) IBOutlet WKInterfaceTable *bookmarkTable;
@property (retain, nonatomic) WatchBookmarksContext *bookmarksContext;
@property (retain, nonatomic) NSArray *displayedItems;
- (IBAction)menuItemHome;
- (IBAction)menuItemCommute;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *topGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *bottomGroup;
- (IBAction)topRecentStops;
- (IBAction)topLocateStops;
- (IBAction)bottomRecentStops;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *mainTextLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *bookmarkLabel;


@end

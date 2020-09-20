//
//  WatchBookmarksInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "UserState.h"
#import "WatchBookmarksContext.h"
#import "InterfaceControllerWithCommuterBookmark.h"
#import "WatchConnectivity/WatchConnectivity.h"

@interface WatchBookmarksInterfaceController : InterfaceControllerWithCommuterBookmark<WCSessionDelegate>

@property (strong, nonatomic) NSUserActivity *userActivity;

@property (strong, nonatomic) IBOutlet WKInterfaceTable *bookmarkTable;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *topGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *mainTextLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *bookmarkLabel;

- (void)applicationDidBecomeActive;
- (void)processUserActivity;

@end

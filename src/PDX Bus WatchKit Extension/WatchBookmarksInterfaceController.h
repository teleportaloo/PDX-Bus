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


#import "InterfaceControllerWithCommuterBookmark.h"
#import "UserState.h"
#import "WatchBookmarksContext.h"
#import "WatchConnectivity/WatchConnectivity.h"
#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface WatchBookmarksInterfaceController
    : InterfaceControllerWithCommuterBookmark <WCSessionDelegate>

@property(strong, nonatomic) NSUserActivity *userActivity;

@property(strong, nonatomic) IBOutlet WKInterfaceTable *bookmarkTable;
@property(strong, nonatomic) IBOutlet WKInterfaceGroup *topGroup;
@property(strong, nonatomic) IBOutlet WKInterfaceLabel *mainTextLabel;
@property(strong, nonatomic) IBOutlet WKInterfaceLabel *bookmarkLabel;
@property(unsafe_unretained, nonatomic)
    IBOutlet WKInterfaceButton *menuHomeButton;
@property(unsafe_unretained, nonatomic)
    IBOutlet WKInterfaceButton *menuCommuteButton;

- (void)applicationDidBecomeActive;
- (void)processUserActivity;

@end

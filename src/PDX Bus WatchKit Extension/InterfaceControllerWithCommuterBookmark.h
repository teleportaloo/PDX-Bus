//
//  InterfaceControllerWithCommuterBookmark.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/6/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "InterfaceControllerWithBackgroundThread.h"
#import "UserFaves.h"

#define kNextScreenTitle @"➡️Commuter"

@interface InterfaceControllerWithCommuterBookmark : InterfaceControllerWithBackgroundThread
{
    bool _nextScreen;
}

@property (copy, nonatomic) NSString *baseTitle;
@property (strong, nonatomic) SafeUserData *faves;
@property (nonatomic, readonly) bool autoCommute;
@property (nonatomic, readonly) bool delayedDisplayOfCommuterBookmark;


- (void)processLocation:(NSDictionary*)location;
- (void)processBookmark:(NSDictionary*)bookmark;
- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce;
- (void)forceCommute;
- (bool)atRoot;

@end

//
//  InterfaceControllerWithCommuterBookmark.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/6/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "InterfaceControllerWithBackgroundThread.h"
#import "UserFaves.h"

@interface InterfaceControllerWithCommuterBookmark : InterfaceControllerWithBackgroundThread
{
    SafeUserData *_faves;
}

@property (retain, nonatomic) SafeUserData *faves;
- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce;
@property (nonatomic, readonly) bool autoCommute;
- (void)forceCommute;
@property (nonatomic, readonly) bool delayedDisplayOfCommuterBookmark;

@end

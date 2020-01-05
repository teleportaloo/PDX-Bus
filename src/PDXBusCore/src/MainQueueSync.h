//
//  MainQueueSync.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainQueueSync : NSObject

+(void) runSyncOnMainQueueWithoutDeadlocking:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END

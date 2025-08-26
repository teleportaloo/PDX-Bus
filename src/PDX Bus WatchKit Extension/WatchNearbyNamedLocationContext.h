//
//  WatchNearbyNamedLocationContext.h
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/26/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface WatchNearbyNamedLocationContext : WatchContext

@property(nonatomic, strong) CLLocation *loc;
@property(nonatomic, copy) NSString *name;

+ (WatchNearbyNamedLocationContext *)contextWithName:(NSString *)name
                                            location:(CLLocation *)loc;

@end

NS_ASSUME_NONNULL_END

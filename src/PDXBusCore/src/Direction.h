//
//  Direction.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop.h"

NS_ASSUME_NONNULL_BEGIN

@interface Direction : NSObject

@property(nonatomic, copy) NSString *dir;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, retain) NSMutableArray<Stop *> *stops;

+ (Direction *)withDir:(NSString *)dir desc:(NSString *)desc;

- (NSComparisonResult)compare:(Direction *)other;

@end

NS_ASSUME_NONNULL_END

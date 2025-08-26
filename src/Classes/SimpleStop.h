//
//  SimpleStop.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/6/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SimpleAnnotation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleStop : SimpleAnnotation

@property(nonatomic, copy) NSString *stopId;

@end

NS_ASSUME_NONNULL_END

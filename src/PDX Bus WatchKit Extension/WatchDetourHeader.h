//
//  WatchDetourHeader.h
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 8/13/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface WatchDetourHeader : WatchRow
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *label;

@end

NS_ASSUME_NONNULL_END

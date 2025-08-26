//
//  TriMetInfo+UI.h
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetInfo.h"
#import "UIColor+MoreDarkMode.h"

NS_ASSUME_NONNULL_BEGIN

@interface TriMetInfo (UI)

+ (UIColor *_Nullable)colorForRoute:(NSString *)route;

@end

NS_ASSUME_NONNULL_END

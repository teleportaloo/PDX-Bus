//
//  RailStation+UI.h
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"
#import "RailStationViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface RailStation (UI)

+ (RailStationViewCell *)tableView:(UITableView *)tableView
           cellWithReuseIdentifier:(NSString *)identifier
                         rowHeight:(CGFloat)height
                       rightMargin:(bool)rightMargin;

+ (RailStationViewCell *)tableView:(UITableView *)tableView
           cellWithReuseIdentifier:(NSString *)identifier
                         rowHeight:(CGFloat)height
                       rightMargin:(bool)rightMargin
                       fixedMargin:(CGFloat)fixedMargin;

@end

NS_ASSUME_NONNULL_END

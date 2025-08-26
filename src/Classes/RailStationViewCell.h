//
//  RailStationViewCell.h
//  PDX Bus
//
//  Created by Andy Wallace on 10/12/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetInfoColoredLines.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RailStationViewCell : UITableViewCell

- (void)configWithRowHeight:(CGFloat)height
                rightMargin:(bool)rightMargin
                fixedMargin:(CGFloat)fixedMargin;
- (void)populateCellWithStation:(NSString *)station
                          lines:(TriMetInfo_ColoredLines)lines;

@end

NS_ASSUME_NONNULL_END

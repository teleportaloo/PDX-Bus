//
//  RailStation+UI.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AllRailStationViewController.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "RailStation+UI.h"
#import "RailStationViewCell.h"
#import "RouteColorBlobView.h"

@implementation RailStation (UI)

#define MAX_TAG 2
#define MAX_LINES 4
#define LABEL_TAG 1000
#define LINES_TAG 2000

+ (RailStationViewCell *)tableView:(UITableView *)tableView
           cellWithReuseIdentifier:(NSString *)identifier
                         rowHeight:(CGFloat)height
                       rightMargin:(bool)rightMargin {
    RailStationViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (cell == nil) {

        cell = [[RailStationViewCell alloc]
              initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:identifier];

        [cell configWithRowHeight:height
                      rightMargin:rightMargin
                      fixedMargin:0.0];
    }

    return cell;
}

+ (RailStationViewCell *)tableView:(UITableView *)tableView
           cellWithReuseIdentifier:(NSString *)identifier
                         rowHeight:(CGFloat)height
                       rightMargin:(bool)rightMargin
                       fixedMargin:(CGFloat)fixedMargin {
    RailStationViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (cell == nil) {

        cell = [[RailStationViewCell alloc]
              initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:identifier];

        [cell configWithRowHeight:height
                      rightMargin:rightMargin
                      fixedMargin:fixedMargin];
    }

    return cell;
}

@end

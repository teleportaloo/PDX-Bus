//
//  WhatsNewHighlight.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/14/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewHighlight.h"

@implementation WhatsNewHighlight

+ (NSNumber*)getPrefix
{
    return @'!';
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString*)text
{
    cell.backgroundColor = [UIColor redColor];
}

- (void)updateCell:(UITableViewCell *)cell tableView:(UITableView *)tableView
{
    cell.textLabel.backgroundColor  = [UIColor clearColor];
    cell.textLabel.textAlignment    = NSTextAlignmentLeft;
    cell.accessoryType              = UITableViewCellAccessoryNone;
    cell.selectionStyle             = UITableViewCellSelectionStyleNone;
}

- (NSString*)displayText:(NSString*)fullText
{
    return [fullText substringFromIndex:1];
}


@end


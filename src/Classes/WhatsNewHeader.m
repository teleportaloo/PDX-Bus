//
//  WhatsNewHeader.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewHeader.h"

@implementation WhatsNewHeader

+ (NSNumber*)getPrefix
{
    return @'.';
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString*)text
{
    int color = [UserPrefs singleton].toolbarColors;
	
	if (color == 0xFFFFFF)
    {
        cell.backgroundColor = [UIColor grayColor];
    }
    else
    {
        cell.backgroundColor = [ViewControllerBase htmlColor:color];
    }
}

- (void)updateCell:(CellLabel *)cell tableView:(UITableView *)tableView
{
    cell.view.backgroundColor = [UIColor clearColor];
    cell.view.textAlignment   = NSTextAlignmentCenter;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;
}

- (NSString*)displayText:(NSString*)fullText
{
    return [fullText substringFromIndex:1];
}

- (NSString*)plainText:(NSString*)fullText
{
    return [self plainTextNormal:fullText];
}

@end

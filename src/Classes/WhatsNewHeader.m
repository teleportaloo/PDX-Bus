//
//  WhatsNewHeader.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewHeader.h"
#import "TriMetInfo.h"

@implementation WhatsNewHeader

+ (NSNumber*)getPrefix
{
    return @'.';
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString*)text
{
    int color = [UserPrefs sharedInstance].toolbarColors;
	
	if (color == 0xFFFFFF)
    {
        cell.backgroundColor = [UIColor grayColor];
    }
    else
    {
        cell.backgroundColor = HTML_COLOR(color);
    }
}

- (void)updateCell:(UITableViewCell *)cell tableView:(UITableView *)tableView
{
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment   = NSTextAlignmentCenter;
    cell.accessoryType             = UITableViewCellAccessoryNone;
    cell.selectionStyle            = UITableViewCellSelectionStyleNone;
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

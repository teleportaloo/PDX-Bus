//
//  WhatsNewSelector.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewSelector.h"

@implementation WhatsNewSelector

+ (NSNumber*)getPrefix
{
    return [NSNumber numberWithChar:'#'];
}

- (void)updateCell:(CellLabel *)cell tableView:(UITableView *)tableView
{
    cell.view.backgroundColor   = [UIColor clearColor];
    cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
    cell.view.textAlignment     = UITextAlignmentLeft;
    cell.selectionStyle         = UITableViewCellSelectionStyleBlue;
}

- (void)processAction:(NSString *)text parent:(ViewControllerBase*)parent
{
    NSString *selector = [self prefix:text restOfText:nil];
    
    SEL action = NSSelectorFromString(selector);
    
    if ([parent respondsToSelector:action])
    {
        [parent performSelector:action];
    }
}

- (NSString*)displayText:(NSString*)fullText
{
    NSString *rest = nil;
    [self prefix:fullText restOfText:&rest];
    return rest;
}


@end

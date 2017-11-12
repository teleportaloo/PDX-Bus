//
//  WhatsNewBasicAction.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewBasicAction.h"
#import "StringHelper.h"

@implementation WhatsNewBasicAction

+ (NSNumber*)getPrefix
{
    return nil;
}

- (void)processAction:(NSString *)text parent:(ViewControllerBase*)parent
{
    [parent.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString*)text
{
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)updateCell:(UITableViewCell *)cell tableView:(UITableView *)tableView
{
    cell.textLabel.backgroundColor  = [UIColor clearColor];
    cell.textLabel.textAlignment    = NSTextAlignmentLeft;
    cell.accessoryType              = UITableViewCellAccessoryNone;
    cell.selectionStyle             = UITableViewCellSelectionStyleNone;
}

- (NSString*)prefix:(NSString *)item restOfText:(NSString**)rest
{
    NSScanner *scanner = [NSScanner scannerWithString:item];
    NSString *prefix = nil;
    
    if (scanner.atEnd)
    {
        return nil;
    }
    
    scanner.scanLocation = 1;
    
    [scanner scanUpToString:@" " intoString:&prefix];
    
    if (rest && !scanner.atEnd)
    {
        *rest = [item substringFromIndex:scanner.scanLocation+1];
    }
    
    return prefix;
    
}

- (NSString*)displayText:(NSString*)fullText
{
    return fullText;
}

- (NSString*)plainTextNormal:(NSString*)fullText
{
    NSAttributedString *text = [[self displayText:fullText] formatAttributedStringWithFont:[UIFont systemFontOfSize:14]];
    
    return text.string;
}

- (NSString*)plainTextIndented:(NSString*)fullText
{
    NSAttributedString *text = [[self displayText:fullText] formatAttributedStringWithFont:[UIFont systemFontOfSize:14]];
    
    return [NSString stringWithFormat:@"- %@",text.string];
}

- (NSString*)plainText:(NSString*)fullText
{
    return [self plainTextIndented:fullText];
}



@end

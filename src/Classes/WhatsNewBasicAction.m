//
//  WhatsNewBasicAction.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewBasicAction.h"
#import "StringHelper.h"

@implementation WhatsNewBasicAction

+ (instancetype)action
{
    return [[[self class] alloc] init];
}

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
    return [self displayText:fullText].removeFormatting;
}

- (NSString*)plainTextIndented:(NSString*)fullText
{    
    return [NSString stringWithFormat:@"- %@",[self displayText:fullText].removeFormatting];
}

- (NSString*)plainText:(NSString*)fullText
{
    return [self plainTextIndented:fullText];
}

+ (bool)matches:(NSString *)string
{
    return [@(string.firstUnichar) isEqualToNumber:[[self class] getPrefix]];
}



@end

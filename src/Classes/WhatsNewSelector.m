//
//  WhatsNewSelector.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewSelector.h"

@implementation WhatsNewSelector

+ (NSNumber *)getPrefix {
    return @'$';
}

- (void)updateCell:(LinkCell *)cell tableView:(UITableView *)tableView {
    cell.textView.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textView.textAlignment = NSTextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)processAction:(NSString *)text parent:(ViewControllerBase *)parent {
    NSString *selector = [self prefix:text restOfText:nil];
    
    NSString *fullSelector = [NSString stringWithFormat:@"xxx%@", selector];
    
    SEL action = NSSelectorFromString(fullSelector);
    
    if ([parent respondsToSelector:action]) {
        void (*actionFunc)(id, SEL) = (void *)[parent methodForSelector:action];
        actionFunc(parent, action);
    }
}

- (NSString *)displayMarkedUpText:(NSString *)fullText {
    NSString *rest = nil;
    
    [self prefix:fullText restOfText:&rest];
    return rest;
}

@end

//
//  WhatsNewView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "LinkCell.h"

@protocol WhatsNewSpecialAction <NSObject>

- (void)processAction:(NSString *)text parent:(ViewControllerBase *)parent;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString *)text;
- (void)updateCell:(LinkCell *)cell tableView:(UITableView *)tableView;
- (NSString *)displayMarkedUpText:(NSString *)fullText;
- (NSString *)plainTextFromMarkUp:(NSString *)fullText;

+ (NSNumber *)getPrefix;

@end

typedef NSMutableArray<NSString *> WhatsNewSection;


@interface WhatsNewView : TableViewWithToolbar<WhatsNewSection *>

+ (NSString *)version;

@end

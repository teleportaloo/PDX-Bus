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

#define kWhatsNewVersion @"10.0"

@protocol WhatsNewSpecialAction <NSObject>

+ (NSNumber*)getPrefix;
- (void)processAction:(NSString *)text parent:(ViewControllerBase*)parent;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell text:(NSString*)text;
- (void)updateCell:(UITableViewCell *)cell tableView:(UITableView *)tableView;
- (NSString*)displayText:(NSString *)fullText;
- (NSString*)plainText:(NSString *)fullText;

@end
	
@interface WhatsNewView : TableViewWithToolbar {
    NSArray *                       _newTextArray;
    NSDictionary *                  _specialActions;
    id<WhatsNewSpecialAction>       _basicAction;
}


@end

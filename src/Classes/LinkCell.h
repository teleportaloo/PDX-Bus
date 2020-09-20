//
//  LinkCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/5/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "LinkResponsiveTextView.h"

@class LinkCell;

typedef bool (^urlAction) (LinkCell *cell,  NSString *url);

NS_ASSUME_NONNULL_BEGIN

@interface LinkCell : UITableViewCell <UITextViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet LinkResponsiveTextView *textView;
@property (nonatomic, copy) urlAction urlCallback;

+ (UINib *)nib;


@end

NS_ASSUME_NONNULL_END

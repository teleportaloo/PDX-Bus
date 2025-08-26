//
//  SelectableTextViewCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/26/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LinkResponsiveTextView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectableTextViewCell : UITableViewCell

- (LinkResponsiveTextView *__nullable)textView;
- (void)resetForReuse;

@end

NS_ASSUME_NONNULL_END

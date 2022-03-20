//
//  LinkResponsiveTextView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LinkResponsiveTextView;

typedef bool (^LinkResponsiveTextViewActionBlock) (LinkResponsiveTextView *view, NSURL *url, NSRange characterRange, UITextItemInteraction interaction);

@interface LinkResponsiveTextView : UITextView <UITextViewDelegate>

@property (nonatomic, copy) LinkResponsiveTextViewActionBlock linkAction;
@property (nonatomic) bool allowSelection;

@end

NS_ASSUME_NONNULL_END

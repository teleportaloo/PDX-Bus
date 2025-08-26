//
//  UIPlaceHolderTextView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/14/19.
//  https://stackoverflow.com/questions/1328638/placeholder-in-uitextview
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface UIPlaceHolderTextView : UITextView

@property(nonatomic, strong) IBInspectable NSString *placeholder;
@property(nonatomic, strong) IBInspectable UIColor *placeholderColor;

- (void)textChanged:(NSNotification *__nullable)notification;

@end

NS_ASSUME_NONNULL_END

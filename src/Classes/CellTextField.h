//
//  CellTextField.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "EditableTableViewCell.h"
#import <UIKit/UIKit.h>

@interface CellTextField : EditableTableViewCell <UITextFieldDelegate>

@property(nonatomic, strong) UITextField *view;
@property CGFloat cellLeftOffset;

+ (CGFloat)cellHeight;
+ (CGFloat)editHeight;
+ (void)initHeight;
+ (UIFont *)editFont;

@end

//
//  CellTextField.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <UIKit/UIKit.h>
#import "EditableTableViewCell.h"

@interface CellTextField : EditableTableViewCell <UITextFieldDelegate>
{
    UITextField *   _view;
	CGFloat         _cellLeftOffset;
}

@property (nonatomic, retain) UITextField *view;
@property CGFloat cellLeftOffset;

+(CGFloat)cellHeight;
+(CGFloat)editHeight;
+(void)initHeight;
+(UIFont *)editFont;

@end

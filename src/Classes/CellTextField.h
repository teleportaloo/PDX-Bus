//
//  CellTextField.h
//  PDX Bus
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


#import <UIKit/UIKit.h>
#import "EditableTableViewCell.h"

@interface CellTextField : EditableTableViewCell <UITextFieldDelegate>
{
    UITextField *_view;
	CGFloat _cellLeftOffset;
}

@property (nonatomic, retain) UITextField *view;
@property CGFloat cellLeftOffset;

+(CGFloat)cellHeight;
+(CGFloat)editHeight;
+(void)initHeight;
+(UIFont *)editFont;

@end

//
//  EditableTableViewCell.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@protocol EditableTableViewCellDelegate;

@interface EditableTableViewCell : UITableViewCell
{
    id <EditableTableViewCellDelegate>  _delegate;
    BOOL                                _isInlineEditing;
}

// Exposes the delegate property to other objects.
@property (nonatomic, assign) id <EditableTableViewCellDelegate> delegate;
@property (nonatomic, assign) BOOL isInlineEditing;

// Informs the cell to stop editing, resulting in keyboard/pickers/etc. being ordered out 
// and first responder status resigned.
- (void)stopEditing;

@end

// Protocol to be adopted by an object wishing to customize cell behavior with respect to editing.
@protocol EditableTableViewCellDelegate <NSObject>

@optional

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell;
// Invoked after editing ends.
- (void)cellDidEndEditing:(EditableTableViewCell *)cell;

@end

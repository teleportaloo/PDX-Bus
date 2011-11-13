//
//  CustomToolbar.m
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
 
#import "CellTextField.h"
#import "ScreenConstants.h"

// UITableView row heights
#define kUIRowHeight			50.0
#define kUIBigRowHeight			60.0
#define kUIRowLabelHeight		22.0

// table view cell content offsets
#define kCellLeftOffset			8.0

#define kCellTopOffset			12.0

#define kTextFieldHeight		30.0
#define kBigTextFieldHeight	    40.0

@implementation CellTextField

@dynamic view;
@synthesize cellLeftOffset = _cellLeftOffset;
static CGRect bounds;
static bool bigScreen;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
	self = [super initWithStyle:style reuseIdentifier:identifier];
	if (self)
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.cellLeftOffset = kCellLeftOffset;
		
	}
	return self;
}

- (void)setView:(UITextField *)inView
{
    if (_view != nil)
    {
        [_view release];
        _view = nil;
    } 
	_view = [inView retain];
	_view.delegate = self;
	
	[self.contentView addSubview:inView];
	[self layoutSubviews];
}

- (UITextField *)view
{
    return _view;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	
	CGRect frame = CGRectMake(	contentRect.origin.x + self.cellLeftOffset,
								contentRect.origin.y + (([CellTextField cellHeight] - [CellTextField editHeight])/2),
								contentRect.size.width - (self.cellLeftOffset + 8.0),
								[CellTextField editHeight]);
	self.view.frame  = frame;
}

- (void)dealloc
{
    if (_view != nil)
    {
        [_view release];
    }
    [super dealloc];
}

- (void)stopEditing
{
    [_view resignFirstResponder];
}

+(void)initHeight
{
	if (bounds.size.width == 0)
	{
		bounds = [[UIScreen mainScreen] bounds];
		
		// Small devices do not need to orient
		if (bounds.size.width <= kSmallestSmallScreenDimension)
		{
			bigScreen = false;
		}
		else {
			bigScreen = true;
		}
	}
}

+(CGFloat)cellHeight
{
	[CellTextField initHeight];
	
	if (bigScreen)
	{
		return kUIBigRowHeight;
	}
	return kUIRowHeight;
}
							  
+(CGFloat)editHeight
{
	[CellTextField initHeight];
	
	if (bigScreen)
	{
		return kBigTextFieldHeight;
	}
	return kTextFieldHeight;
}
							  
+(UIFont *)editFont
{
	[CellTextField initHeight];
	
	if (bigScreen)
	{
		return [UIFont systemFontOfSize:24.0];
	}
	return [UIFont systemFontOfSize:17.0];
	
}

#pragma mark -
#pragma mark <UITextFieldDelegate> Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL beginEditing = YES;
    // Allow the cell delegate to override the decision to begin editing.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellShouldBeginEditing:)])
	{
        beginEditing = [self.delegate cellShouldBeginEditing:self];
    }
    // Update internal state.
    if (beginEditing)
		self.isInlineEditing = YES;
    return beginEditing;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Notify the cell delegate that editing ended.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidEndEditing:)])
	{
        [self.delegate cellDidEndEditing:self];
    }
    // Update internal state.
    self.isInlineEditing = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self stopEditing];
    return YES;
}

@end

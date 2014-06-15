//
//  CellLabel.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CellLabel.h"


@implementation CellLabel

// cell identifier for this custom cell
NSString* kCellLabelView_ID = @"CellTextView_ID";

#define kInsertValue	8.0


@dynamic view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
	self = [super initWithStyle:style reuseIdentifier:identifier];
	if (self)
	{
		// turn off selection use
//		self.selectionStyle = UITableViewCellSelectionStyleNone;
        _view = nil;
	}
	return self;
}

- (void)setView:(UILabel *)inView
{
    if (_view !=nil)
    {
        [_view release];
        _view = nil;
    }
	_view = [inView retain];
    
	[self.contentView addSubview:inView];
	[self layoutSubviews];
}

- (UILabel *)view
{
    return _view;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	
	// inset the text view within the cell
	if (contentRect.size.width > (kInsertValue*2))	// but not if the width is too small
	{
		self.view.frame  = CGRectMake(contentRect.origin.x + kInsertValue,
									  contentRect.origin.y + kInsertValue,
									  contentRect.size.width - (kInsertValue*2),
									  contentRect.size.height - (kInsertValue*2));
	}
}

- (void)dealloc
{
    if (_view !=nil)
    {
        [_view release];
    }
    [super dealloc];
}



@end

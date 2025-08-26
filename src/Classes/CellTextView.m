//
//  CellTextView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CellTextView.h"

#define kInsertValue 8.0

@interface CellTextView () {
    UITextView *_view;
}

@end

@implementation CellTextView

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];

    if (self) {
        // turn off selection use
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _view = nil;
    }

    return self;
}

- (void)setView:(UITextView *)inView {
    _view = nil;
    _view.delegate = nil;
    _view = inView;
    _view.delegate = self;

    [self.contentView addSubview:inView];
    [self layoutSubviews];
}

- (UITextView *)view {
    return _view;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.contentView.bounds;

    // inset the text view within the cell
    if (contentRect.size.width >
        (kInsertValue * 2)) { // but not if the width is too small
        self.view.frame = CGRectMake(
            contentRect.origin.x + kInsertValue + self.cellLeftOffset,
            contentRect.origin.y + kInsertValue,
            contentRect.size.width - (kInsertValue * 2) - self.cellLeftOffset,
            contentRect.size.height - (kInsertValue * 2));
    }
}

#pragma mark -
#pragma mark <UITextViewDelegate> Methods

- (BOOL)textViewShouldBeginEditing:(UITextField *)textField {
    BOOL beginEditing = YES;

    // Allow the cell delegate to override the decision to begin editing.
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(cellShouldBeginEditing:)]) {
        beginEditing = [self.delegate cellShouldBeginEditing:self];
    }

    // Update internal state.
    if (beginEditing) {
        self.isInlineEditing = YES;
    }

    return beginEditing;
}

- (void)textViewDidEndEditing:(UITextField *)textField {
    // Notify the cell delegate that editing ended.
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(cellDidEndEditing:)]) {
        [self.delegate cellDidEndEditing:self];
    }

    // Update internal state.
    self.isInlineEditing = NO;
}

- (BOOL)textViewdShouldReturn:(UITextField *)textField {
    [self stopEditing];
    return YES;
}

- (void)stopEditing {
    [_view resignFirstResponder];
}

@end

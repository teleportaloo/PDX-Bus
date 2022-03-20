//
//  CustomToolbar.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CellTextField.h"
#import "ScreenConstants.h"
#import "UIFont+Utility.h"

// UITableView row heights
#define kUIRowHeight        50.0
#define kUIBigRowHeight     60.0
#define kUIRowLabelHeight   22.0

// table view cell content offsets
#define kCellLeftOffset     8.0
#define kCellTopOffset      12.0
#define kTextFieldHeight    30.0
#define kBigTextFieldHeight 40.0

@interface CellTextField () {
    UITextField *_view;
}

@end

@implementation CellTextField

static CGRect bounds;
static bool bigScreen;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];
    
    if (self) {
        // turn off selection use
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.cellLeftOffset = kCellLeftOffset;
    }
    
    return self;
}

- (void)setView:(UITextField *)inView {
    if (_view != nil) {
        _view = nil;
    }
    
    _view = inView;
    _view.delegate = self;
    
    [self.contentView addSubview:inView];
    [self layoutSubviews];
}

- (UITextField *)view {
    return _view;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentRect = self.contentView.bounds;
    
    CGRect frame = CGRectMake(contentRect.origin.x + self.cellLeftOffset,
                              contentRect.origin.y + (([CellTextField cellHeight] - [CellTextField editHeight]) / 2),
                              contentRect.size.width - (self.cellLeftOffset + 8.0),
                              [CellTextField editHeight]);
    
    self.view.frame = frame;
}

- (void)stopEditing {
    [_view resignFirstResponder];
}

+ (void)initHeight {
    if (bounds.size.width == 0) {
        bounds = [UIScreen mainScreen].bounds;
        
        // Small devices do not need to orient
        if (bounds.size.width <= MaxiPhoneWidth) {
            bigScreen = false;
        } else {
            bigScreen = true;
        }
    }
}

+ (CGFloat)cellHeight {
    [CellTextField initHeight];
    
    if (bigScreen) {
        return kUIBigRowHeight;
    }
    
    return kUIRowHeight;
}

+ (CGFloat)editHeight {
    [CellTextField initHeight];
    
    if (bigScreen) {
        return kBigTextFieldHeight;
    }
    
    return kTextFieldHeight;
}

+ (UIFont *)editFont {
    [CellTextField initHeight];
    
    if (bigScreen) {
        return [UIFont monospacedDigitSystemFontOfSize:24.0];
    }
    
    return [UIFont monospacedDigitSystemFontOfSize:17.0];
}

#pragma mark -
#pragma mark <UITextFieldDelegate> Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL beginEditing = YES;
    
    // Allow the cell delegate to override the decision to begin editing.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellShouldBeginEditing:)]) {
        beginEditing = [self.delegate cellShouldBeginEditing:self];
    }
    
    // Update internal state.
    if (beginEditing) {
        self.isInlineEditing = YES;
    }
    
    return beginEditing;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // Notify the cell delegate that editing ended.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidEndEditing:)]) {
        [self.delegate cellDidEndEditing:self];
    }
    
    // Update internal state.
    self.isInlineEditing = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self stopEditing];
    return YES;
}

@end

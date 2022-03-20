//
//  SelectableTextViewCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/26/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "SelectableTextViewCell.h"

@implementation SelectableTextViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UITextView *)textView {
    return nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    [self addGestureRecognizer:longPressGesture];
}

- (bool)canBecomeFirstResponder {
    return YES;
}

- (void)enableSelection:(id)sender {
    self.textView.allowSelection = YES;
    [self.textView selectAll:nil];
    [self setMenu];
}

- (void)disableSelection:(id)sender {
    self.textView.allowSelection = NO;
    self.textView.selectedTextRange = nil;
    [self setMenu];
}

- (void)resetForReuse {
    [self disableSelection:nil];
}

- (bool)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (action == @selector(enableSelection:)) {
        return YES;
    } else if (action == @selector(disableSelection:)) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
    
}

- (UIMenuController *)setMenu {
    UIMenuController *menu = UIMenuController.sharedMenuController;
    
    if (self.textView.allowSelection) {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Disable selection", @"menu") action:@selector(disableSelection:)];
        menu.menuItems = @[item];
    } else {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Select all", @"menu") action:@selector(enableSelection:)];
        menu.menuItems = @[item];
    }
    return menu;
}

- (void)showMenu:(CGPoint)location inView:(UIView *)view {
    bool firstResponder = view.becomeFirstResponder;
    
    NSAssert(firstResponder, @"UIMenuController must be on first responder");
    
    UIMenuController *menu = [self setMenu];
    
    [menu setTargetRect:view.bounds inView:view];
    [menu setMenuVisible:TRUE animated:TRUE];
    
    
    DEBUG_LOG(@"first responder %d menu width %f, visible %d", firstResponder, menu.menuFrame.size.width, menu.menuVisible);
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (recognizer.view !=nil) {
        CGPoint location = [recognizer locationInView:recognizer.view];
        
        [self showMenu:location inView:recognizer.view];
    }
}

@end

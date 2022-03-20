//
//  LinkResponsiveTextView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "LinkResponsiveTextView.h"

@implementation LinkResponsiveTextView

- (instancetype)init {
    if ((self = [super init])) {
        [self setupLinkDetection];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setupLinkDetection];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupLinkDetection];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self setupLinkDetection];
    }
    
    return self;
}

- (void)setupLinkDetection {
    self.selectable = YES;
    self.dataDetectorTypes = UIDataDetectorTypeLink;
    self.editable = NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // location of the tap
    CGPoint location = point;
    
    location.x -= self.textContainerInset.left;
    location.y -= self.textContainerInset.top;
    
    // find the character that's been tapped
    NSInteger characterIndex = [self.layoutManager characterIndexForPoint:location inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    
    if (characterIndex < self.textStorage.length) {
        // if the character is a link, handle the tap as UITextView normally would
        if ([self.textStorage attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:nil] != nil) {
            return self;
        }
    }
    
    // otherwise return nil so the tap goes on to the next receiver
    return self.allowSelection ? self : nil;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (self.linkAction)
    {
        return self.linkAction(self, URL, characterRange, interaction);
    }
    
    return NO;
}

- (bool)canBecomeFirstResponder {
    return YES;
}

/*
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSString *selectorString = NSStringFromSelector(action);
    
    
    NSSet *selectors = [NSSet setWithArray:@[ @"_accessibilitySpeak:",  @"copy:", @"_translate:", @"_share:" ]];;
    
    BOOL canDo = [selectors containsObject:selectorString];
    
    DEBUG_LOGB(canDo);
    
    if (canDo) {
        //(re)add menuItems to UIMenuController
        DEBUG_LOG(@"Can do action %@", selectorString);
        return YES;
    } else if ([super canPerformAction:action withSender:sender]) {
        DEBUG_LOG(@"Would do action %@", selectorString);
    } else {
        DEBUG_LOG(@"Won't ever do action %@", selectorString);
    }

    return NO;
}
 */





@end

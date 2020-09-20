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


#import "LinkResponsiveTextView.h"

@implementation LinkResponsiveTextView

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
    return nil;
}

@end

//
//  DetourTableViewCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/5/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LinkCell.h"

@implementation LinkCell


+ (UINib *)nib {
    return [UINib nibWithNibName:@"LinkCell" bundle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.textView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (self.urlCallback)
    {
        return self.urlCallback(self, URL.absoluteString);
    }
    
    return TRUE;
}


@end

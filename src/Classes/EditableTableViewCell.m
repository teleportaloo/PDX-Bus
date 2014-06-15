//
//  EditableTableViewCell.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "EditableTableViewCell.h"

@implementation EditableTableViewCell

@synthesize delegate;
@synthesize isInlineEditing;

// To be implemented by subclasses. 
- (void)stopEditing
{}

@end

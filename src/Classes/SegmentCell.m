//
//  SegmentCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/27/11.
//  Copyright 2011. All rights reserved.
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

#import "SegmentCell.h"

#define kSegRowWidth		320.0
#define kSegRowHeight		50.0
#define kUISegHeight		40.0
#define kUISegWidth			310.0
// #define kUISegWidth			200.0

@implementation SegmentCell

@synthesize segment = _segment;

- (void)createSegmentWithContent:(NSArray*)content target:(NSObject *)target action:(SEL)action
{
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	
	self.segment						= [[[UISegmentedControl alloc] initWithItems:content] autorelease];
	self.segment.frame					= frame;
	self.segment.segmentedControlStyle	= UISegmentedControlStylePlain;
	self.segment.autoresizingMask		= UIViewAutoresizingFlexibleWidth;
	[self.segment addTarget:target action:action forControlEvents:UIControlEventValueChanged];
	[self.contentView addSubview:self.segment];
	[self layoutSubviews];
}

- (void)dealloc {
    
	self.segment = nil;
    [super dealloc];
}

+ (CGFloat)segmentCellHeight
{
	return kSegRowHeight;
}


@end

//
//  Detour.m
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

#import "Detour.h"
#import <UIKit/UIStringDrawing.h>


@implementation Detour

@synthesize routeDesc = _routeDesc;
@synthesize detourDesc = _detourDesc;
@synthesize route = _route;

#define kFontName				@"Arial"
#define kTextViewFontSize		16.0

+ (UILabel *)create_UITextView:(UIFont *)font
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	
	UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = font;
    textView.backgroundColor = [UIColor clearColor];
	textView.lineBreakMode =   UILineBreakModeWordWrap;
	textView.adjustsFontSizeToFitWidth = YES;
	textView.numberOfLines = 0;
		
	return textView;
}

- (void) dealloc
{
	self.routeDesc = nil;
	self.detourDesc = nil;
	self.route = nil;
	[super dealloc];
}

@end

//
//  Detour.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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

//
//  DetourUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/5/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "DetourData+iOSUI.h"
#import <UIKit/UIStringDrawing.h>

@implementation Detour (iOSUI)

+ (UILabel *)create_UITextView:(UIFont *)font
{
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
    
    UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = font;
    textView.backgroundColor = [UIColor clearColor];
    textView.lineBreakMode =   NSLineBreakByWordWrapping;
    textView.adjustsFontSizeToFitWidth = YES;
    textView.numberOfLines = 0;
    
    return textView;
}

@end

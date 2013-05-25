//
//  ProgressModal.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
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

#import <UIKit/UIKit.h>

@protocol ProgressDelegate <NSObject>

- (void) ProgressDelegateCancel;

@end


@interface ProgressModalView : UIView {
	UIActivityIndicatorView *_whirly;
	UIProgressView *_progress;
	id<ProgressDelegate> _progressDelegate;
	UILabel *_subText;
    UILabel *_helpText;
   	int _items;
}

- (void) itemsDone:(int)itemsDone;
+ (ProgressModalView *)initWithSuper:(UIView *)back items:(int)items title:(NSString *)title delegate:(id<ProgressDelegate>)delegate
						 orientation:(UIInterfaceOrientation)orientation;
- (void) addSubtext:(NSString *)subtext;
- (void) addHelpText:(NSString *)helpText;


@property (nonatomic, assign) id<ProgressDelegate> progressDelegate;
@property (nonatomic) int items;
@property (nonatomic, retain) UIActivityIndicatorView *whirly;
@property (nonatomic, retain) UIProgressView *progress;
@property (nonatomic, retain) UILabel *subText;
@property (nonatomic, retain) UILabel *helpText;
@property (nonatomic, retain) UIView *helpFrame;


@end


@interface RoundedTransparentRect : UIView 
{
	CGFloat BACKGROUND_OPACITY;
	CGFloat R;
	CGFloat G;
	CGFloat B;
}

@property (nonatomic) CGFloat BACKGROUND_OPACITY;
@property (nonatomic) CGFloat R;
@property (nonatomic) CGFloat G;
@property (nonatomic) CGFloat B;



@end


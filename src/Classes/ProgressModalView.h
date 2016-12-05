//
//  ProgressModal.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@protocol ProgressDelegate <NSObject>

- (void) ProgressDelegateCancel;

@end


@interface ProgressModalView : UIView {
	UIActivityIndicatorView *   _whirly;
	UIProgressView *            _progress;
	id<ProgressDelegate>        _progressDelegate;
	UILabel *                   _subText;
    UILabel *                   _helpText;
   	int                         _totalItems;
    int                         _itemsDone;
}

- (void) itemsDone:(int)itemsDone;
- (void) totalItems:(int)total;
+ (ProgressModalView *)initWithSuper:(UIView *)back items:(int)items title:(NSString *)title delegate:(id<ProgressDelegate>)delegate
						 orientation:(UIInterfaceOrientation)orientation;
- (void) addSubtext:(NSString *)subtext;
- (void) addHelpText:(NSString *)helpText;


@property (nonatomic, assign) id<ProgressDelegate> progressDelegate;
@property (nonatomic) int totalItems;
@property (nonatomic) int itemsDone;
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


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

- (void) progressDelegateCancel;

@end


@interface ProgressModalView : UIView 

@property (nonatomic, weak) id<ProgressDelegate> progressDelegate;
@property (nonatomic) NSInteger totalItems;
@property (nonatomic) NSInteger itemsDone;
@property (nonatomic, strong) UIActivityIndicatorView *whirly;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) UILabel *subText;
@property (nonatomic, strong) UILabel *helpText;
@property (nonatomic, strong) UIView *helpFrame;

- (void) itemsDone:(NSInteger)itemsDone;
- (void) subItemsDone:(NSInteger)subItemsDone totalSubs:(NSInteger)totalSubs;
- (void) totalItems:(NSInteger)total;
- (void) addSubtext:(NSString *)subtext;
- (void) addHelpText:(NSString *)helpText;

+ (ProgressModalView *)initWithSuper:(UIView *)back items:(NSInteger)items title:(NSString *)title delegate:(id<ProgressDelegate>)delegate
                         orientation:(UIInterfaceOrientation)orientation;

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


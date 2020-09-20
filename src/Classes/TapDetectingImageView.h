
/*
 File: TapDetectingImageView.h
 
 */



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TilingView.h"
@protocol TapDetectingImageViewDelegate;

@interface TapDetectingImageView : TilingView

@property (nonatomic, weak) id <TapDetectingImageViewDelegate> delegate;

- (instancetype)initWithImageName:(NSString *)image size:(CGSize)size;

@end


/*
 Protocol for the tap-detecting image view's delegate.
 */
@protocol TapDetectingImageViewDelegate <NSObject>

@optional
- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint;

@end

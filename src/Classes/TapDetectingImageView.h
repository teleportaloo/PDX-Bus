
/*
     File: TapDetectingImageView.h

 */



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#include "TilingView.h"
@protocol TapDetectingImageViewDelegate;



@interface TapDetectingImageView : TilingView {
	
    id <TapDetectingImageViewDelegate> _delegate;
    
    // Touch detection
    CGPoint     _tapLocation;            // Needed to record location of single tap, which will only be registered after delayed perform.
    BOOL        _multipleTouches;        // YES if a touch event contains more than one touch; reset when all fingers are lifted.
    BOOL        _twoFingerTapIsPossible; // Set to NO when 2-finger tap can be ruled out (e.g. 3rd finger down, fingers touch down too far apart, etc).
}

@property (nonatomic, assign) id <TapDetectingImageViewDelegate> delegate;

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


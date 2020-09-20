
/*
 File: TapDetectingImageView.m
 */



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TapDetectingImageView.h"

#define DOUBLE_TAP_DELAY 0.3

CGPoint midpointBetweenPoints(CGPoint a, CGPoint b);

@interface TapDetectingImageView () {
    // Touch detection
    CGPoint _tapLocation;                // Needed to record location of single tap, which will only be registered after delayed perform.
    BOOL _multipleTouches;               // YES if a touch event contains more than one touch; reset when all fingers are lifted.
    BOOL _twoFingerTapIsPossible;        // Set to NO when 2-finger tap can be ruled out (e.g. 3rd finger down, fingers touch down too far apart, etc).
}


- (void)handleSingleTap;
- (void)handleDoubleTap;
- (void)handleTwoFingerTap;
@end

@implementation TapDetectingImageView


- (instancetype)initWithImageName:(NSString *)image size:(CGSize)size {
    self = [super initWithImageName:image size:size];
    
    if (self) {
        [self setUserInteractionEnabled:YES];
        [self setMultipleTouchEnabled:YES];
        _twoFingerTapIsPossible = YES;
        _multipleTouches = NO;
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // cancel any pending handleSingleTap messages
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSingleTap) object:nil];
    
    // update our touch state
    if ([event touchesForView:self].count > 1) {
        _multipleTouches = YES;
    }
    
    if ([event touchesForView:self].count > 2) {
        _twoFingerTapIsPossible = NO;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    BOOL allTouchesEnded = (touches.count == [event touchesForView:self].count);
    
    // first check for plain single/double tap, which is only possible if we haven't seen multiple touches
    if (!_multipleTouches) {
        UITouch *touch = [touches anyObject];
        _tapLocation = [touch locationInView:self];
        
        if (touch.tapCount == 1) {
            [self performSelector:@selector(handleSingleTap) withObject:nil afterDelay:DOUBLE_TAP_DELAY];
        } else if (touch.tapCount == 2) {
            [self handleDoubleTap];
        }
    }
    // check for 2-finger tap if we've seen multiple touches and haven't yet ruled out that possibility
    else if (_multipleTouches && _twoFingerTapIsPossible) {
        // case 1: this is the end of both touches at once
        if (touches.count == 2 && allTouchesEnded) {
            int i = 0;
            int tapCounts[2] = { 0 }; CGPoint tapLocations[2];
            
            for (UITouch *touch in touches) {
                tapCounts[i] = (int)touch.tapCount;
                tapLocations[i] = [touch locationInView:self];
                i++;
            }
            
            if (tapCounts[0] == 1 && tapCounts[1] == 1) { // it's a two-finger tap if they're both single taps
                _tapLocation = midpointBetweenPoints(tapLocations[0], tapLocations[1]);
                [self handleTwoFingerTap];
            }
        }
        // case 2: this is the end of one touch, and the other hasn't ended yet
        else if (touches.count == 1 && !allTouchesEnded) {
            UITouch *touch = [touches anyObject];
            
            if (touch.tapCount == 1) {
                // if touch is a single tap, store its location so we can average it with the second touch location
                _tapLocation = [touch locationInView:self];
            } else {
                _twoFingerTapIsPossible = NO;
            }
        }
        // case 3: this is the end of the second of the two touches
        else if (touches.count == 1 && allTouchesEnded) {
            UITouch *touch = [touches anyObject];
            
            if (touch.tapCount == 1) {
                // if the last touch up is a single tap, this was a 2-finger tap
                _tapLocation = midpointBetweenPoints(_tapLocation, [touch locationInView:self]);
                [self handleTwoFingerTap];
            }
        }
    }
    
    // if all touches are up, reset touch monitoring state
    if (allTouchesEnded) {
        _twoFingerTapIsPossible = YES;
        _multipleTouches = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _twoFingerTapIsPossible = YES;
    _multipleTouches = NO;
}

- (void)handleSingleTap {
    if ([_delegate respondsToSelector:@selector(tapDetectingImageView:gotSingleTapAtPoint:)]) {
        [_delegate tapDetectingImageView:self gotSingleTapAtPoint:_tapLocation];
    }
}

- (void)handleDoubleTap {
    if ([_delegate respondsToSelector:@selector(tapDetectingImageView:gotDoubleTapAtPoint:)]) {
        [_delegate tapDetectingImageView:self gotDoubleTapAtPoint:_tapLocation];
    }
}

- (void)handleTwoFingerTap {
    if ([_delegate respondsToSelector:@selector(tapDetectingImageView:gotTwoFingerTapAtPoint:)]) {
        [_delegate tapDetectingImageView:self gotTwoFingerTapAtPoint:_tapLocation];
    }
}

@end

CGPoint midpointBetweenPoints(CGPoint a, CGPoint b) {
    CGFloat x = (a.x + b.x) / 2.0;
    CGFloat y = (a.y + b.y) / 2.0;
    
    return CGPointMake(x, y);
}

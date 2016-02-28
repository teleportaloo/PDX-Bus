

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>

@protocol WatchPinColor

- (WKInterfaceMapPinColor)getPinColor;
- (UIColor*)getPinTint;
- (bool)hasBearing;
- (double)bearing;
- (CLLocationCoordinate2D)coord;

@end


@interface SimpleWatchPin <WatchPinColor> : NSObject
{
    
}

@property (nonatomic)   WKInterfaceMapPinColor simplePinColor;
@property (nonatomic)   CLLocationCoordinate2D simpleCoord;

@end



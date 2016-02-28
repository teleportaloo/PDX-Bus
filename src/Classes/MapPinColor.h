


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

@class DepartureUI;
@protocol BackgroundTaskProgress;

@protocol MapPinColor <MKAnnotation>

- (MKPinAnnotationColor)getPinColor;
- (UIColor*)getPinTint;
- (bool)showActionMenu;
- (bool)hasBearing;

@optional

- (double)bearing;
- (NSString *)mapStopId;
- (NSString *)mapStopIdText;
- (DepartureUI *)mapDeparture;
- (bool)mapTapped:(id<BackgroundTaskProgress>) progress;
- (NSString *)tapActionText;
@end

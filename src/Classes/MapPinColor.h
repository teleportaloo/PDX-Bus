


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

@class DepartureData;
@protocol BackgroundTaskProgress;

@protocol MapPinColor <MKAnnotation>

@property (nonatomic, readonly) MKPinAnnotationColor pinColor;
@property (nonatomic, readonly, copy) UIColor *pinTint;
@property (nonatomic, readonly) bool showActionMenu;
@property (nonatomic, readonly) bool hasBearing;

@optional

@property (nonatomic, readonly) double doubleBearing;
@property (nonatomic, readonly, copy) NSString *mapStopId;
@property (nonatomic, readonly, copy) NSString *mapStopIdText;
@property (nonatomic, readonly, strong) DepartureData *mapDeparture;
- (bool)mapTapped:(id<BackgroundTaskProgress>) progress;
@property (nonatomic, readonly, copy) NSString *tapActionText;
@property (nonatomic, readonly, copy) UIColor *pinSubTint;
@end

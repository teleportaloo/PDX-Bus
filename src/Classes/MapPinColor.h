


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

@class Departure;
@protocol BackgroundTaskController;

@protocol MapPinColor <MKAnnotation>

typedef enum MapPinColorEnum {
    MAP_PIN_COLOR_RED,
    MAP_PIN_COLOR_GREEN,
    MAP_PIN_COLOR_PURPLE
} MapPinColorValue;

@property (nonatomic, readonly) MapPinColorValue pinColor;
@property (nonatomic, readonly, copy) UIColor *pinTint;
@property (nonatomic, readonly) bool showActionMenu;
@property (nonatomic, readonly) bool hasBearing;

@optional

@property (nonatomic, readonly) double doubleBearing;
@property (nonatomic, readonly, copy) NSString *mapStopId;
@property (nonatomic, readonly, copy) NSString *mapStopIdText;
@property (nonatomic, readonly, strong) Departure *mapDeparture;
@property (nonatomic, readonly, copy) NSString *tapActionText;
@property (nonatomic, readonly, copy) UIColor *pinSubTint;
@property (nonatomic, readonly)  bool useMapTapped;

- (bool)mapTapped:(id<BackgroundTaskController>) progress;
@end

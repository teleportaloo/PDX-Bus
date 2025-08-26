


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

@class Departure;
@protocol TaskController;

@protocol MapPin <MKAnnotation>

typedef enum MapPinColorEnum {
    MAP_PIN_COLOR_RED,
    MAP_PIN_COLOR_GREEN,
    MAP_PIN_COLOR_PURPLE,
    MAP_PIN_COLOR_BLUE,
    MAP_PIN_COLOR_WHITE
} MapPinColorValue;

#define kPinTypeStop NSLocalizedString(@"#b#OStop#b", @"Map pin type")
#define kPinTypeTripStop NSLocalizedString(@"#b#OAt Stop...#b", @"Map pin type")
#define kPinTypeRoute NSLocalizedString(@"#b#ORoute#b", @"Map pin type")
#define kPinTypeVehicle NSLocalizedString(@"#b#OVehicle#b", @"Map pin type")
#define kPinTypeDeparture                                                      \
    NSLocalizedString(@"#b#OVehicle Departure#b", @"Map pin type")
#define kPinTypeBus NSLocalizedString(@"#b#OBus#b", @"Map pin type")
#define kPinTypeTrain NSLocalizedString(@"#b#OTrain#b", @"Map pin type")
#define kPinTypeStreetcar NSLocalizedString(@"#b#OStreetcar#b", @"Map pin type")

@property(nonatomic, readonly) MapPinColorValue pinColor;
@property(nonatomic, readonly, copy) UIColor *pinTint;
@property(nonatomic, readonly) bool pinActionMenu;
@property(nonatomic, readonly) bool pinHasBearing;
@property(nonatomic, readonly, copy) NSString *pinMarkedUpType;

@optional

@property(nonatomic) double pinBearing;
@property(nonatomic, readonly, copy) NSString *pinStopId;
@property(nonatomic, readonly, copy) NSString *pinMarkedUpStopId;
@property(nonatomic, readonly) bool pinUseAction;
@property(nonatomic, readonly, copy) NSString *pinActionText;
@property(nonatomic, readonly, copy) UIColor *pinBlobColor;
@property(nonatomic, readonly, copy) NSString *pinMarkedUpSubtitle;
@property(nonatomic, readonly, copy) NSString *key;
@property(nonatomic, readonly) NSDate *lastUpdated;
@property(nonatomic, readonly) NSString *pinSmallText;

- (bool)pinAction:(id<TaskController>)progress;
@end

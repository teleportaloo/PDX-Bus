


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

@class Departure;
@protocol BackgroundTaskProgress;

@protocol MapPinColor <MKAnnotation>

- (MKPinAnnotationColor) getPinColor;
- (bool) showActionMenu;

@optional

- (NSString *) mapStopId;
- (Departure *) mapDeparture;
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress;
- (NSString *) tapActionText;
@end

//
//  DepartureUI.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetTypes.h"
#import "MapPinColor.h"
#import "ScreenConstants.h"
#import "Departure.h"
#import "DepartureCell.h"
#import <MapKit/MkAnnotation.h>

@interface Departure (iOSUI) <MapPinColor>

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly) MapPinColorValue pinColor;
@property (nonatomic, readonly, strong) Departure *mapDeparture;

- (void)populateCell:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide;
- (NSString *)populateCellAndGetExplaination:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide;
- (NSString *)getFormattedExplaination;
- (void)populateTripCell:(UITableViewCell *)cell item:(NSInteger)item;
- (void)populateCellGeneric:(DepartureCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2;

@end

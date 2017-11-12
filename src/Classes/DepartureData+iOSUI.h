//
//  DepartureUI.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetTypes.h"
#import <MapKit/MkAnnotation.h>
#import "MapPinColor.h"
#import "ScreenConstants.h"
#import "DepartureData.h"
#import "DepartureCell.h"




@interface DepartureData (iOSUI) <MapPinColor>

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title; 
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly) MKPinAnnotationColor pinColor;
@property (nonatomic, readonly, strong) DepartureData *mapDeparture;



- (void)populateCell:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide;
- (void)populateCellAndGetExplaination:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide details:(NSString **)formattedDetails;
- (NSString*)getFormattedExplaination;
- (void)populateTripCell:(UITableViewCell *)cell item:(NSInteger)item;
- (void)populateCellGeneric:(DepartureCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2;


@end

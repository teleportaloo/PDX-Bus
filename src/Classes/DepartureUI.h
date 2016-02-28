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


#define kDepartureCellHeight        55
#define kWideDepartureCellHeight    85

@interface DepartureUI : NSObject <MapPinColor> {
    DepartureData *_data;
}

@property (nonatomic, retain) DepartureData *data;

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (NSString*) title; 
- (NSString*) subtitle;
- (MKPinAnnotationColor) getPinColor;
- (DepartureUI *)mapDeparture;


// Rest
- (id)initWithData:(DepartureData *)data;
- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(CGFloat)width;
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier spaceToDecorate:(bool)spaceToDecorate width:(ScreenWidth)width;
- (UITableViewCell *)bigTableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width;

- (void)populateCell:(UITableViewCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide;
- (void)populateCellAndGetExplaination:(UITableViewCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide color:(UIColor **)color details:(NSString **)details;
- (void)getExplaination:(UIColor**)color details:(NSString **)details;
- (void)populateTripCell:(UITableViewCell *)cell item:(NSInteger)item;
- (void)populateCellGeneric:(UITableViewCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2;


+ (DepartureUI*)createFromData:(DepartureData *)data;


@end

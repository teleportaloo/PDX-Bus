//
//  TripLeg.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TripLegEndPoint.h"
#import "LegShapeParser.h"
#import "ScreenConstants.h"
#import "TripItemCell.h"

#define kNearTo   @"Near "
#define kModeWalk @"Walk"
#define kModeBus  @"Bus"
#define kModeMax  @"Light Rail"
#define kModeSc   @"Streetcar"

typedef enum TripTextTypeEnum {
    TripTextTypeMap,
    TripTextTypeUI,
    TripTextTypeHTML,
    TripTextTypeClip
} TripTextType;

@interface TripLeg : NSObject

@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSString *order;
@property (nonatomic, strong, setter = setXml_date:) NSString *startStartDateFormatted;
@property (nonatomic, strong, setter = setXml_startTime:) NSString *startTimeFormatted;
@property (nonatomic, strong, setter = setXml_endTime:) NSString *endTimeFormatted;
@property (nonatomic, strong, setter = setXml_duration:) NSString *strDurationMins;
@property (nonatomic, readonly) NSInteger durationMins;
@property (nonatomic, copy, setter = setXml_distance:) NSString *strDistanceMiles;
@property (nonatomic, readonly) double distanceMiles;
@property (nonatomic, strong, setter = setXml_number:) NSString *displayRouteNumber;
@property (nonatomic, strong, setter = setXml_internalNumber:) NSString *internalRouteNumber;
@property (nonatomic, strong, setter = setXml_name:) NSString *routeName;
@property (nonatomic, strong, setter = setXml_key:) NSString *key;
@property (nonatomic, strong, setter = setXml_direction:) NSString *direction;
@property (nonatomic, strong, setter = setXml_block:) NSString *block;

@property (nonatomic, strong) TripLegEndPoint *from;
@property (nonatomic, strong) TripLegEndPoint *to;
@property (nonatomic, strong) LegShapeParser *legShape;

- (NSString *)createFromText:(bool)first textType:(TripTextType)type;
- (NSString *)createToText:(bool)last textType:(TripTextType)type;
- (NSString *)direction:(NSString *)dir;

@end

//
//  TripLeg.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TripLegEndPoint.h"
#import "LegShapeParser.h"
#import "ScreenConstants.h"
#import "DataFactory.h"
#import "TripItemCell.h"

#define kNearTo   @"Near "
#define kModeWalk @"Walk"
#define kModeBus  @"Bus"
#define kModeMax  @"Light Rail"
#define kModeSc   @"Streetcar"

typedef enum {
    TripTextTypeMap,
    TripTextTypeUI,
    TripTextTypeHTML,
    TripTextTypeClip
} TripTextType;

@interface TripLeg: DataFactory

@property (nonatomic, strong) NSString        *mode;
@property (nonatomic, strong) NSString      *order;
@property (nonatomic, strong) NSString        *xdate;
@property (nonatomic, strong) NSString        *xstartTime;
@property (nonatomic, strong) NSString        *xendTime;
@property (nonatomic, strong) NSString        *xduration;
@property (nonatomic, strong) NSString        *xdistance;
@property (nonatomic, strong) NSString        *xnumber;
@property (nonatomic, strong) NSString        *xinternalNumber;
@property (nonatomic, strong) NSString        *xname;
@property (nonatomic, strong) NSString        *xkey;
@property (nonatomic, strong) NSString        *xdirection;
@property (nonatomic, strong) NSString        *xblock;
@property (nonatomic, strong) TripLegEndPoint *from;
@property (nonatomic, strong) TripLegEndPoint *to;
@property (nonatomic, strong) LegShapeParser *legShape;

- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
- (NSString*)createToText:(bool)last textType:(TripTextType)type;
- (NSString *)direction:(NSString *)dir;

@end

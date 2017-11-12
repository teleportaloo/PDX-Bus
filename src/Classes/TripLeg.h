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

@interface TripLeg: DataFactory
{
	NSString *          _mode;
    NSString *          _order;
	NSString *          _xdate;
	NSString *          _xstartTime;
	NSString *          _xendTime;
	NSString *          _xduration;
	NSString *          _xdistance;
	TripLegEndPoint *   _from;
	TripLegEndPoint *   _to;
	NSString *          _xnumber;
	NSString *          _xinternalNumber;
	NSString *          _xname;
	NSString *          _xkey;
	NSString *          _xdirection;
	NSString *          _xblock;
	LegShapeParser *    _legShape;
}

@property (nonatomic, retain) NSString		*mode;
@property (nonatomic, retain) NSString      *order;
@property (nonatomic, retain) NSString		*xdate;
@property (nonatomic, retain) NSString		*xstartTime;
@property (nonatomic, retain) NSString		*xendTime;
@property (nonatomic, retain) NSString		*xduration;
@property (nonatomic, retain) NSString		*xdistance;
@property (nonatomic, retain) NSString		*xnumber;
@property (nonatomic, retain) NSString		*xinternalNumber;
@property (nonatomic, retain) NSString		*xname;
@property (nonatomic, retain) NSString		*xkey;
@property (nonatomic, retain) NSString		*xdirection;
@property (nonatomic, retain) NSString		*xblock;
@property (nonatomic, retain) TripLegEndPoint *from;
@property (nonatomic, retain) TripLegEndPoint *to;
@property (nonatomic, retain) LegShapeParser *legShape;

typedef enum {
	TripTextTypeMap,
	TripTextTypeUI,
	TripTextTypeHTML,
	TripTextTypeClip
} TripTextType;

- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
- (NSString*)createToText:(bool)last textType:(TripTextType)type;
- (NSString *)direction:(NSString *)dir;

@end

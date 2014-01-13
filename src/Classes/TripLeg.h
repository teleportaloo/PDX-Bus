//
//  TripLeg.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <Foundation/Foundation.h>
#import "TripLegEndPoint.h"
#import "LegShapeParser.h"
#import "ScreenConstants.h"

#define kNearTo   @"Near "
#define kModeWalk @"Walk"
#define kModeBus  @"Bus"
#define kModeMax  @"Light Rail"
#define kModeSc   @"Streetcar"

@interface TripLeg: NSObject
{
	NSString *_mode;
	NSString *_xdate;
	NSString *_xstartTime;
	NSString *_xendTime;
	NSString *_xduration;
	NSString *_xdistance;
    
	TripLegEndPoint *_from;
	TripLegEndPoint *_to;
	
	NSString *_xnumber;
	NSString *_xinternalNumber;
	NSString *_xname;
	NSString *_xkey;
	NSString *_xdirection;
	NSString *_xblock;
	
	LegShapeParser *_legShape;
}

@property (nonatomic, retain) NSString		*mode;
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

+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width;
+ (void)populateCell:(UITableViewCell*)cell body:(NSString *)body mode:(NSString *)mode time:(NSString *)time leftColor:(UIColor *)col route:(NSString *)route;
- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
- (NSString*)createToText:(bool)last textType:(TripTextType)type;
- (NSString *)direction:(NSString *)dir;
+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height screenWidth:(ScreenType)screenWidth;
+ (CGFloat)bodyTextWidthForScreenWidth:(ScreenType)screenWidth;
@end

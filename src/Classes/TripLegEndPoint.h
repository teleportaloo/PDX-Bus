//
//  TripLegEndPoint.h
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
#import "MapPinColor.h"

@protocol ReturnTripLegEndPoint;

@interface TripLegEndPoint: NSObject <MapPinColor, NSCopying>
{
	NSString *_xlat;
	NSString *_xlon;
	NSString *_xdescription;
	NSString *_xstopId;
	NSString *_displayText;
	NSString *_mapText;
	NSString *_displayModeText;
	NSString *_displayTimeText;
	NSString *_xnumber;
	UIColor *_leftColor;
	int _index;
	id<ReturnTripLegEndPoint> _callback;
}

@property (nonatomic, retain) id<ReturnTripLegEndPoint> callback;
@property (nonatomic, retain) NSString		*xlat;
@property (nonatomic, retain) NSString		*xlon;
@property (nonatomic, retain) NSString		*xdescription;
@property (nonatomic, retain) NSString		*xstopId;
@property (nonatomic, retain) NSString		*displayText;
@property (nonatomic, retain) NSString		*mapText;
@property (nonatomic, retain) NSString		*displayModeText;
@property (nonatomic, retain) NSString		*displayTimeText;
@property (nonatomic, retain) UIColor       *leftColor;
@property (nonatomic, retain) NSString      *xnumber;
@property (nonatomic) int index;

- (NSString*)stopId;
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;
- (bool)mapTapped:(id<BackgroundTaskProgress>) progress;
- (id)copyWithZone:(NSZone *)zone;


@end

@protocol ReturnTripLegEndPoint

- (void) chosenEndpoint:(TripLegEndPoint*)endpoint;
- (NSString *)actionText;

@end


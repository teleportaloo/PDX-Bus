//
//  SimpleAnnotation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/24/09.
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

#import <UIKit/UIKit.h>
#import "MapPinColor.h"


@interface SimpleAnnotation : NSObject <MapPinColor> {
	NSString *_pinTitle;
	NSString *_pinSubtitle;
	MKPinAnnotationColor _pinColor;
	CLLocationCoordinate2D coord;
}

- (NSString *)title;
- (NSString *)subtitle;
- (MKPinAnnotationColor) getPinColor;
- (void)setCoordinateLat:(NSString *)lat lng:(NSString *)lng;
- (void)setCoord:(CLLocationCoordinate2D)value;
- (bool) mapDisclosure;

@property (nonatomic,retain) NSString *pinTitle;
@property (nonatomic,retain) NSString *pinSubtitle;
@property (nonatomic) MKPinAnnotationColor pinColor;


@end

//
//  RailMapView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
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
#import "ReturnStopId.h"
#import "TapDetectingImageView.h"
#import "SimpleAnnotation.h"
#import "StopLocations.h"
#import "Stop.h"
#import "ViewControllerBase.h"
#import "XMLStops.h"
#import "Hotspot.h"

@interface RailMapHotSpots : UIView {
	UIImageView* _mapView;
	BOOL _hidden;
	int _selectedItem;
}

@property (nonatomic, retain) UIImageView* mapView; 
@property (nonatomic) BOOL hidden;
@property (nonatomic) int selectedItem;

- (id)   initWithImageView:(UIImageView*)imgView;
- (void) fadeOut;
- (void) selectItem:(int)i;


@end

typedef enum
{
	EasterEggStart,
	EasterEggNorth1,
	EasterEggNorth2,
	EasterEggNorth3,
	EasterEgg1,
	EasterEgg2,
	EasterEgg3
} EasterEggState;

@interface RailMapView : ViewControllerBase <ReturnStop, UIScrollViewDelegate, TapDetectingImageViewDelegate, UIAlertViewDelegate>{
	UIScrollView	*_scrollView;
	bool _from;
	bool _picker;
	NSMutableArray *_stopIDs;
	RailMapHotSpots *_hotSpots;
	EasterEggState easterEgg;
	int selectedItem;
	StopLocations *_locationsDb;
}

- (void)createToolbarItems;
+ (void)initHotspotData;
- (void)next:(NSTimer*)theTimer;
- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;

#ifdef MAXCOLORS
+ (int)nHotspots;
+ (HOTSPOT *)hotspots;
#endif

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic) bool from;
@property (nonatomic) bool picker;
@property (nonatomic, retain) NSMutableArray *stopIDs;
@property (nonatomic, retain) RailMapHotSpots *hotSpots;
@property (nonatomic, retain) StopLocations *locationsDb;

@end

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
	UIView* _mapView;
	BOOL _hidden;
	int _selectedItem;
    CGPoint _touchPoint;
    RAILMAP *_railMap;
}

@property (nonatomic, retain) UIView* mapView;
@property (nonatomic) BOOL hidden;
@property (nonatomic) int selectedItem;

- (id)   initWithImageView:(UIView*)imgView map:(RAILMAP*)map;
- (void) fadeOut;
- (void) selectItem:(int)i;
- (void) touchAtPoint:(CGPoint) point;


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

typedef struct savedImageStruct
{
    CGPoint contentOffset;
    float   zoom;
    bool    saved;
} SAVED_IMAGE;

@interface RailMapView : ViewControllerBase <ReturnStop, UIScrollViewDelegate, TapDetectingImageViewDelegate, UIAlertViewDelegate>{
	UIScrollView	*_scrollView;
	bool _from;
	bool _picker;
	NSMutableArray *_stopIDs;
	RailMapHotSpots *_hotSpots;
	EasterEggState easterEgg;
	int selectedItem;
	StopLocations *_locationsDb;
    CGPoint _tapPoint;
    RAILMAP *_railMap;
    int _railMapIndex;
    TapDetectingImageView *_imageView;
    UIImageView *_lowResBackgroundImage;
    SAVED_IMAGE _savedImage[kRailMaps];
    UISegmentedControl *_railMapSeg;
    
}

- (void)createToolbarItems;
+ (void)initHotspotData;
- (void)next:(NSTimer*)theTimer;
- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
- (void)loadImage;

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
@property (nonatomic, retain) TapDetectingImageView *imageView;
@property (nonatomic, retain) UIImageView *lowResBackgroundImage;
@property (nonatomic, retain) UISegmentedControl *railMapSeg;

@end

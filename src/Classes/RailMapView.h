//
//  RailMapView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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

@interface RailMapView : ViewControllerBase <ReturnStop, UIScrollViewDelegate, TapDetectingImageViewDelegate, UIAlertViewDelegate, DeselectItemDelegate>{
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
    bool _showNextOnAppearance;
    
}

+ (void)initHotspotData;
- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
- (void)loadImage;
+ (bool)RailMapSupported;


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
@property (nonatomic)         bool showNextOnAppearance;

@end

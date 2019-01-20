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
#import "HotSpot.h"

@interface RailMapHotSpots : UIView {
    UIView *        _mapView;
    BOOL            _hidden;
    int             _selectedItem;
    CGPoint         _touchPoint;
    RAILMAP *       _railMap;
}

@property (nonatomic, strong) UIView* mapView;
@property (nonatomic) BOOL hidden;
@property (nonatomic) int selectedItem;

- (instancetype)   initWithImageView:(UIView*)imgView map:(RAILMAP*)map;
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

@interface RailMapView : ViewControllerBase <ReturnStop, UIScrollViewDelegate, TapDetectingImageViewDelegate, DeselectItemDelegate>
{
    EasterEggState          _easterEgg;
    int                     _selectedItem;
    CGPoint                 _tapPoint;
    RAILMAP *               _railMap;
    int                     _railMapIndex;
    SAVED_IMAGE             _savedImage[kRailMaps];
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) bool from;
@property (nonatomic) bool picker;
@property (nonatomic, strong) NSMutableArray *stopIDs;
@property (nonatomic, strong) RailMapHotSpots *hotSpots;
@property (nonatomic, strong) StopLocations *locationsDb;
@property (nonatomic, strong) TapDetectingImageView *imageView;
@property (nonatomic, strong) UIImageView *lowResBackgroundImage;
@property (nonatomic, strong) UISegmentedControl *railMapSeg;
@property (nonatomic)         bool showNextOnAppearance;

- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
- (void)loadImage;

+ (void)initHotspotData;

#ifdef MAXCOLORS
+ (int)nHotspots;
+ (HOTSPOT *)hotspots;
#endif


@end

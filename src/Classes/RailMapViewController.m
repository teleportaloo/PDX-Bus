//
//  RailMapViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "RailMapViewController.h"
#import "AllRailStationViewController.h"
#import "DebugLogging.h"
#import "DepartureTimesViewController.h"
#import "DirectionViewController.h"
#import "HotSpot.h"
#import "MapViewController.h"
#import "NSString+Core.h"
#import "NearestVehiclesMapViewController.h"
#import "PDXBusAppDelegate+Methods.h"
#include "PointInclusionInPolygonTest.h"
#import "RailMapHotSpotsView.h"
#import "RailStation.h"
#import "RailStationTableViewController.h"
#import "StationData.h"
#import "Stop+UI.h"
#import "TableViewControllerWithToolbar.h"
#import "TaskDispatch.h"
#import "TripPlannerBookmarkViewController.h"
#import "UIApplication+Compat.h"
#import "WebViewController.h"

typedef enum EasterEggStateEnum {
    EasterEggStart,
    EasterEggNorth1,
    EasterEggNorth2,
    EasterEggNorth3,
    EasterEgg1,
    EasterEgg2,
    EasterEgg3
} EasterEggState;

typedef struct SavedImageStruct {
    CGPoint contentOffset;
    float zoom;
    bool saved;
} SavedImage;

@interface RailMapViewController () {
    EasterEggState _easterEgg;
    int _selectedItem;
    CGPoint _tapPoint;
    PtrConstRailMap _railMap;
    int _railMapIndex;
    SavedImage _savedImage[kRailMaps];
    PtrConstHotSpot _hotSpotRegions;
}

@property(nonatomic, strong) UIScrollView *scrollView;

@property(nonatomic) bool picker;
@property(nonatomic, strong) NSMutableArray *stopIDs;
@property(nonatomic, strong) RailMapHotSpotsView *hotSpots;
@property(nonatomic, strong) TilingView *imageView;
@property(nonatomic, strong) UIImageView *lowResBackgroundImage;
@property(nonatomic, strong) UISegmentedControl *railMapSeg;
@property(nonatomic, strong) UIBarButtonItem *segButton;

@property(nonatomic, strong) UITapGestureRecognizer *singleTap;
@property(nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property(nonatomic, strong) UITapGestureRecognizer *twoFingerTap;

- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
- (void)loadImage;

@end

@implementation RailMapViewController

- (instancetype)init {
    if ((self = [super init])) {
        _picker = NO;
        _from = NO;
        self.stopIdStringCallback = nil;

        _hotSpotRegions = HotSpotArrays.sharedInstance.hotSpots;

        _easterEgg = EasterEggStart;
        self.backgroundTask = [BackgroundTaskContainer create:self];

        int mapId;

        if (Settings.showStreetcarMapFirst) {
            mapId = kRailMapPdxStreetcar;
        } else {
            mapId = kRailMapMaxWes;
        }

        _railMap = HotSpotArrays.sharedInstance.railMaps + mapId;
        _railMapIndex = mapId;
    }

    return self;
}

- (void)dealloc {
    self.stopIdStringCallback = nil;
    _hotSpots.mapView = nil;
    self.backgroundTask = nil;
}

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

// OK - we need a little adjustment here for iOS7.  It took we a while to get
// this right - I'm exactly sure what is going on but on the iPad we need to
// make the height a little bigger in some cases. Annoying.

- (CGFloat)heightOffset {
    if (SMALL_SCREEN || (self.screenInfo.screenWidth == WidthBigVariable)) {
        return -
            [UIApplication sharedApplication].compatStatusBarFrame.size.height;
    }

    return 0.0;
}

#pragma mark ReturnStop callbacks

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        [self.stopIdStringCallback returnStopIdString:stop.stopId
                                                 desc:stop.desc];
        return;
    }

    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];

    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:progress
                                                 stopId:stop.stopId];
}

#pragma mark BackgroundTask methods

#pragma mark UI callbacks

- (NSString *)returnStopObjectActionText {
    if (self.stopIdStringCallback) {
        return [self.stopIdStringCallback returnStopIdStringActionText];
    }

    return @"";
}

- (void)showMap:(id)sender {
    int i, j;
    CLLocation *here;
    bool tp;

    NearestVehiclesMapViewController *mapPage =
        [NearestVehiclesMapViewController viewController];

    mapPage.staticOverlays = YES;

    if (_railMapIndex == kRailMapPdxStreetcar) {
        mapPage.trimetRoutes = [NSSet set];
        mapPage.streetcarRoutes = [TriMetInfo streetcarRoutes];
        mapPage.title =
            NSLocalizedString(@"Portland Streetcar", @"map page title");
    } else {
        mapPage.streetcarRoutes = [NSSet set];
        mapPage.trimetRoutes = [TriMetInfo triMetRailLines];
        mapPage.title = NSLocalizedString(@"MAX & WES", @"map page title");
    }

    for (i = _railMap->hotSpots->first; i <= _railMap->hotSpots->last; i++) {
        RailStation *station = [RailStation fromHotSpotIndex:i];

        if (station) {
            // NSString *stop = nil;
            NSString *dir = nil;
            NSString *stopId = nil;

            for (j = 0; j < station.dirArray.count; j++) {
                dir = station.dirArray[j];
                stopId = station.stopIdArray[j];

                here = [StationData locationFromStopId:stopId];
                tp = [StationData tpFromStopId:stopId];

                if (here) {
                    Stop *a = [Stop new];

                    a.stopId = stopId;
                    a.desc = station.name;
                    a.dir = dir;
                    a.location = here;
                    a.stopObjectCallback = self;
                    a.timePoint = tp;

                    [mapPage addPin:a];
                }
            }
        }
    }

    mapPage.staticAnnotations = mapPage.annotations.copy;
    mapPage.staticOverlays = YES;

    mapPage.stopIdStringCallback = self.stopIdStringCallback;

    [mapPage fetchNearestVehiclesAsync:self.backgroundTask];
}

- (void)toggleMap:(UISegmentedControl *)seg {
    if (_railMapIndex != seg.selectedSegmentIndex) {
        [self saveImage];
        _railMapIndex = (int)seg.selectedSegmentIndex;
        _railMap = HotSpotArrays.sharedInstance.railMaps + _railMapIndex;
        _selectedItem = -1;

        Settings.showStreetcarMapFirst =
            (_railMapIndex == kRailMapPdxStreetcar);

        [self loadImage];
    }
}

#pragma mark ViewControllerBase methods

- (void)updateToolbarMainThread {
    self.segButton = [self segBarButtonWithItems:@[ @"MAX & WES", @"Streetcar" ]
                                          action:@selector(toggleMap:)
                                   selectedIndex:_railMapIndex];

    self.railMapSeg = self.segButton.customView;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {

    [toolbarItems addObjectsFromArray:@[
        [UIToolbar mapButtonWithTarget:self action:@selector(showMap:)],
        [UIToolbar flexSpace], self.segButton
    ]];

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)saveImage {
    if (self.imageView) {
        SavedImage *saved = _savedImage + _railMapIndex;
        saved->zoom = self.scrollView.zoomScale;
        saved->contentOffset = self.scrollView.contentOffset;
        saved->saved = YES;

        [self.lowResBackgroundImage removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView = nil;
    }
}

- (void)setupGestureRecognizers {
    // Single tap (1 finger)
    self.singleTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleSingleTap:)];
    self.singleTap.cancelsTouchesInView = NO;
    self.singleTap.delegate = self;

    // Double tap (1 finger)
    self.doubleTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleDoubleTap:)];
    self.doubleTap.numberOfTapsRequired = 2;
    self.doubleTap.cancelsTouchesInView = NO;
    self.doubleTap.delegate = self;

    // Ensure single tap waits for double tap to fail
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];

    // Two-finger single tap
    self.twoFingerTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleTwoFingerTap:)];
    self.twoFingerTap.numberOfTouchesRequired = 2;
    self.twoFingerTap.numberOfTapsRequired = 1;

    self.twoFingerTap.cancelsTouchesInView = NO;
    self.twoFingerTap.delegate = self;

    [self.scrollView addGestureRecognizer:self.singleTap];
    [self.scrollView addGestureRecognizer:self.doubleTap];
    [self.scrollView addGestureRecognizer:self.twoFingerTap];

    self.scrollView.panGestureRecognizer.delaysTouchesBegan = NO;
    self.scrollView.panGestureRecognizer.cancelsTouchesInView = NO;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    _tapPoint = [recognizer locationInView:self.imageView];

    DEBUG_LOG_CGPoint(_tapPoint);

    [self findHotspot];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    // double tap zooms in
    CGPoint tapPoint = [recognizer locationInView:self.imageView];
    float newScale = self.scrollView.zoomScale * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];

    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)recognizer {
    // two-finger tap zooms out
    CGPoint tapPoint = [recognizer locationInView:self.imageView];
    float newScale = self.scrollView.zoomScale / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];

    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)loadImage {
    NSString *path = [[NSBundle mainBundle]
        pathForResource:[NSString stringWithFormat:@"%@_Placeholder",
                                                   _railMap->fileName]
                 ofType:@"gif"];

    self.lowResBackgroundImage = [[UIImageView alloc]
        initWithFrame:(CGRect){CGPointZero, _railMap->size}];

    self.lowResBackgroundImage.image = [UIImage imageWithContentsOfFile:path];
    self.lowResBackgroundImage.userInteractionEnabled = YES;

    self.imageView = [[TilingView alloc] initWithImageName:_railMap->fileName
                                                      size:_railMap->size];

    [self.lowResBackgroundImage setTag:ZOOM_VIEW_TAG];
    self.imageView.frame = self.lowResBackgroundImage.bounds;

    [self.lowResBackgroundImage addSubview:self.imageView];

    self.scrollView.contentSize = _railMap->size;
    [self.scrollView addSubview:self.lowResBackgroundImage];

    // Lets try to calculate something that'll work for all orientations and
    // devices.
    float minimumScale;
    CGRect scrollFrame = self.scrollView.frame;
    CGRect imageFrame = self.imageView.frame;

    // calculate minimum scale to perfectly fit image width, and begin at that
    // scale
    minimumScale = scrollFrame.size.width / imageFrame.size.width;

    self.scrollView.minimumZoomScale =
        scrollFrame.size.height / imageFrame.size.height;

    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's
    //    bounds. As the zoom scale decreases, so more content is visible, the
    //    size of the rect grows.

    self.scrollView.minimumZoomScale = minimumScale;

    self.hotSpots =
        [[RailMapHotSpotsView alloc] initWithImageView:self.imageView
                                                   map:_railMap];

    self.title = _railMap->title;

    SavedImage *saved = _savedImage + _railMapIndex;

    if (saved->saved) {
        self.scrollView.zoomScale = saved->zoom;
        self.scrollView.contentOffset = saved->contentOffset;
    } else {
        CGRect zoom;
        CGRect imageFrame = self.imageView.frame;
        CGRect scrollFrame = self.scrollView.frame;
        CGFloat scale =
            (scrollFrame.size.height / imageFrame.size.height) * 1.25;

        zoom.size.width = self.scrollView.frame.size.width / scale;
        zoom.size.height = self.scrollView.frame.size.height / scale;

        zoom.origin.x = ((imageFrame.size.width - zoom.size.width) / 2.0);
        zoom.origin.y = ((imageFrame.size.height - zoom.size.height) / 2.0);

        DEBUG_LOG(@"Zoom: w %f h %f x %f y %f\n", zoom.size.width,
                  zoom.size.height, zoom.origin.x, zoom.origin.y);

        [self.scrollView zoomToRect:zoom animated:NO];
    }
}

- (void)loadView {
    [super loadView];

    // Set the size for the table view
    CGRect bounds = self.middleWindowRect;

    /// set up main scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:bounds];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
    [self.scrollView setBouncesZoom:YES];
    self.scrollView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.scrollView];

    self.scrollView.delaysContentTouches = NO;

    [self loadImage];

    // [self toggleShowAll];

    // [self.scrollView scrollRectToVisible:zoom animated:NO];
    [self updateToolbar];

    [self setupGestureRecognizers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a
                                     // superview Release anything that's not
                                     // essential, such as cached data
}

- (void)deselectItemCallback {
    [self.hotSpots fadeOut];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.hotSpots fadeOut];

    [super viewWillAppear:animated];
}

#pragma mark Process hotspot string "URL"

- (void)scannerInc:(NSScanner *)scanner {
    if (!scanner.atEnd) {
        scanner.scanLocation++;
    }
}

- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
    if (!scanner.atEnd) {
        [scanner scanUpToString:@"/" intoString:substr];

        // NSLog(@"%@", *substr);
        [self scannerInc:scanner];
    }
}

- (void)toggleShowAll {
    self.hotSpots.showAll = !self.hotSpots.showAll;

    self.imageView.annotates = !self.imageView.annotates;
    [self.imageView setNeedsDisplay];
    self.hotSpots.alpha = self.hotSpots.showAll ? 1.0 : 0.0;
    [self.hotSpots setNeedsDisplay];
    [self updateToolbar];
    _easterEgg = EasterEggStart;

    DEBUG_LOG_BOOL(self.hotSpots.showAll);
}

- (BOOL)processHotSpot:(ConstHotSpot *)hs item:(int)i {
    NSString *url = HS_ACTION(*hs);

    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSCharacterSet *colon =
        [NSCharacterSet characterSetWithCharactersInString:@":"];

    NSString *substr;
    NSString *stationName = @"";
    NSString *wikiLink;
    NSString *map = @"";

    [scanner scanUpToCharactersFromSet:colon intoString:&substr];

    if (substr == nil) {
        return YES;
    }

    switch (*substr.UTF8String) {
    case kLinkTypeNorth: {
        switch (_easterEgg) {
        case EasterEggNorth1:
        case EasterEggNorth2:
            _easterEgg++;
            break;

        case EasterEggNorth3:
            [self toggleShowAll];
            break;

        default:
            _easterEgg = EasterEggNorth1;
            break;
        }
        break;
    }

    case kLinkType1:
    case kLinkType2:
    case kLinkType3: {
        [WebViewController
               displayPage:@"http://www.teleportaloo.org/pdxbus/easteregg/"
                      full:nil
                 navigator:self.navigationController
            itemToDeselect:self
                  whenDone:self.callbackWhenDone];

        _easterEgg = EasterEggStart;
        break;
    }
    case kLinkTypeTest:
        break;

    case kLinkTypeWiki: {
        _easterEgg = EasterEggStart;

        [self scannerInc:scanner];
        //[self.hotSpots selectItem:i];

        wikiLink = [url substringFromIndex:scanner.scanLocation];

        [WebViewController
            displayNamedPage:@"Wikipedia"
                   parameter:[wikiLink stringByRemovingPercentEncoding]
                   navigator:self.navigationController
              itemToDeselect:self
                    whenDone:self.callbackWhenDone];

        break;
    }

    case kLinkTypeHttp: {
        _easterEgg = EasterEggStart;

        //[self.hotSpots selectItem:i];

        [WebViewController displayPage:url
                                  full:nil
                             navigator:self.navigationController
                        itemToDeselect:self
                              whenDone:self.callbackWhenDone];

        break;
    }

    case kLinkTypeDir: {
        _easterEgg = EasterEggStart;
        //[self.hotSpots selectItem:i];

        [self scannerInc:scanner];
        [self nextSlash:scanner intoString:&substr];
        [self nextSlash:scanner intoString:&substr];
        // [self nextSlash:scanner intoString:&substr];
        [self nextSlash:scanner intoString:&stationName];

        DirectionViewController *dirView =
            [DirectionViewController viewController];
        dirView.stopIdStringCallback = self.stopIdStringCallback;
        [dirView fetchDirectionsAsync:self.backgroundTask route:stationName];
        break;
    }

    case kLinkTypeMap: {
        _easterEgg = EasterEggStart;
        //[self.hotSpots selectItem:i];

        [self scannerInc:scanner];
        [self nextSlash:scanner intoString:&substr];
        [self nextSlash:scanner intoString:&substr];
        // [self nextSlash:scanner intoString:&substr];
        [self nextSlash:scanner intoString:&map];

        self.railMapSeg.selectedSegmentIndex = map.integerValue;
        [self toggleMap:self.railMapSeg];
        break;
    }

    case kLinkTypeStop: {
        _easterEgg = EasterEggStart;
        //[self.hotSpots selectItem:i];

        RailStation *station = [RailStation fromHotSpotIndex:i];
        RailStationTableViewController *railView =
            [RailStationTableViewController viewController];
        railView.station = station;
        railView.stopIdStringCallback = self.stopIdStringCallback;
        railView.from = self.from;

        if (self.hotSpots.showAll) {
            railView.map = self;
        }

        [railView fetchShapesAndDetoursAsync:self.backgroundTask];
        break;
    }
    }
    return YES;
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [self.scrollView viewWithTag:ZOOM_VIEW_TAG];
}

/************************************** NOTE
 * **************************************/
/* The following delegate method works around a known bug in
 * zoomToRect:animated: */
/* In the next release after 3.0 this workaround will no longer be necessary */
/**********************************************************************************/
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale + 0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;

    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's
    //    bounds. As the zoom scale decreases, so more content is visible, the
    //    size of the rect grows.
    zoomRect.size.height = self.scrollView.frame.size.height / scale;
    zoomRect.size.width = self.scrollView.frame.size.width / scale;

    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);

    return zoomRect;
}

#pragma mark TapDetectingImageViewDelegate methods

- (void)listAction:(id)unused {
    AllRailStationViewController *allRail =
        [AllRailStationViewController viewController];

    allRail.stopIdStringCallback = self.stopIdStringCallback;
    [self.navigationController pushViewController:allRail animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.showNextOnAppearance) {

        do {
            _selectedItem =
                _railMap->hotSpots->first +
                ((_selectedItem - _railMap->hotSpots->first + 1) %
                 (_railMap->hotSpots->last - _railMap->hotSpots->first + 1));
        } while (HS_TYPE(_hotSpotRegions[_selectedItem]) != kLinkTypeStop);

        [RailMapHotSpotsView touch:_hotSpotRegions + _selectedItem];
        // selectedItem = i;
        [self.hotSpots setNeedsDisplay];
        [self processHotSpot:_hotSpotRegions + _selectedItem
                        item:_selectedItem];
        self.showNextOnAppearance = NO;
    }

    UIBarButtonItem *list = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"A-Z", @"List button")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(listAction:)];

    self.navigationItem.rightBarButtonItem = list;

    [super viewDidAppear:animated];
}

- (void)selectedHotspot {
    [self processHotSpot:_hotSpotRegions + _selectedItem item:_selectedItem];
}

+ (int)findHotSpotInMap:(PtrConstRailMap)map
                   tile:(const RailMapTile *)tile
                  point:(CGPoint)tapPoint {
    int i = NO_HOTSPOT_FOUND;
    ConstHotSpotIndex *indices = tile->hotspots;
    PtrConstHotSpot hotSpotRegions = HotSpotArrays.sharedInstance.hotSpots;
    while (*indices != MAP_END) {
        i = *indices + map->hotSpots->first;

        PtrConstHotSpot hotspot = &(hotSpotRegions[i]);
        // DEBUG_LOG_NSString(hotspot->action);

        if (HOTSPOT_HIT(hotspot, tapPoint)) {

            return i;
            break;
        }

        indices++;
    }

    return NO_HOTSPOT_FOUND;
}

- (void)findHotspot {
    int x = _tapPoint.x / _railMap->tileSize.width;
    int y = _tapPoint.y / _railMap->tileSize.height;

    const RailMapTile *tile = &_railMap->tiles[x][y];

    int i = [RailMapViewController findHotSpotInMap:_railMap
                                               tile:tile
                                              point:_tapPoint];

    if (i != NO_HOTSPOT_FOUND) {
        [RailMapHotSpotsView touch:_hotSpotRegions + i];
        _selectedItem = i;
        [self.hotSpots selectItem:i];
        [self.hotSpots setNeedsDisplay];

        MainTask(^{
          [self selectedHotspot];
        });

    } else {
        [self.hotSpots touchAtPoint:_tapPoint];
    }
}

+ (PtrConstRailMap)railMap:(int)n {
    return HotSpotArrays.sharedInstance.railMaps + n;
}

- (void)backgroundTaskDone:(UIViewController *)viewController
                 cancelled:(bool)cancelled {
    if (cancelled) {
        [self.hotSpots fadeOut];
    }

    [super backgroundTaskDone:viewController cancelled:cancelled];
}

@end

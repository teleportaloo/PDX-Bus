//
//  RailMapView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "RailMapView.h"
#import "TableViewWithToolbar.h"
#import "DepartureTimesView.h"
#import "TripPlannerBookmarkView.h"
#import "RailStationTableView.h"
#import "WebViewController.h"
#import "DirectionView.h"
#import "MapViewController.h"
#import "DebugLogging.h"
#import "HotSpot.h"
#import "RailStation.h"
#import "NearestVehiclesMap.h"
#import "AllRailStationView.h"
#import "NSString+Helper.h"
#import "RailMapHotSpots.h"
#import "UIApplication+Compat.h"
#include "PointInclusionInPolygonTest.h"

typedef enum EasterEggStateEnum {
    EasterEggStart,
    EasterEggNorth1,
    EasterEggNorth2,
    EasterEggNorth3,
    EasterEgg1,
    EasterEgg2,
    EasterEgg3
} EasterEggState;


static HotSpot hotSpotRegions[MAXHOTSPOTS];

int nHotSpots = 0;

typedef struct SavedImageStruct {
    CGPoint contentOffset;
    float zoom;
    bool saved;
} SavedImage;

static RailMap railmaps[] =
{
    { @"MAX & WES Map", @"MAXWESMap",      { 3000, 1700 }, 0, 0, 30, 3,  0, { 0, 0 } },
    { @"Streetcar Map", @"StreetcarMap",   { 1500, 2102 }, 0, 0, 4,  20, 0, { 0, 0 } },
    { nil,              0,               0 }
};

@interface RailMapView () {
    EasterEggState _easterEgg;
    int _selectedItem;
    CGPoint _tapPoint;
    RailMap *_railMap;
    int _railMapIndex;
    SavedImage _savedImage[kRailMaps];
}

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) bool picker;
@property (nonatomic, strong) NSMutableArray *stopIDs;
@property (nonatomic, strong) RailMapHotSpots *hotSpots;
@property (nonatomic, strong) TapDetectingImageView *imageView;
@property (nonatomic, strong) UIImageView *lowResBackgroundImage;
@property (nonatomic, strong) UISegmentedControl *railMapSeg;

- (void)scannerInc:(NSScanner *)scanner;
- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
- (void)loadImage;

@end

@implementation RailMapView

- (void)dealloc {
    self.stopIdStringCallback = nil;
    self.hotSpots.mapView = nil;
    self.backgroundTask = nil;
}

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP     1.5

// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.


- (CGFloat)heightOffset {
    if (SMALL_SCREEN || (self.screenInfo.screenWidth == WidthBigVariable)) {
        return -[UIApplication sharedApplication].compatStatusBarFrame.size.height;
    }
    
    return 0.0;
}

+ (HotSpot *)hotspotRecords {
    return &hotSpotRegions[0];
}

+ (int)nHotspotRecords {
    return nHotSpots;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.picker = NO;
        self.from = NO;
        self.stopIdStringCallback = nil;
        _easterEgg = EasterEggStart;
        self.backgroundTask = [BackgroundTaskContainer create:self];
        
        int mapId;
        
        if (Settings.showStreetcarMapFirst) {
            mapId = kRailMapPdxStreetcar;
        } else {
            mapId = kRailMapMaxWes;
        }
        
        _railMap = railmaps + mapId;
        _railMapIndex = mapId;
    }
    
    return self;
}

#pragma mark ReturnStop callbacks

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        [self.stopIdStringCallback returnStopIdString:stop.stopId desc:stop.desc];        
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:progress stopId:stop.stopId];
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
    
    NearestVehiclesMap *mapPage = [NearestVehiclesMap viewController];
    
    if (_railMapIndex == kRailMapPdxStreetcar) {
        mapPage.trimetRoutes = [NSSet set];
        mapPage.streetcarRoutes = [TriMetInfo streetcarRoutes];
        mapPage.title = NSLocalizedString(@"Portland Streetcar", @"map page title");
    } else {
        mapPage.streetcarRoutes = [NSSet set];
        mapPage.trimetRoutes = [TriMetInfo triMetRailLines];
        mapPage.title = NSLocalizedString(@"MAX & WES", @"map page title");
    }
    
    for (i = _railMap->firstHotspot; i <= _railMap->lastHotspot; i++) {
        HotSpot *hs = hotSpotRegions + i;
        
        if (hs->action.firstUnichar == kLinkTypeStop && hs->nVertices != 0) {
            RailStation *station = [RailStation fromHotSpot:hs index:i];
            
            // NSString *stop = nil;
            NSString *dir = nil;
            NSString *stopId = nil;
            
            for (j = 0; j < station.dirArray.count; j++) {
                dir = station.dirArray[j];
                stopId = station.stopIdArray[j];
                
                here = [AllRailStationView locationFromStopId:stopId];
                tp = [AllRailStationView tpFromStopId:stopId];
                
                if (here) {
                    Stop *a = [Stop new];
                    
                    a.stopId = stopId;
                    a.desc = station.station;
                    a.dir = dir;
                    a.location = here;
                    a.stopObjectCallback = self;
                    a.timePoint = tp;
                    
                    [mapPage addPin:a];
                }
            }
        }
    }
    
    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    
    [mapPage fetchNearestVehiclesAsync:self.backgroundTask];
}

- (void)toggleMap:(UISegmentedControl *)seg {
    if (_railMapIndex != seg.selectedSegmentIndex) {
        [self saveImage];
        _railMapIndex = (int)seg.selectedSegmentIndex;
        _railMap = railmaps + _railMapIndex;
        _selectedItem = -1;
        
        Settings.showStreetcarMapFirst = (_railMapIndex == kRailMapPdxStreetcar);
        
        [self loadImage];
    }
}

#pragma mark ViewControllerBase methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    UIBarButtonItem *segItem = [self segBarButtonWithItems:@[@"MAX & WES", @"Streetcar"] action:@selector(toggleMap:) selectedIndex:_railMapIndex];
    
    self.railMapSeg = segItem.customView;
    
    [toolbarItems addObjectsFromArray:@[
        [UIToolbar mapButtonWithTarget:self action:@selector(showMap:)],
        [UIToolbar flexSpace],
        segItem]];
    
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

- (void)loadImage {
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@_Placeholder", _railMap->fileName]
                                                     ofType:@"gif"];
    
    self.lowResBackgroundImage = [[UIImageView alloc] initWithFrame:(CGRect) { CGPointZero, _railMap->size }];
    
    self.lowResBackgroundImage.image = [UIImage imageWithContentsOfFile:path];
    self.lowResBackgroundImage.userInteractionEnabled = YES;
    
    
    self.imageView = [[TapDetectingImageView alloc] initWithImageName:_railMap->fileName size:_railMap->size];
    
    
    
    self.imageView.delegate = self;
    [self.lowResBackgroundImage setTag:ZOOM_VIEW_TAG];
    self.imageView.frame = self.lowResBackgroundImage.bounds;
    
    [self.lowResBackgroundImage addSubview:self.imageView];
    
    self.scrollView.contentSize = _railMap->size;
    [self.scrollView addSubview:self.lowResBackgroundImage];
    
    // Lets try to calculate something that'll work for all orientations and devices.
    float minimumScale;
    CGRect scrollFrame = self.scrollView.frame;
    CGRect imageFrame = self.imageView.frame;
    
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    minimumScale = scrollFrame.size.width  / imageFrame.size.width;
    
    
    self.scrollView.minimumZoomScale = scrollFrame.size.height / imageFrame.size.height;
    
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    
    
    
    self.scrollView.minimumZoomScale = minimumScale;
    
    self.hotSpots = [[RailMapHotSpots alloc] initWithImageView:self.imageView map:_railMap];
    
    self.title = _railMap->title;
    
    SavedImage *saved = _savedImage + _railMapIndex;
    
    if (saved->saved) {
        self.scrollView.zoomScale = saved->zoom;
        self.scrollView.contentOffset = saved->contentOffset;
    } else {
        CGRect zoom;
        CGRect imageFrame = self.imageView.frame;
        CGRect scrollFrame = self.scrollView.frame;
        CGFloat scale = (scrollFrame.size.height / imageFrame.size.height) * 1.25;
        
        zoom.size.width = self.scrollView.frame.size.width  / scale;
        zoom.size.height = self.scrollView.frame.size.height / scale;
        
        zoom.origin.x = ((imageFrame.size.width   - zoom.size.width)  / 2.0);
        zoom.origin.y = ((imageFrame.size.height  - zoom.size.height) / 2.0);
        
        DEBUG_LOG(@"Zoom: w %f h %f x %f y %f\n",
                  zoom.size.width, zoom.size.height, zoom.origin.x, zoom.origin.y);
        
        
        [self.scrollView zoomToRect:zoom animated:NO];
    }
}

- (void)loadView {
    [super loadView];
    
    [RailMapView initHotspotData];
    
    // Set the size for the table view
    CGRect bounds = self.middleWindowRect;
    
    /// set up main scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:bounds];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
    [self.scrollView setBouncesZoom:YES];
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.scrollView];
    
    [self loadImage];
    
    // [self toggleShowAll];
    
    // [self.scrollView scrollRectToVisible:zoom animated:NO];
    [self updateToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
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

- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr; {
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
    
    DEBUG_LOGB(self.hotSpots.showAll);

    
}

- (BOOL)processHotSpot:(NSString *)url item:(int)i {
    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    
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
            [WebViewController displayPage:@"http://www.teleportaloo.org/pdxbus/easteregg/"
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
            
            [WebViewController displayNamedPage:@"Wikipedia"
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
            
            
            DirectionView *dirView = [DirectionView viewController];
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
            
            
            RailStation *station = [RailStation fromHotSpot:hotSpotRegions + i index:i];
            
            
            RailStationTableView *railView = [RailStationTableView viewController];
            railView.station = station;
            railView.stopIdStringCallback = self.stopIdStringCallback;
            railView.from = self.from;
            
            if (self.hotSpots.showAll) {
                railView.map = self;
            }
            
            [railView maybeFetchRouteShapesAsync:self.backgroundTask];
            break;
        }
    }
    return YES;
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [self.scrollView viewWithTag:ZOOM_VIEW_TAG];
}

/************************************** NOTE **************************************/
/* The following delegate method works around a known bug in zoomToRect:animated: */
/* In the next release after 3.0 this workaround will no longer be necessary      */
/**********************************************************************************/
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale + 0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = self.scrollView.frame.size.height / scale;
    zoomRect.size.width = self.scrollView.frame.size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

#pragma mark TapDetectingImageViewDelegate methods

- (void)listAction:(id)unused {
    AllRailStationView *allRail = [AllRailStationView viewController];
    
    allRail.stopIdStringCallback = self.stopIdStringCallback;
    [self.navigationController pushViewController:allRail animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.showNextOnAppearance) {
        do{
            _selectedItem = _railMap->firstHotspot + ((_selectedItem - _railMap->firstHotspot + 1) % (_railMap->lastHotspot - _railMap->firstHotspot + 1));
        } while (hotSpotRegions[_selectedItem].action.firstUnichar != 's');
        
        hotSpotRegions[_selectedItem].touched = YES;
        // selectedItem = i;
        [self.hotSpots setNeedsDisplay];
        [self processHotSpot:hotSpotRegions[_selectedItem].action item:_selectedItem];
        self.showNextOnAppearance = NO;
    }
    
    UIBarButtonItem *list = [[UIBarButtonItem alloc]
                             initWithTitle:NSLocalizedString(@"A-Z", @"List button")
                             style:UIBarButtonItemStylePlain
                             target:self action:@selector(listAction:)];
    
    
    self.navigationItem.rightBarButtonItem = list;
    
    [super viewDidAppear:animated];
}

- (void)selectedHotspot:(NSTimer *)theTimer {
    [self processHotSpot:hotSpotRegions[_selectedItem].action item:_selectedItem];
}

+ (int)findHotSpotInMap:(RailMap *)map  tile:(RailMapTile *)tile point:(CGPoint)tapPoint {
    int i = NO_HOTSPOT_FOUND;
    ConstHotSpotIndex *indices = tile->hotspots;
    while (*indices != MAP_LAST_INDEX) {
        i = *indices + map->firstHotspot;
        
        HotSpot *hotspot = &hotSpotRegions[i];
        // DEBUG_LOGS(hotspot->action);
        
        if (HOTSPOT_HIT(hotspot, tapPoint)) {
            
            return i;
            break;
        }
        
        indices++;
    }
    
    return NO_HOTSPOT_FOUND;
}

- (void)findHotspot:(NSTimer *)theTimer {
    int x = _tapPoint.x /  _railMap->tileSize.width;
    int y = _tapPoint.y /  _railMap->tileSize.height;
    
    RailMapTile *tile = &_railMap->tiles[x][y];
    
    int i = [RailMapView findHotSpotInMap:_railMap tile:tile point:_tapPoint];
    
    if (i!=NO_HOTSPOT_FOUND) {
        hotSpotRegions[i].touched = YES;
        _selectedItem = i;
        [self.hotSpots selectItem:i];
        [self.hotSpots setNeedsDisplay];
        
        NSDate *soon = [[NSDate date] dateByAddingTimeInterval:0.1];
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(selectedHotspot:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    } else {
        [self.hotSpots touchAtPoint:_tapPoint];
    }
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
    _tapPoint = tapPoint;
    [self findHotspot:nil];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale = self.scrollView.zoomScale * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = self.scrollView.zoomScale / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

//
// Copy the map section from railmap.html.  See that file for how to search and replace the HTML with macros
// to construct this data set.
//





#pragma mark Hotspot Data

// These macros convert some text files into some linked static arrays.


// The Polygons from the HTML become static arrays of vertices
#define HS_START_POLY { static const CGPoint static_vertices [] = {
#define HS_END_POLY   }; hs->coords.vertices = static_vertices; hs->isRect = 0; hs->nVertices = sizeof(static_vertices) / sizeof(static_vertices[0]); hs->action = @
#define HS_END        ; nHotSpots++; hs++; }

// The rectable form the HTML is simpler
#define HS_RECT(X1, Y1, X2, Y2, STR) { static const CGRect static_rect = { (X1), (Y1), (X2)-(X1), (Y2)-(Y1) }; hs->coords.rect = &static_rect; hs->isRect = 1; hs->nVertices = 4; hs->action = (@STR); nHotSpots++; hs++; }

// The tiles are used to optimize the search when the user taps on the map
#define MAP_TILE_ALLOCATE_ARRAY(SZ)  { static RailMapTile *static_tiles[(SZ)]; map->tiles = static_tiles; }
#define MAP_TILE_ALLOCATE_ROW(X, SZ) { static RailMapTile static_row[(SZ)]; map->tiles[(X)] = static_row; }

#define MAP_START_TILE {  static ConstHotSpotIndex static_hotspots[] = {
#define MAP_END_TILE(X, Y)           }; map->tiles[(X)][(Y)].hotspots = static_hotspots; }

+ (void)calcTileSize:(RailMap *)map {
    size_t sz = sizeof(RailMapTile *) * map->yTiles;
    
    sz += sizeof(RailMapTile) * map->xTiles;
    
    for (int x = 0; x < map->xTiles; x++) {
        for (int y = 0; y < map->yTiles; y++) {
            ConstHotSpotIndex *index = map->tiles[x][y].hotspots;
            
            while (*index != MAP_LAST_INDEX) {
                index++;
                sz += sizeof(ConstHotSpotIndex);
            }
        }
    }
    
    DEBUG_LOG(@"Tile size %@ %ld\n", map->title, sz);
}

+ (RailMap*)railMap:(int)n
{
    return &railmaps[n];
}

+ (void)initHotspotData {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (nHotSpots > 0) {
            return;
        }
        
        railmaps[kRailMapMaxWes].firstHotspot = 0;
        HotSpot *hs = hotSpotRegions;
        
        DEBUG_LOGL(sizeof(HotSpot));
        
#include "MaxHotSpotTable.txt"
        
        railmaps[kRailMapMaxWes].lastHotspot = nHotSpots - 1;
        
        railmaps[kRailMapPdxStreetcar].firstHotspot = nHotSpots;
        
#include "StreetcarHotSpotTable.txt"
        
        railmaps[kRailMapPdxStreetcar].lastHotspot = nHotSpots - 1;
        
        
        assert(nHotSpots < MAXHOTSPOTS);
        
#ifdef DEBUGLOGGING
        int i;
        size_t sz = sizeof(hotSpotRegions);
        
        for (i = 0; i < nHotSpots; i++) {
            HotSpot *hs = hotSpotRegions + i;
            
            if (hs->isRect) {
                sz += sizeof(CGRect);
            } else {
                sz += sizeof(CGPoint) * hs->nVertices;
            }
            
            sz += hs->action.length;
        }
        
        DEBUG_LOG(@"Hotspot database size %ld\n", (long)sz);
        
#endif
        
        
        // Put together the striping for the quick search
        
        {
            RailMap *map = &railmaps[kRailMapMaxWes];
            map->tileSize.width = map->size.width  / map->xTiles;
            map->tileSize.height = map->size.height / map->yTiles;
            
#include "MaxHotSpotTiles.txt"
            
#ifdef DEBUGLOGGING
            [RailMapView calcTileSize:map];
#endif
        }
        
        {
            RailMap *map = &railmaps[kRailMapPdxStreetcar];
            map->tileSize.width = map->size.width  / map->xTiles;
            map->tileSize.height = map->size.height / map->yTiles;
            
#include "StreetcarHotSpotTiles.txt"
            
#ifdef DEBUGLOGGING
            [RailMapView calcTileSize:map];
#endif
        }
    });
}

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled {
    if (cancelled) {
        [self.hotSpots  fadeOut];
    }
    
    [super backgroundTaskDone:viewController cancelled:cancelled];
}

@end

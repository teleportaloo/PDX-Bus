//
//  RailMapView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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


static HOTSPOT hotSpotRegions[MAXHOTSPOTS];

extern int pnpoly(int npol, const CGPoint *p, CGFloat x, CGFloat y);



int nHotSpots = 0;

static RAILMAP railmaps[] = 
{
    {@"MAX & WES Map", @"MAXWESMap",   { 3000, 1700 }, 0, 0, 30, 3, 0, { 0, 0 } },
    {@"Streetcar Map", @"StreetcarMap",{ 1500, 1951 }, 0, 0, 4, 20, 0, { 0, 0 } },
    {nil,   0, 0}
};


@implementation RailMapView

- (void)dealloc {
    
    self.callback = nil;
    self.hotSpots.mapView = nil;
    self.backgroundTask = nil;
    
}


#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.


- (CGFloat)heightOffset
{
    if (SMALL_SCREEN || (self.screenInfo.screenWidth == WidthBigVariable))
    {
        return -[UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return 0.0;
}


#ifdef MAXCOLORS
+ (HOTSPOT *)hotspots
{
    return &hotSpotRegions[0];    
}
+ (int)nHotspots
{
    return nHotSpots;    
}

#endif


- (instancetype)init {
    if ((self = [super init]))
    {
        self.picker = NO;
        self.from = NO;
        self.callback = nil;
        _easterEgg = EasterEggStart;
        self.backgroundTask = [BackgroundTaskContainer create:self];
        
        self.locationsDb = [ StopLocations getDatabase];
        
        UserPrefs *prefs = [UserPrefs sharedInstance];
        int mapId;
        
        if (prefs.showStreetcarMapFirst)
        {
            mapId = kRailMapPdxStreetcar;
        }
        else
        {
            mapId = kRailMapMaxWes;
        }
        
        _railMap = railmaps + mapId;
        _railMapIndex = mapId;
    }
    return self;
}

#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskController>) progress
{
    if (self.callback)
    {
        if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
        {
            [self.callback selectedStop:stop.locid desc:stop.desc];
        }
        else 
        {
            [self.callback selectedStop:stop.locid];
        }

        
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:progress loc:stop.locid];
}

#pragma mark BackgroundTask methods

#pragma mark UI callbacks

- (NSString *)actionText
{
    if (self.callback)
    {
        return [self.callback actionText];
    }
    return @"Show departures";
}

-(void)showMap:(id)sender
{
    int i,j;
    CLLocation *here;
    
    NearestVehiclesMap *mapPage = [NearestVehiclesMap viewController];
    
    if (_railMapIndex == kRailMapPdxStreetcar)
    {
        mapPage.trimetRoutes = [NSSet set];
        mapPage.streetcarRoutes = [TriMetInfo streetcarRoutes];
        mapPage.title = NSLocalizedString(@"Portland Streetcar", @"map page title");
    }
    else
    {
        mapPage.streetcarRoutes = [NSSet set];
        mapPage.trimetRoutes = [TriMetInfo triMetRailLines];
        mapPage.title = NSLocalizedString(@"MAX & WES", @"map page title");
    }
    
    for (i=_railMap->firstHotspot; i<= _railMap->lastHotspot;  i++)
    {
        HOTSPOT *hs = hotSpotRegions+i;
        
        if (hs->action.firstUnichar==kLinkTypeStop && hs->nVertices!=0)
        {
            RailStation *station = [RailStation fromHotSpot:hs index:i];
            
            // NSString *stop = nil;
            NSString *dir = nil;
            NSString *locId = nil;
                
            for (j=0; j< station.dirList.count; j++)    
            {
                dir   = station.dirList[j];
                locId = station.locList[j];
                
                here = [self.locationsDb getLocation:locId];
                
                if (here)
                {
                    Stop *a = [Stop data];
                    
                    a.locid = locId;
                    a.desc  = station.station;
                    a.dir   = dir;
                    a.lat   = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
                    a.lng   = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
                    a.callback = self;
                
                    [mapPage addPin:a];
                }
            }
        }
                
    }
    
    mapPage.callback = self.callback;
    
    [mapPage fetchNearestVehiclesAsync:self.backgroundTask];

}

- (void)toggleMap:(UISegmentedControl*)seg
{
    if (_railMapIndex != seg.selectedSegmentIndex)
    {
        [self saveImage];
        _railMapIndex = (int)seg.selectedSegmentIndex;
        _railMap = railmaps + _railMapIndex;
        _selectedItem = -1;
        
        UserPrefs *prefs = [UserPrefs sharedInstance];
        
        prefs.showStreetcarMapFirst = (_railMapIndex == kRailMapPdxStreetcar);
        
        [self loadImage];
    }
}

#pragma mark ViewControllerBase methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    UIBarButtonItem *segItem = [self segBarButtonWithItems:@[@"MAX & WES", @"Streetcar"] action:@selector(toggleMap:) selectedIndex:_railMapIndex];
    
    self.railMapSeg = segItem.customView;
    
    [toolbarItems addObjectsFromArray: @[
                 [UIToolbar mapButtonWithTarget:self action:@selector(showMap:)],
                 [UIToolbar flexSpace],
                 segItem]];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark View methods

-(void)saveImage
{
    if (self.imageView)
    {
        SAVED_IMAGE *saved =_savedImage + _railMapIndex;
        saved->zoom = self.scrollView.zoomScale;
        saved->contentOffset = self.scrollView.contentOffset;
        saved->saved = YES;
        
        [self.lowResBackgroundImage removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView = nil;
    }
}

- (void)loadImage
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@_Placeholder", _railMap->fileName]
                                                      ofType:@"gif"];
    
    self.lowResBackgroundImage = [[UIImageView alloc] initWithFrame:(CGRect){ CGPointZero, _railMap->size }];
    
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
    CGRect imageFrame  = self.imageView.frame;
    
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    minimumScale = scrollFrame.size.width  / imageFrame.size.width;
    
        
    self.scrollView.minimumZoomScale = scrollFrame.size.height / imageFrame.size.height;
    
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    
      
    
    self.scrollView.minimumZoomScale = minimumScale;
    
    self.hotSpots = [[RailMapHotSpots alloc] initWithImageView:self.imageView map:_railMap];
    
    self.title = _railMap->title;
    
    SAVED_IMAGE *saved =_savedImage + _railMapIndex;
    
    if (saved->saved)
    {
        self.scrollView.zoomScale = saved->zoom;
        self.scrollView.contentOffset = saved->contentOffset;
    }
    else
    {
        CGRect zoom;
        CGRect imageFrame  = self.imageView.frame;
        CGRect scrollFrame = self.scrollView.frame;
        CGFloat scale =  (scrollFrame.size.height / imageFrame.size.height) * 1.25   ;
        
        zoom.size.width  = self.scrollView.frame.size.width  / scale;
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
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.scrollView];
    
    [self loadImage];

    
    // [self.scrollView scrollRectToVisible:zoom animated:NO];
     [self updateToolbar];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)deselectItemCallback
{
    [self.hotSpots fadeOut];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.hotSpots fadeOut];
    
    [super viewWillAppear:animated];
}

#pragma mark Process hotspot string "URL"

- (void)scannerInc:(NSScanner *)scanner 
{    
    if (!scanner.atEnd)
    {
        scanner.scanLocation++;
    }
}


- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
    if (!scanner.atEnd)
    {
        [scanner scanUpToString:@"/" intoString:substr];
        
        // NSLog(@"%@", *substr);
        [self scannerInc:scanner];
    }
    
}



-(BOOL) processHotSpot:(NSString *)url item:(int)i
{
    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];

    NSString *substr;
    NSString *stationName = @"";
    NSString *wikiLink;
    NSString *map = @"";
    
    [scanner scanUpToCharactersFromSet:colon intoString:&substr];
    
    if (substr == nil)
    {
        return YES;
    }
    
    switch (*substr.UTF8String)    
    {
        case kLinkTypeNorth:
        {
            switch (_easterEgg)
            {
                case EasterEggNorth1:
                case EasterEggNorth2:
                    _easterEgg ++;
                    break;
                case EasterEggNorth3:
                    self.hotSpots.hidden = !self.hotSpots.hidden;
                    self.imageView.annotates = !self.imageView.annotates;
                    [self.imageView setNeedsDisplay];
                    self.hotSpots.alpha = self.hotSpots.hidden ? 0.0 : 1.0;
                    [self.hotSpots setNeedsDisplay];
                    [self updateToolbar];
//                    [self.toolbar setNeedsDisplay];
                    _easterEgg = EasterEggStart;
                    break;
                default:
                    _easterEgg = EasterEggNorth1;
                    break;
            }
            break;
        }
        case kLinkType1:
        case kLinkType2:
        case kLinkType3:
            {
                [WebViewController displayPage:@"http://www.teleportaloo.org/pdxbus/easteregg/"
                                          full:nil
                                     navigator:self.navigationController
                                itemToDeselect:self
                                      whenDone:self.callbackWhenDone];
                
                _easterEgg = EasterEggStart;
            }
            break;
            
        case kLinkTypeWiki:
        {
            _easterEgg = EasterEggStart;
    
            [self scannerInc:scanner];
            //[self.hotSpots selectItem:i];
        
            wikiLink = [url substringFromIndex:scanner.scanLocation];
        
            [WebViewController displayPage:[NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ]
                                      full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            
            break;
        }
        case kLinkTypeHttp:
        {
            _easterEgg = EasterEggStart;
            
            //[self.hotSpots selectItem:i];
            
            [WebViewController displayPage:url
                                      full:nil
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
        
            break;
        }
        case kLinkTypeDir:
        {
            _easterEgg = EasterEggStart;
            //[self.hotSpots selectItem:i];
        
            [self scannerInc:scanner];
            [self nextSlash:scanner intoString:&substr];
            [self nextSlash:scanner intoString:&substr];
            // [self nextSlash:scanner intoString:&substr];
            [self nextSlash:scanner intoString:&stationName];
        
        
            DirectionView *dirView = [DirectionView viewController];
            dirView.callback = self.callback;
            [dirView fetchDirectionsAsync:self.backgroundTask route:stationName];
            break;
        }
        case kLinkTypeMap:
        {
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
        case kLinkTypeStop:
        {
            _easterEgg = EasterEggStart;
            //[self.hotSpots selectItem:i];
        
        
            RailStation *station = [RailStation fromHotSpot:hotSpotRegions+i index:i];
        
            
            RailStationTableView *railView = [RailStationTableView viewController];
            railView.station = station; 
            railView.callback = self.callback;
            railView.from = self.from;
            railView.locationsDb = self.locationsDb;
            
            if (!self.hotSpots.hidden)
            {
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
    [scrollView setZoomScale:scale+0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = self.scrollView.frame.size.height / scale;
    zoomRect.size.width  = self.scrollView.frame.size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


#pragma mark TapDetectingImageViewDelegate methods

- (void)listAction:(id)unused
{
    AllRailStationView *allRail = [AllRailStationView viewController];
    allRail.callback = self.callback;
    [self.navigationController pushViewController:allRail animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.showNextOnAppearance)
    {
        do
        {
            _selectedItem = _railMap->firstHotspot + ((_selectedItem - _railMap->firstHotspot + 1) % (_railMap->lastHotspot - _railMap->firstHotspot +1));
        } while (hotSpotRegions[_selectedItem].action.firstUnichar !='s');
        
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

- (void) selectedHotspot:(NSTimer*)theTimer
{
    [self processHotSpot:hotSpotRegions[_selectedItem].action item:_selectedItem];
}

- (void)findHotspot:(NSTimer*)theTimer
{
    int i;
    bool found = false;

    {
        int x = _tapPoint.x /  _railMap->tileSize.width;
        int y = _tapPoint.y /  _railMap->tileSize.height;
        
        RAILMAP_TILE *tile = &_railMap->tiles[x][y];
        
        
        HOTSPOT_INDEX *indices = tile->hotspots;
        
        
        
        while (*indices != MAP_LAST_INDEX)
        {
            i = *indices + _railMap->firstHotspot;
            
            HOTSPOT * hotspot = &hotSpotRegions[i];
            DEBUG_LOGS(hotspot->action);
            
            if (    (HOTSPOT_IS_POLY(hotspot) && pnpoly(hotspot->nVertices, hotspot->coords.vertices, _tapPoint.x, _tapPoint.y))
                ||  (HOTSPOT_IS_RECT(hotspot) && CGRectContainsPoint(*hotspot->coords.rect, _tapPoint)))        {
                hotSpotRegions[i].touched = YES;
                _selectedItem = i;
                [self.hotSpots selectItem:i];
                [self.hotSpots setNeedsDisplay];
                
                NSDate *soon = [[NSDate date] dateByAddingTimeInterval:0.1];
                NSTimer *timer = [[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(selectedHotspot:) userInfo:nil repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
                found = true;
                break;
            }
            
            indices++;
        }
    }
    
    if (!found)
    {
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

#ifdef CREATE_MAX_ARRAYS


+(NSMutableArray*)tileScan:(RAILMAP *)map
{
    int x,y,i;
    CGPoint p;
    
    NSMutableArray * xTiles = [NSMutableArray array];
    
    for (x=0; x< map->xTiles; x++)
    {
        NSMutableArray *yTiles = [NSMutableArray array];
        [xTiles addObject:yTiles];
        
        for (y=0; y<map->yTiles; y++)
        {
            [yTiles addObject:[NSMutableSet set]];
        }
        
    }
    
    for (x=0; x< map->size.width; x++)
    {
        int xs = x / map->tileSize.width;
    
        NSMutableArray * yTiles = xTiles[xs];
        
        for (y=0; y< map->size.height; y++)
        {
            int ys = y / map->tileSize.height;
            
            NSMutableSet *set = yTiles[ys];
            
            p.x = x;
            p.y = y;
            
            for (i=map->firstHotspot; i<= map->lastHotspot; i++)
            {
                
                if (    (HOTSPOT_IS_POLY(&hotSpotRegions[i]) && pnpoly(hotSpotRegions[i].nVertices, hotSpotRegions[i].coords.vertices, p.x, p.y))
                    ||  (HOTSPOT_IS_RECT(&hotSpotRegions[i]) && CGRectContainsPoint(*hotSpotRegions[i].coords.rect, p)))
                {
                    [set addObject:@(i)];
                }
            }
        }
    }
    return xTiles;
}

+ (void)dumpTiles:(NSMutableArray *)tiles map:(RAILMAP*)map output:(NSMutableString *)output
{
    [output appendFormat:@"\n/* tiles for %@ (total hotspots: %d) */\n", map->title, map->lastHotspot-map->firstHotspot+1];
    int total = 0;
    
    [output appendFormat:@"/* -- */ MAP_TILE_ALLOCATE_ARRAY(%d)\n", (int)tiles.count];
    
    int x,y;
    for (x=0; x<tiles.count ; x++)
    {
        NSMutableArray * ya = tiles[x];
        // DEBUG_LOG(@"Stripe size %lu\n", (unsigned long)stripeSet.count);
        
        [output appendFormat:@"/* -- */ MAP_TILE_ALLOCATE_ROW(%d,%d)\n", x, (int)ya.count];

        
        for (y=0; y<ya.count; y++)
        {
            NSMutableSet *set = ya[y];
            
            [output appendFormat:@"/* %02d */ MAP_START_TILE ", (int)set.count];
            total += set.count;
            
            for (NSNumber *n in set)
            {
                [output appendFormat:@"%d,", n.intValue - map->firstHotspot];
            }
            
            [output appendFormat:@"MAP_LAST_INDEX MAP_END_TILE(%d,%d)\n", x,y];

        }
    }
    
    [output appendFormat:@"/* Total %d */\n", total];
}

+ (void)makeTiles:(RAILMAP *)map
{
    NSMutableString *output = [NSMutableString string];
    NSMutableArray *tiles = [RailMapView tileScan:map];
    [RailMapView dumpTiles:tiles map:map output:output];
    
    CODE_LOG(@"%@", output );
    
    
}

#endif

#pragma mark Hotspot Data

// These macros convert some text files into some linked static arrays.


// The Polygons from the HTML become static arrays of vertices
#define HS_START_POLY { static const CGPoint static_vertices [] = {
#define HS_END_POLY }; hs->coords.vertices = static_vertices; hs->isRect = 0; hs->nVertices = sizeof(static_vertices)/sizeof(static_vertices[0]); hs->action = @
#define HS_END ; nHotSpots++; hs++; }

// The rectable form the HTML is simpler
#define HS_RECT(X1,Y1,X2,Y2, STR) { static const CGRect static_rect = { (X1),(Y1),(X2) - (X1),(Y2) - (Y1) }; hs->coords.rect = &static_rect; hs->isRect = 1; hs->nVertices = 4; hs->action = (@STR); nHotSpots++; hs++; }

// The tiles are used to optimize the search when the user taps on the map
#define MAP_TILE_ALLOCATE_ARRAY(SZ) { static RAILMAP_TILE * static_tiles[(SZ)]; map->tiles = static_tiles; }
#define MAP_TILE_ALLOCATE_ROW(X,SZ) { static RAILMAP_TILE static_row[(SZ)]; map->tiles[(X)] = static_row; }

#define MAP_START_TILE {  static HOTSPOT_INDEX static_hotspots[] = {
#define MAP_END_TILE(X,Y) }; map->tiles[(X)][(Y)].hotspots = static_hotspots; }

+ (void)calcTileSize:(RAILMAP *)map
{
    size_t sz = sizeof(RAILMAP_TILE*) * map->yTiles;
    
    sz+= sizeof(RAILMAP_TILE) * map->xTiles;
    
    for (int x=0; x< map->xTiles; x++)
        for (int y=0; y<map->yTiles; y++)
        {
            HOTSPOT_INDEX *index = map->tiles[x][y].hotspots;
            
            while (*index != MAP_LAST_INDEX)
            {
                index++;
                sz+=sizeof(HOTSPOT_INDEX);
            }
        }
    
    DEBUG_LOG(@"Tile size %@ %ld\n", map->title, sz);
}

+ (void) initHotspotData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nHotSpots > 0)
        {
            return;
        }
        
        railmaps[kRailMapMaxWes].firstHotspot = 0;
        HOTSPOT *hs = hotSpotRegions;
        
        DEBUG_LOGL(sizeof(HOTSPOT));
        
#include "MaxHotSpotTable.txt"
        
        railmaps[kRailMapMaxWes].lastHotspot = nHotSpots-1;
        
        railmaps[kRailMapPdxStreetcar].firstHotspot = nHotSpots;
        
#include "StreetcarHotSpotTable.txt"
        
        railmaps[kRailMapPdxStreetcar].lastHotspot = nHotSpots-1;
        
        
        assert(nHotSpots < MAXHOTSPOTS);
        
#ifdef DEBUGLOGGING
        int i;
        size_t sz = sizeof(hotSpotRegions);
        
        for (i=0; i< nHotSpots; i++)
        {
            HOTSPOT *hs = hotSpotRegions+i;
            
            if (hs->isRect)
            {
                sz+=sizeof(CGRect);
            }
            else
            {
                sz+=sizeof(CGPoint) * hs->nVertices;
            }
            
            sz+= hs->action.length;
        }
        DEBUG_LOG(@"Hotspot database size %ld\n", (long)sz);
        
#endif
        
        
        // Put together the striping for the quick search
        
        {
            RAILMAP * map = &railmaps[kRailMapMaxWes];
            map->tileSize.width  = map->size.width  / map->xTiles;
            map->tileSize.height = map->size.height / map->yTiles;
            
#include "MaxHotSpotTiles.txt"
            
#ifdef DEBUGLOGGING
            [RailMapView calcTileSize:map];
#endif
        }
        
        {
            RAILMAP * map = &railmaps[kRailMapPdxStreetcar];
            map->tileSize.width  = map->size.width  / map->xTiles;
            map->tileSize.height = map->size.height / map->yTiles;
            
#include "StreetcarHotSpotTiles.txt"
            
#ifdef DEBUGLOGGING
            [RailMapView calcTileSize:map];
#endif
            
        }
        
        
#ifdef CREATE_MAX_ARRAYS
        [RailMapView makeTiles:&railmaps[kRailMapMaxWes]];
        [RailMapView makeTiles:&railmaps[kRailMapPdxStreetcar]];
#endif
        
    });
}

- (void)backgroundTaskDone:(UIViewController*)viewController cancelled:(bool)cancelled
{
    if (cancelled)
    {
        [self.hotSpots  fadeOut];
    }
    [super backgroundTaskDone:viewController cancelled:cancelled];
}

@end

#pragma mark Rail Map Hotspots

@implementation RailMapHotSpots;
@synthesize mapView   = _mapView;
@synthesize hidden = _hidden;
@synthesize selectedItem = _selectedItem;




-(instancetype) initWithImageView:(UIView*)mapView map:(RAILMAP*)map
{
    self = [super initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
    self.backgroundColor = [UIColor clearColor];
    
    self.mapView = mapView;
    
    [self.mapView addSubview:self];
    self.hidden = YES;
    // self.hidden = NO;
    self.selectedItem = -1;
    
    _railMap = map;
    
    return self;
}

- (void)touchAtPoint:(CGPoint)point
{
    self.selectedItem = -1;
    _touchPoint = point;
    self.alpha = 1.0;
    [self setNeedsDisplay];

    [self fadeOut];
}

- (void)selectItem:(int)i
{
    self.selectedItem = i;
    _touchPoint.x = 0;
    _touchPoint.y = 0;
    
    
    switch(hotSpotRegions[i].action.firstUnichar)
    {
        case kLinkTypeHttp:
        case kLinkTypeWiki:
        case kLinkTypeStop:
        case kLinkTypeDir:
        case kLinkType1:
        case kLinkType2:
        case kLinkType3:
            
            self.alpha = 1.0;
            [self setNeedsDisplay];
            break;
            
        case kLinkTypeNorth:
                    break;
            
    }
}

- (void)fadeOut
{
    
    if (self.hidden)
    {
        [UIView beginAnimations:nil context:NULL];  
        [UIView setAnimationDuration:1.0];  
        // [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];  


        self.alpha = 0.0;    
        [UIView commitAnimations]; 
    }
}


- (void)drawHotspot:(HOTSPOT *)hs context:(CGContextRef)context;
{
    if (hs->action.firstUnichar == '#')
    {
        CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.5);
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    }
    else if (hs->touched && !self.hidden)
    {
        CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.5);
        CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
    }
    else
    {
        UIColor * col;
        switch (hs->action.firstUnichar)
        {
            default:
            case kLinkTypeHttp:
                col = [UIColor orangeColor];
                break;
            case kLinkTypeWiki:
                col = [UIColor redColor];
                break;
            case kLinkTypeStop:
            case kLinkTypeDir:
                col = [UIColor modeAwareBlue];
                break;
            
            case kLinkType1:
            case kLinkType2:
            case kLinkType3:
                col = [UIColor modeAwareBlue];
                break;
            case kLinkTypeNorth:
                col = [UIColor grayColor];
                break;
        }
        
        const CGFloat *components = CGColorGetComponents(col.CGColor);
        // printf("%f %f %f\n", components[0], components[1], components[2]);
        CGContextSetRGBFillColor(context, components[0], components[1], components[2], 0.5);
        CGContextSetStrokeColorWithColor(context, col.CGColor);
    }
    
    
    if (HOTSPOT_IS_POLY(hs))
    {
        const CGPoint * vertices = hs->coords.vertices;
        int nVertices = hs->nVertices;
        
        // Draw curves between the midpoints of the polygon's sides with the
        // vertex as the control point.
        
        CGContextMoveToPoint(context, (vertices[0].x+vertices[1].x)/2, (vertices[0].y+vertices[1].y)/2);

        for(int i = 1; i < hs->nVertices; i++)
        {
            CGContextAddQuadCurveToPoint(context,vertices[i].x, vertices[i].y,(vertices[i].x+vertices[(i+1) % nVertices].x)/2, (vertices[i].y+vertices[(i+1) % nVertices].y)/2);
        }
        
        CGContextAddQuadCurveToPoint(context,vertices[0].x, vertices[0].y,(vertices[0].x+vertices[1].x)/2, (vertices[0].y+vertices[1].y)/2);
        CGContextFillPath(context);
    }
    else if (HOTSPOT_IS_RECT(hs))
    {
        CGContextFillEllipseInRect(context, *hs->coords.rect);
    }
}

- (void)drawBlob:(CGContextRef) context
{
    // Drawing code
    
    CGMutablePathRef fillPath = CGPathCreateMutable();
    
    // CGPathAddRects(fillPath, NULL, &rect, 1);
    CGFloat width = 20.0;
    CGRect rect = CGRectMake(_touchPoint.x - width / 2.0,
                             _touchPoint.y - width / 2.0,
                             width,
                             width);
    
    CGRect square;
    
    // CGFloat width = min(CGRectGetWidth(rect), CGRectGetHeight(rect));
    
    square.origin.x = CGRectGetMidX(rect) - width/2;
    square.origin.y = CGRectGetMidY(rect) - width/2;
    square.size.width = width;
    square.size.height = width;
    
    CGPathAddEllipseInRect(fillPath, NULL, square);
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
    
//    CGContextSetRGBFillColor(context, _red , _green, _blue, self.hidden ? 0.0 : 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);
    
    //    DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
    
    CGPathRelease(fillPath);
    
}


- (void)drawRect:(CGRect)rect {
    {
        static CGFloat dash [] = { 5.0, 5.0 };
        CGContextRef context = UIGraphicsGetCurrentContext(); 
        
        
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
        CGContextSetLineDash (context, 5.0, dash, 2);
        CGContextSetLineWidth(context, 1.0);
        
        
        HOTSPOT *hs;
        
        if (self.hidden)
        {
            if (self.selectedItem != -1)
            {
                [self drawHotspot:(hotSpotRegions+self.selectedItem) context:context];
            }
            else if (_touchPoint.x != 0.0)
            {
                [self drawBlob:context];
            }
        }
        else 
        {
            
            if (self.selectedItem == -1 && _touchPoint.x != 0.0)
            {
                [self drawBlob:context];
            }
        
            for (int j=_railMap->firstHotspot; j <= _railMap->lastHotspot; j++)
            {
                hs = hotSpotRegions+j;
                
                if (hs->nVertices > 0)
                {
                    [self drawHotspot:hs context:context];
                }
            }
            
            CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
            
            for (CGFloat x=0; x <  _railMap->xTiles; x++)
            {
                CGFloat xp = x *_railMap->tileSize.width;
                CGContextMoveToPoint(   context, xp, 0);
                CGContextAddLineToPoint(context, xp, _railMap->size.height);
            }
            
            for (CGFloat y=0; y < _railMap->yTiles; y++)
            {
                CGFloat yp = y *_railMap->tileSize.height;
                DEBUG_LOG(@"yp %f\n", yp);
                CGContextMoveToPoint(   context, 0,                     yp);
                CGContextAddLineToPoint(context, _railMap->size.width,  yp);
            }
        
            
            CGContextSetTextDrawingMode(context, kCGTextFill); // This is the default
            [[UIColor blackColor] setFill]; // This is the default
            
            CGContextSetTextMatrix(context, CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0));
            
            for (int x=0; x < _railMap->xTiles; x++)
            {
                for (int y=0; y< _railMap->yTiles; y++)
                {
                    CGFloat xp = x *_railMap->tileSize.width  + _railMap->tileSize.width /2.0;
                    CGFloat yp = y *_railMap->tileSize.height + _railMap->tileSize.height/2.0;
                    
                    HOTSPOT_INDEX *index = _railMap->tiles[x][y].hotspots;
                    
                    int count = 0;
                    
                    while (*index != MAP_LAST_INDEX)
                    {
                        index++;
                        count++;
                    }
                    
                    NSString *sizeText = [NSString stringWithFormat:@"%d", count];
                    
                    [sizeText drawAtPoint:CGPointMake(xp, yp)
                               withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Helvetica"
                                                                                    size:12]
                                                }];

                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
        
           //  CGContextStrokePath(context);
        
        }
        
                
        // CGContextStrokePath(context);
    }
}


@end


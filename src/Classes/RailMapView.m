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


static HOTSPOT hotSpotRegions[MAXHOTSPOTS];

extern int pnpoly(int npol, const CGPoint *p, CGFloat x, CGFloat y);



int nHotSpots = 0;

static RAILMAP railmaps[] = 
{
    {@"MAX & WES Map", @"MAXWESMap",   { 3000, 1700 }, 0, 0, 30, 3, 0, { 0, 0 } },
    {@"Streetcar Map", @"StreetcarMap",{ 1500, 2091 }, 0, 0, 4, 20, 0, { 0, 0 } },
    {nil,   0, 0}
};


@implementation RailMapView

@synthesize scrollView = _scrollView;
@synthesize from = _from;
@synthesize picker = _picker;
@synthesize stopIDs = _stopIDs;
@synthesize hotSpots = _hotSpots;
@synthesize locationsDb = _locationsDb;
@synthesize imageView = _imageView;
@synthesize lowResBackgroundImage = _lowResBackgroundImage;
@synthesize railMapSeg = _railMapSeg;
@synthesize showNextOnAppearance = _showNextOnAppearance;


- (void)dealloc {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.callback = nil;
	self.stopIDs = nil;
    self.hotSpots.mapView = nil;
	self.hotSpots = nil;
	self.locationsDb = nil;
	self.backgroundTask = nil;
    self.lowResBackgroundImage = nil;
    self.imageView = nil;
    self.railMapSeg = nil;
    self.scrollView = nil;
	[super dealloc];
    
}


#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.

- (CGFloat) heightOffset
{
    if (self.iOS7style && (SmallScreenStyle(self.screenInfo.screenWidth) || (self.screenInfo.screenWidth == WidthBigVariable)))
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


- (id)init {
	if ((self = [super init]))
	{
		self.picker = NO;
		self.from = NO;
		self.callback = nil;
		easterEgg = EasterEggStart;
		self.backgroundTask = [BackgroundTaskContainer create:self];
		
		self.locationsDb = [ StopLocations getDatabase];
        
        UserPrefs *prefs = [UserPrefs getSingleton];
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

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress
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
	
	DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
	
	departureViewController.displayName = stop.desc;
	
	[departureViewController fetchTimesForLocationInBackground:progress loc:stop.locid];
	[departureViewController release];
	
}

#pragma mark BackgroundTask methods

-(void)backgroundCompleted:(UIViewController *)viewController
{
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark UI callbacks

- (NSString *)actionText
{
	if (self.callback)
	{
		return [self.callback actionText];
	}
	return @"Show arrivals";
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self notRailAwareButton:buttonIndex];
}

-(void)showMap:(id)sender
{
	
	if (self.locationsDb.isEmpty)
	{
		[self noLocations:@"Rail Map" delegate:self];
		return;
	}
	
	
	int i,j;
	CLLocation *here;
	
    NearestVehiclesMap *mapPage = [[[NearestVehiclesMap alloc] init] autorelease];
    
    if (_railMapIndex == kRailMapPdxStreetcar)
    {
        mapPage.streetcarRoutes = nil;
        mapPage.trimetRoutes = [NSSet set];
        mapPage.title = @"Portland Streetcar";
    }
    else
    {
        mapPage.streetcarRoutes = [NSSet set];
        mapPage.trimetRoutes = [TriMetRouteColors triMetRoutes];
        mapPage.title = @"MAX & WES";
    }
	
	for (i=_railMap->firstHotspot; i<= _railMap->lastHotspot;  i++)
	{
		if (hotSpotRegions[i].action[0]==kLinkTypeStop && hotSpotRegions[i].nVertices!=0)
		{
			RailStation *station = [[[RailStation alloc] initFromHotSpot:hotSpotRegions+i index:i] autorelease];
			
			// NSString *stop = nil;
			NSString *dir = nil;
			NSString *locId = nil;
				
			for (j=0; j< station.dirList.count; j++)	
			{
				dir = [station.dirList objectAtIndex:j];
				locId = [station.locList objectAtIndex:j];
				
				here = [self.locationsDb getLocation:locId];
				
				if (here)
				{
					Stop *a = [[[Stop alloc] init] autorelease];
					
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
	
    [mapPage fetchNearestVehiclesInBackground:self.backgroundTask];

}

- (void)toggleMap:(UISegmentedControl*)seg
{
    if (_railMapIndex != seg.selectedSegmentIndex)
    {
        [self saveImage];
        _railMapIndex = (int)seg.selectedSegmentIndex;
        _railMap = railmaps + _railMapIndex;
        selectedItem = -1;
        
        UserPrefs *prefs = [UserPrefs getSingleton];
        
        prefs.showStreetcarMapFirst = (_railMapIndex == kRailMapPdxStreetcar);
        
        [self loadImage];
    }
}

#pragma mark ViewControllerBase methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    // add a segmented control to the button bar
	UISegmentedControl	*buttonBarSegmentedControl;
	buttonBarSegmentedControl = [[[UISegmentedControl alloc] initWithItems:
                                  [NSArray arrayWithObjects:@"MAX & WES", @"Streetcar", nil]] autorelease];
	[buttonBarSegmentedControl addTarget:self action:@selector(toggleMap:) forControlEvents:UIControlEventValueChanged];
	buttonBarSegmentedControl.selectedSegmentIndex = _railMapIndex;	// start by showing the normal picker
	buttonBarSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	
    
    self.railMapSeg = buttonBarSegmentedControl;
    
    [self setSegColor:buttonBarSegmentedControl];
	
	UIBarButtonItem *segItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl] autorelease];

    
	[toolbarItems addObjectsFromArray: [NSArray arrayWithObjects:
				 [CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)],
				 [CustomToolbar autoFlexSpace],
                 segItem,
				 nil]];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark View methods

#define min(X,Y) ((X)<(Y)?(X):(Y))
#define max(X,Y) ((X)>(Y)?(X):(Y))
#define swap(T,X,Y) { T temp; temp = (X); X = (Y); Y = (X); }

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
    
    self.lowResBackgroundImage = [[[UIImageView alloc] initWithFrame:(CGRect){ CGPointZero, _railMap->size }] autorelease];
    
    [self.lowResBackgroundImage setImage:[UIImage imageWithContentsOfFile:path]];
    self.lowResBackgroundImage.userInteractionEnabled = YES;
                                   
    
    self.imageView = [[[TapDetectingImageView alloc] initWithImageName:_railMap->fileName size:_railMap->size] autorelease];
    
    
    
    [self.imageView setDelegate:self];
    [self.lowResBackgroundImage setTag:ZOOM_VIEW_TAG];
    self.imageView.frame = self.lowResBackgroundImage.bounds;
    
    [self.lowResBackgroundImage addSubview:self.imageView];
    
    [self.scrollView setContentSize:_railMap->size];
    [self.scrollView addSubview:self.lowResBackgroundImage];
    
    // Lets try to calculate something that'll work for all orientations and devices.
	float minimumScale;
    CGRect scrollFrame = [self.scrollView frame];
    CGRect imageFrame  = [self.imageView frame];
	
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    minimumScale = scrollFrame.size.width  / imageFrame.size.width;
    
        
    [self.scrollView setMinimumZoomScale:scrollFrame.size.height / imageFrame.size.height];
    
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    
  	
    
    [self.scrollView setMinimumZoomScale:minimumScale];
	
	self.hotSpots = [[[RailMapHotSpots alloc] initWithImageView:self.imageView map:_railMap] autorelease];
	
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
        CGRect imageFrame  = [self.imageView frame];
        CGRect scrollFrame = [self.scrollView frame];
        CGFloat scale =  (scrollFrame.size.height / imageFrame.size.height) * 1.25   ;
        
        zoom.size.width  = [self.scrollView frame].size.width  / scale;
        zoom.size.height = [self.scrollView frame].size.height / scale;
        
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
	CGRect bounds = [self getMiddleWindowRect];
	
	/// set up main scroll view
    self.scrollView = [[[UIScrollView alloc] initWithFrame:bounds] autorelease];
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setBouncesZoom:YES];
	self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    [[self view] addSubview:self.scrollView];
    
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
	if (![scanner isAtEnd])
	{
		scanner.scanLocation++;
	}
}


- (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
	if (![scanner isAtEnd])
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
	
	switch (*[substr UTF8String])	
	{
		case kLinkTypeNorth:
		{
			switch (easterEgg)
			{
				case EasterEggNorth1:
				case EasterEggNorth2:
					easterEgg ++;
					break;
				case EasterEggNorth3:
					self.hotSpots.hidden = !self.hotSpots.hidden;
					[self.hotSpots setAlpha:self.hotSpots.hidden ? 0.0 : 1.0];
					[self.hotSpots setNeedsDisplay];
					[self updateToolbar];
//					[self.toolbar setNeedsDisplay];
					easterEgg = EasterEggStart;
					break;
				default:
					easterEgg = EasterEggNorth1;
					break;
			}
			break;
		}
		case kLinkType1:
		case kLinkType2:
		case kLinkType3:
			{
				WebViewController *webPage = [[WebViewController alloc] init];
				[webPage setURLmobile:@"http://www.teleportaloo.org/pdxbus/easteregg/"
								 full:nil];
				
				if (self.callback)
				{
					webPage.whenDone = [self.callback getController];
				}
				[webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
				[webPage release];
				
				easterEgg = EasterEggStart;
			}
			break;
			
		case kLinkTypeWiki:
		{
			easterEgg = EasterEggStart;
	
			[self scannerInc:scanner];
			//[self.hotSpots selectItem:i];
		
			wikiLink = [url substringFromIndex:[scanner scanLocation]];
		
			WebViewController *webPage = [[WebViewController alloc] init];
			
			
			[webPage setURLmobile:[NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ] 
	
							 full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			
			if (self.callback)
			{
				webPage.whenDone = [self.callback getController];
			}
			[webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
			[webPage release];
			break;
		}
		case kLinkTypeHttp:
		{
			easterEgg = EasterEggStart;
			
			//[self.hotSpots selectItem:i];
		
			WebViewController *webPage = [[WebViewController alloc] init];
			[webPage setURLmobile:url 
							 full:nil];
		
			if (self.callback)
			{
				webPage.whenDone = [self.callback getController];
			}
		
			[webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
			[webPage release];
			break;
		}
		case kLinkTypeDir:
		{
			easterEgg = EasterEggStart;
			//[self.hotSpots selectItem:i];
		
			[self scannerInc:scanner];
			[self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&substr];
			// [self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&stationName];
		
		
			DirectionView *dirView = [[DirectionView alloc] init];
			dirView.callback = self.callback;
			[dirView fetchDirectionsInBackground:self.backgroundTask route:stationName];
			[dirView release];
			break;
		}
        case kLinkTypeMap:
		{
			easterEgg = EasterEggStart;
			//[self.hotSpots selectItem:i];
            
			[self scannerInc:scanner];
			[self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&substr];
			// [self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&map];
            
            self.railMapSeg.selectedSegmentIndex = [map integerValue];
            [self toggleMap:self.railMapSeg];
			break;
		}
		case kLinkTypeStop:
		{
			easterEgg = EasterEggStart;
			//[self.hotSpots selectItem:i];
		
		
			RailStation *station = [[[RailStation alloc] initFromHotSpot:hotSpotRegions+i index:i] autorelease];
		
			
			RailStationTableView *railView = [[RailStationTableView alloc] init];
			railView.station = station; 
			railView.callback = self.callback;
			railView.from = self.from;
			railView.locationsDb = self.locationsDb;
			
			if (!self.hotSpots.hidden)
			{
				railView.map = self;
			}
			[[self navigationController] pushViewController:railView animated:YES];
			[railView release];
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
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width  = [self.scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


#pragma mark TapDetectingImageViewDelegate methods

- (void)listAction:(id)arg
{
    AllRailStationView *allRail = [[AllRailStationView alloc] init];
    allRail.callback = self.callback;
    [[self navigationController] pushViewController:allRail animated:YES];
    [allRail release];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.showNextOnAppearance)
    {
        do
        {
            selectedItem = _railMap->firstHotspot + ((selectedItem - _railMap->firstHotspot + 1) % (_railMap->lastHotspot - _railMap->firstHotspot +1));
        } while (hotSpotRegions[selectedItem].action[0] !='s');
        
        hotSpotRegions[selectedItem].touched = YES;
        // selectedItem = i;
        [self.hotSpots setNeedsDisplay];
        [self   processHotSpot:[NSString stringWithUTF8String:hotSpotRegions[selectedItem].action] item:selectedItem];
        self.showNextOnAppearance = NO;
    }
    
    UIBarButtonItem *list = [[[UIBarButtonItem alloc]
                              initWithTitle:NSLocalizedString(@"List", @"List button")
                              style:UIBarButtonItemStyleBordered
                              target:self action:@selector(listAction:)] autorelease];
    
    
    self.navigationItem.rightBarButtonItem = list;
    
    [super viewDidAppear:animated];
}

- (void) selectedHotspot:(NSTimer*)theTimer
{
	[self   processHotSpot:[NSString stringWithUTF8String:hotSpotRegions[selectedItem].action] item:selectedItem];	
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
            
            DEBUG_LOG(@"Hotspot: %s\n", hotspot->action);
            
            if (    (HOTSPOT_IS_POLY(hotspot) && pnpoly(hotspot->nVertices, hotspot->coords.vertices, _tapPoint.x, _tapPoint.y))
                ||  (HOTSPOT_IS_RECT(hotspot) && CGRectContainsPoint(*hotspot->coords.rect, _tapPoint)))		{
                hotSpotRegions[i].touched = YES;
                selectedItem = i;
                [self.hotSpots selectItem:i];
                [self.hotSpots setNeedsDisplay];
                
#ifdef ORIGINAL_IPHONE
                NSDate *soon = [[NSDate date] addTimeInterval:0.1];
#else
                NSDate *soon = [[NSDate date] dateByAddingTimeInterval:0.1];
#endif
                NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(selectedHotspot:) userInfo:nil repeats:NO] autorelease];
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
                found = true;
                break;
            }
            
            if (hotSpotRegions[i].nVertices == 0)
            {
                // bail out as fast as we can - the end of the array is not worth
                // searching as they are all NULL hotspots.
                // break;
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
    
  //  NSDate *soon = [[NSDate date] addTimeInterval:0.1];
  //  NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.0 target:self selector:@selector(findHotspot:) userInfo:nil repeats:NO] autorelease];
  //  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale = [self.scrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = [self.scrollView zoomScale] / ZOOM_STEP;
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
    
    NSMutableArray * xTiles = [[[NSMutableArray alloc] init] autorelease];
    
    for (x=0; x< map->xTiles; x++)
    {
        NSMutableArray *yTiles = [[[NSMutableArray alloc] init] autorelease];
        [xTiles addObject:yTiles];
        
        for (y=0; y<map->yTiles; y++)
        {
            [yTiles addObject:[[[NSMutableSet alloc] init] autorelease]];
        }
        
    }
    
    for (x=0; x< map->size.width; x++)
    {
        int xs = x / map->tileSize.width;
    
        NSMutableArray * yTiles = [xTiles objectAtIndex:xs];
        
        for (y=0; y< map->size.height; y++)
        {
            int ys = y / map->tileSize.height;
            
            NSMutableSet *set = [yTiles objectAtIndex:ys];
            
            p.x = x;
            p.y = y;
            
            for (i=map->firstHotspot; i<= map->lastHotspot; i++)
            {
                
                if (    (HOTSPOT_IS_POLY(&hotSpotRegions[i]) && pnpoly(hotSpotRegions[i].nVertices, hotSpotRegions[i].coords.vertices, p.x, p.y))
                    ||  (HOTSPOT_IS_RECT(&hotSpotRegions[i]) && CGRectContainsPoint(*hotSpotRegions[i].coords.rect, p)))
                {
                    [set addObject:[NSNumber numberWithInt:i]];
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
        NSMutableArray * ya = [tiles objectAtIndex:x];
        // DEBUG_LOG(@"Stripe size %lu\n", (unsigned long)stripeSet.count);
        
        [output appendFormat:@"/* -- */ MAP_TILE_ALLOCATE_ROW(%d,%d)\n", x, (int)ya.count];

        
        for (y=0; y<ya.count; y++)
        {
            NSMutableSet *set = [ya objectAtIndex:y];
            
            [output appendFormat:@"/* %02d */ MAP_START_TILE ", (int)set.count];
            total += set.count;
            
            for (NSNumber *n in set)
            {
                [output appendFormat:@"%d,", (int)[n integerValue] - map->firstHotspot];
            }
            
            [output appendFormat:@"MAP_LAST_INDEX MAP_END_TILE(%d,%d)\n", x,y];

        }
    }
    
    [output appendFormat:@"/* Total %d */\n", total];
}

+ (void)makeTiles:(RAILMAP *)map
{
    NSMutableString *output = [[[NSMutableString alloc] init] autorelease];
    NSMutableArray *tiles = [RailMapView tileScan:map];
    [RailMapView dumpTiles:tiles map:map output:output];
    
    CODE_LOG(@"%@", output );
    
    
}

#endif

#pragma mark Hotspot Data

// These macros convert some text files into some linked static arrays.


// The Polygons from the HTML become static arrays of vertices
#define HS_START_POLY { static CGPoint static_vertices [] = {
#define HS_END_POLY }; hs->coords.vertices = static_vertices; hs->isRect = 0; hs->nVertices = sizeof(static_vertices)/sizeof(static_vertices[0]); hs->action =
#define HS_END ; nHotSpots++; hs++; }

// The rectable form the HTML is simpler
#define HS_RECT(X1,Y1,X2,Y2, STR) { static CGRect static_rect = { (X1),(Y1),(X2) - (X1),(Y2) - (Y1) }; hs->coords.rect = &static_rect; hs->isRect = 1; hs->nVertices = 4; hs->action = (STR); nHotSpots++; hs++; }

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
	if (nHotSpots > 0)
	{
		return;
	}
    
    railmaps[kRailMapMaxWes].firstHotspot = 0;
    HOTSPOT *hs = hotSpotRegions;
    
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
        
        sz+= strlen(hs->action);
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
    
	
}

- (void)BackgroundTaskDone:(UIViewController*)viewController cancelled:(bool)cancelled
{
    if (cancelled)
    {
        [self.hotSpots  fadeOut];
    }
    [super BackgroundTaskDone:viewController cancelled:cancelled];
}

+ (bool)RailMapSupported
{
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0);
}



@end

#pragma mark Rail Map Hotspots

@implementation RailMapHotSpots;
@synthesize mapView   = _mapView;
@synthesize hidden = _hidden;
@synthesize selectedItem = _selectedItem;



- (void)dealloc {
	self.mapView = nil;
    [super dealloc];
}

-(id) initWithImageView:(UIView*)mapView map:(RAILMAP*)map
{
	self = [super initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
	[self setBackgroundColor:[UIColor clearColor]];
	
	[self setMapView:mapView];
	
	[self.mapView addSubview:self];
	self.hidden = YES;
    self.selectedItem = -1;
    
    _railMap = map;
	
	return self;
}

- (void)touchAtPoint:(CGPoint)point
{
    self.selectedItem = -1;
    _touchPoint = point;
    [self setAlpha:1.0];
    [self setNeedsDisplay];

    [self fadeOut];
}

- (void)selectItem:(int)i
{
	self.selectedItem = i;
    _touchPoint.x = 0;
    _touchPoint.y = 0;
    
	
	switch(hotSpotRegions[i].action[0])
	{
		case kLinkTypeHttp:
		case kLinkTypeWiki:
		case kLinkTypeStop:
		case kLinkTypeDir:
		case kLinkType1:
		case kLinkType2:
		case kLinkType3:
			
			[self setAlpha:1.0];
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


		[self setAlpha:0.0];	
		[UIView commitAnimations]; 
	}
}


- (void)drawHotspot:(HOTSPOT *)hs context:(CGContextRef)context;
{
	if (hs->action[0] == '#')
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
		switch (hs->action[0])
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
				col = [UIColor blueColor];
				break;
			
			case kLinkType1:
			case kLinkType2:
			case kLinkType3:
				col = [UIColor blueColor];
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
	
//	CGContextSetRGBFillColor(context, _red , _green, _blue, self.hidden ? 0.0 : 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);
	
    //	DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
    
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
            
            char sizeText[20];
            
            CGContextSelectFont(context, [[UIFont systemFontOfSize:12].fontName cStringUsingEncoding:NSUTF8StringEncoding] , 12, kCGEncodingMacRoman);
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
                    
                    snprintf(sizeText, sizeof(sizeText), "%d", count);
                    
                    
                    CGContextShowTextAtPoint(context, xp, yp, sizeText, strlen(sizeText));
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
        
           //  CGContextStrokePath(context);
        
		}
		
				
		// CGContextStrokePath(context);
	}
}


@end


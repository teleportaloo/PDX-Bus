//
//  RailMapView.m
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

#import "RailMapView.h"
#import "TableViewWithToolbar.h"
#import "DepartureTimesView.h"
#import "TripPlannerBookmarkView.h"
#import "RailStationTableView.h"
#import "WebViewController.h"
#import "DirectionView.h"
#import "MapViewController.h"
#import "debug.h"
#import "HotSpot.h"
#import "RailStation.h"


static HOTSPOT hotSpotRegions[MAXHOTSPOTS];
extern int pnpoly(int npol, const CGPoint *p, CGFloat x, CGFloat y);



int nHotSpots = 0;

static RAILMAP railmaps[] = 
{
    {@"MAX & WES Map", @"MAXWESMap",   { 3000, 1185 }, 0, 0 },
    {@"Streetcar Map", @"StreetcarMap",{ 1500, 2075 }, 0, 0 },
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
	self.scrollView = nil;
	self.callback = nil;
	self.stopIDs = nil;
	self.hotSpots = nil;
	self.locationsDb = nil;
	self.backgroundTask = nil;
    self.imageView = nil;
    self.lowResBackgroundImage = nil;
    self.railMapSeg = nil;
	[super dealloc];
}


#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5



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
	
	MapViewController *mapPage = [[MapViewController alloc] init];
	
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
				
				here = [self.locationsDb getLocaction:locId];
				
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
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];	
	
}

- (void)toggleMap:(UISegmentedControl*)seg
{
    if (_railMapIndex != seg.selectedSegmentIndex)
    {
        [self saveImage];
        _railMapIndex = seg.selectedSegmentIndex;
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
								 full:nil
								title:@"Internet"];
				
				if (self.callback)
				{
					webPage.whenDone = [self.callback getController];
				}
				[webPage displayPage:[self navigationController] animated:YES tableToDeselect:nil];
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
	
							 full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ] 
							title:@"Wikipedia"];
			
			if (self.callback)
			{
				webPage.whenDone = [self.callback getController];
			}
			[webPage displayPage:[self navigationController] animated:YES tableToDeselect:nil];
			[webPage release];
			break;
		}
		case kLinkTypeHttp:
		{
			easterEgg = EasterEggStart;
			
			//[self.hotSpots selectItem:i];
		
			WebViewController *webPage = [[WebViewController alloc] init];
			[webPage setURLmobile:url 
							 full:nil
							title:@"Internet"];
		
			if (self.callback)
			{
				webPage.whenDone = [self.callback getController];
			}
		
			[webPage displayPage:[self navigationController] animated:YES tableToDeselect:nil];
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
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
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
}

- (void) selectedHotspot:(NSTimer*)theTimer
{
	[self   processHotSpot:[NSString stringWithUTF8String:hotSpotRegions[selectedItem].action] item:selectedItem];	
}

- (void)findHotspot:(NSTimer*)theTimer
{
    int i;
    bool found = false;
    for (i=_railMap->firstHotspot; i<= _railMap->lastHotspot; i++)
	{
		if (    (hotSpotRegions[i].vertices !=nil  && pnpoly(hotSpotRegions[i].nVertices, hotSpotRegions[i].vertices, _tapPoint.x, _tapPoint.y))
            ||  (hotSpotRegions[i].rect     !=nil  && CGRectContainsPoint(*hotSpotRegions[i].rect, _tapPoint)))		{
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

#pragma mark Hotspot Data

#define HS_START_POLY { static CGPoint tmp [] = { 
#define HS_END_POLY }; hotSpotRegions[nHotSpots].vertices = tmp; hotSpotRegions[nHotSpots].nVertices= sizeof(tmp)/sizeof(tmp[0]);  hotSpotRegions[nHotSpots].action =
#define HS_END ;  nHotSpots++; }
                                                           
#define HS_RECT(X1,Y1,X2,Y2, STR) { static CGRect rect = { X1,Y1,X2-X1,Y2-Y1 }; hotSpotRegions[nHotSpots].rect =&rect;  hotSpotRegions[nHotSpots].nVertices=4; hotSpotRegions[nHotSpots].action = STR; nHotSpots++; }

#define NULL_HOTSPOT(X) hotSpotRegions[nHotSpots].vertices=nil; hotSpotRegions[nHotSpots].nVertices=0; hotSpotRegions[nHotSpots].action = X; nHotSpots++;

//
// Copy the map section from railmap.html.  See that file for how to search and replace the HTML with macros 
// to construct this data set.
//

+ (void) initHotspotData
{  
	if (nHotSpots > 0)
	{
		return;
	}
    
    railmaps[kRailMapMaxWes].firstHotspot = 0;
    
    HS_START_POLY 1327,924,1370,927,1376,1099,1330,1100 HS_END_POLY "s:PSU South%2FSW 5th & Jackson/PSU_South_MAX_station/S,7606"  HS_END
    HS_START_POLY 1160,888,1319,886,1325,928,1161,929 HS_END_POLY "s:PSU South%2FSW 6th & College/PSU_South_MAX_station/N,10293"  HS_END
    HS_START_POLY 247,356,2,603,0,669,36,672,36,624,273,380 HS_END_POLY "s:Hatfield Government Center/Hatfield_Government_Center/S,9848/"  HS_END
    HS_START_POLY 154,511,268,386,302,419,94,630,91,671,38,673,35,626 HS_END_POLY "s:Hillsboro Central%2FSE 3rd TC/Hillsboro_Central%2FSoutheast_3rd_Avenue_Transit_Center/E,9846/W,9845"  HS_END
    HS_START_POLY 99,667,147,666,152,623,346,424,325,399,102,629 HS_END_POLY "s:Tuality Hospital%2FSE 8th Ave/Tuality_Hospital%2FSoutheast_8th_Avenue/E,9843/W,9844"  HS_END
    HS_START_POLY 156,664,198,662,203,621,348,469,329,449,157,621 HS_END_POLY "s:Washington%2FSE 12th Ave/Washington%2FSoutheast_12th_Avenue/E,9841/W,9842"  HS_END
    HS_START_POLY 211,664,263,663,269,617,514,364,481,334,215,616 HS_END_POLY "s:Fair Complex%2FHillsboro Airport/Fair_Complex%2FHillsboro_Airport/E,9838/W,9837"  HS_END
    HS_START_POLY 271,667,316,668,318,618,423,509,402,486,270,620 HS_END_POLY "s:Hawthorn Farm/Hawthorn_Farm/E,9839/W,9840"  HS_END
    HS_START_POLY 319,668,321,620,496,439,525,463,376,623,371,666 HS_END_POLY "s:Orenco%2FNW 231st Ave/Orenco%2FNorthwest_231st_Avenue/E,9835/W,9836"  HS_END
    HS_START_POLY 372,667,424,667,418,627,588,458,559,437,380,620 HS_END_POLY "s:Quatama%2FNW 205th Ave/Quatama%2FNorthwest_205th_Avenue/E,9834/W,9833"  HS_END
    HS_START_POLY 426,670,485,670,483,632,706,407,672,378,424,628 HS_END_POLY "s:Willow Creek%2FSW 185th Ave TC/Willow_Creek%2FSouthwest_185th_Avenue_Transit_Center/E,9831/W,9832"  HS_END
    HS_START_POLY 499,667,545,668,550,616,717,452,691,430,495,624 HS_END_POLY "s:Elmonica%2FSW 170th Ave/Elmonica%2FSouthwest_170th_Avenue/E,9830/W,9829"  HS_END
    HS_START_POLY 548,667,605,666,610,623,713,505,693,485,552,617 HS_END_POLY "s:Merlo Rd%2FSW 158th Ave/Merlo_Road%2FSouthwest_158th_Avenue/E,9828/W,9827"  HS_END
    HS_START_POLY 607,667,653,668,655,621,801,471,771,451,617,618 HS_END_POLY "s:Beaverton Creek/Beaverton_Creek/S,9822/N,9819"  HS_END
    HS_START_POLY 656,670,710,669,717,620,814,514,789,490,661,620 HS_END_POLY "s:Millikan Way/Millikan_Way/E,9826/W,9825"  HS_END
    HS_START_POLY 713,670,758,669,759,622,899,482,873,458,722,618 HS_END_POLY "s:Beaverton Central/Beaverton_Central/E,9824/W,9823"  HS_END
    HS_START_POLY 765,677,824,679,820,639,1018,442,978,413,765,620 HS_END_POLY "s:Beaverton TC/Beaverton_Transit_Center/MAX Northbound,9821/MAX Southbound,9818/WES Southbound,13066"  HS_END
    HS_START_POLY 281,47,281,160,707,159,707,48 HS_END_POLY "http://www.trimet.org"  HS_END
    HS_START_POLY 1638,561,1698,507,1722,568,1682,608 HS_END_POLY "w:Steel_Bridge"  HS_END
    HS_START_POLY 1343,185,1309,216,1513,423,1551,386 HS_END_POLY "w:Willamette_River"  HS_END
    HS_START_POLY 982,787,772,785,773,736,982,735 HS_END_POLY "s:Hall%2FNimbus/Hall%2FNimbus/WES,13067"  HS_END
    HS_START_POLY 770,840,770,900,977,900,976,837 HS_END_POLY "s:Tigard TC/Tigard_Transit_Center/S,13068/N,13073"  HS_END
    HS_START_POLY 769,968,770,1020,939,1021,938,971 HS_END_POLY "s:Tualatin/Tualatin_Station/WES,13069"  HS_END
    HS_START_POLY 769,1083,769,1145,1020,1149,1019,1084 HS_END_POLY "s:Wilsonville/Wilsonville_Station/N,13070"  HS_END
    HS_START_POLY 891,677,976,677,964,633,1089,515,1045,475,908,615 HS_END_POLY "s:Sunset TC/Sunset_Transit_Center/E,9969/W,9624"  HS_END
    HS_START_POLY 1161,427,1163,671,1209,669,1209,427 HS_END_POLY "s:Washington Park/Washington_Park_(MAX_station)/E,10120/W,10121"  HS_END
    HS_START_POLY 1207,261,1252,261,1250,620,1210,659 HS_END_POLY "s:Goose Hollow%2FSW Jefferson St/Goose_Hollow%2FSW_Jefferson_St/E,10118/W,10117"  HS_END
    HS_START_POLY 1251,298,1290,299,1290,593,1251,597 HS_END_POLY "s:Kings Hill%2FSW Salmon St/Kings_Hill%2FSouthwest_Salmon/N,9759/S,9820"  HS_END
    HS_START_POLY 1295,400,1330,399,1351,454,1350,591,1299,631 HS_END_POLY "s:JELD-WEN Field/PGE_Park_(MAX_station)/E,9758/W,9757"  HS_END
    HS_START_POLY 22,842,21,877,463,878,461,843 HS_END_POLY "d://100"  HS_END
    HS_START_POLY 2158,542,2381,323,2426,358,2198,582 HS_END_POLY "s:Gateway%2FNE 99th TC/Gateway%2FNortheast_99th_Avenue_Transit_Center/N,8370/S,8347"  HS_END
    HS_START_POLY 2917,67,2916,150,2991,152,2987,68 HS_END_POLY "n"  HS_END
    HS_START_POLY 1399,454,1398,660,1429,689,1433,455 HS_END_POLY "s:Galleria%2FSW 10th/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/W,8384"  HS_END
    HS_START_POLY 1434,438,1463,439,1458,718,1428,693 HS_END_POLY "s:Pioneer Square North/Pioneer_Square_South_and_Pioneer_Square_North/W,8383"  HS_END
    HS_START_POLY 1353,676,1376,652,1480,752,1454,775 HS_END_POLY "s:Pioneer Courthouse%2FSW 6th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/N,7777"  HS_END
    HS_START_POLY 1177,696,1178,735,1390,734,1367,696 HS_END_POLY "s:Library%2FSW 9th Ave/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/E,8333"  HS_END
    HS_START_POLY 1150,735,1150,776,1416,775,1419,760,1414,738 HS_END_POLY "s:Pioneer Square South/Pioneer_Square_South_and_Pioneer_Square_North/E,8334"  HS_END
    HS_START_POLY 1255,782,1443,782,1398,825,1253,819 HS_END_POLY "s:SW 6th & Madison St/Southwest_6th_%26_Madison_Street_(MAX_station)/N,13123"  HS_END
    HS_START_POLY 1165,830,1398,830,1348,876,1164,872 HS_END_POLY "s:PSU%2FSW 6th & Montgomery/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_(MAX_station)/N,7774"  HS_END
    HS_START_POLY 1257,928,1256,970,1327,968,1326,928 HS_END_POLY "w:Portland_State_University"  HS_END
    HS_START_POLY 1462,539,1547,539,1544,574,1532,588,1463,588 HS_END_POLY "s:Union Station%2FNW 6th & Hoyt St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_(MAX_station)/N,7763"  HS_END
    HS_START_POLY 1462,591,1542,591,1541,644,1460,643 HS_END_POLY "s:NW 6th & Davis St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/N,9299"  HS_END
    HS_START_POLY 1466,646,1521,646,1530,698,1520,705,1495,728,1464,702 HS_END_POLY "s:SW 6th & Pine St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/N,7787"  HS_END
    HS_START_POLY 1507,473,1506,520,1602,519,1603,473 HS_END_POLY "w:Union_Station_%28Portland%29"  HS_END
    HS_START_POLY 1553,570,1564,581,1675,683,1689,631,1585,541 HS_END_POLY "s:Union Station%2FNW 5th & Glisan St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_and_Union_Station%2FNorthwest_5th_%26_Glisan_Street/S,7601"  HS_END
    HS_START_POLY 1556,650,1671,722,1680,692,1558,578 HS_END_POLY "s:NW 5th & Couch St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/S,9303"  HS_END
    HS_START_POLY 1471,802,1496,771,1616,892,1592,919 HS_END_POLY "s:Pioneer Place%2FSW 5th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/S,7646"  HS_END
    HS_START_POLY 1537,730,1563,703,1657,716,1661,754,1537,751 HS_END_POLY "s:SW 5th & Oak St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/S,7627"  HS_END
    HS_START_POLY 1530,753,1506,774,1537,806,1676,790,1672,756 HS_END_POLY "s:Mall%2FSW 5th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/W,8382"  HS_END
    HS_START_POLY 1552,808,1593,804,1677,793,1683,827,1594,855 HS_END_POLY "s:Morrison%2FSW 3rd Ave/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/W,8381"  HS_END
    HS_START_POLY 1376,894,1417,853,1421,1000,1379,1001 HS_END_POLY "s:PSU%2FSW 5th & Mill St/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_and_PSU_Urban_Center%2FSouthwest_5th_%26_Mill_Street/S,7618"  HS_END
    HS_START_POLY 1426,843,1468,801,1478,1086,1434,1085 HS_END_POLY "s:City Hall%2FSW 5th & Jefferson St/Southwest_6th_%26_Madison_Street_and_City_Hall%2FSouthwest_5th_%26_Jefferson_Street/S,7608"  HS_END
    HS_START_POLY 1494,824,1538,867,1526,1007,1484,1008 HS_END_POLY "s:Mall%2FSW 4th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/E,8335"  HS_END
    HS_START_POLY 1543,876,1588,921,1582,1093,1535,1094 HS_END_POLY "s:Yamhill District/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/E,8336"  HS_END
    HS_START_POLY 1683,659,1952,659,1951,708,1681,706 HS_END_POLY "s:Old Town%2FChinatown/Old_Town%2FChinatown/N,8339/S,8378"  HS_END
    HS_START_POLY 1680,738,1929,741,1930,783,1679,780 HS_END_POLY "s:Skidmore Fountain/Skidmore_Fountain_(MAX_station)/N,8338/S,8379"  HS_END
    HS_START_POLY 1672,890,1655,843,1818,840,1819,890 HS_END_POLY "s:Oak%2FSW 1st Ave/Oak_Street%2FSouthwest_1st_Avenue/N,8337/S,8380"  HS_END
    HS_START_POLY 1592,12,1814,10,1814,49,1593,59 HS_END_POLY "s:Expo Center/Expo_Center_(MAX_station)/S,11498"  HS_END
    HS_START_POLY 1595,61,1873,48,1873,100,1595,98 HS_END_POLY "s:Delta Park%2FVanport/Delta_Park%2FVanport/S,11499/N,11516"  HS_END
    HS_START_POLY 1598,99,1835,100,1836,147,1598,146 HS_END_POLY "s:Kenton%2FN Denver/Kenton%2FNorth_Denver_Avenue/S,11500/N,11515"  HS_END
    HS_START_POLY 1598,146,1803,146,1804,189,1598,188 HS_END_POLY "s:N Lombard TC/North_Lombard_Transit_Center/S,11501/N,11514"  HS_END
    HS_START_POLY 1599,187,1597,233,1774,235,1770,188 HS_END_POLY "s:Rosa Parks/North_Rosa_Parks_Way/S,11502/N,11513"  HS_END
    HS_START_POLY 1597,233,1816,235,1817,279,1596,280 HS_END_POLY "s:N Killingsworth/North_Killingsworth_Street/S,11503/N,11512"  HS_END
    HS_START_POLY 1598,281,1761,282,1762,311,1597,313 HS_END_POLY "s:N Prescott/North_Prescott_Street/S,11504/N,11511"  HS_END
    HS_START_POLY 1599,313,1798,312,1797,343,1596,346 HS_END_POLY "s:Overlook Park/Overlook_Park/S,11505/N,11510"  HS_END
    HS_START_POLY 1597,346,1699,344,1766,371,1726,416,1595,418 HS_END_POLY "s:Albina%2FMississippi/Albina%2FMississippi/S,11506/N,11509"  HS_END
    HS_START_POLY 1655,492,1681,520,1898,297,1871,266 HS_END_POLY "s:Interstate%2FRose Quarter/Interstate%2FRose_Quarter/S,11507/N,11508"  HS_END
    HS_START_POLY 1698,503,1849,347,1889,381,1722,562 HS_END_POLY "s:Rose Quarter TC/Rose_Quarter_Transit_Center/E,8340/W,8377"  HS_END
    HS_START_POLY 1929,342,1948,362,1826,509,1825,565,1759,564,1781,497 HS_END_POLY "s:Convention Center/Convention_Center_(MAX_station)/E,8341/W,8376"  HS_END
    HS_START_POLY 1828,564,1898,563,1894,503,1939,455,1901,418,1828,507 HS_END_POLY "s:NE 7th Ave/Northeast_7th_Avenue/E,8342/W,8375"  HS_END
    HS_START_POLY 1900,564,1954,563,1956,511,2114,349,2077,316,1898,502 HS_END_POLY "s:Lloyd Center%2FNE 11th Ave/Lloyd_Center%2FNortheast_11th_Avenue/E,8343/W,8374"  HS_END
    HS_START_POLY 1955,564,2014,563,2014,513,2185,334,2155,305,1956,513 HS_END_POLY "s:Hollywood%2FNE 42nd Ave/Hollywood%2FNortheast_42nd_Avenue_Transit_Center/E,8344/W,8373"  HS_END
    HS_START_POLY 2016,563,2084,563,2085,511,2127,452,2097,428,2014,512 HS_END_POLY "s:NE 60th Ave/Northeast_60th_Avenue/E,8345/W,8372"  HS_END
    HS_START_POLY 2083,564,2147,565,2153,515,2201,452,2158,414,2134,446,2085,511 HS_END_POLY "s:NE 82nd Ave/Northeast_82nd_Avenue/E,8346/W,8371"  HS_END
    HS_START_POLY 2080,115,2085,173,2474,160,2476,112 HS_END_POLY "s:Portland Int'l Airport/Portland_International_Airport_(MAX_station)/E,10579"  HS_END
    HS_START_POLY 2122,174,2295,167,2313,213,2164,212 HS_END_POLY "s:Mt Hood Ave/Mount_Hood_Avenue_(MAX_station)/N,10576/S,10577"  HS_END
    HS_START_POLY 2170,212,2358,215,2356,257,2183,257 HS_END_POLY "s:Cascades/Cascades_(MAX_station)/W,10574/E,10575"  HS_END
    HS_START_POLY 2182,257,2491,263,2493,326,2333,325,2183,330 HS_END_POLY "s:Parkrose%2FSumner TC/Parkrose%2FSumner_Transit_Center/N,10572/S,10573"  HS_END
    HS_START_POLY 2196,600,2373,597,2376,647,2196,650 HS_END_POLY "s:SE Main St/Southeast_Main_Street/S,13124/N,13139"  HS_END
    HS_START_POLY 2199,652,2372,647,2374,699,2200,704 HS_END_POLY "s:SE Division St/Southeast_Division_Street/S,13125/N,13138"  HS_END
    HS_START_POLY 2200,705,2398,700,2397,755,2201,753 HS_END_POLY "s:SE Powell Blvd/Southeast_Powell_Boulevard/S,13126/N,13137"  HS_END
    HS_START_POLY 2198,757,2402,754,2404,809,2199,810 HS_END_POLY "s:SE Holgate Blvd/Southeast_Holgate_Boulevard/S,13127/N,13136"  HS_END
    HS_START_POLY 2198,810,2580,809,2578,857,2198,859 HS_END_POLY "s:Lents%2FSE Foster Rd/Lents_Town_Center%2FSoutheast_Foster_Road/S,13128/N,13135"  HS_END
    HS_START_POLY 2198,859,2371,859,2371,910,2198,911 HS_END_POLY "s:SE Flavel St/Southeast_Flavel_Street/S,13129/N,13134"  HS_END
    HS_START_POLY 2199,912,2372,912,2373,949,2200,948 HS_END_POLY "s:SE Fuller Rd/Southeast_Fuller_Road/S,13130/N,13133"  HS_END
    HS_START_POLY 2201,950,2588,951,2588,1002,2202,1001 HS_END_POLY "s:Clackamas Town Center TC/Clackamas_Town_Center_Transit_Center_(MAX_station)/N,13132"  HS_END
    HS_START_POLY 2274,565,2328,566,2327,517,2375,469,2350,442,2274,520 HS_END_POLY "s:E 102nd Ave/East_102nd_Avenue/E,8348/W,8369"  HS_END
    HS_START_POLY 2328,565,2375,566,2379,528,2441,450,2418,425,2331,518 HS_END_POLY "s:E 122nd Ave/East_122nd_Avenue_(MAX_station)/E,8349/W,8368"  HS_END
    HS_START_POLY 2378,566,2416,565,2418,518,2480,461,2452,436,2381,529 HS_END_POLY "s:E 148th Ave/East_148th_Avenue_(MAX_station)/E,8350/W,8367"  HS_END
    HS_START_POLY 2419,565,2457,564,2454,525,2516,465,2497,448,2420,518 HS_END_POLY "s:E 162nd Ave/East_162nd_Avenue_(MAX_station)/E,8351/W,8366"  HS_END
    HS_START_POLY 2458,565,2499,564,2495,524,2559,461,2536,444,2456,527 HS_END_POLY "s:E 172nd/East_172nd_Avenue_(MAX_station)/E,8352/W,8365"  HS_END
    HS_START_POLY 2499,564,2556,564,2553,533,2624,452,2591,434,2498,523 HS_END_POLY "s:E 181st/East_181st_Avenue_(MAX_station)/E,8353/W,8364"  HS_END
    HS_START_POLY 2559,564,2615,564,2616,531,2748,388,2723,362,2554,533 HS_END_POLY "s:Rockwood%2FE 188th Ave TC/Rockwood%2FEast_188th_Avenue_Transit_Center_(MAX_station)/E,8354/W,8363"  HS_END
    HS_START_POLY 2617,563,2659,563,2657,531,2831,348,2811,330,2619,530 HS_END_POLY "s:Ruby Junction%2FE 197th Ave/Ruby_Junction%2FEast_197th_Avenue_(MAX_station)/E,8355/W,8362"  HS_END
    HS_START_POLY 2661,564,2706,563,2711,522,2782,443,2761,424,2659,532 HS_END_POLY "s:Civic Drive/Civic_Drive/E,13450/W,13449"  HS_END
    HS_START_POLY 2766,564,2765,534,2920,372,2890,343,2715,521,2706,565 HS_END_POLY "s:Gresham City Hall/Gresham_City_Hall_(MAX_station)/E,8356/W,8361"  HS_END
    HS_START_POLY 2767,568,2826,567,2833,534,2991,370,2995,306,2767,531 HS_END_POLY "s:Gresham Central TC/Gresham_Central_Transit_Center_(MAX_station)/E,8357/W,8360"  HS_END
    HS_START_POLY 2828,570,2887,571,2886,529,2984,443,2960,407,2837,532 HS_END_POLY "s:Cleveland Ave/Cleveland_Avenue_(MAX_station)/W,8359"  HS_END
    HS_START_POLY 23,878,463,880,462,909,23,911 HS_END_POLY "d://200"  HS_END
    HS_START_POLY 22,910,461,911,461,943,23,943,24,927 HS_END_POLY "d://90"  HS_END
    HS_START_POLY 24,945,478,945,477,977,23,978 HS_END_POLY "d://190"  HS_END
    HS_START_POLY 26,980,445,978,445,1010,26,1011 HS_END_POLY "d://203"  HS_END
    HS_START_POLY 27,1012,708,1012,708,1048,27,1046 HS_END_POLY "m://1"  HS_END
    HS_START_POLY 29,1048,204,1050,203,1079,28,1078 HS_END_POLY "w:Park_and_ride"  HS_END
    HS_START_POLY 30,1079,203,1080,202,1111,30,1112 HS_END_POLY "http://trimet.org/howtoride/bikes/bikeandride.htm"  HS_END
    HS_START_POLY 32,1112,211,1113,210,1149,32,1149 HS_END_POLY "http://trimet.org/transitcenters/index.htm"  HS_END
    HS_START_POLY 21,716,145,711,149,762,21,762 HS_END_POLY "w:Hillsboro,_Oregon"  HS_END
    HS_START_POLY 601,717,742,715,742,764,602,762 HS_END_POLY "w:Beaverton,_Oregon"  HS_END
    HS_START_POLY 598,1084,742,1083,744,1128,598,1126 HS_END_POLY "w:Wilsonville,_Oregon"  HS_END
    HS_START_POLY 1381,1098,1549,1099,1549,1136,1381,1134 HS_END_POLY "w:South_Waterfront"  HS_END
    HS_START_POLY 1890,798,2065,796,2065,852,1890,853 HS_END_POLY "w:Neighborhoods_of_Portland,_Oregon#Southeast"  HS_END
    HS_START_POLY 2155,1009,2313,1007,2317,1054,2155,1050 HS_END_POLY "w:Clackamas,_Oregon"  HS_END
    HS_START_POLY 2717,612,2860,609,2861,658,2715,657 HS_END_POLY "w:Gresham,_Oregon"  HS_END
    HS_START_POLY 1427,146,1567,149,1564,180,1428,176 HS_END_POLY "w:Neighborhoods_of_Portland,_Oregon#North"  HS_END
    HS_START_POLY 1351,377,1467,377,1468,436,1351,435 HS_END_POLY "w:Neighborhoods_of_Portland,_Oregon#Northwest"  HS_END
    HS_START_POLY 292,174,693,172,693,257,291,257 HS_END_POLY "w:Light_Rail"  HS_END
    HS_START_POLY 2874,1144,2987,1144,2988,1166,2874,1166 HS_END_POLY "w:Portal:Current_events%2F2010_September_5"  HS_END
    HS_START_POLY 2432,1146,2865,1144,2866,1167,2433,1167 HS_END_POLY "w:Disclaimer"  HS_END
    HS_START_POLY 1319,908,1339,926,1569,693,1553,679 HS_END_POLY "w:Portland_Transit_Mall"  HS_END
  	
    railmaps[kRailMapMaxWes].lastHotspot = nHotSpots-1;
    
    railmaps[kRailMapPdxStreetcar].firstHotspot = nHotSpots;
    
    
    HS_RECT(1146,1361,1186,1401, "s:SE%20Water%2FOMSI%20(Streetcar)//S,13615" )
    HS_RECT(1237,1229,1277,1269, "s:SE%20Grand%20&%20Mill//N,2171" )
    HS_RECT(1199,1228,1239,1268, "s:SE%20M%20L%20King%20&%20Mill//S,5933" )
    HS_RECT(1236,1119,1276,1159, "s:SE%20Grand%20&%20Hawthorne//N,13616" )
    HS_RECT(1196,1134,1236,1174, "s:SE%20M%20L%20King%20&%20Hawthorne//S,13614" )
    HS_RECT(1241,1004,1281,1044, "s:SE%20Grand%20&%20Taylor//N,11483" )
    HS_RECT(1201,1004,1241,1044, "s:SE%20M%20L%20King%20&%20Taylor//S,13585" )
    HS_RECT(1244,929,1284,969, "s:SE%20Grand%20&%20Belmont//N,11484" )
    HS_RECT(1204,928,1244,968, "s:SE%20M%20L%20King%20&%20Morrison//S,13584" )
    HS_RECT(1247,813,1287,853, "s:SE%20Grand%20&%20Stark//N,13597" )
    HS_RECT(1208,811,1248,851, "s:SE%20M%20L%20King%20&%20Stark//S,13613" )
    HS_RECT(1254,650,1294,690, "s:SE%20Grand%20&%20E%20Burnside//N,2167" )
    HS_RECT(1215,650,1255,690, "s:NE%20M%20L%20King%20&%20E%20Burnside//S,5901" )
    HS_RECT(1220,427,1260,467, "s:NE%20M%20L%20King%20&%20Hoyt//S,5912" )
    HS_RECT(1259,428,1299,468, "s:NE%20Grand%20&%20Hoyt//N,2169" )
    HS_RECT(1277,391,1317,431, "s:NE%20Oregon%20&%20Grand//W,13612" )
    HS_RECT(1259,348,1299,388, "s:NE%20Grand%20&%20Pacific//N,2175" )
    HS_RECT(1328,284,1368,324, "s:NE%207th%20&%20Holladay//S,13611" )
    HS_RECT(1330,185,1370,225, "s:NE%207th%20&%20Halsey//S,13610" )
    HS_RECT(1263,262,1303,302, "s:NE%20Grand%20&%20Multnomah//N,9343" )
    HS_RECT(1268,102,1308,142, "s:NE%20Grand%20&%20Broadway//N,13617" )
    HS_RECT(1282,140,1322,180, "s:NE%20Weidler%20&%20Grand//E,13609" )
    HS_RECT(1170,97,1210,137, "s:NE%20Broadway%20&%202nd%20(Streetcar)//W,13618" )
    HS_RECT(1169,137,1209,177, "s:NE%20Weidler%20&%202nd%20(Streetcar)//E,13608" )
    HS_RECT(998,118,1038,158, "s:N%20Weidler%2FN Broadway%20&%20Ross//E,13607/W,13619" )
    HS_RECT(629,312,669,352, "s:NW%209th%20&%20Lovejoy//E,13606" )
    HS_RECT(564,276,604,316, "s:NW%2011th%20&%20Marshall//S,13620" )
    HS_RECT(44,279,84,319, "s:NW%2023rd%20&%20Marshall//S,8989" )
    HS_RECT(117,311,157,351, "s:NW%20Lovejoy%20&%2022nd//E,3596" )
    HS_RECT(125,243,165,283, "s:NW%20Northrup%20&%2022nd//W,10778" )
    HS_RECT(183,310,223,350, "s:NW%20Lovejoy%20&%2021st//E,3595" )
    HS_RECT(183,244,223,284, "s:NW%20Northrup%20&%2021st//W,10777" )
    HS_RECT(342,245,382,285, "s:NW%20Northrup%20&%2018th//W,10776" )
    HS_RECT(342,308,382,348, "s:NW%20Lovejoy%20&%2018th//E,10751" )
    HS_RECT(473,244,513,284, "s:NW%20Northrup%20&%2014th//W,10775" )
    HS_RECT(506,311,546,351, "s:NW%20Lovejoy%20&%2013th//E,10752" )
    HS_RECT(536,246,576,286, "s:NW%2012th%20&%20Northrup//W,12796" )
    HS_RECT(601,258,641,298, "s:NW%2010th%20&%20Northrup//N,13604" )
    HS_RECT(567,372,607,412, "s:NW%2011th%20&%20Johnson//S,10753" )
    HS_RECT(604,372,644,412, "s:NW%2010th%20&%20Johnson//N,10773" )
    HS_RECT(565,472,605,512, "s:NW%2011th%20&%20Glisan//S,10754" )
    HS_RECT(605,472,645,512, "s:NW%2010th%20&%20Glisan//N,10772" )
    HS_RECT(566,534,606,574, "s:NW%2011th%20&%20Everett//S,10755" )
    HS_RECT(605,534,645,574, "s:NW%2010th%20&%20Everett//N,10771" )
    HS_RECT(566,599,606,639, "s:NW%2011th%20&%20Couch//S,10756" )
    HS_RECT(607,600,647,640, "s:NW%2010th%20&%20Couch//N,10770" )
    HS_RECT(603,676,643,716, "s:SW%2010th%20&%20Stark//N,10769" )
    HS_RECT(540,721,580,761, "s:SW%2011th%20&%20Alder//S,9600" )
    HS_RECT(580,739,620,779, "s:SW%2010th%20&%20Alder//N,10768" )
    HS_RECT(550,796,590,836, "s:Central%20Library/Portland_Central_Library/N,10767" )
    HS_RECT(505,814,545,854, "s:SW%2011th%20&%20Taylor//S,9633" )
    HS_RECT(507,912,555,963, "s:Art%20Museum/Portland_Art_Museum/N,6493" )
    HS_RECT(460,931,500,971, "s:SW%2011th%20&%20Jefferson//S,10759" )
    HS_RECT(432,989,472,1029, "s:SW%2011th%20&%20Clay//S,10760" )
    HS_RECT(470,1007,510,1047, "s:SW%2010th%20&%20Clay//N,10765" )
    HS_RECT(494,1049,534,1089, "s:SW%20Park%20&%20Market//E,11011" )
    HS_RECT(480,1090,520,1130, "s:SW%20Park%20&%20Mill//W,10766" )
    HS_RECT(553,1111,593,1151, "s:PSU%20Urban%20Center//N,10764" )
    HS_RECT(574,1151,614,1191, "s:SW%205th%20&%20Montgomery//S,10763" )
    HS_RECT(593,1100,633,1140, "s:SW%205th%20&%20Market//E,10762" )
    HS_RECT(623,1209,663,1249, "s:SW%203rd%20&%20Harrison//W,12382/E,12375" )
    HS_RECT(689,1235,729,1275, "s:SW%201st%20&%20Harrison//W,12381/E,12376" )
    HS_RECT(902,1731,942,1771, "s:OHSU%20Commons//N,12883" )
    HS_RECT(864,1715,904,1755, "s:SW%20Moody%20&%20Gibbs//S,12760" )
    HS_RECT(814,1362,854,1402, "s:SW%20River%20Pkwy%20&%20Moody//W,12379/E,12378" )
    HS_RECT(730,1283,770,1323, "s:SW%20Harrison%20Street//N,12380/S,12377" )
    HS_RECT(850,1557,890,1597, "s:SW%20Moody%20&%20Meade//N,13602/S,13601" )
    HS_RECT(896,1876,936,1916, "s:SW%20Bond%20&%20Lane//N,12882" )
    HS_RECT(857,1860,897,1900, "s:SW%20Moody%20&%20Gaines//S,12880" )
    HS_RECT(872,1962,912,2002, "s:SW%20Lowell%20&%20Bond//E,12881" )
    HS_RECT(518,358,562,397, "http://www.pnca.edu/" )
    HS_RECT(27,1054,285,1097, "http://www.pnca.edu/" )
    HS_RECT(862,520,904,559, "http://www.portlandchinesegarden.org/" )
    HS_RECT(26,1110,284,1153, "http://www.portlandchinesegarden.org/" )
    HS_RECT(590,574,619,600, "http://www.pcs.org/" )
    HS_RECT(31,1165,289,1208, "http://www.pcs.org/" )
    HS_RECT(649,816,700,865, "http://www.thesquarepdx.org/" )
    HS_RECT(31,1219,289,1262, "http://www.thesquarepdx.org/" )
    HS_RECT(34,1275,292,1318, "http://www.multcolib.org/" )
    HS_RECT(598,861,637,904, "http://www.pcpa.com/schnitzer" )
    HS_RECT(35,1330,293,1373, "http://www.pcpa.com/schnitzer" )
    HS_RECT(587,903,622,935, "http://www.pcpa.com/" )
    HS_RECT(30,1386,368,1427, "http://www.pcpa.com/" )
    HS_RECT(29,1441,287,1484, "http://www.pam.org" )
    HS_RECT(670,969,709,1002, "w:Portland_City_Hall_(Oregon)" )
    HS_RECT(27,1496,163,1535, "w:Portland_City_Hall_(Oregon)" )
    HS_RECT(834,985,888,1030, "http://www.portlandonline.com/parks/finder/index.cfm?PropertyID=156&action=ViewPark" )
    HS_RECT(28,1552,269,1597, "http://www.portlandonline.com/parks/finder/index.cfm?PropertyID=156&action=ViewPark" )
    HS_RECT(682,1112,725,1152, "http://www.pcpa.com/keller" )
    HS_RECT(28,1606,223,1649, "http://www.pcpa.com/keller" )
    HS_RECT(521,1088,552,1120, "http://pdx.edu/profile/visit-lincoln-hall" )
    HS_RECT(28,1661,341,1706, "http://pdx.edu/profile/visit-lincoln-hall" )
    HS_RECT(30,1719,346,1759, "http://www.ohsu.edu/xd/health/ohsu-near-you/portland/south-waterfront/chh.cfm" )
    HS_RECT(1128,1412,1162,1441, "http://www.portlandopera.org/" )
    HS_RECT(31,1771,404,1819, "http://www.portlandopera.org/" )
    HS_RECT(1089,1180,1130,1219, "http://www.pcc.edu/climb/" )
    HS_RECT(30,1827,372,1873, "http://www.pcc.edu/climb/" )
    HS_RECT(1231,885,1263,924, "http://www.visitahc.org/" )
    HS_RECT(33,1884,298,1925, "http://www.visitahc.org/" )
    HS_RECT(1190,1345,1218,1379, "http://www.orhf.org/" )
    HS_RECT(36,1936,294,1979, "http://www.orhf.org/" )
    HS_RECT(559,959,588,998, "http://ohs.org/" )
    HS_RECT(34,1993,292,2036, "http://ohs.org/" )
    HS_RECT(1349,1793,1408,1831, "n" )
    HS_RECT(35,480,125,570, "http://www.portlandonline.com" )
    HS_RECT(1343,1857,1412,1920, "http://www.portlandstreetcar.org" )
    HS_RECT(139,478,223,570, "http://www.portlandstreetcar.org" )
    HS_RECT(231,493,400,562, "http://www.portlandoregon.gov/transportation/32360" )
    HS_RECT(605,645,639,671, "d://194" )
    HS_RECT(1245,214,1318,252, "d://194" )
    HS_RECT(1201,1190,1268,1220, "d://194" )
    HS_RECT(97,599,354,673, "d://194" )
    HS_RECT(90,799,344,841, "http://trimet.org/pm/construction/bridge.htm" )
    HS_RECT(569,644,603,672, "d://193" )
    HS_RECT(393,309,471,352, "d://193" )
    HS_RECT(790,1408,871,1447, "d://193" )
    HS_RECT(97,682,355,755, "d://193" )
    HS_RECT(80,844,350,965, "m://0" )
    HS_RECT(433,1992,696,2032, "http://www.portlandstreetcar.org" )
    
   
    
     
    HS_START_POLY 974,254,1017,224,1003,202,980,176,937,212,955,239 HS_END_POLY "w:Veterans_Memorial_Coliseum_(Portland)" HS_END
    HS_START_POLY 1082,1525,1178,1525,1175,1464,1073,1462,1031,1465,1034,1524 HS_END_POLY "http://trimet.org/pm/construction/bridge.htm" HS_END
    HS_START_POLY 521,1768,553,1739,545,1700,517,1691,475,1706,481,1746 HS_END_POLY "http://gobytram.com/" HS_END
    HS_START_POLY 838,1750,865,1748,857,1709,833,1711,787,1715,793,1755 HS_END_POLY "http://gibbsbridge.org/" HS_END
    HS_START_POLY 1229,490,1217,471,1232,361,1154,357,1155,440,1166,492 HS_END_POLY "http://www.oregoncc.org/" HS_END
    HS_START_POLY 785,423,818,386,810,347,778,327,740,353,746,393 HS_END_POLY "http://www.amtrak.com/servlet/ContentServer?pagename=am/am2Station/Station_Page&code=PDX" HS_END
    HS_START_POLY 1095,1373,1128,1336,1120,1297,1088,1277,1050,1303,1056,1343 HS_END_POLY "http://www.omsi.edu" HS_END
    HS_START_POLY 1451,278,1483,278,1479,217,1478,201,1421,203,1420,279 HS_END_POLY "http://www.lloydcenter.com/" HS_END
    HS_START_POLY 851,296,898,260,882,214,844,197,806,223,808,264 HS_END_POLY "w:Broadway_Bridge_(Portland)" HS_END
    HS_START_POLY 118,259,130,234,129,226,98,231,83,235,86,256 HS_END_POLY "http://www.linfield.edu/portland/" HS_END
    HS_START_POLY 115,322,117,310,136,291,117,270,86,270,84,323 HS_END_POLY "http://www.legacyhealth.org/goodsam" HS_END
    HS_START_POLY 1081,316,1114,279,1106,240,1074,220,1036,246,1042,286 HS_END_POLY "w:Rose_Garden_(arena)" HS_END
    
    railmaps[kRailMapPdxStreetcar].lastHotspot = nHotSpots-1;
    
	assert(nHotSpots < MAXHOTSPOTS);
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
	
	
    if (hs->vertices)
    {
        for(int i = 0; i < hs->nVertices; i++)
        {
            if(i == 0)
            {
                // move to the first point
                CGContextMoveToPoint(context, hs->vertices[i].x, hs->vertices[i].y);
            }
            else
            {
                CGContextAddLineToPoint(context, hs->vertices[i].x, hs->vertices[i].y);
            }
        }
        CGContextAddLineToPoint(context, hs->vertices[0].x, hs->vertices[0].y);
	
        CGContextFillPath(context);
    }
    else if (hs->rect)
    {
        CGContextFillRect(context, *hs->rect);
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
		
			for (int j=_railMap->firstHotspot; j <= _railMap->lastHotspot; j++)
			{
				hs = hotSpotRegions+j;
				
				if (hs->nVertices > 0)
				{
					[self drawHotspot:hs context:context];
				}
			}
		}
		
				
		// CGContextStrokePath(context);
	}
}


@end


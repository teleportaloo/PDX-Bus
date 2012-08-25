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


@implementation RailMapView

@synthesize scrollView = _scrollView;
@synthesize from = _from;
@synthesize picker = _picker;
@synthesize stopIDs = _stopIDs;
@synthesize hotSpots = _hotSpots;
@synthesize locationsDb = _locationsDb;


- (void)dealloc {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.scrollView = nil;
	self.callback = nil;
	self.stopIDs = nil;
	self.hotSpots = nil;
	self.locationsDb = nil;
	self.backgroundTask = nil;
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

-(void)BackgroundCompleted:(UIViewController *)viewController
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
	
	for (i=0; i< nHotSpots;  i++)
	{
		if (hotSpotRegions[i].action[0]==kLinkTypeStop && hotSpotRegions[i].vertices!=nil)
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

#pragma mark ViewControllerBase methods

- (void)createToolbarItems
{
	NSArray *items = nil;
	
	
	items = [NSArray arrayWithObjects: 
				 [self autoDoneButton], 
				 [CustomToolbar autoFlexSpace], 
				 [CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)],
				 [CustomToolbar autoFlexSpace],
				 [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)],
				 nil];
	
	[self setToolbarItems:items animated:NO];
}

#pragma mark View methods

#define min(X,Y) ((X)<(Y)?(X):(Y))
#define max(X,Y) ((X)>(Y)?(X):(Y))
#define swap(T,X,Y) { T temp; temp = (X); X = (Y); Y = (X); }

- (void)loadView {
	[super loadView];
	
	[RailMapView initHotspotData];
	
	// Set the size for the table view
	CGRect bounds;
	bounds.size.width = [[UIScreen mainScreen] applicationFrame].size.width;
	bounds.size.height = [[UIScreen mainScreen] applicationFrame].size.height;
	bounds.origin.x = 0;
	bounds.origin.y = 0;
	
	/// set up main scroll view
    self.scrollView = [[[UIScrollView alloc] initWithFrame:bounds] autorelease];
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setBouncesZoom:YES];
	self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    [[self view] addSubview:self.scrollView];
    
    // add touch-sensitive image view to the scroll view
   TapDetectingImageView *imageView = [[TapDetectingImageView alloc] initWithImage:[UIImage imageNamed:@"railsystem.gif"]];
 //  TapDetectingImageView *imageView = [[TapDetectingImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];

    //	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"railsystem.gif"]];
    [imageView setDelegate:self];
    [imageView setTag:ZOOM_VIEW_TAG];
    [self.scrollView setContentSize:[imageView frame].size];
    [self.scrollView addSubview:imageView];
    
	// Lets try to calculate something that'll work for all orientations and devices.
	CGRect zoom;
	CGRect imageFrame  = [imageView frame];
	CGRect scrollFrame = [self.scrollView frame];
	float minimumScale;
    
	
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    minimumScale = scrollFrame.size.width  / imageFrame.size.width;
            
    CGFloat scale =  (scrollFrame.size.height / imageFrame.size.height) * 1.25   ;
    
    [self.scrollView setMinimumZoomScale:scrollFrame.size.height / imageFrame.size.height];

		
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
        
    zoom.size.width  = [self.scrollView frame].size.width  / scale;
    zoom.size.height = [self.scrollView frame].size.height / scale;
        
    zoom.origin.x = ((imageFrame.size.width   - zoom.size.width)  / 2.0);
    zoom.origin.y = ((imageFrame.size.height  - zoom.size.height) / 2.0);
        
	DEBUG_LOG(@"Zoom: w %f h %f x %f y %f\n",
			  zoom.size.width, zoom.size.height, zoom.origin.x, zoom.origin.y);
	
		
    [self.scrollView setMinimumZoomScale:minimumScale];
	
	self.hotSpots = [[[RailMapHotSpots alloc] initWithImageView:imageView] autorelease];
	
	[imageView release];
    
	[self.scrollView zoomToRect:zoom animated:NO];
	// [self.scrollView scrollRectToVisible:zoom animated:NO];
 	[self createToolbarItems];
	
	self.title = @"Rail Map";
	
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
		[scanner setScanLocation:[scanner scanLocation] + 1];
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
	NSString *stationName;
	NSString *wikiLink;
	
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
					[self createToolbarItems];
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
				[[self navigationController] pushViewController:webPage animated:YES];
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
			[[self navigationController] pushViewController:webPage animated:YES];
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
		
			[[self navigationController] pushViewController:webPage animated:YES];
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

- (void) next:(NSTimer*)theTimer
{
	do
	{
		
		selectedItem = (selectedItem + 1) % nHotSpots;
	} while (hotSpotRegions[selectedItem].action[0] !='s');
	
	hotSpotRegions[selectedItem].touched = YES;
	// selectedItem = i;
	[self.hotSpots setNeedsDisplay];
	[self   processHotSpot:[NSString stringWithUTF8String:hotSpotRegions[selectedItem].action] item:selectedItem];
}

- (void) selectedHotspot:(NSTimer*)theTimer
{
	[self   processHotSpot:[NSString stringWithUTF8String:hotSpotRegions[selectedItem].action] item:selectedItem];	
}

- (void)findHotspot:(NSTimer*)theTimer
{
    int i;
    bool found = false;
    for (i=0; i< nHotSpots; i++)
	{
		if (hotSpotRegions[i].nVertices > 0 && pnpoly(hotSpotRegions[i].nVertices, hotSpotRegions[i].vertices, _tapPoint.x, _tapPoint.y))
		{
			hotSpotRegions[i].touched = YES;
			selectedItem = i;
			[self.hotSpots selectItem:i];
			[self.hotSpots setNeedsDisplay];
			
			NSDate *soon = [[NSDate date] addTimeInterval:0.1];
			NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(selectedHotspot:) userInfo:nil repeats:NO] autorelease];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            found = true;
			break;
		}
        
        if (hotSpotRegions[i].nVertices == 0)
        {
            // bail out as fast as we can - the end of the array is not worth
            // searching as they are all NULL hotspots.
            break;
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

#define HOTSPOT_POLYGON { static CGPoint tmp [] = { 
#define HOTSPOT_ACTION }; hotSpotRegions[nHotSpots].vertices = tmp; hotSpotRegions[nHotSpots].nVertices= sizeof(tmp)/sizeof(tmp[0]);  hotSpotRegions[nHotSpots].action = 
#define HOTSPOT_END ;  nHotSpots++; }


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
    HOTSPOT_POLYGON 1327,924,1370,927,1376,1099,1330,1100 HOTSPOT_ACTION "s:PSU South%2FSW 5th & Jackson/PSU_South_MAX_station/S,7606"  HOTSPOT_END
    HOTSPOT_POLYGON 1160,888,1319,886,1325,928,1161,929 HOTSPOT_ACTION "s:PSU South%2FSW 6th & College/PSU_South_MAX_station/N,10293"  HOTSPOT_END
    HOTSPOT_POLYGON 247,356,2,603,0,669,36,672,36,624,273,380 HOTSPOT_ACTION "s:Hatfield Government Center/Hatfield_Government_Center/S,9848/"  HOTSPOT_END
    HOTSPOT_POLYGON 154,511,268,386,302,419,94,630,91,671,38,673,35,626 HOTSPOT_ACTION "s:Hillsboro Central%2FSE 3rd TC/Hillsboro_Central%2FSoutheast_3rd_Avenue_Transit_Center/E,9846/W,9845"  HOTSPOT_END
    HOTSPOT_POLYGON 99,667,147,666,152,623,346,424,325,399,102,629 HOTSPOT_ACTION "s:Tuality Hospital%2FSE 8th Ave/Tuality_Hospital%2FSoutheast_8th_Avenue/E,9843/W,9844"  HOTSPOT_END
    HOTSPOT_POLYGON 156,664,198,662,203,621,348,469,329,449,157,621 HOTSPOT_ACTION "s:Washington%2FSE 12th Ave/Washington%2FSoutheast_12th_Avenue/E,9841/W,9842"  HOTSPOT_END
    HOTSPOT_POLYGON 211,664,263,663,269,617,514,364,481,334,215,616 HOTSPOT_ACTION "s:Fair Complex%2FHillsboro Airport/Fair_Complex%2FHillsboro_Airport/E,9838/W,9837"  HOTSPOT_END
    HOTSPOT_POLYGON 271,667,316,668,318,618,423,509,402,486,270,620 HOTSPOT_ACTION "s:Hawthorn Farm/Hawthorn_Farm/E,9839/W,9840"  HOTSPOT_END
    HOTSPOT_POLYGON 319,668,321,620,496,439,525,463,376,623,371,666 HOTSPOT_ACTION "s:Orenco%2FNW 231st Ave/Orenco%2FNorthwest_231st_Avenue/E,9835/W,9836"  HOTSPOT_END
    HOTSPOT_POLYGON 372,667,424,667,418,627,588,458,559,437,380,620 HOTSPOT_ACTION "s:Quatama%2FNW 205th Ave/Quatama%2FNorthwest_205th_Avenue/E,9834/W,9833"  HOTSPOT_END
    HOTSPOT_POLYGON 426,670,485,670,483,632,706,407,672,378,424,628 HOTSPOT_ACTION "s:Willow Creek%2FSW 185th Ave TC/Willow_Creek%2FSouthwest_185th_Avenue_Transit_Center/E,9831/W,9832"  HOTSPOT_END
    HOTSPOT_POLYGON 499,667,545,668,550,616,717,452,691,430,495,624 HOTSPOT_ACTION "s:Elmonica%2FSW 170th Ave/Elmonica%2FSouthwest_170th_Avenue/E,9830/W,9829"  HOTSPOT_END
    HOTSPOT_POLYGON 548,667,605,666,610,623,713,505,693,485,552,617 HOTSPOT_ACTION "s:Merlo Rd%2FSW 158th Ave/Merlo_Road%2FSouthwest_158th_Avenue/E,9828/W,9827"  HOTSPOT_END
    HOTSPOT_POLYGON 607,667,653,668,655,621,801,471,771,451,617,618 HOTSPOT_ACTION "s:Beaverton Creek/Beaverton_Creek/S,9822/N,9819"  HOTSPOT_END
    HOTSPOT_POLYGON 656,670,710,669,717,620,814,514,789,490,661,620 HOTSPOT_ACTION "s:Millikan Way/Millikan_Way/E,9826/W,9825"  HOTSPOT_END
    HOTSPOT_POLYGON 713,670,758,669,759,622,899,482,873,458,722,618 HOTSPOT_ACTION "s:Beaverton Central/Beaverton_Central/E,9824/W,9823"  HOTSPOT_END
    HOTSPOT_POLYGON 765,677,824,679,820,639,1018,442,978,413,765,620 HOTSPOT_ACTION "s:Beaverton TC/Beaverton_Transit_Center/MAX Northbound,9821/MAX Southbound,9818/WES Southbound,13066"  HOTSPOT_END
    HOTSPOT_POLYGON 281,47,281,160,707,159,707,48 HOTSPOT_ACTION "http://www.trimet.org"  HOTSPOT_END
    HOTSPOT_POLYGON 1638,561,1698,507,1722,568,1682,608 HOTSPOT_ACTION "w:Steel_Bridge"  HOTSPOT_END
    HOTSPOT_POLYGON 1343,185,1309,216,1513,423,1551,386 HOTSPOT_ACTION "w:Willamette_River"  HOTSPOT_END
    HOTSPOT_POLYGON 982,787,772,785,773,736,982,735 HOTSPOT_ACTION "s:Hall%2FNimbus/Hall%2FNimbus/WES,13067"  HOTSPOT_END
    HOTSPOT_POLYGON 770,840,770,900,977,900,976,837 HOTSPOT_ACTION "s:Tigard TC/Tigard_Transit_Center/S,13068/N,13073"  HOTSPOT_END
    HOTSPOT_POLYGON 769,968,770,1020,939,1021,938,971 HOTSPOT_ACTION "s:Tualatin/Tualatin_Station/WES,13069"  HOTSPOT_END
    HOTSPOT_POLYGON 769,1083,769,1145,1020,1149,1019,1084 HOTSPOT_ACTION "s:Wilsonville/Wilsonville_Station/N,13070"  HOTSPOT_END
    HOTSPOT_POLYGON 891,677,976,677,964,633,1089,515,1045,475,908,615 HOTSPOT_ACTION "s:Sunset TC/Sunset_Transit_Center/E,9969/W,9624"  HOTSPOT_END
    HOTSPOT_POLYGON 1161,427,1163,671,1209,669,1209,427 HOTSPOT_ACTION "s:Washington Park/Washington_Park_(MAX_station)/E,10120/W,10121"  HOTSPOT_END
    HOTSPOT_POLYGON 1207,261,1252,261,1250,620,1210,659 HOTSPOT_ACTION "s:Goose Hollow%2FSW Jefferson St/Goose_Hollow%2FSW_Jefferson_St/E,10118/W,10117"  HOTSPOT_END
    HOTSPOT_POLYGON 1251,298,1290,299,1290,593,1251,597 HOTSPOT_ACTION "s:Kings Hill%2FSW Salmon St/Kings_Hill%2FSouthwest_Salmon/N,9759/S,9820"  HOTSPOT_END
    HOTSPOT_POLYGON 1295,400,1330,399,1351,454,1350,591,1299,631 HOTSPOT_ACTION "s:JELD-WEN Field/PGE_Park_(MAX_station)/E,9758/W,9757"  HOTSPOT_END
    HOTSPOT_POLYGON 22,842,21,877,463,878,461,843 HOTSPOT_ACTION "d://100"  HOTSPOT_END
    HOTSPOT_POLYGON 2158,542,2381,323,2426,358,2198,582 HOTSPOT_ACTION "s:Gateway%2FNE 99th TC/Gateway%2FNortheast_99th_Avenue_Transit_Center/N,8370/S,8347"  HOTSPOT_END
    HOTSPOT_POLYGON 2917,67,2916,150,2991,152,2987,68 HOTSPOT_ACTION "n"  HOTSPOT_END
    HOTSPOT_POLYGON 1399,454,1398,660,1429,689,1433,455 HOTSPOT_ACTION "s:Galleria%2FSW 10th/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/W,8384"  HOTSPOT_END
    HOTSPOT_POLYGON 1434,438,1463,439,1458,718,1428,693 HOTSPOT_ACTION "s:Pioneer Square North/Pioneer_Square_South_and_Pioneer_Square_North/W,8383"  HOTSPOT_END
    HOTSPOT_POLYGON 1353,676,1376,652,1480,752,1454,775 HOTSPOT_ACTION "s:Pioneer Courthouse%2FSW 6th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/N,7777"  HOTSPOT_END
    HOTSPOT_POLYGON 1177,696,1178,735,1390,734,1367,696 HOTSPOT_ACTION "s:Library%2FSW 9th Ave/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/E,8333"  HOTSPOT_END
    HOTSPOT_POLYGON 1150,735,1150,776,1416,775,1419,760,1414,738 HOTSPOT_ACTION "s:Pioneer Square South/Pioneer_Square_South_and_Pioneer_Square_North/E,8334"  HOTSPOT_END
    HOTSPOT_POLYGON 1255,782,1443,782,1398,825,1253,819 HOTSPOT_ACTION "s:SW 6th & Madison St/Southwest_6th_%26_Madison_Street_(MAX_station)/N,13123"  HOTSPOT_END
    HOTSPOT_POLYGON 1165,830,1398,830,1348,876,1164,872 HOTSPOT_ACTION "s:PSU%2FSW 6th & Montgomery/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_(MAX_station)/N,7774"  HOTSPOT_END
    HOTSPOT_POLYGON 1257,928,1256,970,1327,968,1326,928 HOTSPOT_ACTION "w:Portland_State_University"  HOTSPOT_END
    HOTSPOT_POLYGON 1462,539,1547,539,1544,574,1532,588,1463,588 HOTSPOT_ACTION "s:Union Station%2FNW 6th & Hoyt St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_(MAX_station)/N,7763"  HOTSPOT_END
    HOTSPOT_POLYGON 1462,591,1542,591,1541,644,1460,643 HOTSPOT_ACTION "s:NW 6th & Davis St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/N,9299"  HOTSPOT_END
    HOTSPOT_POLYGON 1466,646,1521,646,1530,698,1520,705,1495,728,1464,702 HOTSPOT_ACTION "s:SW 6th & Pine St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/N,7787"  HOTSPOT_END
    HOTSPOT_POLYGON 1507,473,1506,520,1602,519,1603,473 HOTSPOT_ACTION "w:Union_Station_%28Portland%29"  HOTSPOT_END
    HOTSPOT_POLYGON 1553,570,1564,581,1675,683,1689,631,1585,541 HOTSPOT_ACTION "s:Union Station%2FNW 5th & Glisan St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_and_Union_Station%2FNorthwest_5th_%26_Glisan_Street/S,7601"  HOTSPOT_END
    HOTSPOT_POLYGON 1556,650,1671,722,1680,692,1558,578 HOTSPOT_ACTION "s:NW 5th & Couch St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/S,9303"  HOTSPOT_END
    HOTSPOT_POLYGON 1471,802,1496,771,1616,892,1592,919 HOTSPOT_ACTION "s:Pioneer Place%2FSW 5th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/S,7646"  HOTSPOT_END
    HOTSPOT_POLYGON 1537,730,1563,703,1657,716,1661,754,1537,751 HOTSPOT_ACTION "s:SW 5th & Oak St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/S,7627"  HOTSPOT_END
    HOTSPOT_POLYGON 1530,753,1506,774,1537,806,1676,790,1672,756 HOTSPOT_ACTION "s:Mall%2FSW 5th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/W,8382"  HOTSPOT_END
    HOTSPOT_POLYGON 1552,808,1593,804,1677,793,1683,827,1594,855 HOTSPOT_ACTION "s:Morrison%2FSW 3rd Ave/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/W,8381"  HOTSPOT_END
    HOTSPOT_POLYGON 1376,894,1417,853,1421,1000,1379,1001 HOTSPOT_ACTION "s:PSU%2FSW 5th & Mill St/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_and_PSU_Urban_Center%2FSouthwest_5th_%26_Mill_Street/S,7618"  HOTSPOT_END
    HOTSPOT_POLYGON 1426,843,1468,801,1478,1086,1434,1085 HOTSPOT_ACTION "s:City Hall%2FSW 5th & Jefferson St/Southwest_6th_%26_Madison_Street_and_City_Hall%2FSouthwest_5th_%26_Jefferson_Street/S,7608"  HOTSPOT_END
    HOTSPOT_POLYGON 1494,824,1538,867,1526,1007,1484,1008 HOTSPOT_ACTION "s:Mall%2FSW 4th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/E,8335"  HOTSPOT_END
    HOTSPOT_POLYGON 1543,876,1588,921,1582,1093,1535,1094 HOTSPOT_ACTION "s:Yamhill District/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/E,8336"  HOTSPOT_END
    HOTSPOT_POLYGON 1683,659,1952,659,1951,708,1681,706 HOTSPOT_ACTION "s:Old Town%2FChinatown/Old_Town%2FChinatown/N,8339/S,8378"  HOTSPOT_END
    HOTSPOT_POLYGON 1680,738,1929,741,1930,783,1679,780 HOTSPOT_ACTION "s:Skidmore Fountain/Skidmore_Fountain_(MAX_station)/N,8338/S,8379"  HOTSPOT_END
    HOTSPOT_POLYGON 1672,890,1655,843,1818,840,1819,890 HOTSPOT_ACTION "s:Oak%2FSW 1st Ave/Oak_Street%2FSouthwest_1st_Avenue/N,8337/S,8380"  HOTSPOT_END
    HOTSPOT_POLYGON 1592,12,1814,10,1814,49,1593,59 HOTSPOT_ACTION "s:Expo Center/Expo_Center_(MAX_station)/S,11498"  HOTSPOT_END
    HOTSPOT_POLYGON 1595,61,1873,48,1873,100,1595,98 HOTSPOT_ACTION "s:Delta Park%2FVanport/Delta_Park%2FVanport/S,11499/N,11516"  HOTSPOT_END
    HOTSPOT_POLYGON 1598,99,1835,100,1836,147,1598,146 HOTSPOT_ACTION "s:Kenton%2FN Denver/Kenton%2FNorth_Denver_Avenue/S,11500/N,11515"  HOTSPOT_END
    HOTSPOT_POLYGON 1598,146,1803,146,1804,189,1598,188 HOTSPOT_ACTION "s:N Lombard TC/North_Lombard_Transit_Center/S,11501/N,11514"  HOTSPOT_END
    HOTSPOT_POLYGON 1599,187,1597,233,1774,235,1770,188 HOTSPOT_ACTION "s:Rosa Parks/North_Rosa_Parks_Way/S,11502/N,11513"  HOTSPOT_END
    HOTSPOT_POLYGON 1597,233,1816,235,1817,279,1596,280 HOTSPOT_ACTION "s:N Killingsworth/North_Killingsworth_Street/S,11503/N,11512"  HOTSPOT_END
    HOTSPOT_POLYGON 1598,281,1761,282,1762,311,1597,313 HOTSPOT_ACTION "s:N Prescott/North_Prescott_Street/S,11504/N,11511"  HOTSPOT_END
    HOTSPOT_POLYGON 1599,313,1798,312,1797,343,1596,346 HOTSPOT_ACTION "s:Overlook Park/Overlook_Park/S,11505/N,11510"  HOTSPOT_END
    HOTSPOT_POLYGON 1597,346,1699,344,1766,371,1726,416,1595,418 HOTSPOT_ACTION "s:Albina%2FMississippi/Albina%2FMississippi/S,11506/N,11509"  HOTSPOT_END
    HOTSPOT_POLYGON 1655,492,1681,520,1898,297,1871,266 HOTSPOT_ACTION "s:Interstate%2FRose Quarter/Interstate%2FRose_Quarter/S,11507/N,11508"  HOTSPOT_END
    HOTSPOT_POLYGON 1698,503,1849,347,1889,381,1722,562 HOTSPOT_ACTION "s:Rose Quarter TC/Rose_Quarter_Transit_Center/E,8340/W,8377"  HOTSPOT_END
    HOTSPOT_POLYGON 1929,342,1948,362,1826,509,1825,565,1759,564,1781,497 HOTSPOT_ACTION "s:Convention Center/Convention_Center_(MAX_station)/E,8341/W,8376"  HOTSPOT_END
    HOTSPOT_POLYGON 1828,564,1898,563,1894,503,1939,455,1901,418,1828,507 HOTSPOT_ACTION "s:NE 7th Ave/Northeast_7th_Avenue/E,8342/W,8375"  HOTSPOT_END
    HOTSPOT_POLYGON 1900,564,1954,563,1956,511,2114,349,2077,316,1898,502 HOTSPOT_ACTION "s:Lloyd Center%2FNE 11th Ave/Lloyd_Center%2FNortheast_11th_Avenue/E,8343/W,8374"  HOTSPOT_END
    HOTSPOT_POLYGON 1955,564,2014,563,2014,513,2185,334,2155,305,1956,513 HOTSPOT_ACTION "s:Hollywood%2FNE 42nd Ave/Hollywood%2FNortheast_42nd_Avenue_Transit_Center/E,8344/W,8373"  HOTSPOT_END
    HOTSPOT_POLYGON 2016,563,2084,563,2085,511,2127,452,2097,428,2014,512 HOTSPOT_ACTION "s:NE 60th Ave/Northeast_60th_Avenue/E,8345/W,8372"  HOTSPOT_END
    HOTSPOT_POLYGON 2083,564,2147,565,2153,515,2201,452,2158,414,2134,446,2085,511 HOTSPOT_ACTION "s:NE 82nd Ave/Northeast_82nd_Avenue/E,8346/W,8371"  HOTSPOT_END
    HOTSPOT_POLYGON 2080,115,2085,173,2474,160,2476,112 HOTSPOT_ACTION "s:Portland Int'l Airport/Portland_International_Airport_(MAX_station)/E,10579"  HOTSPOT_END
    HOTSPOT_POLYGON 2122,174,2295,167,2313,213,2164,212 HOTSPOT_ACTION "s:Mt Hood Ave/Mount_Hood_Avenue_(MAX_station)/N,10576/S,10577"  HOTSPOT_END
    HOTSPOT_POLYGON 2170,212,2358,215,2356,257,2183,257 HOTSPOT_ACTION "s:Cascades/Cascades_(MAX_station)/W,10574/E,10575"  HOTSPOT_END
    HOTSPOT_POLYGON 2182,257,2491,263,2493,326,2333,325,2183,330 HOTSPOT_ACTION "s:Parkrose%2FSumner TC/Parkrose%2FSumner_Transit_Center/N,10572/S,10573"  HOTSPOT_END
    HOTSPOT_POLYGON 2196,600,2373,597,2376,647,2196,650 HOTSPOT_ACTION "s:SE Main St/Southeast_Main_Street/S,13124/N,13139"  HOTSPOT_END
    HOTSPOT_POLYGON 2199,652,2372,647,2374,699,2200,704 HOTSPOT_ACTION "s:SE Division St/Southeast_Division_Street/S,13125/N,13138"  HOTSPOT_END
    HOTSPOT_POLYGON 2200,705,2398,700,2397,755,2201,753 HOTSPOT_ACTION "s:SE Powell Blvd/Southeast_Powell_Boulevard/S,13126/N,13137"  HOTSPOT_END
    HOTSPOT_POLYGON 2198,757,2402,754,2404,809,2199,810 HOTSPOT_ACTION "s:SE Holgate Blvd/Southeast_Holgate_Boulevard/S,13127/N,13136"  HOTSPOT_END
    HOTSPOT_POLYGON 2198,810,2580,809,2578,857,2198,859 HOTSPOT_ACTION "s:Lents%2FSE Foster Rd/Lents_Town_Center%2FSoutheast_Foster_Road/S,13128/N,13135"  HOTSPOT_END
    HOTSPOT_POLYGON 2198,859,2371,859,2371,910,2198,911 HOTSPOT_ACTION "s:SE Flavel St/Southeast_Flavel_Street/S,13129/N,13134"  HOTSPOT_END
    HOTSPOT_POLYGON 2199,912,2372,912,2373,949,2200,948 HOTSPOT_ACTION "s:SE Fuller Rd/Southeast_Fuller_Road/S,13130/N,13133"  HOTSPOT_END
    HOTSPOT_POLYGON 2201,950,2588,951,2588,1002,2202,1001 HOTSPOT_ACTION "s:Clackamas Town Center TC/Clackamas_Town_Center_Transit_Center_(MAX_station)/N,13132"  HOTSPOT_END
    HOTSPOT_POLYGON 2274,565,2328,566,2327,517,2375,469,2350,442,2274,520 HOTSPOT_ACTION "s:E 102nd Ave/East_102nd_Avenue/E,8348/W,8369"  HOTSPOT_END
    HOTSPOT_POLYGON 2328,565,2375,566,2379,528,2441,450,2418,425,2331,518 HOTSPOT_ACTION "s:E 122nd Ave/East_122nd_Avenue_(MAX_station)/E,8349/W,8368"  HOTSPOT_END
    HOTSPOT_POLYGON 2378,566,2416,565,2418,518,2480,461,2452,436,2381,529 HOTSPOT_ACTION "s:E 148th Ave/East_148th_Avenue_(MAX_station)/E,8350/W,8367"  HOTSPOT_END
    HOTSPOT_POLYGON 2419,565,2457,564,2454,525,2516,465,2497,448,2420,518 HOTSPOT_ACTION "s:E 162nd Ave/East_162nd_Avenue_(MAX_station)/E,8351/W,8366"  HOTSPOT_END
    HOTSPOT_POLYGON 2458,565,2499,564,2495,524,2559,461,2536,444,2456,527 HOTSPOT_ACTION "s:E 172nd/East_172nd_Avenue_(MAX_station)/E,8352/W,8365"  HOTSPOT_END
    HOTSPOT_POLYGON 2499,564,2556,564,2553,533,2624,452,2591,434,2498,523 HOTSPOT_ACTION "s:E 181st/East_181st_Avenue_(MAX_station)/E,8353/W,8364"  HOTSPOT_END
    HOTSPOT_POLYGON 2559,564,2615,564,2616,531,2748,388,2723,362,2554,533 HOTSPOT_ACTION "s:Rockwood%2FE 188th Ave TC/Rockwood%2FEast_188th_Avenue_Transit_Center_(MAX_station)/E,8354/W,8363"  HOTSPOT_END
    HOTSPOT_POLYGON 2617,563,2659,563,2657,531,2831,348,2811,330,2619,530 HOTSPOT_ACTION "s:Ruby Junction%2FE 197th Ave/Ruby_Junction%2FEast_197th_Avenue_(MAX_station)/E,8355/W,8362"  HOTSPOT_END
    HOTSPOT_POLYGON 2661,564,2706,563,2711,522,2782,443,2761,424,2659,532 HOTSPOT_ACTION "s:Civic Drive/Civic_Drive/E,13450/W,13449"  HOTSPOT_END
    HOTSPOT_POLYGON 2766,564,2765,534,2920,372,2890,343,2715,521,2706,565 HOTSPOT_ACTION "s:Gresham City Hall/Gresham_City_Hall_(MAX_station)/E,8356/W,8361"  HOTSPOT_END
    HOTSPOT_POLYGON 2767,568,2826,567,2833,534,2991,370,2995,306,2767,531 HOTSPOT_ACTION "s:Gresham Central TC/Gresham_Central_Transit_Center_(MAX_station)/E,8357/W,8360"  HOTSPOT_END
    HOTSPOT_POLYGON 2828,570,2887,571,2886,529,2984,443,2960,407,2837,532 HOTSPOT_ACTION "s:Cleveland Ave/Cleveland_Avenue_(MAX_station)/W,8359"  HOTSPOT_END
    HOTSPOT_POLYGON 23,878,463,880,462,909,23,911 HOTSPOT_ACTION "d://200"  HOTSPOT_END
    HOTSPOT_POLYGON 22,910,461,911,461,943,23,943,24,927 HOTSPOT_ACTION "d://90"  HOTSPOT_END
    HOTSPOT_POLYGON 24,945,478,945,477,977,23,978 HOTSPOT_ACTION "d://190"  HOTSPOT_END
    HOTSPOT_POLYGON 26,980,445,978,445,1010,26,1011 HOTSPOT_ACTION "d://203"  HOTSPOT_END
    HOTSPOT_POLYGON 27,1012,708,1012,708,1048,27,1046 HOTSPOT_ACTION "d://193"  HOTSPOT_END
    HOTSPOT_POLYGON 29,1048,204,1050,203,1079,28,1078 HOTSPOT_ACTION "w:Park_and_ride"  HOTSPOT_END
    HOTSPOT_POLYGON 30,1079,203,1080,202,1111,30,1112 HOTSPOT_ACTION "http://trimet.org/howtoride/bikes/bikeandride.htm"  HOTSPOT_END
    HOTSPOT_POLYGON 32,1112,211,1113,210,1149,32,1149 HOTSPOT_ACTION "http://trimet.org/transitcenters/index.htm"  HOTSPOT_END
    HOTSPOT_POLYGON 21,716,145,711,149,762,21,762 HOTSPOT_ACTION "w:Hillsboro,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 601,717,742,715,742,764,602,762 HOTSPOT_ACTION "w:Beaverton,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 598,1084,742,1083,744,1128,598,1126 HOTSPOT_ACTION "w:Wilsonville,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 1381,1098,1549,1099,1549,1136,1381,1134 HOTSPOT_ACTION "w:South_Waterfront"  HOTSPOT_END
    HOTSPOT_POLYGON 1890,798,2065,796,2065,852,1890,853 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#Southeast"  HOTSPOT_END
    HOTSPOT_POLYGON 2155,1009,2313,1007,2317,1054,2155,1050 HOTSPOT_ACTION "w:Clackamas,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 2717,612,2860,609,2861,658,2715,657 HOTSPOT_ACTION "w:Gresham,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 1427,146,1567,149,1564,180,1428,176 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#North"  HOTSPOT_END
    HOTSPOT_POLYGON 1351,377,1467,377,1468,436,1351,435 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#Northwest"  HOTSPOT_END
    HOTSPOT_POLYGON 292,174,693,172,693,257,291,257 HOTSPOT_ACTION "w:Light_Rail"  HOTSPOT_END
    HOTSPOT_POLYGON 2874,1144,2987,1144,2988,1166,2874,1166 HOTSPOT_ACTION "w:Portal:Current_events%2F2010_September_5"  HOTSPOT_END
    HOTSPOT_POLYGON 2432,1146,2865,1144,2866,1167,2433,1167 HOTSPOT_ACTION "w:Disclaimer"  HOTSPOT_END
    HOTSPOT_POLYGON 1319,908,1339,926,1569,693,1553,679 HOTSPOT_ACTION "w:Portland_Transit_Mall"  HOTSPOT_END
  	
    // Autogenerated code from building with CREATE_MAX_ARRAYS.  These are really just
    // dummy entries so that the same array can be used.
    
    NULL_HOTSPOT("s:SW%20Lowell%20&%20Bond//E,12881");
	NULL_HOTSPOT("s:SW%20Bond%20&%20Lane//N,12882");
	NULL_HOTSPOT("s:OHSU%20Commons//N,12883");
	NULL_HOTSPOT("s:SW%20Moody%20&%20Gibbs//N,12896/S,12760");
	NULL_HOTSPOT("s:SW%20River%20Pkwy%20&%20Moody//W,12379/E,12378");
	NULL_HOTSPOT("s:SW%20Harrison%20Street//N,12380/S,12377");
	NULL_HOTSPOT("s:SW%201st%20&%20Harrison//W,12381/E,12376");
	NULL_HOTSPOT("s:SW%203rd%20&%20Harrison//W,12382/E,12375");
	NULL_HOTSPOT("s:PSU%20Urban%20Center//N,10764");
	NULL_HOTSPOT("s:SW%20Park%20&%20Mill//W,10766");
	NULL_HOTSPOT("s:SW%2010th%20&%20Clay//N,10765");
	NULL_HOTSPOT("s:Art%20Museum//N,6493");
	NULL_HOTSPOT("s:Central%20Library//N,10767");
	NULL_HOTSPOT("s:SW%2010th%20&%20Alder//N,10768");
	NULL_HOTSPOT("s:SW%2010th%20&%20Stark//N,10769");
	NULL_HOTSPOT("s:NW%2010th%20&%20Couch//N,10770");
	NULL_HOTSPOT("s:NW%2010th%20&%20Everett//N,10771");
	NULL_HOTSPOT("s:NW%2010th%20&%20Glisan//N,10772");
	NULL_HOTSPOT("s:NW%2010th%20&%20Johnson//N,10773");
	NULL_HOTSPOT("s:NW%2010th%20&%20Marshall//N,10774");
	NULL_HOTSPOT("s:NW%2012th%20&%20Northrup//W,12796");
	NULL_HOTSPOT("s:NW%20Northrup%20&%2014th//W,10775");
	NULL_HOTSPOT("s:NW%20Northrup%20&%2018th//W,10776");
	NULL_HOTSPOT("s:NW%20Northrup%20&%2021st//W,10777");
	NULL_HOTSPOT("s:NW%20Northrup%20&%2022nd//W,10778");
	NULL_HOTSPOT("s:NW%2023rd%20&%20Marshall//S,8989");
	NULL_HOTSPOT("s:NW%20Lovejoy%20&%2022nd//E,3596");
	NULL_HOTSPOT("s:NW%20Lovejoy%20&%2021st//E,3595");
	NULL_HOTSPOT("s:NW%20Lovejoy%20&%2018th//E,10751");
	NULL_HOTSPOT("s:NW%20Lovejoy%20&%2013th//E,10752");
	NULL_HOTSPOT("s:NW%2011th%20&%20Johnson//S,10753");
	NULL_HOTSPOT("s:NW%2011th%20&%20Glisan//S,10754");
	NULL_HOTSPOT("s:NW%2011th%20&%20Everett//S,10755");
	NULL_HOTSPOT("s:NW%2011th%20&%20Couch//S,10756");
	NULL_HOTSPOT("s:SW%2011th%20&%20Alder//S,13302");
	NULL_HOTSPOT("s:SW%2011th%20&%20Taylor//S,9633");
	NULL_HOTSPOT("s:SW%2011th%20&%20Jefferson//S,10759");
	NULL_HOTSPOT("s:SW%2011th%20&%20Clay//S,10760");
	NULL_HOTSPOT("s:SW%20Park%20&%20Market//E,11011");
	NULL_HOTSPOT("s:SW%205th%20&%20Market//E,10762");
	NULL_HOTSPOT("s:SW%205th%20&%20Montgomery//S,10763");
	NULL_HOTSPOT("s:SW%20Moody%20&%20Gaines//S,12880");
	
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

-(id) initWithImageView:(UIImageView*)mapView
{
	self = [super initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
	[self setBackgroundColor:[UIColor clearColor]];
	
	[self setMapView:mapView];
	
	[self.mapView addSubview:self];
	self.hidden = YES;
	
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
	
	
	for(int i = 0; i < hs->nVertices; i++)
	{
		
		
		// CGPoint point = [_mapView convertCoordinate:coord toPointToView:self];
		
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
		
			for (int j=0; j < nHotSpots; j++)
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


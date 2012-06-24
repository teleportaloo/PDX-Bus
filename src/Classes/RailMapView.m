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
	// UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"railsystem.gif"]];
    [imageView setDelegate:self];
    [imageView setTag:ZOOM_VIEW_TAG];
    [self.scrollView setContentSize:[imageView frame].size];
    [self.scrollView addSubview:imageView];
    
	// Lets try to calculate something that'll work for all orientations and devices.
	CGRect zoom;
	CGRect imageFrame  = [imageView frame];
	CGRect scrollFrame = [self.scrollView frame];
	float minimumScale;
    
	
	if (SMALL_SCREEN(self.screenWidth))
	{
		// calculate minimum scale to perfectly fit image width, and begin at that scale
		minimumScale = scrollFrame.size.width  / imageFrame.size.width;
		[self.scrollView setMaximumZoomScale:1.5];
		
		
		zoom.origin.x = ((imageFrame.size.width - scrollFrame.size.width) / 2.0);
		zoom.origin.y = ((imageFrame.size.height - scrollFrame.size.height) / 2.0);
		//zoom.size.width = [self.scrollView frame].size.width;
		//zoom.size.height = [self.scrollView frame].size.height;
		
		// This is a hack.  I don't know why this position does not work
		// in the iOS4, it seems to be half the position?
		if ([[UIDevice currentDevice].systemVersion doubleValue] >=4.0)
		{
			zoom.origin.x = 420;
			zoom.origin.y = 152;
		}
		zoom.size.width = [self.scrollView frame].size.width;
		zoom.size.height = [self.scrollView frame].size.height;
	}
	else {
		CGFloat scale = 1.0;
		// UIInterfaceOrientation orientation = self.interfaceOrientation;
		
		switch (self.interfaceOrientation)
		{
			case UIInterfaceOrientationPortraitUpsideDown:	
			case UIInterfaceOrientationPortrait:
				scale = 3.2;
				break;
			case	UIInterfaceOrientationLandscapeLeft:
			case	UIInterfaceOrientationLandscapeRight:
				scale  = 2.305;
				swap(CGFloat, scrollFrame.size.width, scrollFrame.size.height);
				swap(CGFloat, scrollFrame.origin.x, scrollFrame.origin.y);
				break;
		}
		
		// calculate minimum scale to perfectly fit image width, and begin at that scale
		minimumScale = min (
								  scrollFrame.size.width  / imageFrame.size.width,
								  scrollFrame.size.height  / imageFrame.size.height);
		
		// CGFloat scale = 3.2;//1 / minimumScale; //    1.0; // 3.2;
		
		CGPoint center = CGPointMake(
									 CGRectGetMidX(imageFrame),
									 CGRectGetMidY(imageFrame));					 
		
		zoom.size.height = imageFrame.size.height / scale;
		zoom.size.width  = imageFrame.size.width  / scale;
		
		zoom.origin.x = center.x - (zoom.size.width  / 2.0);
		zoom.origin.y = center.y - (zoom.size.height / 2.0); 
		
		DEBUG_LOG(@"Zoom: w %f h %f x %f y %f\n",
				  zoom.size.width, zoom.size.height, zoom.origin.x, zoom.origin.y);
		
		[self.scrollView setMaximumZoomScale:4];
	}
	
	
	DEBUG_LOG(@"Zoom: w %f h %f x %f y %f\n",
			  zoom.size.width, zoom.size.height, zoom.origin.x, zoom.origin.y);
	
		
    [self.scrollView setMinimumZoomScale:minimumScale];
	
	
	self.hotSpots = [[[RailMapHotSpots alloc] initWithImageView:imageView] autorelease];
	
	[imageView release];
	
	[self.scrollView zoomToRect:zoom animated:NO];
	[self.scrollView scrollRectToVisible:zoom animated:NO];
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

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
	int i;
	
	for (i=0; i< nHotSpots; i++)
	{
		if (hotSpotRegions[i].nVertices > 0 && pnpoly(hotSpotRegions[i].nVertices, hotSpotRegions[i].vertices, tapPoint.x, tapPoint.y))
		{
			hotSpotRegions[i].touched = YES;
			selectedItem = i;
			[self.hotSpots selectItem:i];
			[self.hotSpots setNeedsDisplay];
			
			NSDate *soon = [[NSDate date] addTimeInterval:0.1];
			NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(selectedHotspot:) userInfo:nil repeats:NO] autorelease];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
			
			
			break;
		}
	}
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
	
	HOTSPOT_POLYGON 164,218,3,389,2,435,31,434,32,392,183,237 HOTSPOT_ACTION "s:Hatfield Government Center/Hatfield_Government_Center/S,9848/"  HOTSPOT_END
    HOTSPOT_POLYGON 150,273,190,234,212,254,82,384,81,434,34,435,33,393 HOTSPOT_ACTION "s:Hillsboro Central%2FSE 3rd TC/Hillsboro_Central%2FSoutheast_3rd_Avenue_Transit_Center/E,9846/W,9845"  HOTSPOT_END
    HOTSPOT_POLYGON 84,433,109,434,111,393,225,276,208,262,85,385 HOTSPOT_ACTION "s:Tuality Hospital%2FSE 8th Ave/Tuality_Hospital%2FSoutheast_8th_Avenue/E,9843/W,9844"  HOTSPOT_END
    HOTSPOT_POLYGON 111,436,145,435,150,392,244,292,226,276,115,391 HOTSPOT_ACTION "s:Washington%2FSE 12th Ave/Washington%2FSoutheast_12th_Avenue/E,9841/W,9842"  HOTSPOT_END
    HOTSPOT_POLYGON 148,434,186,433,189,388,353,221,328,205,151,391 HOTSPOT_ACTION "s:Fair Complex%2FHillsboro Airport/Fair_Complex%2FHillsboro_Airport/E,9838/W,9837"  HOTSPOT_END
    HOTSPOT_POLYGON 189,433,225,433,224,387,295,311,275,298,190,391 HOTSPOT_ACTION "s:Hawthorn Farm/Hawthorn_Farm/E,9839/W,9840"  HOTSPOT_END
    HOTSPOT_POLYGON 225,432,225,390,330,275,346,295,257,389,258,434 HOTSPOT_ACTION "s:Orenco%2FNW 231st Ave/Orenco%2FNorthwest_231st_Avenue/E,9835/W,9836"  HOTSPOT_END
    HOTSPOT_POLYGON 261,435,290,435,289,390,391,285,373,269,261,389 HOTSPOT_ACTION "s:Quatama%2FNW 205th Ave/Quatama%2FNorthwest_205th_Avenue/E,9834/W,9833"  HOTSPOT_END
    HOTSPOT_POLYGON 292,434,339,436,339,394,476,256,446,231,291,389 HOTSPOT_ACTION "s:Willow Creek%2FSW 185th Ave TC/Willow_Creek%2FSouthwest_185th_Avenue_Transit_Center/E,9831/W,9832"  HOTSPOT_END
    HOTSPOT_POLYGON 340,435,377,435,377,390,484,284,464,268,342,393 HOTSPOT_ACTION "s:Elmonica%2FSW 170th Ave/Elmonica%2FSouthwest_170th_Avenue/E,9830/W,9829"  HOTSPOT_END
    HOTSPOT_POLYGON 378,433,410,431,414,391,483,318,466,300,379,387 HOTSPOT_ACTION "s:Merlo Rd%2FSW 158th Ave/Merlo_Road%2FSouthwest_158th_Avenue/E,9828/W,9827"  HOTSPOT_END
    HOTSPOT_POLYGON 411,434,445,433,449,390,537,300,519,285,417,393 HOTSPOT_ACTION "s:Beaverton Creek/Beaverton_Creek/E,9822/W,9819"  HOTSPOT_END
    HOTSPOT_POLYGON 447,433,486,433,485,392,546,327,530,308,449,392 HOTSPOT_ACTION "s:Millikan Way/Millikan_Way/E,9826/W,9825"  HOTSPOT_END
    HOTSPOT_POLYGON 486,433,515,433,517,383,600,304,583,287,486,392 HOTSPOT_ACTION "s:Beaverton Central/Beaverton_Central/E,9824/W,9823"  HOTSPOT_END
    HOTSPOT_POLYGON 517,434,550,433,550,398,691,264,668,244,519,384 HOTSPOT_ACTION "s:Beaverton TC/Beaverton_Transit_Center/MAX Northbound,9821/MAX Southbound,9818/WES Southbound,13066"  HOTSPOT_END
    HOTSPOT_POLYGON 186,39,186,104,484,106,483,39 HOTSPOT_ACTION "http://www.trimet.org"  HOTSPOT_END
    HOTSPOT_POLYGON 1105,352,1131,327,1153,352,1129,377 HOTSPOT_ACTION "w:Steel_Bridge"  HOTSPOT_END
    HOTSPOT_POLYGON 900,100,875,121,1007,253,1029,235 HOTSPOT_ACTION "w:Willamette_River"  HOTSPOT_END
    HOTSPOT_POLYGON 659,506,510,506,511,469,660,468 HOTSPOT_ACTION "s:Hall%2FNimbus/Hall%2FNimbus/WES,13067"  HOTSPOT_END
    HOTSPOT_POLYGON 511,548,511,581,640,581,637,547 HOTSPOT_ACTION "s:Tigard TC/Tigard_Transit_Center/S,13068/N,13073"  HOTSPOT_END
    HOTSPOT_POLYGON 510,620,510,660,639,660,637,620 HOTSPOT_ACTION "s:Tualatin/Tualatin_Station/WES,13069"  HOTSPOT_END
    HOTSPOT_POLYGON 510,706,510,737,695,737,694,705 HOTSPOT_ACTION "s:Wilsonville/Wilsonville_Station/N,13070"  HOTSPOT_END
    HOTSPOT_POLYGON 611,436,642,435,644,396,716,330,693,306,611,392 HOTSPOT_ACTION "s:Sunset TC/Sunset_Transit_Center/E,9969/W,9624"  HOTSPOT_END
    HOTSPOT_POLYGON 785,262,785,433,813,433,808,262 HOTSPOT_ACTION "s:Washington Park/Washington_Park_(MAX_station)/E,10120/W,10121"  HOTSPOT_END
    HOTSPOT_POLYGON 807,159,833,159,836,390,812,417 HOTSPOT_ACTION "s:Goose Hollow%2FSW Jefferson St/Goose_Hollow%2FSW_Jefferson_St/E,10118/W,10117"  HOTSPOT_END
    HOTSPOT_POLYGON 837,179,864,178,864,380,835,384 HOTSPOT_ACTION "s:Kings Hill%2FSW Salmon St/Kings_Hill%2FSouthwest_Salmon/N,9759/S,9820"  HOTSPOT_END
    HOTSPOT_POLYGON 870,162,896,162,896,268,902,368,871,383 HOTSPOT_ACTION "s:JELD-WEN Field (PGE Park)/PGE_Park_(MAX_station)/E,9758/W,9757"  HOTSPOT_END
    HOTSPOT_POLYGON 17,519,17,543,318,541,317,516 HOTSPOT_ACTION "d://100"  HOTSPOT_END
    HOTSPOT_POLYGON 1457,334,1595,196,1621,217,1477,358 HOTSPOT_ACTION "s:Gateway%2FNE 99th TC/Gateway%2FNortheast_99th_Avenue_Transit_Center/N,8370/S,8347"  HOTSPOT_END
    HOTSPOT_POLYGON 1821,50,1820,133,1895,135,1891,51 HOTSPOT_ACTION "n"  HOTSPOT_END
    HOTSPOT_POLYGON 938,291,937,423,955,439,957,291 HOTSPOT_ACTION "s:Galleria%2FSW 10th/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/W,8384"  HOTSPOT_END
    HOTSPOT_POLYGON 956,274,976,275,973,460,955,440 HOTSPOT_ACTION "s:Pioneer Square North/Pioneer_Square_South_and_Pioneer_Square_North/W,8383"  HOTSPOT_END
    HOTSPOT_POLYGON 906,427,921,412,987,476,969,494 HOTSPOT_ACTION "s:Pioneer Courthouse%2FSW 6th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/N,7777"  HOTSPOT_END
    HOTSPOT_POLYGON 789,438,788,462,938,464,914,438 HOTSPOT_ACTION "s:Library%2FSW 9th Ave/Library%2FSouthwest_9th_Avenue_and_Galleria%2FSouthwest_10th_Avenue/E,8333"  HOTSPOT_END
    HOTSPOT_POLYGON 782,480,781,504,953,503,962,495,946,481 HOTSPOT_ACTION "s:Pioneer Square South/Pioneer_Square_South_and_Pioneer_Square_North/E,8334"  HOTSPOT_END
    HOTSPOT_POLYGON 842,503,961,504,937,532,842,531 HOTSPOT_ACTION "s:SW 6th & Madison St/Southwest_6th_%26_Madison_Street_(MAX_station)/N,13123"  HOTSPOT_END
    HOTSPOT_POLYGON 774,534,930,535,904,561,774,560 HOTSPOT_ACTION "s:PSU%2FSW 6th & Montgomery/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_(MAX_station)/N,7774"  HOTSPOT_END
    HOTSPOT_POLYGON 826,571,826,595,863,595,865,570 HOTSPOT_ACTION "w:Portland_State_University"  HOTSPOT_END
    HOTSPOT_POLYGON 977,326,1033,326,1031,361,988,362,977,362 HOTSPOT_ACTION "s:Union Station%2FNW 6th & Hoyt St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_(MAX_station)/N,7763"  HOTSPOT_END
    HOTSPOT_POLYGON 975,362,1029,362,1030,407,976,407 HOTSPOT_ACTION "s:NW 6th & Davis St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/N,9299"  HOTSPOT_END
    HOTSPOT_POLYGON 976,407,1029,407,1029,440,1010,460,992,460,974,441 HOTSPOT_ACTION "s:SW 6th & Pine St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/N,7787"  HOTSPOT_END
    HOTSPOT_POLYGON 991,289,993,326,1062,326,1061,289 HOTSPOT_ACTION "w:Union_Station_%28Portland%29"  HOTSPOT_END
    HOTSPOT_POLYGON 1041,364,1053,375,1119,434,1120,399,1065,339 HOTSPOT_ACTION "s:Union Station%2FNW 5th & Glisan St/Union_Station%2FNorthwest_6th_%26_Hoyt_Street_and_Union_Station%2FNorthwest_5th_%26_Glisan_Street/S,7601"  HOTSPOT_END
    HOTSPOT_POLYGON 1039,401,1121,470,1120,436,1041,366 HOTSPOT_ACTION "s:NW 5th & Couch St/Northwest_6th_%26_Davis_Street_and_Northwest_5th_%26_Couch_Street/S,9303"  HOTSPOT_END
    HOTSPOT_POLYGON 985,509,1003,492,1079,569,1064,587 HOTSPOT_ACTION "s:Pioneer Place%2FSW 5th Ave/Pioneer_Courthouse%2FSouthwest_6th_and_Pioneer_Place%2FSouthwest_5th/S,7646"  HOTSPOT_END
    HOTSPOT_POLYGON 1025,471,1041,456,1105,458,1106,482,1025,482 HOTSPOT_ACTION "s:SW 5th & Oak St/Southwest_6th_%26_Pine_Street_and_Southwest_5th_%26_Oak_Street/S,7627"  HOTSPOT_END
    HOTSPOT_POLYGON 1017,483,1009,494,1028,512,1118,512,1119,483 HOTSPOT_ACTION "s:Mall%2FSW 5th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/W,8382"  HOTSPOT_END
    HOTSPOT_POLYGON 1032,514,1058,514,1120,514,1120,539,1063,547 HOTSPOT_ACTION "s:Morrison%2FSW 3rd Ave/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/W,8381"  HOTSPOT_END
    HOTSPOT_POLYGON 941,546,962,545,961,625,940,624 HOTSPOT_ACTION "s:PSU%2FSW 5th & Mill St/PSU_Urban_Center%2FSouthwest_6th_%26_Montgomery_Street_and_PSU_Urban_Center%2FSouthwest_5th_%26_Mill_Street/S,7618"  HOTSPOT_END
    HOTSPOT_POLYGON 963,529,985,511,992,701,966,700 HOTSPOT_ACTION "s:City Hall%2FSW 5th & Jefferson St/Southwest_6th_%26_Madison_Street_and_City_Hall%2FSouthwest_5th_%26_Jefferson_Street/S,7608"  HOTSPOT_END
    HOTSPOT_POLYGON 996,527,1025,551,1020,648,993,649 HOTSPOT_ACTION "s:Mall%2FSW 4th Ave/Mall%2FSouthwest_4th_Avenue_and_Mall%2FSouthwest_5th_Avenue/E,8335"  HOTSPOT_END
    HOTSPOT_POLYGON 1031,556,1059,587,1054,700,1026,702 HOTSPOT_ACTION "s:Yamhill District/Yamhill_District_and_Morrison%2FSouthwest_3rd_Avenue/E,8336"  HOTSPOT_END
    HOTSPOT_POLYGON 1126,412,1298,414,1300,452,1126,449 HOTSPOT_ACTION "s:Old Town%2FChinatown/Old_Town%2FChinatown/N,8339/S,8378"  HOTSPOT_END
    HOTSPOT_POLYGON 1125,451,1289,453,1291,495,1126,493 HOTSPOT_ACTION "s:Skidmore Fountain/Skidmore_Fountain_(MAX_station)/N,8338/S,8379"  HOTSPOT_END
    HOTSPOT_POLYGON 1109,569,1110,541,1219,542,1219,569 HOTSPOT_ACTION "s:Oak%2FSW 1st Ave/Oak_Street%2FSouthwest_1st_Avenue/N,8337/S,8380"  HOTSPOT_END
    HOTSPOT_POLYGON 1281,511,1316,510,1314,578,1281,577 HOTSPOT_ACTION "1"  HOTSPOT_END
    HOTSPOT_POLYGON 1321,549,1356,548,1354,612,1320,613 HOTSPOT_ACTION "2"  HOTSPOT_END
    HOTSPOT_POLYGON 1363,590,1399,591,1401,654,1363,655 HOTSPOT_ACTION "3"  HOTSPOT_END
    HOTSPOT_POLYGON 1062,4,1203,3,1203,30,1059,30 HOTSPOT_ACTION "s:Expo Center/Expo_Center_(MAX_station)/E,11498"  HOTSPOT_END
    HOTSPOT_POLYGON 1062,31,1251,30,1251,59,1060,59 HOTSPOT_ACTION "s:Delta Park%2FVanport/Delta_Park%2FVanport/S,11499/N,11516"  HOTSPOT_END
    HOTSPOT_POLYGON 1060,58,1220,58,1222,83,1062,84 HOTSPOT_ACTION "s:Kenton%2FN Denver/Kenton%2FNorth_Denver_Avenue/S,11500/N,11515"  HOTSPOT_END
    HOTSPOT_POLYGON 1063,87,1209,86,1209,115,1063,114 HOTSPOT_ACTION "s:N Lombard TC/North_Lombard_Transit_Center/S,11501/N,11514"  HOTSPOT_END
    HOTSPOT_POLYGON 1062,115,1061,143,1186,142,1184,116 HOTSPOT_ACTION "s:Rosa Parks/North_Rosa_Parks_Way/S,11502/N,11513"  HOTSPOT_END
    HOTSPOT_POLYGON 1061,142,1212,142,1213,171,1061,172 HOTSPOT_ACTION "s:N Killingsworth/North_Killingsworth_Street/S,11503/N,11512"  HOTSPOT_END
    HOTSPOT_POLYGON 1063,173,1176,174,1176,191,1063,193,1061,186,1061,190 HOTSPOT_ACTION "s:N Prescott/North_Prescott_Street/S,11504/N,11511"  HOTSPOT_END
    HOTSPOT_POLYGON 1065,193,1203,192,1201,210,1065,210 HOTSPOT_ACTION "s:Overlook Park/Overlook_Park/S,11505/N,11510"  HOTSPOT_END
    HOTSPOT_POLYGON 1063,212,1152,210,1182,228,1150,258,1061,255 HOTSPOT_ACTION "s:Albina%2FMississippi/Albina%2FMississippi/S,11506/N,11509"  HOTSPOT_END
    HOTSPOT_POLYGON 1106,303,1130,325,1274,184,1250,163 HOTSPOT_ACTION "s:Interstate%2FRose Quarter/Interstate%2FRose_Quarter/S,11507/N,11508"  HOTSPOT_END
    HOTSPOT_POLYGON 1132,324,1272,188,1290,207,1155,348 HOTSPOT_ACTION "s:Rose Quarter TC/Rose_Quarter_Transit_Center/E,8340/W,8377"  HOTSPOT_END
    HOTSPOT_POLYGON 1292,210,1309,224,1223,314,1222,366,1197,368,1197,307 HOTSPOT_ACTION "s:Convention Center/Convention_Center_(MAX_station)/E,8341/W,8376"  HOTSPOT_END
    HOTSPOT_POLYGON 1224,365,1251,366,1252,313,1277,283,1263,271,1227,313 HOTSPOT_ACTION "s:NE 7th Ave/Northeast_7th_Avenue/E,8342/W,8375"  HOTSPOT_END
    HOTSPOT_POLYGON 1253,367,1288,368,1288,321,1391,208,1371,189,1256,311 HOTSPOT_ACTION "s:Lloyd Center%2FNE 11th Ave/Lloyd_Center%2FNortheast_11th_Avenue/E,8343/W,8374"  HOTSPOT_END
    HOTSPOT_POLYGON 1297,367,1335,367,1336,317,1447,201,1427,181,1296,317 HOTSPOT_ACTION "s:Hollywood%2FNE 42nd Ave/Hollywood%2FNortheast_42nd_Avenue_Transit_Center/E,8344/W,8373"  HOTSPOT_END
    HOTSPOT_POLYGON 1352,367,1383,365,1385,314,1418,278,1400,260,1350,312 HOTSPOT_ACTION "s:NE 60th Ave/Northeast_60th_Avenue/E,8345/W,8372"  HOTSPOT_END
    HOTSPOT_POLYGON 1390,368,1420,367,1422,316,1456,282,1437,259,1427,270,1390,313 HOTSPOT_ACTION "s:NE 82nd Ave/Northeast_82nd_Avenue/E,8346/W,8371"  HOTSPOT_END
    HOTSPOT_POLYGON 1396,60,1398,85,1654,85,1654,61 HOTSPOT_ACTION "s:Portland Int'l Airport/Portland_International_Airport_(MAX_station)/E,10579"  HOTSPOT_END
    HOTSPOT_POLYGON 1418,97,1533,96,1534,117,1437,116 HOTSPOT_ACTION "s:Mt Hood Ave/Mount_Hood_Avenue_(MAX_station)/N,10576/S,10577"  HOTSPOT_END
    HOTSPOT_POLYGON 1446,127,1568,129,1569,150,1464,149 HOTSPOT_ACTION "s:Cascades/Cascades_(MAX_station)/W,10574/E,10575"  HOTSPOT_END
    HOTSPOT_POLYGON 1459,160,1662,159,1663,195,1602,195,1458,198 HOTSPOT_ACTION "s:Parkrose%2FSumner TC/Parkrose%2FSumner_Transit_Center/N,10572/S,10573"  HOTSPOT_END
    HOTSPOT_POLYGON 1461,377,1580,375,1580,405,1461,407 HOTSPOT_ACTION "s:SE Main St/Southeast_Main_Street/S,13124/N,13139"  HOTSPOT_END
    HOTSPOT_POLYGON 1460,410,1586,409,1588,437,1461,440 HOTSPOT_ACTION "s:SE Division St/Southeast_Division_Street/S,13125/N,13138"  HOTSPOT_END
    HOTSPOT_POLYGON 1458,447,1588,445,1589,472,1460,475 HOTSPOT_ACTION "s:SE Powell Blvd/Southeast_Powell_Boulevard/S,13126/N,13137"  HOTSPOT_END
    HOTSPOT_POLYGON 1461,481,1606,478,1606,509,1462,508 HOTSPOT_ACTION "s:SE Holgate Blvd/Southeast_Holgate_Boulevard/S,13127/N,13136"  HOTSPOT_END
    HOTSPOT_POLYGON 1460,513,1716,514,1716,547,1460,545 HOTSPOT_ACTION "s:Lents%2FSE Foster Rd/Lents_Town_Center%2FSoutheast_Foster_Road/S,13128/N,13135"  HOTSPOT_END
    HOTSPOT_POLYGON 1460,550,1570,551,1570,579,1460,580 HOTSPOT_ACTION "s:SE Flavel St/Southeast_Flavel_Street/S,13129/N,13134"  HOTSPOT_END
    HOTSPOT_POLYGON 1460,585,1586,583,1587,604,1460,606 HOTSPOT_ACTION "s:SE Fuller Rd/Southeast_Fuller_Road/S,13130/N,13133"  HOTSPOT_END
    HOTSPOT_POLYGON 1460,612,1721,608,1723,643,1460,642 HOTSPOT_ACTION "s:Clackamas Town Center TC/Clackamas_Town_Center_Transit_Center_(MAX_station)/N,13132"  HOTSPOT_END
    HOTSPOT_POLYGON 1513,367,1555,365,1557,324,1585,289,1567,279,1513,333 HOTSPOT_ACTION "s:E 102nd Ave/East_102nd_Avenue/E,8348/W,8369"  HOTSPOT_END
    HOTSPOT_POLYGON 1557,366,1586,367,1587,329,1634,277,1611,263,1559,325 HOTSPOT_ACTION "s:E 122nd Ave/East_122nd_Avenue_(MAX_station)/E,8349/W,8368"  HOTSPOT_END
    HOTSPOT_POLYGON 1588,366,1613,366,1614,325,1648,289,1632,280,1590,330 HOTSPOT_ACTION "s:E 148th Ave/East_148th_Avenue_(MAX_station)/E,8350/W,8367"  HOTSPOT_END
    HOTSPOT_POLYGON 1614,366,1641,366,1640,332,1677,288,1665,275,1616,327 HOTSPOT_ACTION "s:E 162nd Ave/East_162nd_Avenue_(MAX_station)/E,8351/W,8366"  HOTSPOT_END
    HOTSPOT_POLYGON 1643,366,1668,366,1668,328,1702,288,1693,277,1642,332 HOTSPOT_ACTION "s:E 172nd/East_172nd_Avenue_(MAX_station)/E,8352/W,8365"  HOTSPOT_END
    HOTSPOT_POLYGON 1670,365,1694,365,1693,333,1740,281,1727,268,1672,328 HOTSPOT_ACTION "s:E 181st/East_181st_Avenue_(MAX_station)/E,8353/W,8364"  HOTSPOT_END
    HOTSPOT_POLYGON 1698,365,1738,363,1737,331,1841,217,1823,200,1699,330 HOTSPOT_ACTION "s:Rockwood%2FE 188th Ave TC/Rockwood%2FEast_188th_Avenue_Transit_Center_(MAX_station)/E,8354/W,8363"  HOTSPOT_END
    HOTSPOT_POLYGON 1742,364,1773,364,1775,328,1883,209,1867,197,1742,333 HOTSPOT_ACTION "s:Ruby Junction%2FE 197th Ave/Ruby_Junction%2FEast_197th_Avenue_(MAX_station)/E,8355/W,8362"  HOTSPOT_END
    HOTSPOT_POLYGON 1777,366,1805,365,1806,327,1844,286,1831,272,1778,327 HOTSPOT_ACTION "s:Civic Drive/Civic_Drive/E,13450/W,13449"  HOTSPOT_END
    HOTSPOT_POLYGON 1845,365,1843,331,1943,228,1922,209,1810,326,1808,367 HOTSPOT_ACTION "s:Gresham City Hall/Gresham_City_Hall_(MAX_station)/E,8356/W,8361"  HOTSPOT_END
    HOTSPOT_POLYGON 1846,367,1889,366,1887,331,1999,222,1994,181,1845,329 HOTSPOT_ACTION "s:Gresham Central TC/Gresham_Central_Transit_Center_(MAX_station)/E,8357/W,8360"  HOTSPOT_END
    HOTSPOT_POLYGON 1896,366,1929,367,1928,325,1989,267,1974,251,1895,331 HOTSPOT_ACTION "s:Cleveland Ave/Cleveland_Avenue_(MAX_station)/W,8359"  HOTSPOT_END
    HOTSPOT_POLYGON 15,543,335,543,334,563,15,562 HOTSPOT_ACTION "d://200"  HOTSPOT_END
    HOTSPOT_POLYGON 15,565,335,565,336,582,15,581,15,572 HOTSPOT_ACTION "d://90"  HOTSPOT_END
    HOTSPOT_POLYGON 14,586,333,584,334,603,15,606 HOTSPOT_ACTION "d://190"  HOTSPOT_END
    HOTSPOT_POLYGON 18,610,424,607,424,630,19,629 HOTSPOT_ACTION "d://203"  HOTSPOT_END
    HOTSPOT_POLYGON 13,632,419,631,419,650,12,652 HOTSPOT_ACTION "d://193"  HOTSPOT_END
    HOTSPOT_POLYGON 21,653,423,651,424,676,22,674 HOTSPOT_ACTION "w:Fareless_Square"  HOTSPOT_END
    HOTSPOT_POLYGON 25,676,148,678,148,698,24,698 HOTSPOT_ACTION "w:Park_and_ride"  HOTSPOT_END
    HOTSPOT_POLYGON 23,699,146,699,146,721,24,719 HOTSPOT_ACTION "http://trimet.org/howtoride/bikes/bikeandride.htm"  HOTSPOT_END
    HOTSPOT_POLYGON 25,722,148,722,148,744,26,742 HOTSPOT_ACTION "http://trimet.org/transitcenters/index.htm"  HOTSPOT_END
    HOTSPOT_POLYGON 18,459,102,457,101,486,17,486 HOTSPOT_ACTION "w:Hillsboro,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 406,460,499,458,497,486,407,484 HOTSPOT_ACTION "w:Beaverton,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 403,702,501,702,500,727,404,727 HOTSPOT_ACTION "w:Wilsonville,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 920,707,1041,708,1042,725,921,724 HOTSPOT_ACTION "w:South_Waterfront"  HOTSPOT_END
    HOTSPOT_POLYGON 1128,632,1249,632,1246,664,1127,663 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#Southeast"  HOTSPOT_END
    HOTSPOT_POLYGON 1441,653,1550,653,1551,678,1442,678 HOTSPOT_ACTION "w:Clackamas,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 1814,390,1902,389,1902,414,1815,414 HOTSPOT_ACTION "w:Gresham,_Oregon"  HOTSPOT_END
    HOTSPOT_POLYGON 935,78,1039,83,1037,109,936,103 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#North"  HOTSPOT_END
    HOTSPOT_POLYGON 896,228,974,231,976,271,896,270 HOTSPOT_ACTION "w:Neighborhoods_of_Portland,_Oregon#Northwest"  HOTSPOT_END
    HOTSPOT_POLYGON 197,110,465,112,464,164,196,163 HOTSPOT_ACTION "w:Light_Rail"  HOTSPOT_END
    HOTSPOT_POLYGON 1868,734,1981,734,1982,756,1868,756 HOTSPOT_ACTION "w:Portal:Current_events%2F2010_September_5"  HOTSPOT_END
    HOTSPOT_POLYGON 1581,735,1856,733,1857,756,1581,758 HOTSPOT_ACTION "w:Disclaimer"  HOTSPOT_END
    HOTSPOT_POLYGON 941,528,954,539,1031,461,1021,450 HOTSPOT_ACTION "w:Portland_Transit_Mall"  HOTSPOT_END
    HOTSPOT_POLYGON 863,586,889,560,922,587,879,626,861,602 HOTSPOT_ACTION "w:PSU_South"  HOTSPOT_END
    HOTSPOT_POLYGON 159,440,159,456,194,457,194,440 HOTSPOT_ACTION "w:17_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 395,444,394,456,440,455,439,442 HOTSPOT_ACTION "w:11_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 638,443,678,443,677,459,638,459 HOTSPOT_ACTION "w:10_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 460,566,495,566,496,582,460,583 HOTSPOT_ACTION "w:27_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1017,47,1047,46,1048,64,1018,63 HOTSPOT_ACTION "w:6_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1013,163,1013,178,1047,178,1046,164 HOTSPOT_ACTION "w:14_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1410,153,1410,168,1446,170,1448,154 HOTSPOT_ACTION "w:14_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1324,377,1365,376,1364,392,1325,391 HOTSPOT_ACTION "w:14_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1181,376,1285,378,1283,407,1181,407 HOTSPOT_ACTION "w:22_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1410,499,1449,500,1450,517,1409,516 HOTSPOT_ACTION "w:16_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 1679,376,1720,374,1720,391,1679,391 HOTSPOT_ACTION "w:23_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 500,739,560,739,560,759,500,759 HOTSPOT_ACTION "http://www.trimet.org/fares/zones.htm"  HOTSPOT_END
    HOTSPOT_POLYGON 948,725,1021,726,1022,756,949,755 HOTSPOT_ACTION "w:32_(number)"  HOTSPOT_END
    HOTSPOT_POLYGON 892,390,903,367,936,403,931,418,916,406,913,413 HOTSPOT_ACTION "w:Downtown_Portland"  HOTSPOT_END
    HOTSPOT_POLYGON 872,386,884,396,890,394,913,417,904,427,912,437,893,438,857,402 HOTSPOT_ACTION "w:Downtown_Portland"  HOTSPOT_END
    
    
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

- (void)selectItem:(int)i
{
	self.selectedItem = i;
	
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


//
//  RootViewController.m
//  TriMetTimes
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

#import "RootViewController.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "DepartureTimesView.h"
#import "RouteView.h"
#import "EditableTableViewCell.h"
#import "CellTextField.h"
#import "UserFaves.h"
#import "AboutView.h"
#import "SupportView.h"
#import "WebViewController.h"
#import "DetoursView.h"
#import "FindByLocationView.h"
#import "EditBookMarkView.h"
#import "FlashViewController.h"
#import "TripPlannerDateView.h"
#import "AppDelegateMethods.h"
#import "RailMapView.h"
#import "debug.h"
#import "RssView.h"
#import "XMLTrips.h"
#import "TripPlannerDateView.h"
#import "TripPlannerResultsView.h"
#import "TripPlannerCacheView.h"
#import "DepartureHistoryView.h"
#import "WhatsNewView.h"
#import "TripPlannerSummaryView.h"
#import "AllRailStationView.h"
#import "AlarmViewMinutes.h"
#import "AlarmAccurateStopProximity.h"
#import "LocationServicesDebugView.h"
#import "VehicleLocatingTableView.h"

#import "TripPlannerLocatingView.h"

#import "ZXingWidgetController.h"
#import "QRCodeReader.h"
#import "ProgressModalView.h"

#import "AddressBook/AddressBook.h"
#import <AddressBook/ABPerson.h>

#define kTableSectionStopId		0
#define kTableSectionFaves		1
#define kTableSectionAbout		2
#define kTableSectionPlanner    3
#define kTableSectionAlarms     4
#define kTableSectionTriMet     5

#define kTableFaveAdd			0
#define kTableFaveTrip			1
#define kTableFaveEditingRows	2

#define kTableTriMetDetours		0
#define kTableTriMetAlerts		1
#define kTableTriMetLink        2
#define kTableTriMetFacebook    3
#define kTableTriMetCall		4
#define kTableTriMetTweet		5
#define kTableTriMetTicketApp   6
#define kTableStreetcarTweet	7


#define kTableAboutSettings     0
#define kTableAboutRowAbout     1
#define kTableAboutSupport      3
#define kTableAboutFacebook		4
#define kTableAboutRate         5
#define kTableAboutRowEmail     6

#define kTableFindRowId			0
#define kTableFindRowBrowse		1
#define kTableFindRowLocate		2
#define kTableFindRowRailStops	3
#define kTableFindRowRailMap    4
#define kTableFindRowQR         5
#define kTableFindRowHistory	6
#define kTableFindRowVehicle	7


#define kTableTripRowPlanner    0
#define kTableTripRowCache      1
#define kTableTripRows          2

#define kUIEditHeight			50.0
#define kUIRowHeight			40.0

#define kTextFieldId			@"TextField"
#define kAboutId				@"AboutLink"
#define kPlainId				@"Plain"
#define kAlarmCellId			@"Alarm"


static NSString *callString = @"tel:1-503-238-RIDE";

// #define LOADINGSCREEN


@implementation RootViewController
@synthesize editWindow			= _editWindow;
@synthesize lastArrivalsShown	= _lastArrivalsShown;
@synthesize editCell			= _editCell;
@synthesize lastArrivalNames    = _lastArrivalNames;
@synthesize alarmKeys			= _alarmKeys;
@synthesize commuterBookmark	= _commuterBookmark;
@synthesize settingsView        = _settingsView;
@synthesize progressView        = _progressView;
@synthesize triMetRows          = _triMetRows;
@synthesize aboutRows           = _aboutRows;
@synthesize arrivalRows         = _arrivalRows;
@synthesize launchStops         = _launchStops;
@synthesize routingURL          = _routingURL;
@synthesize delayedInitialAction = _delayedInitialAction;
@synthesize initialAction       = _initialAction;
@synthesize initialBookmarkName = _initalBookmarkName;
@synthesize initialBookmarkIndex = _initialBookmarkIndex;
@synthesize initialActionArgs   = _initialActionArgs;
@synthesize viewLoaded          = _viewLoaded;
@synthesize goButton            = _goButton;
@synthesize helpButton          = _helpButton;

- (void)dealloc {
	self.editWindow			= nil;
	self.lastArrivalsShown	= nil;
	self.editCell			= nil;
	self.lastArrivalNames	= nil;
	self.alarmKeys			= nil;
	self.commuterBookmark   = nil;
    self.settingsView       = nil;
    self.progressView       = nil;
    self.triMetRows         = nil;
    self.aboutRows          = nil;
    self.tweetAt            = nil;
    self.initTweet          = nil;
    self.arrivalRows        = nil;
    self.launchStops        = nil;
    self.routingURL         = nil;
    self.initialActionArgs  = nil;
    self.goButton           = nil;
    self.helpButton         = nil;

	[super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (CGFloat) heightOffset
{
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        return -20.0;
    }
    return 0.0;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems removeAllObjects];
    bool spaceNeeded = NO;
    
    
    if ([UserPrefs getSingleton].locateToolbarIcon)
    {
        [toolbarItems addObject:[CustomToolbar autoLocateWithTarget:self  action:@selector(autoLocate:)]];
        spaceNeeded = YES;
    }
    
    if ([UserPrefs getSingleton].commuteButton)
    {
        if (spaceNeeded)
        {
            [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        }
        [toolbarItems addObject:[CustomToolbar autoCommuteWithTarget:self action:@selector(commuteAction:)]];
        spaceNeeded = YES;
    }
    
    if (self.ZXingSupported && [UserPrefs getSingleton].qrCodeScannerIcon)
    {
        if (spaceNeeded)
        {
             [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        }
        [toolbarItems addObject:[CustomToolbar autoQRScanner:self action:@selector(QRScannerAction:)]];
        spaceNeeded = YES;
    }
    
    if ([UserPrefs getSingleton].ticketAppIcon)
    {
        if (spaceNeeded)
        {
             [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        }
        [toolbarItems addObject:[self autoTicketAppButton]];
        spaceNeeded = YES;
    }
    
    [self maybeAddFlashButtonWithSpace:spaceNeeded buttons:toolbarItems big:YES];
    
    
    if (self.goButton==nil)
    {
        self.goButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                       target:self
                                                                       action:@selector(editGoAction:)] autorelease];
    }
    
    
    if (self.helpButton==nil)
    {
        self.helpButton = [[[UIBarButtonItem alloc] initWithTitle:@"Help"
                                                            style:UIBarButtonItemStyleBordered
                                                           target:self action:@selector(helpAction:)] autorelease];
    }
}

#pragma mark UI Helper functions



- (void) delayedQRScanner:(NSObject *)arg
{
    ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];
    
    

    int color = [UserPrefs getSingleton].toolbarColors;
	
    
	if (color == 0xFFFFFF)
	{
        if (self.iOS7style)
        {
            widController.overlayView.toolbar.barTintColor =  nil;
            widController.overlayView.toolbar.tintColor =  nil;
        }
        else
        {
            widController.overlayView.toolbar.tintColor =  nil;
        }
	}
	else
	{
        if (self.iOS7style)
        {
            widController.overlayView.toolbar.barTintColor = [self htmlColor:color];
            widController.overlayView.toolbar.tintColor =  [UIColor whiteColor];
        }
        else
        {
            widController.overlayView.toolbar.tintColor =  nil;
        }
            
    }
    
    NSMutableSet *readers = [[NSMutableSet alloc ] init];
    
    QRCodeReader* qrcodeReader = [[QRCodeReader alloc] init];
    [readers addObject:qrcodeReader];
    [qrcodeReader release];
    
    widController.readers = readers;
    [readers release];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    widController.soundToPlay =
        [NSURL fileURLWithPath:[mainBundle pathForResource:@"beep-beep" ofType:@"aiff"] isDirectory:NO];
    [self presentModalViewController:widController animated:YES];
    [widController release];   
}

- (bool)QRCodeScanner
{
    if (self.ZXingSupported)
    {
        TriMetTimesAppDelegate *delegate = [TriMetTimesAppDelegate getSingleton];
    
        self.progressView = [ProgressModalView initWithSuper:delegate.window
                                                       items:0 
                                                       title:@"Starting QR Code Scanner"
                                                    delegate:nil
                                                 orientation:self.interfaceOrientation];
    
        [delegate.window addSubview:self.progressView];
    
        NSTimer *timer = [[[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.01]
                                                   interval:0.0 
                                                     target:[self retain]
                                                   selector:@selector(delayedQRScanner:) 
                                                   userInfo:nil 
                                                    repeats:NO] autorelease];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    else {
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:nil
														   message:@"QR Scanning is not supported in this version of iOS. :-("
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil ] autorelease];
		[alert show]; 
        return NO;
    }
    return YES;
}

- (NSString *)addressFromMapItem:(MKMapItem *)mapItem
{
    if (mapItem.name != nil)
    {
        return mapItem.name;
    }
    
    NSMutableString *address = [[[NSMutableString alloc] init] autorelease];
    
    if (mapItem.placemark.addressDictionary != nil)
    {
        // NSDictionary *dict = mapItem.placemark.addressDictionary;
       
        CFDictionaryRef dict =  (CFDictionaryRef)mapItem.placemark.addressDictionary;

        NSString* item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
    
        if (item && [item length] > 0)
        {
            [address appendString:item];
        }
    
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCityKey);
    
        if (item && [item length] > 0)
        {
            if ([address length] > 0)
            {
                [address appendString:@", "];
            }
            [address appendString:item];
        }
    
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStateKey);
        
        if (item && [item length] > 0)
        {
            if ([address length] > 0)
            {
                [address appendString:@","];
            }
            [address appendString:item];
    
    
        }
        return address;
    }
    
    return nil;

}

- (void)launchTripPlannerFromURL
{
    MKDirectionsRequest* directionsInfo = [[[MKDirectionsRequest alloc] initWithContentsOfURL:self.routingURL] autorelease];
    
    self.routingURL = nil;
    
    TripPlannerLocatingView * locView = [[ TripPlannerLocatingView alloc ] init];
	
    XMLTrips *query = [[[XMLTrips alloc] init] autorelease];
    
    if (directionsInfo.source.isCurrentLocation)
    {
        query.userRequest.fromPoint.useCurrentLocation = YES;
    }
    else
    {
        query.userRequest.fromPoint.locationDesc = [self addressFromMapItem:directionsInfo.source];
        query.userRequest.fromPoint.currentLocation = directionsInfo.source.placemark.location;
        DEBUG_LOG(@"From desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }
    
    if (directionsInfo.destination.isCurrentLocation)
    {
        query.userRequest.toPoint.useCurrentLocation = YES;
    }
    else
    {
        query.userRequest.toPoint.locationDesc = [self addressFromMapItem:directionsInfo.destination];
        query.userRequest.toPoint.currentLocation = directionsInfo.destination.placemark.location;
        DEBUG_LOG(@"To desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }
    
    
    query.userRequest.timeChoice = TripDepartAfterTime;
    query.userRequest.dateAndTime = [NSDate date];
    
    locView.tripQuery = query;
	
    [locView nextScreen:[self navigationController] forceResults:NO postQuery:NO
            orientation:self.interfaceOrientation
          taskContainer:self.backgroundTask];
	
    [locView release];


}

- (void)launchFromURL
{
        
    DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];

    [departureViewController fetchTimesForLocationInBackground:self.backgroundTask
                                                       loc:self.launchStops
                                                     title:@"Launching..."];
    [departureViewController release];

    self.launchStops = nil;
}


- (void)QRScannerAction:(id)sender
{
    [self QRCodeScanner];
}

- (void)autoLocate:(id)sender
{
    if (self.initialActionArgs)
    {
        FindByLocationView *findView = [[FindByLocationView alloc] initAutoLaunch];
        
        [findView actionArgs:self.initialActionArgs];
        self.initialActionArgs = nil;
        
        
        // Push the detail view controller
        [[self navigationController] pushViewController:findView animated:YES];
        [findView release];
    }
    else if ([UserPrefs getSingleton].autoLocateShowOptions)
    {
        FindByLocationView *findView = [[FindByLocationView alloc] init];
        
        // Push the detail view controller
        [[self navigationController] pushViewController:findView animated:YES];
        [findView release];

    }
    else
    {

        FindByLocationView *findView = [[FindByLocationView alloc] initAutoLaunch];
        
        // Push the detail view controller
        [[self navigationController] pushViewController:findView animated:YES];
        [findView release];
    }

    
}

- (void)commuteAction:(id)sender
{
	TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate getSingleton];
	
	NSDictionary *commuteBookmark = [app checkForCommuterBookmarkShowOnlyOnce:NO];
	
	if (commuteBookmark!=nil)
	{
	
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask 
															   loc:[commuteBookmark valueForKey:kUserFavesLocation]
															 title:[commuteBookmark valueForKey:kUserFavesChosenName]
		];
		[departureViewController release];
	}
	else {
		UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Commute"
														   message:@"No commuter bookmark was found for the current day of the week and time. To create a commuter bookmark, edit a bookmark to set which days to use it for the morning or evening commute."
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil ] autorelease];
		[alert show];
	}
}

- (void)helpAction:(id)sender
{
	SupportView *supportView = [[SupportView alloc] init];
	
	// Push the detail view controller
	[[self navigationController] pushViewController:supportView animated:YES];
	[supportView release];
	
}



- (bool)canMakePhoneCall
{
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:callString]];
}

- (void)executeInitialAction
{
	DEBUG_PRINTF("Last arrivals: %s", [self.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding]);
	
    if (!self.viewLoaded)
    {
        self.delayedInitialAction = YES;
        return;
    }
    
    
    bool showAbout = [self newVersion:@"lastRun.plist" version:kAboutVersion];
	bool showWhatsNew = [self newVersion:@"whatsNew.plist" version:kWhatsNewVersion];
	
	if (showAbout)
	{
		AboutView *aboutView = [[AboutView alloc] init];
		
		// Push the detail view controller
		[[self navigationController] pushViewController:aboutView animated:NO];
		[aboutView release];
		
	}
	else  if (showWhatsNew)
	{
		WhatsNewView *whatsNew = [[WhatsNewView alloc] init];
		[[self navigationController] pushViewController:whatsNew animated:NO];
		[whatsNew release];
	}
	else if (self.routingURL)
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        [self launchTripPlannerFromURL];
    }
    else if (self.launchStops)
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        [self launchFromURL];
    }
    else if (self.commuterBookmark)
	{
		[_userData clearLastArrivals];
		
        [self.navigationController popToRootViewControllerAnimated:NO];
        
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask 
															   loc:[self.commuterBookmark valueForKey:kUserFavesLocation]
															 title:[self.commuterBookmark valueForKey:kUserFavesChosenName]
		 ];
		[departureViewController release];		
		showingLast = true;
		self.commuterBookmark = nil;
	}
    else if (self.initialAction == InitialAction_TripPlanner)
    {
        [self tripPlanner:YES];
    }
    else if (self.initialAction == InitialAction_Commute)
    {
        [self commuteAction:nil];
    }
    else if (self.initialAction == InitialAction_Locate)
    {
        [self autoLocate:nil];
    }
    else if (self.initialAction == InitialAction_QRCode)
    {
        [self QRCodeScanner];
    }
    else if (self.initialAction == InitialAction_BookmarkIndex)
    {
        [self openFave:self.initialBookmarkIndex allowEdit:NO];
    }
    else if (self.initialBookmarkName != nil)
    {
        bool found = NO;
        int foundItem = 0;
        @synchronized (_userData)
        {
            for (int i=0; i< _userData.faves.count; i++)
            {
                NSMutableDictionary *item = (NSMutableDictionary *)[_userData.faves objectAtIndex:i];
                NSString *name = [item valueForKey:kUserFavesChosenName];
                if (name!=nil && [self.initialBookmarkName isEqualToString:name])
                {
                    found = YES;
                    foundItem = i;
                    break;
                }
            }
        }
        if (found)
        {
            [self openFave:foundItem allowEdit:NO];
        }
    }
    else
    {
        // Reload just in case the user changed the settings outside the app
        [self reloadData];
        [self updateToolbar];
    }
    
    self.delayedInitialAction = NO;
    self.initialAction = InitialAction_None;
    self.initialBookmarkName = nil;
}

- (UITextField *)createTextField_Rounded
{
	CGRect frame = CGRectMake(30.0, 0.0, 50.0, [CellTextField editHeight]);
	UITextField *returnTextField = [[[UITextField alloc] initWithFrame:frame] autorelease];
    
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"<enter stop ID>";
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	
	returnTextField.keyboardType = UIKeyboardTypeNumberPad;
	returnTextField.returnKeyType = UIReturnKeyGo;
	
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	self.editWindow = returnTextField;
	
	return returnTextField;
}

-(void)tripPlanner:(bool)animated
{	
	
	TripPlannerSummaryView *tripStart = [[TripPlannerSummaryView alloc] init];
//	tripStart.from = true;
	// tripStart.tripQuery = self.tripQuery;
	
	// tripStart.tripQuery.userFaves = self.userFaves;
	@synchronized (_userData)
	{
		[tripStart.tripQuery addStopsFromUserFaves:_userData.faves];
	}
	
	
	// Push the detail view controller
	[[self navigationController] pushViewController:tripStart animated:YES];
	[tripStart release];
	
}

- (void)updatePlaceholderRows:(bool)add
{
	NSArray *indexPaths = [NSArray arrayWithObjects:
						   [NSIndexPath indexPathForRow:[_userData.faves count] inSection:faveSection],
						   [NSIndexPath indexPathForRow:[_userData.faves count]+1 inSection:faveSection],
						   nil];
	
	int rows = [self.table numberOfRowsInSection:faveSection];
	
	if (add && (rows <= [_userData.faves count])) {
		// Show the placeholder rows
		[self.table insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
		
	} else if (!add && [_userData.faves count]!=0) {
        // Hide the placeholder rows.
		[self.table deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
	}
	
}


- (void)editGoAction:(id)sender
{
	[self.editWindow resignFirstResponder];
}


// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	keyboardUp = YES;
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc]
									  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
									  target:self
									  action:@selector(cancelAction:)] autorelease];
	
	
	
	
	self.navigationItem.leftBarButtonItem = cancelButton;
	self.navigationItem.rightBarButtonItem = self.goButton;
	
	[self.table scrollToRowAtIndexPath:[NSIndexPath 
										indexPathForRow:kTableFindRowId
										inSection:editSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	
	return YES;
}

#pragma mark View methods

- (void)mapSections
{
	if (_taskList)
	{
		self.alarmKeys = _taskList.taskKeys;
	}
	if ([UserPrefs getSingleton].bookmarksAtTheTop)
	{
		sections = 0;
		if (self.alarmKeys!=nil && self.alarmKeys.count>0)
		{
			sectionMap[sections++] = kTableSectionAlarms;
		}
		
		faveSection = sections;
		sectionMap[sections++] = kTableSectionFaves;
		editSection = sections;
		sectionMap[sections++] = kTableSectionStopId;
		sectionMap[sections++] = kTableSectionPlanner;
		
	}
	else
	{
		sections = 0;
		if (_taskList!=nil && _taskList.taskCount>0)
		{
			sectionMap[sections++] = kTableSectionAlarms;
		}
		
		editSection = sections;
		sectionMap[sections++] = kTableSectionStopId;
		
				
		sectionMap[sections++] = kTableSectionPlanner;
		
		faveSection = sections;
		sectionMap[sections++] = kTableSectionFaves;
		
		
	}
	
    sectionMap[sections++] = kTableSectionTriMet;
    
	sectionMap[sections++] = kTableSectionAbout;
	
}


- (bool)initMembers
{
	bool result = [super initMembers];
	
	if ([AlarmTaskList supported])
	{
		_taskList = [AlarmTaskList getSingleton];
	}
	return result;
}

- (void)reloadData
{
	[self mapSections];
	[self setTheme];
	[super reloadData];
}

- (void)loadView
{
	[self initMembers];
	[self mapSections];
	[super loadView];
	self.table.allowsSelectionDuringEditing = YES;
}

- (bool)newVersion:(NSString *)file version:(NSString *)version
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSString *lastRun = [documentsDirectory stringByAppendingPathComponent:file];
    NSMutableDictionary *dict = nil;
	bool newVersion = NO;
	
	if ([fileManager fileExistsAtPath:lastRun] == NO) {
        dict = [[[NSMutableDictionary alloc] init] autorelease];
		[dict setObject:version forKey:kVersion];
		[dict writeToFile:lastRun atomically:YES];
		newVersion = YES;
    }
	else {
		dict = [[[NSMutableDictionary alloc] initWithContentsOfFile:lastRun] autorelease];
		NSString *lastVerRun = [dict objectForKey:kVersion];
		if (![lastVerRun isEqualToString:version])
		{
			newVersion = YES;	
			[dict setObject:version forKey:kVersion];
			[dict writeToFile:lastRun atomically:YES];
		}
	}
	
	return newVersion;
	
}

- (void)viewDidLoad {
#ifndef LOADINGSCREEN
	self.navigationItem.leftBarButtonItem = self.editButtonItem;    
	self.title = NSLocalizedString(@"PDX Bus", @"Main Screen title");
#else
    self.title = @"Loading PDX Bus";
#endif
	
    self.viewLoaded = YES;
    if (self.delayedInitialAction)
    {
        [self executeInitialAction];
        self.delayedInitialAction = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	
}

- (void) handleChangeInUserSettings:(id)obj
{
	[self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (_taskList)
	{
		_taskList.observer = self;
	}
	
	if ([_userData favesChanged])
	{
		[_userData cacheAppData];
		_userData.favesChanged = NO;
		//[[(RootViewController *)[self.navigationController topViewController] table] reloadData];	
		
	}	
	
	if (!showingLast)
	{
		[_userData clearLastArrivals];
		//[[(RootViewController *)[self.navigationController topViewController] table] reloadData];	

	}
    
#ifndef LOADINGSCREEN
	self.navigationItem.rightBarButtonItem = self.helpButton;
#endif
	
	[self reloadData];
    [self updateToolbar];
	showingLast = false;
	
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeInUserSettings:) name:NSUserDefaultsDidChangeNotification object:nil];
    
}


- (void)viewDidDisappear:(BOOL)animated {
	if (_taskList)
	{
		_taskList.observer = nil;
	}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

#pragma mark Editing callbacks
// Set the editing state of the view controller. We pass this down to the table view and also modify the content
// of the table to insert a placeholder row for adding content when in editing mode.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    // Calculate the index paths for all of the placeholder rows based on the number of items in each section.
	//	[tableView setEditing:editing animated:animated];
	
	// if ([self.userFaves count] > 0)
	{
		[self.table setEditing:editing animated:animated];
		[self.table beginUpdates];
		[self updatePlaceholderRows:editing];
		[self.table endUpdates];
	}
	
	/*
	 // Workaround for a display bug = the line is missing between this cell and the one before
	 // unless we force it to be re-drawn and re-layed out.
	 if ([self.userFaves count] > 0)
	 {
	 UITableViewCell *prev = [tableView cellForRowAtIndexPath:[NSIndexPath 
	 indexPathForRow:[self.userFaves count]-1
	 inSection:faveSection]];
	 [prev setNeedsDisplay];
	 [prev setNeedsLayout];
	 
	 }
	 */
}



- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	UITextView *textView = (UITextView*)[(CellTextField*)cell view];
	[self postEditingAction:textView];
}


- (void)cancelAction:(id)sender
{
	self.navigationItem.rightBarButtonItem = self.helpButton;
	[self.editWindow resignFirstResponder];
}

-(void)postEditingAction:(UITextView *)textView;
{
	NSString *editText = [self justNumbers:textView.text];
	
	if (editText.length !=0 && (!keyboardUp || self.navigationItem.rightBarButtonItem != self.helpButton ))
	{
		
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
		departureViewController.displayName = @"";
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:editText];
		[departureViewController release];
	}
	else if (keyboardUp)
	{
		[self.editWindow resignFirstResponder];	
	}
	self.navigationItem.rightBarButtonItem = self.helpButton;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	keyboardUp = NO;
	
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = 0;
	
	switch (sectionMap[section])
	{
	case kTableSectionStopId:
        {
            NSMutableArray *rowArray = [[[NSMutableArray alloc] init] autorelease];
            
            [rowArray addObject:[NSNumber numberWithInt:kTableFindRowId]];
            [rowArray addObject:[NSNumber numberWithInt:kTableFindRowBrowse]];
            [rowArray addObject:[NSNumber numberWithInt:kTableFindRowLocate]];
            
            if ([UserPrefs getSingleton].vehicleLocations)
            {
                [rowArray addObject:[NSNumber numberWithInt:kTableFindRowVehicle]];
            }
            
            [rowArray addObject:[NSNumber numberWithInt:kTableFindRowRailStops]];
            
            if ([RailMapView RailMapSupported])
            {
                [rowArray addObject:[NSNumber numberWithInt:kTableFindRowRailMap]];
            }
            
            if (self.ZXingSupported)
            {
                [rowArray addObject:[NSNumber numberWithInt:kTableFindRowQR]];
            }
            
            if ([UserPrefs getSingleton].maxRecentStops != 0)
            {
                [rowArray addObject:[NSNumber numberWithInt:kTableFindRowHistory]];
            }
            
			self.arrivalRows = rowArray;
            rows = rowArray.count;

			break;
        }
	case kTableSectionFaves:
		{
			uint cnt = _userData.faves.count;
			DEBUG_LOG(@"Cnt %d Editing self %d tableview %d\n", cnt, self.editing, tableView.editing);
			rows = cnt + ((cnt==0 || self.editing) ? kTableFaveEditingRows : 0);
			DEBUG_LOG(@"Rows %d\n", rows);

			break;
		}
	case kTableSectionAlarms:
		{
			if (_taskList)
			{
				rows = self.alarmKeys.count;
			}
			break;
		}
    case kTableSectionAbout:
        {
            NSMutableArray *rowArray = [[[NSMutableArray alloc] init] autorelease];
            
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutSettings]];
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutRowAbout]];
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutSupport]];
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutFacebook]];
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutRate]];
            [rowArray addObject:[NSNumber numberWithInt:kTableAboutRowEmail]];
            
            
            self.aboutRows = rowArray;
            rows = rowArray.count;
        }
        break;
	case kTableSectionTriMet:
        {
            NSMutableArray *rowArray = [[[NSMutableArray alloc] init] autorelease];
                        
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetDetours]];
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetAlerts]];
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetTweet]];
            
            [rowArray addObject:[NSNumber numberWithInt:kTableStreetcarTweet]];
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetFacebook]];
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetTicketApp]];
            [rowArray addObject:[NSNumber numberWithInt:kTableTriMetLink]];
            
            if ([self canMakePhoneCall])
			{
                [rowArray addObject:[NSNumber numberWithInt:kTableTriMetCall]];
            }
            
            self.triMetRows = rowArray;
            rows = rowArray.count;
        }
        break;
	case kTableSectionPlanner:
			
			rows = kTableTripRows;
			if ([UserPrefs getSingleton].maxRecentTrips == 0)
			{
				rows--;
			}
			break;
	}
	// printf("Section %d rows %d\n", section, rows);
	return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (sectionMap[section])
	{
		case kTableSectionStopId:
			return @"Show arrivals for stop:";
		case kTableSectionAlarms:
			return @"Alarms:";
		case kTableSectionFaves:
			return @"Bookmarks:";
        case kTableSectionTriMet:
            return @"More info from TriMet:";
		case kTableSectionAbout:
			return @"More app info:";
		case kTableSectionPlanner:
			return @"Trips:";
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;
	
	switch (sectionMap[indexPath.section])
	{
		case kTableSectionStopId:
        {
            NSNumber *row = [self.arrivalRows objectAtIndex:indexPath.row];
			if (row.intValue == kTableFindRowId)
			{
				result = [CellTextField cellHeight];
			}
			else
			{
				result = [self basicRowHeight];
			}
			break;
		}
		case kTableSectionAbout:
        case kTableSectionTriMet:
			result = [self basicRowHeight];
			break;
			
		case kTableSectionFaves:
		case kTableSectionPlanner:
			result = [self basicRowHeight];
			break;

		case kTableSectionAlarms:
			result = [AlarmCell rowHeight:[self screenWidth]];

			break;
	}
	return result;
}

- (void)tableView: (UITableView*)tableView willDisplayCell: (UITableViewCell*)cell forRowAtIndexPath: (NSIndexPath*)indexPath
{
    
    switch(sectionMap[indexPath.section])
	{
		case kTableSectionAlarms:
            if (indexPath.row < self.alarmKeys.count)
			{
               
				AlarmTask *task = [_taskList taskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
                
				if (task!=nil & task.alarmState == AlarmFired)
				{
					cell.backgroundColor =  [UIColor yellowColor];
				}
                else
                {
                    cell.backgroundColor =  [UIColor whiteColor]; 
                }
            }
            break;
            default:
            break;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// DEBUG_LOG(@"cellForRowAtIndexPath %d %d\n", indexPath.section, indexPath.row);
	// [self dumpPath:@"cellForRowAtIndexPath" path:indexPath];
	
	switch(sectionMap[indexPath.section])
	{
		case kTableSectionStopId:
		{
            NSNumber *row = [self.arrivalRows objectAtIndex:indexPath.row];
			switch (row.intValue)
			{
				case kTableFindRowId:
				{
					if (self.editCell == nil)
					{
						self.editCell =  [[[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTextFieldId] autorelease];	
						self.editCell.view = [self createTextField_Rounded];
						self.editCell.delegate = self;
                        
                        if (self.iOS7style)
                        {
                            self.editCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                        else
                        {
                            self.editCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                        }
						self.editCell.imageView.image = [self alwaysGetIcon:kIconEnterStopID]; 
						self.editCell.cellLeftOffset = 50.0;
					}
					// printf("kTableFindRowId %p\n", sourceCell);
					return self.editCell;	
				}
				case kTableFindRowBrowse:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Browse all routes for stop";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon:kIconBrowse]; 
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
				}
				case kTableFindRowRailMap:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Choose from rail maps";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon:kIconMaxMap];
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
				}
                    
			    case kTableFindRowRailStops:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Search rail stations";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon:KIconRailStations]; 
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
				}
                case kTableFindRowVehicle:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Locate the vehicle I'm on";
					cell.textLabel.font = [self getBasicFont];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
					return cell;
				}
				case kTableFindRowLocate:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Locate nearby stops";	
					cell.textLabel.font = [self getBasicFont];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
					return cell;
				}
				case kTableFindRowHistory:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Recent stops";	
					cell.textLabel.font = [self getBasicFont];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon:kIconArrivals]; 
					return cell;
				}
                    
                case kTableFindRowQR:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
					}
					
					// Set up the cell
					cell.textLabel.text = @"Scan TriMet QR Code";	
					cell.textLabel.font = [self getBasicFont];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon7:kIconCameraAction7 old:kIconCameraAction];
					return cell;
				}
			}
		}
		case kTableSectionFaves:
		{
			// printf("fave row: %d count %d\n", indexPath.row, [self.userFaves count]);
			UITableViewCell *cell;
			if (indexPath.row < _userData.faves.count)
			{
				// printf("go!\n");
				cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
				}
				
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
				
				// Set up the cell
				@synchronized (_userData)
				{
					NSDictionary *item = (NSDictionary *)[_userData.faves objectAtIndex:indexPath.row];
					// printf("item %p\n", item);
				
					cell.textLabel.text = [item valueForKey:kUserFavesChosenName];
					cell.textLabel.font = [self getBasicFont];
					// cell.imageView.image = [TableViewWithToolbar getIcon:@"Favourites.png"]; 
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
				
				
					if ([item valueForKey:kUserFavesTrip] != nil)
					{
						cell.imageView.image = [self getFaveIcon:kIconTripPlanner];
					}
					else // if ([item valueForKey:kUserFavesLocation] != nil)
					{
						NSNumber *morning = [item valueForKey:kUserFavesMorning];
						NSNumber *day     = [item valueForKey:kUserFavesDayOfWeek];
						if (day && [day intValue]!=kDayNever)
						{
							if (morning == nil || [morning boolValue])
							{
								cell.imageView.image = [self getFaveIcon:kIconMorning]; 
							}
							else 
							{
								cell.imageView.image = [self getFaveIcon:kIconEvening]; 
							}
						}
						else 
						{
							cell.imageView.image = [self getFaveIcon:kIconFave]; 
						}

						
					}
				}
			}
			else
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kNewBookMark];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kNewBookMark] autorelease];
				}
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.font = [self getBasicFont];
				cell.editingAccessoryType = cell.accessoryType;
				switch (indexPath.row - _userData.faves.count)
				
				{
					case kTableFaveAdd:
						cell.textLabel.text = @"Add new stop";
						cell.imageView.image = [self getFaveIcon:kIconFave];
						break;
					case kTableFaveTrip:
						cell.textLabel.text = @"Add new trip";
						cell.imageView.image = [self getFaveIcon:kIconTripPlanner];
						break;
				}
			}
			
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:NO];
			return cell;
		}
		case kTableSectionTriMet:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAboutId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAboutId] autorelease];
			}
			
			NSNumber *row = [self.triMetRows objectAtIndex:indexPath.row];
			
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
			
			switch (row.intValue)
			{
				
				case kTableTriMetCall:
					cell.textLabel.text = @"Call TriMet on 503-238-RIDE";
					cell.imageView.image =  [self getActionIcon:kIconPhone]; 
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case kTableTriMetLink:
					cell.textLabel.text = @"Visit TriMet online";
					cell.imageView.image = [self getActionIcon:kIconTriMetLink];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
                case kTableTriMetTweet:
					cell.textLabel.text = @"@TriMet on Twitter";
					cell.imageView.image = [self getActionIcon:kIconTwitter];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
                case kTableStreetcarTweet:
					cell.textLabel.text = @"@PDXStreetcar on Twitter";
					cell.imageView.image = [self getActionIcon:kIconTwitter];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
                case kTableTriMetTicketApp:
					cell.textLabel.text = @"TriMet Tickets app";
					cell.imageView.image = [self getActionIcon:kIconTicket];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableTriMetAlerts:
					cell.textLabel.text = @"Rider alerts";
					cell.imageView.image = [self getActionIcon:kIconAlerts];  
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableTriMetDetours:
					cell.textLabel.text = @"All detours";
					cell.imageView.image = [self getActionIcon:kIconDetour];  
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
                case kTableTriMetFacebook:
					cell.textLabel.text = @"TriMet's Facebook Page";
					cell.imageView.image = [self getActionIcon:kIconFacebook];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;

			}
			cell.textLabel.font = [self getBasicFont];
			return cell;
		}
        case kTableSectionAbout:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAboutId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAboutId] autorelease];
			}
            
            NSNumber *row = [self.aboutRows objectAtIndex:indexPath.row];
			
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
            
			switch (row.intValue)
			{
                case kTableAboutSettings:
					cell.textLabel.text = @"Settings";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconSettings];
					break;    
				case kTableAboutRowAbout:
					cell.textLabel.text = @"About & legal";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconAbout];
					break;
                case kTableAboutSupport:
					cell.textLabel.text = @"Help, Tips & support";
					cell.imageView.image = [self getActionIcon:kIconXml];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableAboutFacebook:
					cell.textLabel.text = @"PDX Bus Fan Page";
					cell.imageView.image = [self getActionIcon:kIconFacebook];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableAboutRowEmail:
					cell.textLabel.text = @"Email bookmarks";
					cell.imageView.image = [self getActionIcon:kIconEmail];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableAboutRate:
					cell.textLabel.text = @"Rate PDX Bus in the App Store";
                    cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.imageView.image = [self getActionIcon:kIconAward];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
			}
			cell.textLabel.font = [self getBasicFont];
			return cell;
		}
		case kTableSectionAlarms:
		{
			UITableViewCell *cell = nil;
			
			if (indexPath.row < self.alarmKeys.count)
			{
				AlarmTask *task = [_taskList taskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
			
				if (task!=nil)
				{
					NSString *cellId = [task cellReuseIdentifier:kAlarmCellId width:[self screenWidth]];
					cell = [tableView dequeueReusableCellWithIdentifier:cellId];
					if (cell == nil)
					{
						cell = [AlarmCell tableviewCellWithReuseIdentifier:cellId 
																width:[self screenWidth] 
															   height:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
					
					}
					
					[task populateCell:(AlarmCell*)cell];
					
					[((AlarmCell*)cell) resetState];

					cell.imageView.image = [self getActionIcon:task.icon];
                    
				}
			}
			
			
			
			if (cell  == nil)
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kAboutId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAboutId] autorelease];
				}
				
				cell.textLabel.text = nil;
				
				cell.textLabel.text = @"Alarm completed";
				cell.imageView.image = nil;
				cell.accessoryType  = UITableViewCellAccessoryNone;
			}
			
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			cell.editingAccessoryType = cell.accessoryType;
			
			return cell;
		}	
		case kTableSectionPlanner:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainId] autorelease];
			}
			
			switch( indexPath.row )
			{
				case kTableTripRowPlanner:
					// Set up the cell
					cell.textLabel.text = @"Trip planner";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconTripPlanner];
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
				case kTableTripRowCache:
					// Set up the cell
					cell.textLabel.text = @"Recent trips";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconHistory];
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
			}
		}
	}
	
	return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath;
}

-(NSString*)propertyListToHex:(NSDictionary *)item
{
	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:item format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];						
	
	if (data != nil)
	{
		NSMutableString *hex = [[[NSMutableString alloc] init] autorelease];
		
		for (int i=0; i<data.length; i++)
		{
			[hex appendFormat:@"%02X", ((unsigned char*)data.bytes)[i]];
		}
		
		return hex;
	}
	
	return nil;
}

- (void)openFave:(int)index allowEdit:(bool)allowEdit
{
    NSMutableDictionary *item = nil;
    NSString *location = nil;
    TripUserRequest *req = nil;
    NSMutableDictionary *tripItem = nil;
    
    if (index < _userData.faves.count)
    {
        @synchronized (_userData)
        {
            item = (NSMutableDictionary *)[_userData.faves objectAtIndex:index];
            location = [item valueForKey:kUserFavesLocation];
            tripItem = [item valueForKey:kUserFavesTrip];
            req = [[[TripUserRequest alloc] initFromDict:tripItem] autorelease];
        }
    }
    if (    allowEdit
        &&  (self.table.editing
             || _userData.faves.count==0
             || (tripItem==nil && item!=nil && ((location==nil) || ([location length] == 0)))
             || (tripItem !=nil
                 && req !=nil
                 && req.fromPoint.locationDesc==nil
                 && req.fromPoint.useCurrentLocation == false)))
    {
        switch (index - _userData.faves.count)
        {
            default:
            {
                EditBookMarkView *edit = [[EditBookMarkView alloc] init];
                [edit editBookMark:item item:index];
                [[self navigationController] pushViewController:edit animated:YES];
                [edit release];
                break;
            }
            case kTableFaveAdd:
            {
                EditBookMarkView *edit = [[EditBookMarkView alloc] init];
                [edit addBookMark];
                [[self navigationController] pushViewController:edit animated:YES];
                [edit release];
                break;
            }
            case kTableFaveTrip:
            {
                EditBookMarkView *edit = [[EditBookMarkView alloc] init];
                [edit addTripBookMark];
                [[self navigationController] pushViewController:edit animated:YES];
                [edit release];
                break;
            }
        }
    }
    else if (location !=nil)
    {
        DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
        
        
        [departureViewController fetchTimesForLocationInBackground:self.backgroundTask
                                                               loc:location
                                                             title:[item valueForKey:kUserFavesChosenName]];
        [departureViewController release];
    }
    else
    {
        TripPlannerDateView *tripDate = [[TripPlannerDateView alloc] init];
        
        [tripDate initializeFromBookmark:req];
        @synchronized (_userData)
        {
            [tripDate.tripQuery addStopsFromUserFaves:_userData.faves];
        }
        
        // Push the detail view controller
        [tripDate nextScreen:[self navigationController] taskContainer:self.backgroundTask];
        [tripDate release];
        
    }

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationItem.rightBarButtonItem == self.goButton)
    {
        self.navigationItem.rightBarButtonItem = self.helpButton;
        [self.editWindow resignFirstResponder];
    }
	
    switch(sectionMap[indexPath.section])
    {
        case kTableSectionStopId:
        {
            NSNumber *row = [self.arrivalRows objectAtIndex:indexPath.row];
            switch (row.intValue)
            {
                case kTableFindRowId:
                {
                    
                    UITextView *textView = (UITextView*)[self.editCell view];
                    
                    NSString *editText = [self justNumbers:textView.text];
                    
                    if ([editText length] == 0)
                    {
                        return;
                    }
                    
                    
                    if (keyboardUp)
                    {
                        [self.editWindow resignFirstResponder];
                    }
                    else
                    {
                        // UITextView *textView = (UITextView*)[self.editCell view];
                        [self postEditingAction:textView];
                    }
                    break;
                }
                case kTableFindRowBrowse:
                {
                    RouteView *routeViewController = [[RouteView alloc] init];
                    
                    [routeViewController fetchRoutesInBackground:self.backgroundTask];
                    
                    [routeViewController release];
                    break;
                }
                case kTableFindRowLocate:
                {
                    FindByLocationView *findView = [[FindByLocationView alloc] init];
                    
                    
                    // Push the detail view controller
                    [[self navigationController] pushViewController:findView animated:YES];
                    [findView release];
                    break;
                }
                case kTableFindRowVehicle:
                {
                    VehicleLocatingTableView *findView = [[VehicleLocatingTableView alloc] init];
                    [[self navigationController] pushViewController:findView animated:YES];
                    [findView release];
                    break;
                }

                    
                case kTableFindRowRailMap:
                {
                    
                    RailMapView *webPage = [[RailMapView alloc] init];
                    [[self navigationController] pushViewController:webPage animated:YES];
                    [webPage release];
                    break;
                    
                }
                case kTableFindRowRailStops:
                {
                    
                    AllRailStationView *allRail = [[AllRailStationView alloc] init];
                    [[self navigationController] pushViewController:allRail animated:YES];
                    [allRail release];
                    break;
                    
                }
                case kTableFindRowHistory:
                {
                    
                    DepartureHistoryView *history = [[DepartureHistoryView alloc] init];
                    [[self navigationController] pushViewController:history animated:YES];
                    [history release];
                    break;
                    
                }
                    
                case kTableFindRowQR:
                {   
                    if (![self QRCodeScanner])
                    {
                        [self clearSelection];
                    }
                }
            }
            
            
            break;
        }
        case kTableSectionFaves:
        {
            [self openFave:indexPath.row allowEdit:YES];
            break;
        }
        case kTableSectionAlarms:
        {			 
            if (indexPath.row < self.alarmKeys.count)
            {
                AlarmTask *task = [_taskList taskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
                
                if (task !=nil)
                {
                    [task showToUser:self.backgroundTask];
                }
            }
            
            break;
            
        }
        case kTableSectionTriMet:
        {
			NSNumber *row = [self.triMetRows objectAtIndex:indexPath.row];
            
			switch (row.intValue)
            {
                case kTableStreetcarTweet:
                {
                    self.tweetAt   = @"PDXStreetcar";
                    self.initTweet = @"@PDXStreetcar #pdxbus";
                    
                    [self tweet];
                    break;
                }
                case kTableTriMetTweet:
                {
                    self.tweetAt   = @"TriMet";
                    self.initTweet = @"@TriMet #pdxbus";
                    
                    [self tweet];
                    break;
                }
                    
                case kTableTriMetTicketApp:
                {
                    [self ticketApp];
                    break;
                }
                    
                case kTableTriMetCall:
                {
                    if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:callString]])
                    {
                        // there was an error trying to open the URL. for the moment we'll simply ignore it.
                    }
                    break;
                }
                case kTableTriMetLink:
                {
                    WebViewController *webPage = [[WebViewController alloc] init];
                    [webPage setURLmobile:@"http://trimet.org" full:nil title:@"TriMet.org"]; 
                    [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
                    [webPage release];
                    break;
                }
                case kTableTriMetAlerts:
                {
                    WebViewController *webPage = [[WebViewController alloc] init];
                    [webPage setURLmobile:@"http://trimet.org/m/alerts" full:nil title:@"TriMet.org"]; 
                    [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
                    [webPage release];
                    break;
                    
                    /*
                    RssView *rss = [[RssView alloc] init];
                    [rss fetchRssInBackground:self.backgroundTask url:@"http://service.govdelivery.com/service/rss/item_updates.rss?code=ORTRIMET_24"];
                    [rss release];
                     */
                    
                    /*
                     WebViewController *webPage = [[WebViewController alloc] init];
                     [webPage setURL:@"http://trimet.org/alerts/small/index.htm"  title:@"Rider Alerts"]; 
                     [[self navigationController] pushViewController:webPage animated:YES];
                     [webPage release];
                     */ 
                    
                    break;
                    
                }
                case kTableTriMetDetours:
                {
                    DetoursView *detourView = [[DetoursView alloc] init];
                    [detourView fetchDetoursInBackground:self.backgroundTask];
                    
                    [detourView release];
                    break;
                }
                case kTableTriMetFacebook:
                {
                    [self facebookTriMet];
                    break;
                }
            }
        }
        break;
            
        case kTableSectionAbout:
        {
            
            NSNumber *row = [self.aboutRows objectAtIndex:indexPath.row];
            
            switch (row.intValue)
            {
                case kTableAboutSettings:
                {				
                    self.settingsView = [[[IASKAppSettingsViewController alloc] init] autorelease];
                    
                    self.settingsView.showDoneButton = NO;
                    // Push the detail view controller
                    [[self navigationController] pushViewController:self.settingsView animated:YES];
                    
                    break;
                }	    
                case kTableAboutRowAbout:
                {				
                    AboutView *aboutView = [[AboutView alloc] init];
                    
                    // Push the detail view controller
                    [[self navigationController] pushViewController:aboutView animated:YES];
                    [aboutView release];
                    break;
                }			
                case kTableAboutSupport:
                {
                    SupportView  *supportView = [[SupportView alloc] init];
                    
                    // Push the detail view controller
                    [[self navigationController] pushViewController:supportView animated:YES];
                    [supportView release];
                    
                    break;
                }
                case kTableAboutRate:
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                // @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=289814055"]];
                                                                @"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=289814055&mt=8"]];       
                    [self.table deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }    
                    
                case kTableAboutFacebook:
                    
                {
                    [self facebook];
                    break;
                }
                case kTableAboutRowEmail:
                {
                    @synchronized (_userData)
                    {
                        MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
                        
                        email.mailComposeDelegate = self;
                        
                        if (![MFMailComposeViewController canSendMail])
                        {
                            UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"email"
                                                                               message:@"Cannot send email on this device"
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil] autorelease];
                            [alert show];
                            [email release];
                            break;
                        }
                        
                        [email setSubject:@"PDX Bus Bookmarks"];
                        
                        // NSMutableString *mailto = [[[NSMutableString alloc] initWithFormat:@"mailto:?subject=PDXBus%%20Bookmarks&body="] autorelease];
                        NSMutableString *body = [[NSMutableString alloc] init];
                        NSDictionary *item;
                        
                        [body appendFormat:@"Click on a link to add a bookmark to PDXBus (requires version 4.3 or better).<br><br>"];
                        
                        int i;
                        for (i=0; i< [_userData.faves count]; i++)
                        {
                            
                            item = (NSDictionary *)[_userData.faves objectAtIndex:i];
                            if ([item valueForKey:kUserFavesLocation] != nil)
                            {
                                [body appendFormat:@"<a href=\"pdxbus2://?d%@/\">%@</a> - %@<br>",
                                 [self propertyListToHex:item],
                                 [item valueForKey:kUserFavesChosenName],
                                 [item valueForKey:kUserFavesLocation]];
                            }
                            else 
                            {
                                [body appendFormat:@"<a href=\"pdxbus2://?d%@/\">%@</a> - Trip Planner Bookmark<br>",
                                 [self propertyListToHex:item],[item valueForKey:kUserFavesChosenName]];						
                            }
                        }
                        
                        [body appendFormat:@"<br><br>"];
                        
                        
                        [body appendFormat:@"<a href = \"pdxbus2://"];
                        for (i=0; i< _userData.faves.count; i++)
                        {
                            item = (NSDictionary *)[_userData.faves objectAtIndex:i];
                            [body appendFormat:@"?d%@/",
                             [self propertyListToHex:item]];						
                        }
                        [body appendFormat:@"\">Add all bookmarks</a>"];
                        
                        [email setMessageBody:body isHTML:YES];
                        
                        [self presentModalViewController:email animated:YES];
                        [email release];
                        
                        DEBUG_LOG(@"BODY\n%@\n", body);
                        
                        [body release];
                        
                    }
                }
            }
            break;
        }
        case kTableSectionPlanner:
			if (indexPath.row == kTableTripRowPlanner)
			{
				[self tripPlanner:YES];
			}
			else 
			{
				TripPlannerCacheView *tripCache = [[TripPlannerCacheView alloc] init];
				// Push the detail view controller
				[[self navigationController] pushViewController:tripCache animated:YES];
				[tripCache release];
			}
        }
}



 // Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	bool editingSet = false;
	DEBUG_LOG(@"delete r %d  s %d\n", indexPath.row, indexPath.section);
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row from the data source
//		[self.table beginUpdates];
		switch (sectionMap[indexPath.section])
		{
			case kTableSectionFaves:
				@synchronized(_userData)
				{	
					if (_userData.faves.count == 1 && !self.editing)
					{
						editingSet = YES;
						[self setEditing:YES animated:YES];
					}
					[_userData.faves removeObjectAtIndex:indexPath.row];
					[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
					[_userData cacheAppData];
				
					if (editingSet)
					{
						[self setEditing:NO animated:YES];
					}
				}
				break;
			case kTableSectionAlarms:
				[_taskList cancelTaskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
				NSMutableArray *newKeys = [[[NSMutableArray alloc] initWithArray:self.alarmKeys] autorelease];
				[newKeys removeObjectAtIndex:indexPath.row];
				self.alarmKeys = newKeys;
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				
				if (self.alarmKeys.count == 0)
				{
					[self reloadData];
				}
				break;
		}
//		[self.table endUpdates];

	}	
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
		EditBookMarkView *edit = [[EditBookMarkView alloc] init];
		[edit addBookMark];
		// Push the detail view controller
		[[self navigationController] pushViewController:edit animated:YES];
		[edit release];
	}	
}


// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (sectionMap[indexPath.section])
	{
		case kTableSectionFaves:
			switch (indexPath.row - _userData.faves.count)
			{
				default:				
					return UITableViewCellEditingStyleDelete;
				case kTableFaveAdd:
				case kTableFaveTrip:
					return UITableViewCellEditingStyleInsert;
			}
			return UITableViewCellEditingStyleNone;
		case kTableSectionAlarms:
			return UITableViewCellEditingStyleDelete;
			
	}
	return UITableViewCellEditingStyleNone;
}



 // Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the specified item to be editable.
	
	switch(sectionMap[indexPath.section])
	{
		case kTableSectionStopId:
			return NO;
		case kTableSectionFaves:
			return YES;
		case kTableSectionAlarms:
			return YES;
		case kTableSectionAbout:
			return NO;
	}	
	return NO;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	// printf("********HERE\n");
	uint srcSection = sectionMap[sourceIndexPath.section];
	
	int sectionMax=1;
	
	switch (srcSection)
	{
		case kTableSectionFaves:
			sectionMax = _userData.faves.count;
			break;
			
	}
	
	if (proposedDestinationIndexPath.section < sourceIndexPath.section)
	{
		return [NSIndexPath 
				indexPathForRow:0
				inSection:sourceIndexPath.section];
	}
	if (proposedDestinationIndexPath.section > sourceIndexPath.section)
	{
		return [NSIndexPath 
				indexPathForRow:sectionMax-1
				inSection:sourceIndexPath.section];
	}
	if (proposedDestinationIndexPath.row >= sectionMax)
	{
		return [NSIndexPath 
				indexPathForRow:sectionMax-1
				inSection:sourceIndexPath.section];
	}
	return proposedDestinationIndexPath;
	
}

 
/*
// Have an accessory view for the second section only
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return (sectionMap[indexPath.section] == kTableSectionFaves && indexPath.row < [self.userFaves count] && self.editing) 
				? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
}
*/

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
//	[self dumpPath:@"moveRowAtIndexPath from" path:fromIndexPath];
//	[self dumpPath:@"moveRowAtIndexPath to  " path:toIndexPath];
	
	switch (sectionMap[fromIndexPath.section])
	{
		case kTableSectionFaves:
		{
			if (sectionMap[toIndexPath.section] == kTableSectionFaves)
			{
				@synchronized (_userData)
				{
					NSDictionary *move = [[_userData.faves objectAtIndex:fromIndexPath.row] retain];
				
					if (fromIndexPath.row < toIndexPath.row)
					{
						[_userData.faves insertObject:move atIndex:toIndexPath.row+1];
						[_userData.faves removeObjectAtIndex:fromIndexPath.row];
					}
					else
					{
						[_userData.faves removeObjectAtIndex:fromIndexPath.row];
						[_userData.faves insertObject:move atIndex:toIndexPath.row];
					}
					[move release];
					[_userData cacheAppData];
				}
			}

			break;
		}
	}
//	[tableView reloadData];
}




 // Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the item to be re-orderable.
	switch (sectionMap[indexPath.section]) {
		case kTableSectionFaves:
			if (indexPath.row < _userData.faves.count)
			{
				return YES;
			}
			return NO;
		default:
			break;
	}
	return NO;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	switch(sectionMap[indexPath.section])
	{
		case kTableSectionAlarms:
		{
			if (self.navigationItem.rightBarButtonItem == self.goButton)
			{
				self.navigationItem.rightBarButtonItem = self.helpButton;
				[self.editWindow resignFirstResponder];
			}
	
			if (indexPath.row < self.alarmKeys.count)
			{
#ifdef DEBUG_ALARMS	
				AlarmTask *task = [_taskList taskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
				LocationServicesDebugView *debugView = [[LocationServicesDebugView alloc] init];
				debugView.data = task;
				[[self navigationController] pushViewController:debugView animated:YES];
				[debugView release];
#else
                [_taskList cancelTaskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
#endif
			}

			break;
			
		}
		case kTableSectionStopId:
		{
			
			UITextView *textView = (UITextView*)[self.editCell view];
			
			NSString *editText = [self justNumbers:textView.text];
			
			if ([editText length] == 0)
			{
				return;
			}
			
			
			if (keyboardUp)
			{
				[self.editWindow resignFirstResponder];
			}
			else
			{
				// UITextView *textView = (UITextView*)[self.editCell view];
				[self postEditingAction:textView];
			}
			break;
		}
	}
}

#pragma mark Mail Composer callbacks

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark Alarm tasks callbacks
- (void)taskUpdate:(id)task
{
	AlarmTask *realTask = (AlarmTask *)task;
	
	int alarmSection = -1;
	int i=0;
	
	// Find the alarm section
	for (i=0; i<sections; i++)
	{
		if (sectionMap[i] == kTableSectionAlarms)
		{
			alarmSection = i;
			break;
		}
	}
	
	if (alarmSection !=-1)
	{
		i=0;
		for (NSString *key in self.alarmKeys)
		{
			if ([key isEqualToString:[realTask key]])
			{
				[self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i
																							   inSection:alarmSection]] 
								  withRowAnimation:UITableViewRowAnimationNone];
				
			}
			i++;
		}
	}
}

- (void)taskStarted:(id)task
{
	
}

- (void)taskDone:(id)task
{
	if (!self.table.editing)
	{
		[self reloadData];
	}
}

#pragma mark -
#pragma mark ZXingDelegateMethods


- (bool)ZXingSupported
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (device != nil)
        {
            return YES;
        }
    }
    
    return NO ;
}


- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)result {
    [self dismissModalViewControllerAnimated:YES];
    
    /*
    UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"QR Code read"
                                                       message:result
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil ] autorelease];
    [alert show]; 
    */
    
    DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
    [departureViewController fetchTimesViaQrCodeRedirectInBackground:self.backgroundTask URL:result];
    [departureViewController release];
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller {
    [self.progressView removeFromSuperview];
    self.progressView= nil;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)zxingControllerDidDisplay:(ZXingWidgetController *)controller
{
    [self.progressView removeFromSuperview];
    self.progressView= nil;
}

- (void)didEnterBackground
{
    [self.progressView removeFromSuperview];
    self.progressView= nil;
    [self dismissModalViewControllerAnimated:YES];  
}




@end


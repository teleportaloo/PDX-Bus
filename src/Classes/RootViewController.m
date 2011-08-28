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
#define kTableTriMetCall		3
#define kTableTriMetRowsNoPhone 3
#define kTableTriMetRowsPhone	4


#define kTableAboutSettings     0
#define kTableAboutRowAbout     1
#define kTableAboutTwitter		2
#define kTableAboutFacebook		3
#define kTableAboutRate         4
#define kTableAboutRowEmail     5
#define kTableAboutRows         6


#define kTableFindRowId			0
#define kTableFindRowBrowse		1
#ifdef ALL_RAIL_STATIONS
#define kTableFindRowLocate		2
#define kTableFindRowRailStops	3
#define kTableFindRowRailMap	4
#define kTableFindRowHistory	5
#else
#define kTableFindRowLocate		2
#define kTableFindRowRailMap	3
#define kTableFindRowHistory	4
#endif

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


@implementation RootViewController
@synthesize editWindow			= _editWindow;
@synthesize lastArrivalsShown	= _lastArrivalsShown;
@synthesize editCell			= _editCell;
@synthesize lastArrivalNames    = _lastArrivalNames;
@synthesize alarmKeys			= _alarmKeys;
@synthesize commuterBookmark	= _commuterBookmark;
@synthesize settingsView        = _settingsView;


- (void)dealloc {
	self.editWindow			= nil;
	self.lastArrivalsShown	= nil;
	self.editCell			= nil;
	self.lastArrivalNames	= nil;
	self.alarmKeys			= nil;
	self.commuterBookmark   = nil;
    self.settingsView       = nil;
	[super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (void)createToolbarItems
{
	NSArray *items = nil;
	
	if (_prefs.commuteButton)
	{
		items = [NSArray arrayWithObjects: 
					  [CustomToolbar autoCommuteWithTarget:self action:@selector(commuteAction:)],
					  [CustomToolbar autoFlexSpace], 
					  [self autoBigFlashButton], nil];
	}
	else 
	{
		items = [NSArray arrayWithObjects: 
				 [CustomToolbar autoFlexSpace], 
				 [self autoBigFlashButton], nil];
	}

	[self setToolbarItems:items animated:NO];
}

#pragma mark UI Helper functions

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

- (void)infoAction:(id)sender
{
	AboutView *aboutView = [[AboutView alloc] init];
	
	// Push the detail view controller
	[[self navigationController] pushViewController:aboutView animated:YES];
	[aboutView release];
	
}

- (bool)canMakePhoneCall
{
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:callString]];
}

- (bool)maybeShowLast
{
	DEBUG_PRINTF("Last arrivals: %s LSD %d\n", [self.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding], _prefs.lastScreenDisplayed);
	
	if (self.commuterBookmark)
	{
		[_userData clearLastArrivals];
		
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask 
															   loc:[self.commuterBookmark valueForKey:kUserFavesLocation]
															 title:[self.commuterBookmark valueForKey:kUserFavesChosenName]
		 ];
		[departureViewController release];		
		showingLast = true;
		self.commuterBookmark = nil;
		return true;
	}
	else if (self.lastArrivalsShown!=nil && _prefs.lastScreenDisplayed)
	{
		NSString *localCopyLastArrivals = [self.lastArrivalsShown retain];
		NSArray *localCopyLastNames = [self.lastArrivalNames retain];
		self.lastArrivalsShown = nil;
		self.lastArrivalNames = nil;
				
		[_userData clearLastArrivals];
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
		departureViewController.displayName = nil;
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:localCopyLastArrivals names:localCopyLastNames];
		[departureViewController release];
		[localCopyLastArrivals release];
		[localCopyLastNames release];
		showingLast = true;
		return true;
	}
	return false;
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
	
	
	UIBarButtonItem *goButton = [[[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
								  target:self
								  action:@selector(editGoAction:)] autorelease];
	
	self.navigationItem.leftBarButtonItem = cancelButton;
	self.navigationItem.rightBarButtonItem = goButton;
	
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
	if (_prefs.bookmarksAtTheTop)
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

- (void) handleChangeInUserSettings:(id)obj
{
	[self reloadData];
	[self createToolbarItems];
}

- (bool)initMembers
{
	bool result = [super initMembers];
	
	if ([AlarmTaskList supported])
	{
		_taskList = [AlarmTaskList getSingleton];
	}
	if (result)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeInUserSettings:) name:NSUserDefaultsDidChangeNotification object:nil];	
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
	// Add the following line if you want the list to be editable
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.title = NSLocalizedString(@"PDX Bus", @"RootViewController title");	
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
	else if (![self maybeShowLast] && _prefs.displayTripPlanning)
	{
		[self tripPlanner:NO];
	}
	DEBUG_PRINTF("Last arrivals: %s LSD %d\n", [self.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding], _prefs.lastScreenDisplayed);
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	
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
	
	UIBarButtonItem *info = [[[UIBarButtonItem alloc]
							  initWithTitle:@"Help"
							  style:UIBarButtonItemStyleBordered
							  target:self action:@selector(infoAction:)] autorelease];
	
	
	self.navigationItem.rightBarButtonItem = info;
	
	
	[self reloadData];
	showingLast = false;
	
}

- (void)viewWillDisappear:(BOOL)animated {
	
}

- (void)viewDidDisappear:(BOOL)animated {
	if (_taskList)
	{
		_taskList.observer = nil;
	}
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
	self.navigationItem.rightBarButtonItem = nil;
	[self.editWindow resignFirstResponder];
}

-(void)postEditingAction:(UITextView *)textView;
{
	NSString *editText = [self justNumbers:textView.text];
	
	if (editText.length !=0 && (!keyboardUp || self.navigationItem.rightBarButtonItem != nil ))
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
	self.navigationItem.rightBarButtonItem = nil;
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
#ifdef ALL_RAIL_STATIONS
			rows = 6;
#else
			rows = 5;
#endif
			if (_prefs.maxRecentStops == 0)
			{
				rows--;
			}

			break;
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
            rows = kTableAboutRows;
            break;
	case kTableSectionTriMet:
			if ([self canMakePhoneCall])
			{
				rows = kTableTriMetRowsPhone;
			}
			else {
				rows = kTableTriMetRowsNoPhone;
			}

			break;
	case kTableSectionPlanner:
			
			rows = kTableTripRows;
			if (_prefs.maxRecentTrips == 0)
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
            return @"More travel info:";
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
			if (indexPath.row == 0)
			{
				result = [CellTextField cellHeight];
			}
			else
			{
				result = [self basicRowHeight];
			}
			break;
		
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
			switch (indexPath.row)
			{
				case kTableFindRowId:
				{
					if (self.editCell == nil)
					{
						self.editCell =  [[[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTextFieldId] autorelease];	
						self.editCell.view = [self createTextField_Rounded];
						self.editCell.delegate = self;
						self.editCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
						self.editCell.imageView.image = [self alwaysGetIcon:kIconEnterStopID]; 
						self.editCell.cellLeftOffset = 40.0;
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
					cell.textLabel.text = @"Choose from rail map";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
					cell.imageView.image = [self getActionIcon:kIconRailMap]; 
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					return cell;
				}
#ifdef ALL_RAIL_STATIONS
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
#endif
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
					cell.imageView.image = [self getActionIcon:kIconLocate]; 
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
						if (day && morning && [day intValue]!=kDayNever)
						{
							if ([morning boolValue])
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
			
			int row = indexPath.row;
			
			// Skip the phone button on touch or iPad
			
			if (![self canMakePhoneCall] && row >= kTableTriMetCall)
			{
				row++;
			}
            
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
			
			switch (row)
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
			
			int row = indexPath.row;
			
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
            
			switch (row)
			{
                case kTableAboutSettings:
					cell.textLabel.text = @"Settings";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconSettings];
					break;    
				case kTableAboutRowAbout:
					cell.textLabel.text = @"Tips, Links & About";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconAbout];
					break;
				case kTableAboutTwitter:
					cell.textLabel.text = @"Twitter @pdxbus";
					cell.imageView.image = [self getActionIcon:kIconTwitter];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kTableAboutFacebook:
					cell.textLabel.text = @"Facebook Fan Page";
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {	
    if (self.navigationItem.rightBarButtonItem != nil)
    {
        self.navigationItem.rightBarButtonItem = nil;
        [self.editWindow resignFirstResponder];
    }
	
	int row = indexPath.row;
    
    switch(sectionMap[indexPath.section])
    {
        case kTableSectionStopId:
        {
            switch (row)
            {
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
                case kTableFindRowRailMap:
                {
                    
                    RailMapView *webPage = [[RailMapView alloc] init];
                    [[self navigationController] pushViewController:webPage animated:YES];
                    [webPage release];
                    break;
                    
                }
#ifdef ALL_RAIL_STATIONS
                case kTableFindRowRailStops:
                {
                    
                    AllRailStationView *allRail = [[AllRailStationView alloc] init];
                    [[self navigationController] pushViewController:allRail animated:YES];
                    [allRail release];
                    break;
                    
                }
#endif
                case kTableFindRowHistory:
                {
                    
                    DepartureHistoryView *history = [[DepartureHistoryView alloc] init];
                    [[self navigationController] pushViewController:history animated:YES];
                    [history release];
                    break;
                    
                }
            }
            
            
            break;
        }
        case kTableSectionFaves:
        {
            NSMutableDictionary *item = nil;
            NSString *location = nil;
            TripUserRequest *req = nil;
            NSMutableDictionary *tripItem = nil;
            
            if (row < _userData.faves.count)
            {
                @synchronized (_userData)
                {
                    item = (NSMutableDictionary *)[_userData.faves objectAtIndex:indexPath.row];
                    location = [item valueForKey:kUserFavesLocation];
                    tripItem = [item valueForKey:kUserFavesTrip];
                    req = [[[TripUserRequest alloc] initFromDict:tripItem] autorelease];
                }
            }
            if (tableView.editing || _userData.faves.count==0 || (tripItem==nil && item!=nil && ((location==nil) || ([location length] == 0)))
                || (tripItem !=nil && req !=nil && req.fromPoint.locationDesc==nil && req.fromPoint.useCurrentLocation == false))
            {
                switch (indexPath.row - _userData.faves.count)
                {	 
					default:
					{
						EditBookMarkView *edit = [[EditBookMarkView alloc] init];
						[edit editBookMark:item item:indexPath.row];
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
            
			// Skip the phone button on touch or iPad
            
			if (![self canMakePhoneCall] && row >= kTableTriMetCall)
			{
                row++;
			}
            
			switch (row)
            {
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
                    [[self navigationController] pushViewController:webPage animated:YES];
                    [webPage release];
                    break;
                }
                case kTableTriMetAlerts:
                {
                    WebViewController *webPage = [[WebViewController alloc] init];
                    [webPage setURLmobile:@"http://trimet.org/m/alerts" full:nil title:@"TriMet.org"]; 
                    [[self navigationController] pushViewController:webPage animated:YES];
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
            }
        }
			break;
        case kTableSectionAbout:
            
            // Skip the phone button on touch or iPad
            
            switch (row)
            {
                case kTableAboutSettings:
                {				
                    self.settingsView = [[IASKAppSettingsViewController alloc] init];
                    
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
                case kTableAboutTwitter:
                {
                    WebViewController *webPage = [[WebViewController alloc] init];
                    //[webPage setRSS:@"http:://twitter.com/statuses/user_timeline/78506125.rss"  title:@"@pdxbus"];
                    [webPage setURLmobile:@"http://mobile.twitter.com/pdxbus" full:@"http://www.twitter.com/pdxbus" title:@"@pdxbus"]; 
                    webPage.showErrors = NO;
                    [[self navigationController] pushViewController:webPage animated:YES];
                    [webPage release];
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
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.facebook.com/PDXBus"]];
                    [self.table deselectRowAtIndexPath:indexPath animated:YES];
                    
                    /*
                     WebViewController *webPage = [[WebViewController alloc] init];
                     //[webPage setRSS:@"http:://twitter.com/statuses/user_timeline/78506125.rss"  title:@"@pdxbus"];
                     [webPage setURLmobile:@"http://touch.facebook.com/PDXBus" full:@"http://www.facebook.com/PDXBus" title:@"Facebook"]; 
                     webPage.showErrors = NO;
                     [[self navigationController] pushViewController:webPage animated:YES];
                     [webPage release];
                     */
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
                             [self propertyListToHex:item],[item valueForKey:kUserFavesChosenName]];						
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
					[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
					[_userData cacheAppData];
				
					if (editingSet)
					{
						[self setEditing:NO animated:YES];
					}
				}
				break;
			case kTableSectionAlarms:
				[_taskList cancelTaskForKey:[self.alarmKeys objectAtIndex:indexPath.row]];
				NSMutableArray *newKeys = [[NSMutableArray alloc] initWithArray:self.alarmKeys];
				[newKeys removeObjectAtIndex:indexPath.row];
				self.alarmKeys = newKeys;
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
				
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
			if (self.navigationItem.rightBarButtonItem != nil)
			{
				self.navigationItem.rightBarButtonItem = nil;
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

@end


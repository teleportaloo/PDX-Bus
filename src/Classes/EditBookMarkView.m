//
//  EditBookMarkView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "EditBookMarkView.h"
#import "UserFaves.h"
#import "CellTextField.h"
#import "CellTextView.h"
#import "DepartureTimesView.h"
#import "RouteView.h"
#import "AddNewStopToBookMark.h"
#import "RailMapView.h"
#import "TripPlannerEndPointView.h"
#import "TripPlannerDateView.h"
#import "TripPlannerOptions.h"
#import "AllRailStationView.h"
#import "DayOfTheWeekView.h"
#import "SegmentCell.h"
#import "StringHelper.h"

#define kTableName              0
#define kTableStops             1
#define kTableSectionTrip		2
#define kTableDelete            3
#define kTableRun               4
#define kTableCommute           5
#define kTableRowStopId         6
#define kTableRowStopBrowse     7
#define kTableRowRailMap        8
#define kTableRowRailStations   9
#define kTableTripRowFrom		10
#define kTableTripRowTo			11
#define kTableTripRowOptions    12
#define kTableRowTime			13

#define kUIEditHeight			55.0
#define kUIRowHeight			40.0

@implementation EditBookMarkView



@synthesize originalFave	= _originalFave;
@synthesize stops			= _stops;
@synthesize editWindow		= _editWindow;
@synthesize item			= _item;
@synthesize editCell		= _editCell;
@synthesize userRequest		= _userReq;



- (void)dealloc {
	
	self.stops = nil;
	self.editWindow = nil;
	self.originalFave = nil;
	self.editCell = nil;
	self.userRequest = nil;
	[super dealloc];
}


- (id)init {
	if ((self = [super init]))
	{
		// clear the last run so the commute bookmark can be tested
		[SafeUserData getSingleton].lastRun = nil;
	}
	return self;
}

-(void) setupArrivalSections
{
    [self clearSectionMaps];
    
    [self addSectionType:kTableName];
    [self addRowType:kTableName];
    
    _stopSection = [self addSectionType:kTableStops];
    
    for (int i=0; i<self.stops.count; i++)
    {
        [self addRowType:kTableStops];
    }
    
    [self addRowType:kTableRowStopId];
    [self addRowType:kTableRowStopBrowse];
    [self addRowType:kTableRowRailMap];
    [self addRowType:kTableRowRailStations];
    
    [self addSectionType:kTableCommute];
    [self addRowType:kTableCommute];
    
    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];
}

-(void) setupTripSections
{
    [self clearSectionMaps];
    
    [self addSectionType:kTableName];
    [self addRowType:kTableName];
    
    [self addSectionType:kTableSectionTrip];
    [self addRowType:kTableTripRowFrom];
    [self addRowType:kTableTripRowTo];
    [self addRowType:kTableTripRowOptions];
    [self addRowType:kTableRowTime];
    
    [self addSectionType:kTableRun];
    [self addRowType:kTableRun];
    
    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];
    
	_stopSection   = kNoRowSectionTypeFound;
}

#pragma mark Commuter Helper functions

- (bool)autoCommuteEnabled
{
	bool autoCommute = NO;
	if (self.originalFave!=nil)
	{
		NSNumber *days = [self.originalFave objectForKey:kUserFavesDayOfWeek];
		
		if ([days intValue]!=kDayNever)
		{
			autoCommute = YES;
		}
	}
	return autoCommute;	
}

- (bool)autoCommuteMorning
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesMorning];
	bool morning = TRUE;
	
	if (num)
	{
		morning = [num boolValue];
	}
	
	return morning;
}

- (NSString *)daysPostfix
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesDayOfWeek];
	int days = kDayNever;
	
	if (num)
	{
		days = [num intValue];
	}
	
	if (days == kDayNever)
	{
		return @"";
	}
	
	if ([self autoCommuteMorning])
	{
		return NSLocalizedString(@" mornings", @"text concatonated after a list of weekdays");
	}
	return NSLocalizedString(@" afternoons", @"text concatonated after a list of weekdays");
}

- (NSString *)dayPrefix
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesDayOfWeek];
	int days = kDayNever;
	
	if (num)
	{
		days = [num intValue];
	}
	
	switch (days)
	{
		case kDayNever:
			return @"";
		case kDayAllWeek:
			return NSLocalizedString(@"Show ", @"before text 'every day in the <morning or evening>'");
		default:
			return NSLocalizedString(@"Show on ", @"followed by a list of the days of the week");
	}
}

- (NSString*)daysString
{
	NSNumber *num = [self.originalFave objectForKey:kUserFavesDayOfWeek];
	int days = kDayNever;
	
	if (num)
	{
		days = [num intValue];
	}
	
	return [EditBookMarkView daysString:days];
}

+ (NSString *)daysString:(int)days
{
	switch (days)
	{
		case kDayNever:
			return NSLocalizedString(@"No days selected", @"error message");
		case kDayWeekend:
			return NSLocalizedString(@"weekend", @"");
		case kDayWeekday:
			return NSLocalizedString(@"weekday", @"");
		case kDayAllWeek:
			return NSLocalizedString(@"everyday in the", @"followed by <morning/afternoon>");
		case kDayMon:
			return NSLocalizedString(@"Monday",   @"full name for day of the week");
		case kDayTue:
			return NSLocalizedString(@"Tuesday",  @"full name for day of the week");
		case kDayWed:
			return NSLocalizedString(@"Wednesday",@"full name for day of the week");
		case kDayThu:
			return NSLocalizedString(@"Thursday", @"full name for day of the week");
		case kDayFri:
			return NSLocalizedString(@"Friday",   @"full name for day of the week");
		case kDaySat:
			return NSLocalizedString(@"Saturday", @"full name for day of the week");
		case kDaySun:
			return NSLocalizedString(@"Sunday",   @"full name for day of the week");
		default:
		{
			NSMutableString *dayStr = [[[NSMutableString alloc] init] autorelease];
			NSString *spacing = @"";
			static NSString *space = @" ";
			
#define ADD_DAY(X, STR)									\
			if ((days & X) !=0)							\
			{											\
				[dayStr appendString:spacing];			\
				[dayStr appendString:STR];				\
				spacing = space;						\
			}											
			
			ADD_DAY(kDayMon, NSLocalizedString(@"Mon", @"short name for day of the week"))
			ADD_DAY(kDayTue, NSLocalizedString(@"Tue", @"short name for day of the week"))
			ADD_DAY(kDayWed, NSLocalizedString(@"Wed", @"short name for day of the week"))
			ADD_DAY(kDayThu, NSLocalizedString(@"Thu", @"short name for day of the week"))
			ADD_DAY(kDayFri, NSLocalizedString(@"Fri", @"short name for day of the week"))
			ADD_DAY(kDaySat, NSLocalizedString(@"Sat", @"short name for day of the week"))
			ADD_DAY(kDaySun, NSLocalizedString(@"Sun", @"short name for day of the week"))
			
			return dayStr;
		}
	}
}

#pragma mark Segmented controls

- (void)timeSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl*)sender;
	self.userRequest.timeChoice = (TripTimeChoice)seg.selectedSegmentIndex;
	[self.originalFave setObject:[self.userRequest toDictionary] forKey:kUserFavesTrip];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Helper functions

-(void)makeNewFave
{
	@synchronized (_userData)
	{	
		self.originalFave = [[[ NSMutableDictionary alloc ] init] autorelease];
		[_userData.faves addObject:self.originalFave];
		self.item = [_userData.faves count]-1;
	}
}

-(void)addBookMark
{
	[self makeNewFave];
	[self.originalFave setObject:kNewBookMark forKey:kUserFavesChosenName];
	self.stops = [[[NSMutableArray alloc] init] autorelease];
	self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
	[self setupArrivalSections];
}

-(void)addTripBookMark
{
	[self makeNewFave];
	[self.originalFave setObject:kNewTripBookMark forKey:kUserFavesChosenName];
	
	NSDictionary *lastTrip = _userData.lastTrip;
	
	if (lastTrip !=nil)
	{
		self.userRequest = [[[TripUserRequest alloc] initFromDict:lastTrip] autorelease];
		self.userRequest.dateAndTime = nil;
		self.userRequest.arrivalTime = NO;
	}
	else
	{
		self.userRequest = [[[TripUserRequest alloc] init] autorelease];
	}
	
	
	self.userRequest.timeChoice = TripDepartAfterTime;
	[self.originalFave setObject:[self.userRequest toDictionary] forKey:kUserFavesTrip];
	self.title = NSLocalizedString(@"Add Trip Bookmark", @"screen title");
	[self setupTripSections];
}


-(void)processStops:(NSString *)locs
{
    self.stops = [StringHelper arrayFromCommaSeparatedString:locs];
}

-(void) addBookMarkFromStop:(NSString *)desc location:(NSString *)locid
{
	[self makeNewFave];
	[self.originalFave setObject:desc forKey:kUserFavesChosenName];
	[self processStops:locid];
	self.userRequest = nil;
	[self setupArrivalSections];
	[self.originalFave setObject:locid forKey:kUserFavesLocation];
	self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
}

-(void) addBookMarkFromUserRequest:(XMLTrips*)tripQuery;
{
	[self makeNewFave];
	NSString *title = [tripQuery shortName];
	
	if (title == nil) 
	{
		title = NSLocalizedString(@"New Trip", @"screen title");
	}

	[self.originalFave setObject:title forKey:kUserFavesChosenName];
	self.stops = nil;
	[self setupTripSections];
	self.userRequest = tripQuery.userRequest;
	[self.originalFave setObject:[tripQuery.userRequest toDictionary] forKey:kUserFavesTrip];
	self.title = NSLocalizedString(@"Add bookmark", @"screen title");
}



-(void) editBookMark:(NSMutableDictionary *)fave item:(uint)i
{
	self.item = i;
	self.originalFave = fave;
	
	if ([fave valueForKey:kUserFavesTrip] == nil )
	{	
		[self processStops:[fave valueForKey:kUserFavesLocation]];
		[self setupArrivalSections];
	}
	else // if ([fave valueForKey:kUserFavesTrip] !=nil)
	{
		self.userRequest = [[[TripUserRequest alloc] init] autorelease];
		[self.userRequest fromDictionary:[fave valueForKey:kUserFavesTrip]];
		[self setupTripSections];
	}
		
	self.title = NSLocalizedString(@"Edit bookmark", @"screen title");
}

- (UITextField *)createTextField_Rounded
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, [CellTextField editHeight]);
	UITextField *returnTextField = [[[UITextField alloc] initWithFrame:frame] autorelease];
    
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"";
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	
	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;
	
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	self.editWindow = returnTextField;
	
	return returnTextField;
}

- (void) selectFromRailMap
{
	RailMapView *rmView = [[RailMapView alloc] init];
	
	rmView.callback = self;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:rmView animated:YES];
	[rmView release];
    
    _reloadArrival = YES;
}

- (void) selectFromRailStations
{
	AllRailStationView *rmView = [[AllRailStationView alloc] init];
	
	rmView.callback = self;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:rmView animated:YES];
	[rmView release];
    
    _reloadArrival = YES;
}

- (void) browseForStop
{
	RouteView *routeViewController = [[RouteView alloc] init];
	
	routeViewController.callback = self;
	
	[routeViewController fetchRoutesInBackground:self.backgroundTask];
	[routeViewController release];
    
    _reloadArrival = YES;
}

- (void) enterStopId
{
	AddNewStopToBookMark *add = [[AddNewStopToBookMark alloc] init];
	
	add.callback = self;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:add animated:YES];
	[add release];
    
    _reloadArrival = YES;
}

- (BOOL) updateStopsInFave
{
	if (self.originalFave !=nil)	{
		NSMutableString *locations = [[NSMutableString alloc] init];
		
		int i;
		
		if ([self.stops count] > 0)
		{
			[locations appendFormat:@"%@", [self.stops objectAtIndex:0]];
			for (i=1; i< [self.stops count]; i++)
			{
				[locations appendFormat:@",%@",[self.stops objectAtIndex:i]];
			}
		}
		
		[self.originalFave setObject:locations forKey:kUserFavesLocation];
		[locations release];
		return YES;
	}
	return NO;
	
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self sections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch ([self sectionType:section])
	{
		case kTableName:
			return NSLocalizedString(@"Bookmark name:", @"section header");
		case kTableStops:
			return NSLocalizedString(@"Add stop ids in the desired order:", @"section header");
		case kTableSectionTrip:
			return NSLocalizedString(@"Trip:", @"section header");
		case kTableCommute:
			return NSLocalizedString(@"For commuters, PDX Bus can automatically show this bookmark the first time the app starts in the morning or afternoon:", @"section header");
	}
	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = 0.0;
    
    switch ([self rowType:indexPath])
    {
        case kTableName:
            result = [CellTextField cellHeight];
            break;
        case kTableTripRowOptions:
            result = [TripLeg getTextHeight:[self.userRequest optionsDisplayText]
                                      width:[TripLeg bodyTextWidth:self.screenInfo]];
            break;
        case kTableTripRowTo:
            result = [TripLeg getTextHeight:[self.userRequest.toPoint userInputDisplayText]
                                      width:[TripLeg bodyTextWidth:self.screenInfo]];
            break;
        case kTableTripRowFrom:
            result = [TripLeg getTextHeight:[self.userRequest.fromPoint userInputDisplayText]
                                      width:[TripLeg bodyTextWidth:self.screenInfo]];
            break;
        case kTableRowTime:
            result = [SegmentCell segmentCellHeight];
            break;
        case kTableRun:
        case kTableStops:
        case kTableDelete:
        case kTableRowStopId:
        case kTableRowStopBrowse:
        case kTableRowRailMap:
        case kTableRowRailStations:
            result = [self basicRowHeight];
            break;
        case kTableCommute:
            return [self basicRowHeight] * 1.4;
            break;
    }
    
    return result;
}

- (UITableViewCell *)plainCell:(UITableView *)tableView text:(NSString *)text indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(plainCell)];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(plainCell)] autorelease];
    }
    
    // Set up the cell
    cell.accessoryType = UITableViewCellAccessoryNone ;
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
    cell.textLabel.text = text;
    
    [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
    cell.textLabel.font = [self getBasicFont];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
	switch([self rowType:indexPath])
    {
        case kTableName:
        {
            if (self.editCell == nil)
            {
                self.editCell = [[[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTableName)]
                                 autorelease];
                self.editCell.view = [self createTextField_Rounded];
                self.editCell.delegate = self;
            }
            self.editCell.view.text = [self.originalFave objectForKey:kUserFavesChosenName];
            return self.editCell;
        }
        case kTableStops:
            return [self plainCell:tableView text:[self.stops objectAtIndex:indexPath.row] indexPath:indexPath];
        case kTableRowStopId:
            return [self plainCell:tableView text: NSLocalizedString(@"Add new stop ID", @"button text") indexPath:indexPath];
        case kTableRowStopBrowse:
            return [self plainCell:tableView text: NSLocalizedString(@"Browse routes for stop", @"button text)") indexPath:indexPath];
        case kTableRowRailMap:
            return [self plainCell:tableView text: NSLocalizedString(@"Select stop from rail maps", @"button text") indexPath:indexPath];
        case kTableRowRailStations:
            return [self plainCell:tableView text: NSLocalizedString(@"Search rail stations for stop", @"button text") indexPath:indexPath];
            
        case kTableRun:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTableRun)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTableRun)] autorelease];
            }
            
            // Set up the cell
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            cell.textLabel.text = NSLocalizedString(@"Show trip", @"button text");
            cell.imageView.image = [self getActionIcon:kIconTripPlanner];
            return cell;
            
        }
            
        case kTableTripRowFrom:
        case kTableTripRowTo:
        {
            CGFloat h = [self tableView:[self table] heightForRowAtIndexPath:indexPath];
            CGFloat w = [TripLeg bodyTextWidth:self.screenInfo];
            NSString *cellIdentifier = [NSString stringWithFormat:@"TripLeg%f+%f", h,w];
            
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil)
            {
                
                
                cell = [TripLeg tableviewCellWithReuseIdentifier:cellIdentifier
                                                       rowHeight:h
                                                      screenInfo:self.screenInfo];
                        
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = nil;
            
            NSString *text;
            NSString *dir;
            
            if ([self rowType:indexPath] == kTableTripRowFrom)
            {
                text = [self.userRequest.fromPoint userInputDisplayText];
                dir = NSLocalizedString(@"From", @"trip starting from");
                
            }
            else {
                text = [self.userRequest.toPoint userInputDisplayText];
                dir = NSLocalizedString(@"To", @"trip ending at");
            }
            
            [TripLeg populateCell:cell body:text mode:dir time:nil leftColor:nil route:nil];
            return cell;
            
        }
        case kTableTripRowOptions:
        {
            NSString *cellId = MakeCellIdW(kTableTripRowOptions, self.screenInfo.appWinWidth);
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil)
            {
                CGFloat h = [self tableView:[self table] heightForRowAtIndexPath:indexPath];
                
                cell = [TripLeg tableviewCellWithReuseIdentifier:cellId
                                                       rowHeight:h
                                                      screenInfo:self.screenInfo];
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = nil;
            
            [TripLeg populateCell:cell body:[self.userRequest optionsDisplayText] mode:NSLocalizedString(@"Options", @"trip options") time:nil leftColor:nil route:nil];
            return cell;
        }
            
        case kTableRowTime:
        {
            SegmentCell *cell = (SegmentCell*)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kTableRowTime)];
            if (cell == nil) {
                cell = [[[SegmentCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:MakeCellId(kTableRowTime)] autorelease];
                
                [cell createSegmentWithContent:[NSArray arrayWithObjects:
                                                NSLocalizedString(@"Ask for Time",@"trip time in bookmark"),
                                                NSLocalizedString(@"Depart Now",@"trip time in bookmark"),  nil]
                                        target:self
                                        action:@selector(timeSegmentChanged:)];
                cell.isAccessibilityElement = NO;
            }
            cell.segment.selectedSegmentIndex = self.userRequest.timeChoice;
            return cell;
        }
            
            
        case kTableDelete:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTableDelete)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTableDelete)] autorelease];
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.font = [self getBasicFont];
            }
            
            // Set up the cell
            
            
            cell.textLabel.text = NSLocalizedString(@"Delete bookmark", @"button text");
            cell.imageView.image = [self getActionIcon:kIconDelete];
            [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
            return cell;
            
            break;
        }
        case kTableCommute:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kTableCommute)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTableCommute)] autorelease];
            }
            
            // Set up the cell
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", 
                                   [self dayPrefix], 
                                   [self daysString],
                                   [self daysPostfix] ];
            
            if ([self autoCommuteEnabled])
            {
                if ([self autoCommuteMorning])
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
                cell.imageView.image = [self getFaveIcon:kIconArrivals];
            }
            
            
            return cell;	
        }
            
            
    }
	
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch([self rowType:indexPath])
    {
            
        case kTableStops:
        {
            DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
            departureViewController.callback = self;
            [departureViewController fetchTimesForLocationInBackground:self.backgroundTask
                                                                   loc:[self.stops objectAtIndex:indexPath.row]
                                                                 title:[self.originalFave objectForKey:kUserFavesChosenName]];
            [departureViewController release];
            break;
        }
        case kTableRowStopBrowse:
            [self browseForStop];
            break;
        case kTableRowRailMap:
            [self selectFromRailMap];
            break;
        case kTableRowRailStations:
            [self selectFromRailStations];
            break;
        case kTableRowStopId:
            [self enterStopId];
            break;
        case kTableTripRowFrom:
        case kTableTripRowTo:
        {
            TripPlannerEndPointView *tripEnd = [[TripPlannerEndPointView alloc] init];
            
            
            tripEnd.from = ([self rowType:indexPath]== kTableTripRowFrom) ;
            tripEnd.tripQuery = [[[XMLTrips alloc] init] autorelease];
            tripEnd.tripQuery.userRequest = self.userRequest;
            @synchronized (_userData)
            {
                [tripEnd.tripQuery addStopsFromUserFaves:_userData.faves];
            }
            tripEnd.popBackTo = self;
            
            // Push the detail view controller
            [[self navigationController] pushViewController:tripEnd animated:YES];
            [tripEnd release];
            _reloadTrip = YES;
            
            break;
        }
        case kTableTripRowOptions:
        {
            TripPlannerOptions * options = [[ TripPlannerOptions alloc ] init];
            
            options.tripQuery = [[[XMLTrips alloc] init] autorelease];
            options.tripQuery.userRequest = self.userRequest;
            
            [[self navigationController] pushViewController:options animated:YES];
            
            
            [options release];
            _reloadTrip = YES;
            break;
            
        }
        case kTableRun:
        {
            
            TripPlannerDateView *tripDate = [[TripPlannerDateView alloc] init];
            
            [tripDate initializeFromBookmark:self.userRequest];
            
            @synchronized (_userData)
            {
                [tripDate.tripQuery addStopsFromUserFaves:_userData.faves];
            }
            
            
            // Push the detail view controller
            [tripDate nextScreen:[self navigationController] taskContainer:self.backgroundTask];
            [tripDate release];
            
            break;
        }
        case kTableDelete:
        {
            @synchronized (_userData)
            {
                [_userData.faves removeObjectAtIndex:self.item];
                
                [[self navigationController] popViewControllerAnimated:YES];
                break;
            }
        }
        case kTableCommute:
        {
            _reloadArrival = YES;
            DayOfTheWeekView *dow = [[DayOfTheWeekView alloc] init];
            dow.originalFave = self.originalFave;
            [[self navigationController] pushViewController:dow animated:YES];
            [dow release];
            break;
        }
    }
}



// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
		[self.stops removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		[self updateStopsInFave];
        [self setupArrivalSections];
        [tableView endUpdates];
	}	
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
		
        switch ([self rowType:indexPath])
		{
			case kTableRowStopBrowse:
				[self browseForStop];
				break;
			case kTableRowStopId:
				[self enterStopId];
				break;
		}
	}	
}

// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self sectionType:indexPath.section] == kTableStops)
	{
		if ( indexPath.row < [self.stops count])
		{
			return UITableViewCellEditingStyleDelete;
		}
		return UITableViewCellEditingStyleInsert;
		
	}
	return UITableViewCellEditingStyleNone;
}

// Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the specified item to be editable.
	
	switch([self sectionType:indexPath.section])
	{
		case kTableStops:
			return YES;
		case kTableSectionTrip:
		case kTableName:
		case kTableDelete:
		case kTableRun:
		case kTableCommute:
			
			return NO;
	}	
	return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if ([self sectionType:proposedDestinationIndexPath.section] != kTableStops)
	{
		return [NSIndexPath 
				indexPathForRow:0
				inSection:_stopSection];
	}
	
	if (proposedDestinationIndexPath.row >= [self.stops count])
	{
		return [NSIndexPath 
				indexPathForRow:[self.stops count]-1
				inSection:_stopSection];
	}
	
	return proposedDestinationIndexPath;
	
}

/*
// Have an accessory view for the second section only
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == kTableSectionStops) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
}
*/

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
    if ([self sectionType:fromIndexPath.section] == kTableStops && [self sectionType:toIndexPath.section] == kTableStops)
	{
		NSString *move = [[self.stops objectAtIndex:fromIndexPath.row] retain];
		
		if (fromIndexPath.row < toIndexPath.row)
		{
			[self.stops insertObject:move atIndex:toIndexPath.row+1];
			[self.stops removeObjectAtIndex:fromIndexPath.row];
		}
		else
		{
			[self.stops removeObjectAtIndex:fromIndexPath.row];
			[self.stops insertObject:move atIndex:toIndexPath.row];
		}
		[move release];
		[self updateStopsInFave];
	}
}

// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the item to be re-orderable.
    if ([self rowType:indexPath] == kTableStops)
	{
		return YES;
	}
	return NO;
}

#pragma mark View methods

- (void)viewDidLoad {
	// Add the following line if you want the list to be editable
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.table.editing = YES;
	_userData.favesChanged = YES;
    [super viewDidLoad];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (_reloadTrip)
	{
		[self.originalFave setObject:[self.userRequest toDictionary] forKey:kUserFavesTrip];
		[self reloadData];
		_reloadTrip = FALSE;
	}
	
	if (_reloadArrival)
	{
        [self setupArrivalSections];
		[self reloadData];
		_reloadArrival = FALSE;
	}
}

- (void)loadView
{
	[super loadView];
	self.table.allowsSelectionDuringEditing = YES;
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


#pragma mark Text Editing Methods
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc]
									  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
									  target:self
									  action:@selector(cancelAction:)] autorelease];
	self.navigationItem.rightBarButtonItem = cancelButton;
	
	[self.table scrollToRowAtIndexPath:[NSIndexPath 
										indexPathForRow:0
										inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	
	
	
	return YES;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	UITextView *textView = (UITextView*)[(CellTextField*)cell view];
	if (textView.text.length !=0 && self.navigationItem.rightBarButtonItem != nil )
	{
		[self.originalFave setObject:textView.text forKey:kUserFavesChosenName];
	}
	else
	{
		textView.text = [self.originalFave objectForKey:kUserFavesChosenName];
	}
}

- (void)cancelAction:(id)sender
{
	self.navigationItem.rightBarButtonItem = nil;
	[self.editWindow resignFirstResponder];
}

#pragma mark ReturnStopId methods

- (NSString *)actionText
{
    return NSLocalizedString(@"Add stop to bookmark", @"Button text");
}

-(void) selectedStop:(NSString *)stopId
{
	[[self navigationController] popToViewController:self animated:YES];
	[self.stops addObject:stopId];
	[self updateStopsInFave];
	[self reloadData];
}

-(void) selectedStop:(NSString *)stopId desc:(NSString*)stopDesc
{
	if ([self.editCell.view.text isEqualToString:kNewBookMark])
	{
		[self.originalFave setObject:stopDesc forKey:kUserFavesChosenName];
		self.editCell.view.text = stopDesc;
	}
	
	[[self navigationController] popToViewController:self animated:YES];
	[self.stops addObject:stopId];
	[self updateStopsInFave];
	[self reloadData];
}

-(UIViewController*) getController
{
	return self;
}

#pragma mark TripReturnUserRequest methods

-(void)userRequest:(TripUserRequest *)userRequest
{
	self.userRequest = userRequest;
	
	if ([self.editCell.view.text isEqualToString:kNewTripBookMark])
	{
		[self.originalFave setObject:[userRequest shortName] forKey:kUserFavesChosenName];
		self.editCell.view.text = [userRequest shortName];
	}
	
	
	[self.originalFave setObject:[userRequest toDictionary] forKey:kUserFavesTrip];
	
	[self reloadData];
}



@end

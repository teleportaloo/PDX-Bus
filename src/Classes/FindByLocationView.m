//
//  FindByLocationView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FindByLocationView.h"
#import "XMLAllStops.h"
#import "RootViewController.h"
#import "StopDistance.h"
#import "DepartureTimesView.h"
#import "CellLabel.h"
#import "NearestStopsMap.h"
#import "NearestRoutesView.h"
#import "DebugLogging.h"
#import "TripPlannerEndPointView.h"
#import "BackgroundTaskContainer.h"

#define kGpsLocateSection	0
#define kNoGpsLocateSection 1
#define kDistanceSection	2
#define kModeSection		3
#define kShowSection        4
#define kAutoSection        5
#define kNoteSection        6

#define kLocatingAccuracy	0
#define kLocatingStop		1

#define kShowArrivals		0
#define kShowMap			1
#define kShowRoute			2

#define kDistanceNextToMe	0
#define kDistanceHalfMile   1
#define kDistanceMile		2
#define kDistance3Miles		3

#define kSegRowWidth		320
#define kSegRowHeight		40
#define kUISegHeight		40
#define kUISegWidth			320

#define kAutoAsk            0
#define kAutoPrevious       1

#define kGoCellId			@"go"

#define kHelpText           @"\nNote: Using previous settings chosen in 'Locate nearby stops' main menu."

@implementation FindByLocationView

@synthesize cachedRoutes = _cachedRoutes;
@synthesize lastLocate   = _lastLocate;
@synthesize autoLaunch   = _autoLaunch;
@synthesize startingLocationName = _startingLocationName;
@synthesize startingLocation = _startingLocation;

// @synthesize progressText = _progressText;

- (void)dealloc {
	self.cachedRoutes = nil;
	self.lastLocate   = nil;
    self.startingLocation = nil;
    self.startingLocationName = nil;

	[super dealloc];
}

- (void) basicInit
{
    self.title = @"Locate Stops";
    _maxRouteCount = 1;
    _mode = TripModeAll;
    _dist = kDistanceHalfMile;
    _show = kShowArrivals;
    _firstDisplay = YES;
    
    self.lastLocate = _userData.lastLocate;
    
    if (self.lastLocate != nil)
    {
        _mode = ((NSNumber *)[self.lastLocate objectForKey:kLocateMode]).intValue;
        _show = ((NSNumber *)[self.lastLocate objectForKey:kLocateShow]).intValue;
        _dist = ((NSNumber *)[self.lastLocate objectForKey:kLocateDist]).intValue;
    }
}

- (id) initWithLocation:(CLLocation*)location description:(NSString*)locationName
{
    if ((self = [super init]))
	{
		[self basicInit];
        
        self.startingLocation = location;
        self.startingLocationName = locationName;
        
        static NSInteger sections[] = { kNoGpsLocateSection, kDistanceSection, kModeSection, kShowSection };
        _sections  = sections;
        _nSections = sizeof(sections) / sizeof(sections[0]);
	}
    
    return self;
}

- (id) init
{
	if ((self = [super init]))
	{
		[self basicInit];
        
        static NSInteger sections[] = { kGpsLocateSection, kDistanceSection, kModeSection, kShowSection,kAutoSection,kNoteSection };
        _sections  = sections;
        _nSections = sizeof(sections) / sizeof(sections[0]);
		
	}
	return self;
}

- (void)actionArgs:(NSDictionary *)args
{
    NSString *arg = [args objectForKey:@"distance"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:kDistanceNextToMe], @"closest",
                            [NSNumber numberWithInt:kDistanceNextToMe], @"Closest",
                            [NSNumber numberWithInt:kDistanceHalfMile], @"0.5",         
                            [NSNumber numberWithInt:kDistanceMile],     @"1",           
                            [NSNumber numberWithInt:kDistance3Miles],   @"3",           
                              nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            _dist = (int)[num integerValue];
        }
    }
    
    arg = [args objectForKey:@"mode"];
    
    if (arg !=nil)
    {       
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithInt:TripModeBusOnly],    @"Bus",         
                               [NSNumber numberWithInt:TripModeBusOnly],    @"bus",
                               [NSNumber numberWithInt:TripModeBusOnly],    @"Busses",
                               [NSNumber numberWithInt:TripModeBusOnly],    @"busses",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"Train",       
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"train",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"Trains",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"trains",
                               [NSNumber numberWithInt:TripModeAll],        @"both",        
                               [NSNumber numberWithInt:TripModeAll],        @"Both",        
                               [NSNumber numberWithInt:TripModeAll],        @"BusAndTrain",
                               [NSNumber numberWithInt:TripModeAll],        @"busandtrain",
                               [NSNumber numberWithInt:TripModeAll],        @"BussesAndTrains",
                               [NSNumber numberWithInt:TripModeAll],        @"bussesandtrains",
                               
                               nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            _mode = (TripMode)[num integerValue];
        }
    }
    
    arg = [args objectForKey:@"show"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithInt:kShowArrivals],  @"Arrivals",
                               [NSNumber numberWithInt:kShowArrivals],  @"arrivals",
                               [NSNumber numberWithInt:kShowMap],       @"map",
                               [NSNumber numberWithInt:kShowMap],       @"Map",
                               [NSNumber numberWithInt:kShowRoute],     @"routes",
                               [NSNumber numberWithInt:kShowRoute],     @"Routes",
                               nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            _show = (int)[num integerValue];
        }
    }
}

- (id) initAutoLaunch
{
    _autoLaunch = YES;
    
	return [self init];
}

- (void)setDistance
{
    switch (_dist)
    {
        case kDistanceNextToMe:
            _minDistance = kDistNextToMe;
            _maxToFind = kMaxStops;
            break;
        case kDistanceHalfMile:
            _minDistance = kDistHalfMile;
            _maxToFind = kMaxStops;
            break;
        case kDistanceMile:
            _minDistance = kDistMile;
            _maxToFind = kMaxStops;
            break;
        case kDistance3Miles:
            _minDistance = kDistMile * 3;
            _maxToFind = kMaxStops;
            break;
    }
}

- (void)startLocating
{
    LocatingView *locator = [[[LocatingView alloc] init] autorelease];
    
    locator.delegate = self;
    [self setDistance];
    
    switch (_dist)
    {
        case kDistanceNextToMe:
            locator.accuracy = kAccNextToMe;
             break;
        case kDistanceHalfMile:
            locator.accuracy = kAccHalfMile;
            break;
        case kDistanceMile:
            locator.accuracy = kAccMile;
            break;
        case kDistance3Miles:
            locator.accuracy = kAcc3Miles;
            break;
    }
    
    
    [self.navigationController pushViewController:locator animated:YES];
}

#pragma mark TableViewWithToolbar methods

-(void)resetButton:(id)arg
{
    _mode = TripModeAll;
    _show = kShowArrivals;
    _dist = kDistanceHalfMile;
    UserPrefs *prefs = [UserPrefs getSingleton];
    prefs.autoLocateShowOptions = YES;
    [self reloadData];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    UIBarButtonItem *resetButton = [[[UIBarButtonItem alloc]
                              initWithTitle:@"Reset Options" style:UIBarButtonItemStyleBordered
                              target:self action:@selector(resetButton:)] autorelease];
    
    
    [toolbarItems addObject:resetButton];
    
}

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark UI Helper functions

-(void)backButton:(id)sender
{
	[super backButton:sender];
}

- (void)locatingViewFinished:(LocatingView *)locatingView
{
    if (!locatingView.failed && !locatingView.cancelled)
    {
        [self searchAndDisplay:locatingView.backgroundTask location:locatingView.lastLocation];
    }
    else if (locatingView.cancelled)
    {
        [locatingView.navigationController popViewControllerAnimated:YES];
    }
}

- (void)searchAndDisplay:(BackgroundTaskContainer *)background location:(CLLocation *)here
{
	switch (_show)
	{
		case kShowMap:
		{
			NearestStopsMap *mapView = [[NearestStopsMap alloc] init];
			[mapView fetchNearestStopsInBackground:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			
			if ([mapView supportsOverlays])
			{
				mapView.circle = [MKCircle circleWithCenterCoordinate:here.coordinate radius:_minDistance];
			}
			[mapView release];
			break;
		}
		case kShowRoute:
		{
			NearestRoutesView *routesView = [[NearestRoutesView alloc] init];
			[routesView fetchNearestRoutesInBackground:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			[routesView release];
			break;
		}
		case kShowArrivals:
		{
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			[departureViewController fetchTimesForNearestStopsInBackground:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			[departureViewController release];
			break;
		}
	}
    
    if (_autoLaunch)
    {
        [background setHelp:kHelpText];
    }
}


#pragma mark Segment Controls

- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	[parent addSubview:segmentedControl];
	[parent layoutSubviews];
	[segmentedControl autorelease];
	return segmentedControl;
}

- (void)modeSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	_mode = (TripMode)seg.selectedSegmentIndex;
}

- (void)showSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	_show = (int)seg.selectedSegmentIndex;
}


- (void)distSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	_dist = (int)seg.selectedSegmentIndex;
}

- (void)autoSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	
    UserPrefs *prefs = [UserPrefs getSingleton];
    
    switch (seg.selectedSegmentIndex)
    {
    case kAutoAsk:
            prefs.autoLocateShowOptions = YES;
            break;
    default:
    case kAutoPrevious:
            prefs.autoLocateShowOptions = NO;
            break;
    }
}



#pragma mark TableViewWithToolbar methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return _nSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch (_sections[section])
	{
		case kDistanceSection:
			return @"Search radius:";
		case kModeSection:
			return @"Mode of travel:";
		case kShowSection:
			return @"Show:";
        case kNoteSection:
            return @"Note: This page is always shown when 'Locate nearby stops' is selected from the main list.";
        case kAutoSection:
			return @"Locate toolbar button behavior:";
		case kGpsLocateSection:
			return nil; // [NSString stringWithFormat:@"Choosing 'Arrivals' will show a maximum of %d stops.", kMaxStops];
        case kNoGpsLocateSection:
            return self.startingLocationName;
	}
	return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    if (_sections[section] != kNoteSection)
    {
        return 1;
    }
    return 0;
}

#define kUIProgressBarWidth		240.0
#define kUIProgressBarHeight	10.0
#define kRowHeight				40.0

#define kRowWidth				300.0

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;

	switch (_sections[indexPath.section])
	{
        case kDistanceSection:
		case kModeSection:
		case kShowSection:
        case kAutoSection:
            
			result = kSegRowHeight;
			break;
		case kGpsLocateSection:
        case kNoGpsLocateSection:
        case kNoteSection:
			result = [self basicRowHeight];
			break;
	}
	return result;
}

- (UITableViewCell *)segCell:(NSString*)cellId items:(NSArray*)items action:(SEL)action
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
	
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	[cell.contentView addSubview:segmentedControl];
	[segmentedControl autorelease];
	
	[cell layoutSubviews];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.isAccessibilityElement = NO;
	cell.backgroundView = [self clearView];
	
	return cell;
	
}

- (UISegmentedControl *)getSeg:(UITableViewCell *)cell
{
	for (UIView *v in cell.contentView.subviews)
	{
		if ([v isKindOfClass:[UISegmentedControl class]])
		{
			return (UISegmentedControl *)v;
		}
	}
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
	DEBUG_LOG(@"Requesting cell for ip %ld %ld\n", (long)indexPath.section, (long)indexPath.row);
	
	switch (_sections[indexPath.section])
	{
		case kDistanceSection:
		{
			static NSString *segmentId = @"dist";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Closest", @"½ mile", @"1 mile", @"3 miles", nil]
							  action:@selector(distSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = _dist;
			return cell;	
		}
		case kShowSection:
		{
			static NSString *segmentId = @"show";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Arrivals", @"Map", @"Routes", nil]
							  action:@selector(showSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = _show;
			return cell;	
		}
		case kModeSection:
		{
			static NSString *segmentId = @"mode";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Bus only", @"Rail only", @"Bus or Rail", nil]
							  action:@selector(modeSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = _mode;
			return cell;	
		}
        case kAutoSection:
		{
			static NSString *segmentId = @"auto";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId
							   items:[NSArray arrayWithObjects:@"Show this page", @"Show results", nil]
							  action:@selector(autoSegmentChanged:)];
			}
			
            if ([UserPrefs getSingleton].autoLocateShowOptions)
            {
                [self getSeg:cell].selectedSegmentIndex = kAutoAsk;
            }
            else
            {
                [self getSeg:cell].selectedSegmentIndex = kAutoPrevious;

            }
			return cell;
		}
		case kGpsLocateSection:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGoCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGoCellId] autorelease];
			}
			cell.textLabel.text = @"Start locating";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
			return cell;
        }
        case kNoGpsLocateSection:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGoCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGoCellId] autorelease];
			}
			cell.textLabel.text = @"Find nearby stops";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
			return cell;
        }
        
	}
		
	return nil;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (_sections[indexPath.section])
	{
		case kGpsLocateSection:
            [self startLocating];
			break;
        case kNoGpsLocateSection:
            [self setDistance];
            [self searchAndDisplay:self.backgroundTask location:self.startingLocation];
            break;
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:kGoCellId])
	{
		cell.backgroundColor = [UIColor greenColor];
	}
    
    
}


#pragma mark View methods

- (void)viewWillDisappear:(BOOL)animated
{
    if (!_autoLaunch)
    {
        self.lastLocate = [[[NSMutableDictionary alloc] init] autorelease];
	
        [self.lastLocate setObject:[NSNumber numberWithInt:_mode] forKey:kLocateMode];
        [self.lastLocate setObject:[NSNumber numberWithInt:_dist] forKey:kLocateDist];
        [self.lastLocate setObject:[NSNumber numberWithInt:_show] forKey:kLocateShow];
	
        _userData.lastLocate = self.lastLocate;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_autoLaunch && _firstDisplay)
    {
        _firstDisplay=NO;
        [self startLocating];
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}



@end


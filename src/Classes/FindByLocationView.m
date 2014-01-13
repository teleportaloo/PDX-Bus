//
//  FindByLocationView.m
//  PDX Bus
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

#import "FindByLocationView.h"
#import "XMLAllStops.h"
#import "RootViewController.h"
#import "StopDistance.h"
#import "DepartureTimesView.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "CellLabel.h"
#import "NearestStopsMap.h"
#import "NearestRoutesView.h"
#import "debug.h"
#import "TripPlannerEndPointView.h"

#define kGoSection			0
#define kDistanceSection	1
#define kModeSection		2
#define kShowSection        3
#define kAutoSection        4
#define kNoteSection        5

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

// @synthesize progressText = _progressText;

- (void)dealloc {
	self.cachedRoutes = nil;
	self.lastLocate   = nil;

	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
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
            _dist = [num integerValue];
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
            _mode = [num integerValue];
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
            _show = [num integerValue];
        }
    }
}

- (id) initAutoLaunch
{
    _autoLaunch = YES;
    
	return [self init];
}

- (void)startLocating
{
    LocatingView *locator = [[[LocatingView alloc] init] autorelease];
    
    locator.delegate = self;
    
    switch (_dist)
    {
        case kDistanceNextToMe:
            locator.accuracy = kAccNextToMe;
            _minDistance = kDistNextToMe;
            _maxToFind = kMaxStops;
            break;	
        case kDistanceHalfMile:
            locator.accuracy = kAccHalfMile;
            _minDistance = kDistHalfMile;
            _maxToFind = kMaxStops;
            break;
        case kDistanceMile:
            locator.accuracy = kAccMile;
            _minDistance = kDistMile;
            _maxToFind = kMaxStops;
            break;
        case kDistance3Miles:
            locator.accuracy = kAcc3Miles;
            _minDistance = kDistMile * 3;
            _maxToFind = kMaxStops;
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
        [self searchAndDisplay:locatingView];
    }
    else if (locatingView.cancelled)
    {
        [locatingView.navigationController popViewControllerAnimated:YES];
    }
}

- (void)searchAndDisplay:(LocatingView *)locatingView
{
	switch (_show)
	{
		case kShowMap:
		{
			NearestStopsMap *mapView = [[NearestStopsMap alloc] init];
			[mapView fetchNearestStopsInBackground:locatingView.backgroundTask location:locatingView.lastLocation maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			
			if ([mapView supportsOverlays])
			{
				mapView.circle = [MKCircle circleWithCenterCoordinate:locatingView.lastLocation.coordinate radius:_minDistance];
			}
			[mapView release];
			break;
		}
		case kShowRoute:
		{
			NearestRoutesView *routesView = [[NearestRoutesView alloc] init];
			[routesView fetchNearestRoutesInBackground:locatingView.backgroundTask location:locatingView.lastLocation maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			[routesView release];
			break;
		}
		case kShowArrivals:
		{
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			[departureViewController fetchTimesForNearestStopsInBackground:locatingView.backgroundTask location:locatingView.lastLocation maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			[departureViewController release];
			break;
		}
	}
    
    if (_autoLaunch)
    {
        [locatingView.backgroundTask setHelp:kHelpText];
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
	_mode = seg.selectedSegmentIndex;
}

- (void)showSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	_show = seg.selectedSegmentIndex;
}


- (void)distSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	_dist = seg.selectedSegmentIndex;
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
	
	return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch (section)
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
		case kGoSection:
			return nil; // [NSString stringWithFormat:@"Choosing 'Arrivals' will show a maximum of %d stops.", kMaxStops];
	}
	return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    if (section != kNoteSection)
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

	switch (indexPath.section)
	{
        case kDistanceSection:
		case kModeSection:
		case kShowSection:
        case kAutoSection:
            
			result = kSegRowHeight;
			break;
		case kGoSection:
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
		
	DEBUG_LOG(@"Requesting cell for ip %d %d\n", indexPath.section, indexPath.row);
	
	switch (indexPath.section)
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
		case kGoSection:
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
        
	}
		
	return nil;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section)
	{
		case kGoSection:
            [self startLocating];
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


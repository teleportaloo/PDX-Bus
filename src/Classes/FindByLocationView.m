//
//  FindByLocationView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FindByLocationView.h"
#import "RootViewController.h"
#import "StopDistanceData.h"
#import "DepartureTimesView.h"
#import "CellLabel.h"
#import "NearestVehiclesMap.h"
#import "NearestRoutesView.h"
#import "DebugLogging.h"
#import "TripPlannerEndPointView.h"
#import "BackgroundTaskContainer.h"
#import "SimpleAnnotation.h"
#import "BearingAnnotationView.h"
#import "LocationAuthorization.h"

enum SECTIONS_AND_ROWS
{
    kGpsLocateSection,
    kNoGpsLocateSection,
    kDistanceSection,
    kModeSection,
    kShowSection,
    kAutoSection,
    kNoteSection,
    kMapSection
};


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

#define kHelpText           @"\nNote: Using previous settings chosen in 'Locate nearby stops' main menu."

@implementation FindByLocationView

@synthesize cachedRoutes = _cachedRoutes;
@synthesize lastLocate   = _lastLocate;
@synthesize autoLaunch   = _autoLaunch;
@synthesize startingLocationName = _startingLocationName;
@synthesize startingLocation = _startingLocation;
@synthesize circle      = _circle;

// @synthesize progressText = _progressText;

- (void)dealloc {
	self.cachedRoutes = nil;
	self.lastLocate   = nil;
    self.startingLocation = nil;
    self.startingLocationName = nil;
    self.circle = nil;
    
    if (self.mapUpdateTimer)
    {
        [self.mapUpdateTimer invalidate];
        self.mapUpdateTimer = nil;
    }

	[super dealloc];
}

- (void) basicInit
{
    self.title = NSLocalizedString(@"Locate Stops", @"page title");
    _maxRouteCount = 1;
    _mode = TripModeAll;
    _dist = kDistanceHalfMile;
    _show = kShowArrivals;
    _firstDisplay = YES;
    
    self.lastLocate = _userData.lastLocate;
    
    if (self.lastLocate != nil)
    {
        _mode = self.lastLocate[kLocateMode].intValue;
        _show = self.lastLocate[kLocateShow].intValue;
        _dist = self.lastLocate[kLocateDist].intValue;
    }
}

- (instancetype) initWithLocation:(CLLocation*)location description:(NSString*)locationName
{
    if ((self = [super init]))
	{
		[self basicInit];
        
        self.startingLocation = location;
        self.startingLocationName = locationName;
        
        [self clearSectionMaps];
        [self addSectionType:kNoGpsLocateSection];
        [self addRowType:kNoGpsLocateSection];

        [self addSectionType:kDistanceSection];
        [self addRowType:kDistanceSection];
        [self addRowType:kMapSection];
    
        [self addSectionType:kModeSection];
        [self addRowType:kModeSection];
        
        [self addSectionType:kShowSection];
        [self addRowType:kShowSection];
	}
    
    return self;
}

- (instancetype) init
{
	if ((self = [super init]))
	{
		[self basicInit];
        
        [self clearSectionMaps];
        
        
        [self addSectionType:kGpsLocateSection];
        [self addRowType:kGpsLocateSection];
        
        [self addSectionType:kDistanceSection];
        [self addRowType:kDistanceSection];
        [self addRowType:kMapSection];
        
        [self addSectionType:kModeSection];
        [self addRowType:kModeSection];
        
        [self addSectionType:kShowSection];
        [self addRowType:kShowSection];
        
        [self addSectionType:kAutoSection];
        [self addRowType:kAutoSection];
        
        
        
        [self addSectionType:kNoteSection];
	}
	return self;
}

- (void)actionArgs:(NSDictionary *)args
{
    NSString *arg = args[@"distance"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = @{
                               @"closest"   : @kDistanceNextToMe,
                               @"Closest"   : @kDistanceNextToMe,
                               @"0.5"       : @kDistanceHalfMile,
                               @"1"         : @kDistanceMile,
                               @"3"         : @kDistance3Miles };
        NSNumber *num = dmap[arg];
        if (num)
        {
            _dist = (int)num.integerValue;
        }
    }
    
    arg = args[@"mode"];
    
    if (arg !=nil)
    {       
        NSDictionary *dmap = @{
                               @"Bus"               : @(TripModeBusOnly),
                               @"bus"               : @(TripModeBusOnly),
                               @"Busses"            : @(TripModeBusOnly),
                               @"busses"            : @(TripModeBusOnly),
                               @"Buses"             : @(TripModeBusOnly),
                               @"buses"             : @(TripModeBusOnly),
                               @"Train"             : @(TripModeTrainOnly),
                               @"train"             : @(TripModeTrainOnly),
                               @"Trains"            : @(TripModeTrainOnly),
                               @"trains"            : @(TripModeTrainOnly),
                               @"both"              : @(TripModeAll),
                               @"Both"              : @(TripModeAll),
                               @"BusAndTrain"       : @(TripModeAll),
                               @"busandtrain"       : @(TripModeAll),
                               @"BussesAndTrains"   : @(TripModeAll),
                               @"bussesandtrains"   : @(TripModeAll),
                               @"BusesAndTrains"    : @(TripModeAll),
                               @"busesandtrains"    : @(TripModeAll)};
        
        NSNumber *num = dmap[arg];
        if (num)
        {
            _mode = (TripMode)num.integerValue;
        }
    }
    
    arg = args[@"show"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = @{
                               @"Arrivals"  : @kShowArrivals,
                               @"arrivals"  : @kShowArrivals,
                               @"map"       : @kShowMap,
                               @"Map"       : @kShowMap,
                               @"routes"    : @kShowRoute,
                               @"Routes"    : @kShowRoute};
        
        NSNumber *num = dmap[arg];
        if (num)
        {
            _show = (int)num.integerValue;
        }
    }
}

- (instancetype) initAutoLaunch
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
    LocatingView *locator = [LocatingView viewController];
    
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

-(void)resetButton:(id)unused
{
    _mode = TripModeAll;
    _show = kShowArrivals;
    _dist = kDistanceHalfMile;
    UserPrefs *prefs = [UserPrefs singleton];
    prefs.autoLocateShowOptions = YES;
    [self reloadData];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    UIBarButtonItem *resetButton = [[[UIBarButtonItem alloc]
                              initWithTitle:NSLocalizedString(@"Reset Options", @"button text") style:UIBarButtonItemStylePlain
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
            NearestVehiclesMap *mapView = [NearestVehiclesMap viewController];
            mapView.circle = [MKCircle circleWithCenterCoordinate:here.coordinate radius:_minDistance];
			[mapView fetchNearestVehiclesAndStopsAsync:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
            
			break;
		}
		case kShowRoute:
		{
            [[NearestRoutesView viewController] fetchNearestRoutesAsync:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
			break;
		}
		case kShowArrivals:
		{
			[[DepartureTimesView viewController] fetchTimesForNearestStopsAsync:background location:here maxToFind:_maxToFind minDistance:_minDistance mode:_mode];
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
    [self setDistance];
    [self updateCircle];
}

- (void)autoSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	
    UserPrefs *prefs = [UserPrefs singleton];
    
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
	
    return self.sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch ([self sectionType:section])
	{
		case kDistanceSection:
            return NSLocalizedString(@"Search radius:", @"Section title");
		case kModeSection:
            return NSLocalizedString(@"Mode of travel:", @"Section title");
		case kShowSection:
            return NSLocalizedString(@"Show:",  @"Section title");
        case kNoteSection:
            return NSLocalizedString(@"Note: This page is always shown when 'Locate nearby stops' is selected from the main list.", @"Page note");
        case kAutoSection:
            return NSLocalizedString(@"Locate toolbar button behavior:", @"Section title");
		case kGpsLocateSection:
			return nil; // [NSString stringWithFormat:@"Choosing 'Arrivals' will show a maximum of %d stops.", kMaxStops];
        case kNoGpsLocateSection:
            return self.startingLocationName;
	}
	return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    return [self rowsInSection:section];
}

#define kUIProgressBarWidth		240.0
#define kUIProgressBarHeight	10.0
#define kRowHeight				40.0

#define kRowWidth				300.0

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;

	switch ([self rowType:indexPath])
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
        case kMapSection:
            result = self.mapCellHeight;
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

- (void)updateCircle
{
    if (self.mapView)
    {
        [self setDistance];
        if (self.circle)
        {
            [self.mapView removeOverlay:self.circle];
            self.circle = nil;
        }
        
        if (self.self.startingLocation != nil)
        {
            self.circle = [MKCircle circleWithCenterCoordinate:self.startingLocation.coordinate radius:_minDistance];
        }
        else if (self.mapView.userLocation!=nil)
        {
            self.circle = [MKCircle circleWithCenterCoordinate:self.mapView.userLocation.location.coordinate radius:_minDistance];
        }
            
        self.mapView.delegate = self;
        
        [self.mapView addOverlay:self.circle];
        
        
        MKMapRect flyTo = MKMapRectNull;
        // MKMapPoint annotationPoint = MKMapPointForCoordinate(self.startingLocation.coordinate);
        
        flyTo = self.circle.boundingMapRect;
        
        
        UIEdgeInsets insets = {
            5,
            5,
            5,
            5
        };
        
        
        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo edgePadding:insets] animated:YES];
    }
    
    bool newAuthorization = [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:NO];
    
    if (newAuthorization != _locationAuthorized)
    {
        _locationAuthorized = newAuthorization;
    
        NSIndexPath *locIndex = [self firstIndexPathOfSectionType:kGpsLocateSection rowType:kGpsLocateSection];
    
        if (locIndex)
        {
            [self.table reloadRowsAtIndexPaths:@[locIndex] withRowAnimation:NO];
        }
    }
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if (overlay == self.circle)
    {
        MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:overlay];
        circleView.strokeColor = [UIColor greenColor];
        circleView.lineWidth = 3.0;
        return [circleView autorelease];
        
    }
    
    // Can't reurn nil so make a dummy one
    return [[[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]] autorelease];
}

- (void)startCircleTimer
{
    if (!self.startingLocation && self.mapView && self.mapUpdateTimer == nil)
    {

        self.mapUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                               target:self
                                                             selector:@selector(updateCircle)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DEBUG_LOG(@"Requesting cell for ip %ld %ld\n", (long)indexPath.section, (long)indexPath.row);
    
    switch ([self rowType:indexPath])
    {
        case kDistanceSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kDistanceSection)];
            if (cell == nil) {
                cell = [self segCell:MakeCellId(kDistanceSection)
                               items:@[
                                       NSLocalizedString(@"Closest",   @"Short segment button text"),
                                       NSLocalizedString(@"½ mile",    @"Short segment button text"),
                                       NSLocalizedString(@"1 mile",    @"Short segment button text"),
                                       NSLocalizedString(@"3 miles",   @"Short segment button text"),
                                       ]
                              action:@selector(distSegmentChanged:)];
            }
            
            [self getSeg:cell].selectedSegmentIndex = _dist;
            return cell;
        }
        case kShowSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kShowSection)];
            if (cell == nil) {
                cell = [self segCell:MakeCellId(kShowSection)
                               items:@[
                                       NSLocalizedString(@"Arrivals",  @"Short segment button text"),
                                       NSLocalizedString(@"Map",       @"Short segment button text"),
                                       NSLocalizedString(@"Routes",    @"Short segment button text"),
                                       ]
                              action:@selector(showSegmentChanged:)];
            }
            
            [self getSeg:cell].selectedSegmentIndex = _show;
            return cell;
        }
        case kModeSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kModeSection)];
            if (cell == nil) {
                cell = [self segCell:MakeCellId(kModeSection)
                               items:@[
                                       NSLocalizedString(@"Bus only",          @"Short segment button text"),
                                       NSLocalizedString(@"Rail only",         @"Short segment button text"),
                                       NSLocalizedString(@"Bus or Rail",       @"Short segment button text"),
                                       ]
                              action:@selector(modeSegmentChanged:)];
            }
            
            [self getSeg:cell].selectedSegmentIndex = _mode;
            return cell;
        }
        case kAutoSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kAutoSection)];
            if (cell == nil) {
                cell = [self segCell:MakeCellId(kAutoSection)
                               items:@[
                                       NSLocalizedString(@"Show this page",@"Short segment button text"),
                                       NSLocalizedString(@"Show results", @"Short segment button text"),
                                       ]
                              action:@selector(autoSegmentChanged:)];
            }
            
            if ([UserPrefs singleton].autoLocateShowOptions)
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
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kGpsLocateSection)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kGpsLocateSection)] autorelease];
            }
            
            if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:NO])
            {
                cell.textLabel.text = NSLocalizedString(@"Start locating", @"Button text");
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Current location not authorized", @"Button text");
            }
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = self.basicFont;
            
            [self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
            return cell;
        }
        case kNoGpsLocateSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kNoGpsLocateSection)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kNoGpsLocateSection)] autorelease];
            }
            cell.textLabel.text = NSLocalizedString(@"Find nearby stops", @"Button text");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = self.basicFont;
            
            [self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
            return cell;
        }
        case kMapSection:
        {
            UITableViewCell *cell = [self getMapCell:MakeCellId(kMapSection) withUserLocation:YES];
            
            if (self.startingLocation)
            {
                SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];
                
                annotLoc.pinTitle = self.startingLocationName;
                annotLoc.pinColor = MKPinAnnotationColorRed;
                annotLoc.coordinate = self.startingLocation.coordinate;
                
                [self.mapView addAnnotation:annotLoc];
            }
            
            [self startCircleTimer];
            [self updateCircle];
            
            return cell;
        }
            
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch ([self sectionType:indexPath.section])
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
    
    if ([cell.reuseIdentifier isEqualToString:MakeCellId(kGpsLocateSection)])
	{
        if (![LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:NO])
        {
            cell.backgroundColor = [UIColor redColor];
        }
	}
}


#pragma mark View methods

- (void)viewWillDisappear:(BOOL)animated
{
    // if (!_autoLaunch)
    {
        self.lastLocate = [@{ kLocateMode : @(_mode),
                             kLocateDist : @(_dist),
                             kLocateShow : @(_show) }.mutableCopy autorelease];
        
        _userData.lastLocate = self.lastLocate;
    }
    
    if (self.mapUpdateTimer)
    {
        [self.mapUpdateTimer invalidate];
        self.mapUpdateTimer = nil;
    }
    
    if (self.mapView)
    {
        self.mapView.delegate = nil;
    }
    
    [super viewWillDisappear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.mapView)
    {
        self.mapView.delegate = self;
    }
    
    bool authorized = YES;
    
    if (self.startingLocation==nil)
    {
        authorized = [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:YES backgroundRequired:NO];
    }
    
    
    if (_autoLaunch && _firstDisplay && authorized)
    {
        _firstDisplay=NO;
        [self startLocating];
    }
    else
    {
        [self startCircleTimer];
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


- (void)didTapMap:(id)sender
{
    [self updateCircle];
}


@end


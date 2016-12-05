//
//  RailStationTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStationTableView.h"
#import "DepartureTimesView.h"
#import "WebViewController.h"
#import "SimpleAnnotation.h"
#import "MapViewController.h"
#import "RailMapView.h"
#import "AllRailStationView.h"
#import "TriMetRouteColors.h"
#import "DirectionView.h"
#import "AlarmTaskList.h"
#import "TripPlannerSummaryView.h"
#import "FindByLocationView.h"



@implementation RailStationTableView

@synthesize station			= _station;
@synthesize from			= _from;
@synthesize locationsDb		= _locationsDb;
@synthesize map				= _map;
@synthesize routes			= _routes;

enum SECTIONS_AND_ROWS {
    kSectionStation,
    kSectionArrivals,
    kSectionTripPlanner,
    kSectionRoute,
    kSectionWikiLink,
    kSectionAlarm,
    kSectionMap,
    kRowStation,
    kRowAllArrivals,
    kRowLocationArrival,
    kRowNearbyStops,
    kRowWikiLink,
    kRowTripToHere,
    kRowTripFromHere,
    kRowProximityAlarm,
    kRowRoute,
    kRowMap
};

#define kDirectionCellHeight	45.0
#define DIRECTION_TAG			1
#define ID_TAG					2


- (void)dealloc {
	self.locationsDb = nil;
	self.station = nil;
	self.map = nil;
	self.routes = nil;
	[super dealloc];
}


- (instancetype)init {
	if ((self = [super init]))
	{
        self.title = NSLocalizedString(@"Station Details", @"page title");
	}
	return self;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle) getStyle
{
	return UITableViewStylePlain;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{	
	[toolbarItems addObject:[UIToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    [toolbarItems addObject:[UIToolbar autoFlexSpace]];
    
    
	if (self.map != nil)
    {
        [toolbarItems addObject: [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"button text")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showNext:)] autorelease]];
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
    }
	
	
    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AlarmTaskList *taskList = [AlarmTaskList singleton];
    NSString *stopId = self.station.locList.firstObject;
	CLLocation *here = [self.locationsDb getLocation:stopId];

	[taskList userAlertForProximityAction:buttonIndex 
								   stopId:stopId 
									  loc:here
									 desc:self.station.station];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)addLineToRoutes:(RAILLINES)line
{
	if (self.station.line & line) 
	{
		[self.routes addObject:@(line)];
	}
}

- (void)viewDidLoad
{
	// Workout if we have any routes
	
    self.routes = [NSMutableArray array];

	
	[self addLineToRoutes:kBlueLine];
	[self addLineToRoutes:kRedLine];
	[self addLineToRoutes:kGreenLine];
	[self addLineToRoutes:kYellowLine];
	[self addLineToRoutes:kStreetcarALoop];
    [self addLineToRoutes:kStreetcarBLoop];
    [self addLineToRoutes:kStreetcarNsLine];
	[self addLineToRoutes:kWesLine];
    [self addLineToRoutes:kOrangeLine];
    
    
    if (self.callback)
    {
        self.title = NSLocalizedString(@"Choose a stop below:", @"main page title");
    }
    
    [self clearSectionMaps];
    
    [self addSectionType:kSectionStation];
    [self addRowType:kRowStation];
    [self addRowType:kRowMap];
    
    
    NSInteger arrivalSection = [self addSectionType:kSectionArrivals];
    
    NSInteger rows = self.station.locList.count;
    if (rows > 1 && self.callback == nil)
    {
        [self addRowType:kRowAllArrivals];
    }
    
    _firstLocationRow = [self rowsInSection:arrivalSection];
    
    for (int i=0; i< rows; i++)
    {
        [self addRowType:kRowLocationArrival];
    }
    
    if (self.callback ==nil)
    {
        [self addRowType:kRowNearbyStops];
        [self addSectionType:kSectionTripPlanner];
        [self addRowType:kRowTripToHere];
        [self addRowType:kRowTripFromHere];
    }
    
    if (self.station.wikiLink)
    {
        [self addSectionType:kSectionWikiLink];
        [self addRowType:kRowWikiLink];
    }
    
    if (self.routes.count > 0)
    {
        [self addSectionType:kSectionRoute];
    
        for (int i=0; i < self.routes.count; i++)
        {
            [self addRowType:kRowRoute];
        }
    }
    
    if ([AlarmTaskList proximitySupported])
    {
        [self addSectionType:kSectionAlarm];
        [self addRowType:kRowProximityAlarm];
    }
    
    [super viewDidLoad];
}

#pragma mark UI helper functions

- (UITableViewCell *)plainCell:(UITableView *)tableView
{
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.font = self.basicFont;
	
	return cell;
	
}

-(void)showMap:(id)sender
{
    int i;
    CLLocation *here;
    
    MapViewController *mapPage = [MapViewController viewController];
    
    for (i=0; i< self.station.locList.count;  i++)
    {
        here = [self.locationsDb getLocation:self.station.locList[i]];
        
        if (here)
        {
            Stop *a = [Stop data];
            
            a.locid = self.station.locList[i];
            a.desc  = self.station.station;
            a.dir   = self.station.dirList[i];
            a.lat   = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
            a.lng   = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
            a.callback = self;
            
            [mapPage addPin:a];
        }
    }
    mapPage.callback = self.callback;
    [self.navigationController pushViewController:mapPage animated:YES];
}

-(void)showNext:(id)sender
{
    self.map.showNextOnAppearance = YES;
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSInteger sectionType = [self sectionType:section];
    
	switch (sectionType)
    {
		case kSectionRoute:
            return NSLocalizedString(@"Routes", @"section header");
		case kSectionStation:
			return nil;
        case kSectionTripPlanner:
            return NSLocalizedString(@"Trip Planner", @"section header");
		case kSectionArrivals:
			
			if (self.callback)
			{
				return NSLocalizedString(@"Choose from one of these stop(s):", @"section header");
			}
			return NSLocalizedString(@"Arrivals", @"section header");
		case kSectionWikiLink:
			return NSLocalizedString(@"More Information", @"section header");
		case kSectionAlarm:
			return NSLocalizedString(@"Alarms", @"section header");
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
 	
    return [self sections];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self rowType:indexPath] == kRowMap)
    {
        return [self mapCellHeight];
    }
    
    return self.basicRowHeight;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self rowsInSection:section];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    NSInteger rowType = [self rowType:indexPath];
	switch (rowType)
	{
		case kRowStation:
        default:
		{
			NSString *cellId = [NSString stringWithFormat:@"station%f", self.screenInfo.appWinWidth];
			cell = [tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:cellId 
														   rowHeight:[self basicRowHeight] 
														 screenWidth:self.screenInfo.screenWidth
														 rightMargin:NO
																font:self.basicFont];
				
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
			}
			
			
			// cell = [self plainCell:tableView];
			//cell.textLabel.text =  self.station.station;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.imageView.image = nil;
			//cell.textLabel.textAlignment = NSTextAlignmentCenter;
			
			
			[RailStation populateCell:cell 
							  station:self.station.station
								lines:[AllRailStationView railLines:self.station.index]];
			
			break;
		}
        case kRowTripToHere:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Plan trip to here", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconTripPlanner];
            break;
            
        case kRowTripFromHere:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Plan trip from here", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconTripPlanner];
            break;
		case kRowAllArrivals:
			cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"All arrivals", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconRecent];
            break;
        case kRowLocationArrival:
            cell = [self plainCell:tableView];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (ID %@)",
                                   self.station.dirList[indexPath.row-_firstLocationRow],
                                   self.station.locList[indexPath.row-_firstLocationRow]];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            if (self.callback==nil)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.imageView.image = [self getActionIcon:kIconRecent];
            break;
        case kRowNearbyStops:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Nearby stops", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
			break;
		case kRowWikiLink:
			cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Wikipedia article", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconWiki];
            break;
		case kRowProximityAlarm:
			cell = [self plainCell:tableView];
			cell.textLabel.text = kUserProximityCellText;
			cell.imageView.image = [self getActionIcon:kIconAlarm];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case kRowRoute:
		{
			RAILLINES line = self.routes[indexPath.row].intValue;
			
			NSString *cellId = [NSString stringWithFormat:@"route%f", self.screenInfo.appWinWidth];
			cell = [tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:cellId 
														   rowHeight:[self basicRowHeight] 
														 screenWidth:self.screenInfo.screenWidth
														 rightMargin:YES
																font:self.basicFont];
				
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
			}
			
			
			// cell = [self plainCell:tableView];
			//cell.textLabel.text =  self.station.station;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			//cell.textLabel.textAlignment = NSTextAlignmentCenter;
			
			
			[RailStation populateCell:cell 
							  station:[NSString stringWithFormat:@"%@ info", [TriMetRouteColors rawColorForLine:line]->name]
								lines:line];
            break;
			
		}
        case kRowMap:
        {
            cell = [self getMapCell:MakeCellId(kRowMap) withUserLocation:NO];
            
            MKMapRect flyTo = MKMapRectNull;
            
            for (int i=0; i<self.station.locList.count; i++)
            {
                NSString *stopId = self.station.locList[i];
                NSString *dir =    self.station.dirList [i];
                
                CLLocation *loc = [self.locationsDb getLocation:stopId];
                
                SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];
                
                annotLoc.pinTitle = dir;
                annotLoc.pinColor = MKPinAnnotationColorRed;
                annotLoc.coordinate = loc.coordinate;
                
                [self.mapView addAnnotation:annotLoc];
                
                MKMapPoint annotationPoint = MKMapPointForCoordinate(loc.coordinate);
                
                MKMapRect busRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 2000);
                
                flyTo = MKMapRectUnion(flyTo, busRect);
                
            }
            
            UIEdgeInsets insets = {
                30, 10,
                10, 20
            };
            
            [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo edgePadding:insets] animated:YES];
            break;
        }
            
				
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowStation:
            break;
        case kRowTripToHere:
        case kRowTripFromHere:
        {
            TripPlannerSummaryView *tripPlanner = [TripPlannerSummaryView viewController];
            
            // Push the detail view controller
            
            TripEndPoint *endpoint = nil;
            
            if (rowType == kRowTripFromHere)
            {
                endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
            }
            else
            {
                endpoint = tripPlanner.tripQuery.userRequest.toPoint;
            }
            
            
            endpoint.useCurrentLocation = false;
            endpoint.additionalInfo     = self.station.station;
            endpoint.locationDesc       = self.station.locList.firstObject;
            
            
            [self.navigationController pushViewController:tripPlanner animated:YES];
            break;
        }
        case kRowAllArrivals:
        {
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
            
            NSMutableString *locs = [NSMutableString string];
            
            int i;
            
            [locs appendString:self.station.locList.firstObject];
            
            for (i=1; i< self.station.locList.count; i++)
            {
                [locs appendFormat:@",%@", self.station.locList[i]];
            }
            
            [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:locs];
            break;
        }
        case kRowLocationArrival:
        {
            
            if (self.callback)
            {
                
                if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
                {
                    [self.callback selectedStop:self.station.locList[indexPath.row] desc:self.station.station];
                }
                else
                {
                    [self.callback selectedStop:self.station.locList[indexPath.row]];
                    
                }
            }
            else if ((indexPath.row- _firstLocationRow) < self.station.locList.count)
            {
                [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                                  loc:self.station.locList[indexPath.row-_firstLocationRow]];
            }
            break;
        }
        case kRowNearbyStops:
        {
            CLLocation *here = [self.locationsDb getLocation:self.station.locList.firstObject];
            
            if (here !=nil)
            {
                FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:here description:self.station.station];
                
                [self.navigationController pushViewController:find animated:YES];
                
                [find release];
            }
            else
            {
                UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Nearby stops", @"alert title")
                                                                   message:NSLocalizedString(@"No location info is availble for that stop.", @"alert message")
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                         otherButtonTitles:nil] autorelease];
                [alert show];
                
            }
            break;
        }
        case kRowWikiLink:
        {
            [WebViewController displayPage:[NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", self.station.wikiLink ]
                                      full:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/%@", self.station.wikiLink ]
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
        }
        case kRowProximityAlarm:
        {
            AlarmTaskList *taskList = [AlarmTaskList singleton];
            [taskList userAlertForProximity:self];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case kRowRoute:
        {
            RAILLINES line = self.routes[indexPath.row].intValue;
            NSString *route = [TriMetRouteColors routeString:[TriMetRouteColors rawColorForLine:line]];
            
            DirectionView *dirView = [DirectionView viewController];
            dirView.callback = self.callback;
            [dirView fetchDirectionsAsync:self.backgroundTask route:route];
            break;
        }
    }
}



#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress
{
	if (self.callback)
	{
		/*
		 if ([self.callback getController] != nil)
		 {
		 [self.navigationController popToViewController:[self.callback getController] animated:YES];
		 }
		 */		
		if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
		{
			[self.callback selectedStop:stop.locid desc:self.station.station];
		}
		else {
			[self.callback selectedStop:stop.locid];
		}

		
		return;
	}
	
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
	departureViewController.displayName = stop.desc;
	[departureViewController fetchTimesForLocationAsync:progress loc:stop.locid];
}

- (NSString *)actionText
{
	if (self.callback)
	{
		return [self.callback actionText];
	}
	return @"Show arrivals";
	
}

@end


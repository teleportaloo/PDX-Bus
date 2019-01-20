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
#import "TriMetInfo.h"
#import "DirectionView.h"
#import "AlarmTaskList.h"
#import "TripPlannerSummaryView.h"
#import "FindByLocationView.h"
#import "VehicleTableView.h"
#import "StringHelper.h"
#import "KMLRoutes.h"

@implementation RailStationTableView

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
    kRowNearbyVehicles,
    kRowWikiLink,
    kRowTripToHere,
    kRowTripFromHere,
    kRowProximityAlarm,
    kRowRoute,
    kRowMap
};

#define kDirectionCellHeight        45.0
#define DIRECTION_TAG               1
#define ID_TAG                      2




- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Station Details", @"page title");
    }
    return self;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle) style
{
    return UITableViewStylePlain;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{    
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    [toolbarItems addObject:[UIToolbar flexSpace]];
    
    
    if (self.map != nil)
    {
        [toolbarItems addObject: [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"button text")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showNext:)]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    
    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    // Workout if we have any routes
    
    self.routes = [NSMutableArray array];
    
    for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number!=kNoRoute; info++)
    {
        if (self.station.line & info->line_bit)
        {
            [self.routes addObject:@(info->line_bit)];
        }
    }
    
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
    [self addRowType:kRowLocationArrival count:rows];
    
    if (self.callback ==nil)
    {
        [self addRowType:kRowNearbyStops];
        
        if ([UserPrefs sharedInstance].vehicleLocations)
        {
            [self addRowType:kRowNearbyVehicles];
        }
        
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
        [self addRowType:kRowRoute count:self.routes.count];
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
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"Cell"];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
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
    
    if (self.shapes)
    {
        mapPage.lineCoords = self.shapes;
        mapPage.lineOptions = MapViewNoFitLines;
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
    
    return UITableViewAutomaticDimension;
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
            
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRowStation)
                                rowHeight:[self basicRowHeight]];
            
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
            cell.imageView.image = [self getIcon:kIconTripPlanner];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowTripFromHere:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Plan trip from here", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getIcon:kIconTripPlanner];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowAllArrivals:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"All arrivals", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getIcon:kIconRecent];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowLocationArrival:
            cell = [self plainCell:tableView];
            cell.textLabel.attributedText = [[NSString stringWithFormat:@"%@ #A#[(ID %@)#]",
                                              self.station.dirList[indexPath.row-_firstLocationRow],
                                              self.station.locList[indexPath.row-_firstLocationRow]] formatAttributedStringWithFont:self.basicFont];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            if (self.callback==nil)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.imageView.image = [self getIcon:kIconRecent];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowNearbyStops:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Nearby stops", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getIcon:kIconLocate7];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowNearbyVehicles:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Nearby vehicles", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getIcon:kIconLocate7];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowWikiLink:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Wikipedia article", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getIcon:kIconWiki];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowProximityAlarm:
            cell = [self plainCell:tableView];
            cell.textLabel.text = kUserProximityCellText;
            cell.imageView.image = [self getIcon:kIconAlarm];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowRoute:
        {
            RAILLINES line = self.routes[indexPath.row].intValue;
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRowRoute)
                                rowHeight:[self basicRowHeight]];
            
            // cell = [self plainCell:tableView];
            //cell.textLabel.text =  self.station.station;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = nil;
            //cell.textLabel.textAlignment = NSTextAlignmentCenter;
            
            
            [RailStation populateCell:cell
                              station:[NSString stringWithFormat:@"%@ info", [TriMetInfo infoForLine:line]->full_name]
                                lines:line];
            break;
            
        }
        case kRowMap:
        {
            cell = [self getMapCell:MakeCellId(kRowMap) withUserLocation:NO];
            
            MKMapRect flyTo = MKMapRectNull;
            
            bool showRoute = [UserPrefs sharedInstance].kmlRoutes;
            
            
            KMLRoutes *kml = [KMLRoutes xml];
            
            for (int i=0; i<self.station.locList.count; i++)
            {
                NSString *stopId = self.station.locList[i];
                NSString *dir =    self.station.dirList [i];
                
                CLLocation *loc = [self.locationsDb getLocation:stopId];
                
                SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];
                
                annotLoc.pinTitle = dir;
                annotLoc.pinColor = MAP_PIN_COLOR_RED;
                annotLoc.coordinate = loc.coordinate;
                
                [self.mapView addAnnotation:annotLoc];
                
                MKMapPoint annotationPoint = MKMapPointForCoordinate(loc.coordinate);
                
                MKMapRect busRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 2000);
                
                flyTo = MKMapRectUnion(flyTo, busRect);
                
                ShapeRoutePath *path;
                
                if (showRoute)
                {
                    NSMutableArray *overlays = [NSMutableArray array];
                    if (self.shapes == nil)
                    {
                        self.shapes = [NSMutableArray array];
                        
                        for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number!=kNoRoute; info++)
                        {
                            NSString *route = [TriMetInfo routeString:info];
                            
                            if ((self.station.line0 & info->line_bit)!=0)
                            {
                                path = [kml lineCoordsForRoute:route direction:kKmlFirstDirection];
                                if (path)
                                {
                                    [path addPolylines:overlays];
                                    [self.shapes addObject:path];
                                }
                            }
                            
                            if ((self.station.line1 & info->line_bit)!=0)
                            {
                                path = [kml lineCoordsForRoute:route direction:kKmlOptionalDirection];
                                if (path)
                                {
                                    [path addPolylines:overlays];
                                    [self.shapes addObject:path];
                                }
                            }
                        }
                    }
                    else
                    {
                        for (ShapeRoutePath *path in self.shapes)
                        {
                            [path addPolylines:overlays];
                        }
                    }
                    [self.mapView addOverlays:overlays];
                }
                
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
                
            }
            else
            {
                UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Nearby stops", @"alert title")
                                                                   message:NSLocalizedString(@"No location info is availble for that stop.", @"alert message")
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                         otherButtonTitles:nil];
                [alert show];
                
            }
            break;
        }
        case kRowNearbyVehicles:
        {
            CLLocation *here = [self.locationsDb getLocation:self.station.locList.firstObject];
            
            if (here !=nil)
            {
                [[VehicleTableView viewController] fetchNearestVehiclesAsync:self.backgroundTask
                                                                    location:here
                                                                 maxDistance:[UserPrefs sharedInstance].vehicleLocatorDistance
                                                           backgroundRefresh:NO
                 ];
            }
            else
            {
                UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Nearby vehicles", @"alert title")
                                                                   message:NSLocalizedString(@"No location info is availble for that stop.", @"alert message")
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                         otherButtonTitles:nil];
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
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            [taskList userAlertForProximity:self source:[tableView cellForRowAtIndexPath:indexPath]
                                 completion:^(bool cancelled, bool accurate) {
                                     if (!cancelled)
                                     {
                                         NSString *stopId = self.station.locList.firstObject;
                                         CLLocation *here = [self.locationsDb getLocation:stopId];
                                     
                                         [taskList addTaskForStopIdProximity:stopId loc:here desc:self.station.station accurate:accurate];
                                     }
                                     [self.table deselectRowAtIndexPath:indexPath animated:YES];
                                 }];
            break;
        }
        case kRowRoute:
        {
            RAILLINES line = self.routes[indexPath.row].intValue;
            NSString *route = [TriMetInfo routeString:[TriMetInfo infoForLine:line]];
            
            DirectionView *dirView = [DirectionView viewController];
            dirView.callback = self.callback;
            [dirView fetchDirectionsAsync:self.backgroundTask route:route];
            break;
        }
    }
}



#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskController>) progress
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


- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[RoutePolyline class]])
    {
        return [(RoutePolyline *)overlay renderer];
    }
    return [[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (void)maybeFetchRouteShapesAsync:(id<BackgroundTaskController>)task
{
    bool needsFetching = NO;
    
    KMLRoutes *kml = 0;
    
    if ([UserPrefs sharedInstance].kmlRoutes)
    {
        kml = [KMLRoutes xml];
        
        needsFetching = !kml.cached;
    }
    
    if (needsFetching)
    {
        [task taskRunAsync:^{
            [task taskStartWithItems:1 title:@"getting route shapes"];
            kml.oneTimeDelegate = task;
            [kml fetch];
            [task taskItemsDone:1];
            return (UIViewController*)self;
        }];
    }
    else
    {        
        [task taskCompleted:self];
    }

}

@end


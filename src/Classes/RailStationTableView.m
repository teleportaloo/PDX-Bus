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
#import "NSString+Helper.h"
#import "KMLRoutes.h"
#import "TaskState.h"
#import "Icons.h"
#import "UIAlertController+SimpleMessages.h"

@interface RailStationTableView () {
    NSInteger _firstLocationRow;
}


@property (nonatomic, strong) NSMutableArray<NSNumber *> *routes;

@property (nonatomic, strong) NSMutableArray<ShapeRoutePath *> *shapes;

@end

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

#define kDirectionCellHeight 45.0
#define DIRECTION_TAG        1
#define ID_TAG               2




- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Station Details", @"page title");
    }
    
    return self;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle)style {
    return UITableViewStylePlain;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    [toolbarItems addObject:[UIToolbar flexSpace]];
    
    if (self.map != nil) {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"button text")
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

- (void)viewDidLoad {
    // Workout if we have any routes
    
    self.routes = [NSMutableArray array];
    
    for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number != kNoRoute; info++) {
        if (self.station.line & info->line_bit) {
            [self.routes addObject:@(info->line_bit)];
        }
    }
    
    if (self.stopIdCallback) {
        self.title = NSLocalizedString(@"Choose a stop below:", @"main page title");
    }
    
    [self clearSectionMaps];
    
    [self addSectionType:kSectionStation];
    [self addRowType:kRowStation];
    [self addRowType:kRowMap];
    
    
    NSInteger arrivalSection = [self addSectionType:kSectionArrivals];
    
    NSInteger rows = self.station.stopIdArray.count;
    
    if (rows > 1 && self.stopIdCallback == nil) {
        [self addRowType:kRowAllArrivals];
    }
    
    _firstLocationRow = [self rowsInSection:arrivalSection];
    [self addRowType:kRowLocationArrival count:rows];
    
    if (self.stopIdCallback == nil) {
        [self addRowType:kRowNearbyStops];
        
        if (Settings.vehicleLocations) {
            [self addRowType:kRowNearbyVehicles];
        }
        
        [self addSectionType:kSectionTripPlanner];
        [self addRowType:kRowTripToHere];
        [self addRowType:kRowTripFromHere];
    }
    
    if (self.station.wikiLink) {
        [self addSectionType:kSectionWikiLink];
        [self addRowType:kRowWikiLink];
    }
    
    if (self.routes.count > 0) {
        [self addSectionType:kSectionRoute];
        [self addRowType:kRowRoute count:self.routes.count];
    }
    
    if ([AlarmTaskList proximitySupported]) {
        [self addSectionType:kSectionAlarm];
        [self addRowType:kRowProximityAlarm];
    }
    
    [super viewDidLoad];
}

#pragma mark UI helper functions

- (UITableViewCell *)plainCell:(UITableView *)tableView {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"Cell"];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.font = self.basicFont;
    return cell;
}

- (void)showMap:(id)sender {
    int i;
    CLLocation *here;
    
    MapViewController *mapPage = [MapViewController viewController];
    
    for (i = 0; i < self.station.stopIdArray.count; i++) {
        here = [AllRailStationView locationFromStopId:self.station.stopIdArray[i]];
        
        if (here) {
            Stop *a = [Stop data];
            
            a.stopId = self.station.stopIdArray[i];
            a.desc = self.station.station;
            a.dir = self.station.dirArray[i];
            a.lat = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
            a.lng = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
            a.callback = self;
            
            [mapPage addPin:a];
        }
    }
    
    if (self.shapes) {
        mapPage.lineCoords = self.shapes;
        mapPage.lineOptions = MapViewNoFitLines;
    }
    
    mapPage.stopIdCallback = self.stopIdCallback;
    [self.navigationController pushViewController:mapPage animated:YES];
}

- (void)showNext:(id)sender {
    self.map.showNextOnAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];
    
    switch (sectionType) {
        case kSectionRoute:
            return NSLocalizedString(@"Routes", @"section header");
            
        case kSectionStation:
            return nil;
            
        case kSectionTripPlanner:
            return NSLocalizedString(@"Trip Planner", @"section header");
            
        case kSectionArrivals:
            
            if (self.stopIdCallback) {
                return NSLocalizedString(@"Choose from one of these stop(s):", @"section header");
            }
            
            return NSLocalizedString(@"Departures", @"section header");
            
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kRowMap) {
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
    
    switch (rowType) {
        case kRowStation:
        default: {
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRowStation)
                                rowHeight:[self basicRowHeight]];
            
            // cell = [self plainCell:tableView];
            //cell.textLabel.text = self.station.station;
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
            cell.imageView.image = [Icons getIcon:kIconTripPlanner];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowTripFromHere:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Plan trip from here", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconTripPlanner];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowAllArrivals:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"All departures", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconRecent];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowLocationArrival:
            cell = [self plainCell:tableView];
            cell.textLabel.attributedText = FormatTextBasic(([NSString stringWithFormat:@"%@ #A#[(ID %@)#]",
                                                              self.station.dirArray[indexPath.row - _firstLocationRow],
                                                              self.station.stopIdArray[indexPath.row - _firstLocationRow]]));
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            if (self.stopIdCallback == nil) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.imageView.image = [Icons getIcon:kIconRecent];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowNearbyStops:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Nearby stops", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getModeAwareIcon:kIconLocate7];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowNearbyVehicles:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Nearby vehicles", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getModeAwareIcon:kIconLocate7];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowWikiLink:
            cell = [self plainCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Wikipedia article", @"main menu item");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons characterIcon:@"W"];
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowProximityAlarm:
            cell = [self plainCell:tableView];
            cell.textLabel.text = kUserProximityCellText;
            cell.imageView.image = [Icons getIcon:kIconAlarm];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
            
        case kRowRoute: {
            RAILLINES line = self.routes[indexPath.row].intValue;
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRowRoute)
                                rowHeight:[self basicRowHeight]];
            
            // cell = [self plainCell:tableView];
            //cell.textLabel.text = self.station.station;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = nil;
            //cell.textLabel.textAlignment = NSTextAlignmentCenter;
            
            
            [RailStation populateCell:cell
                              station:[NSString stringWithFormat:@"%@ info", [TriMetInfo infoForLine:line]->full_name]
                                lines:line];
            break;
        }
            
        case kRowMap: {
            cell = [self getMapCell:MakeCellId(kRowMap) withUserLocation:NO];
            
            MKMapRect flyTo = MKMapRectNull;
            
            bool showRoute = Settings.kmlRoutes;
            
            
            KMLRoutes *kml = [KMLRoutes xml];
            
            for (int i = 0; i < self.station.stopIdArray.count; i ++) {
                NSString *stopId = self.station.stopIdArray[i];
                NSString *dir = self.station.dirArray [i];
                
                CLLocation *loc = [AllRailStationView locationFromStopId:stopId];
                
                SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];
                
                annotLoc.pinTitle = dir;
                annotLoc.pinColor = MAP_PIN_COLOR_RED;
                annotLoc.coordinate = loc.coordinate;
                
                [self.mapView addAnnotation:annotLoc];
                
                MKMapPoint annotationPoint = MKMapPointForCoordinate(loc.coordinate);
                
                MKMapRect busRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 2000);
                
                flyTo = MKMapRectUnion(flyTo, busRect);
                
                ShapeRoutePath *path;
                
                if (showRoute) {
                    NSMutableArray *overlays = [NSMutableArray array];
                    
                    if (self.shapes == nil) {
                        self.shapes = [NSMutableArray array];
                        
                        for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number != kNoRoute; info++) {
                            NSString *route = [TriMetInfo routeString:info];
                            
                            if ((self.station.line0 & info->line_bit) != 0) {
                                path = [kml lineCoordsForRoute:route direction:kKmlFirstDirection];
                                
                                if (path) {
                                    [path addPolylines:overlays];
                                    [self.shapes addObject:path];
                                }
                            }
                            
                            if ((self.station.line1 & info->line_bit) != 0) {
                                path = [kml lineCoordsForRoute:route direction:kKmlOptionalDirection];
                                
                                if (path) {
                                    [path addPolylines:overlays];
                                    [self.shapes addObject:path];
                                }
                            }
                        }
                    } else {
                        for (ShapeRoutePath *path in self.shapes) {
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
    
    switch (rowType) {
        case kRowStation:
            break;
            
        case kRowTripToHere:
        case kRowTripFromHere: {
            TripPlannerSummaryView *tripPlanner = [TripPlannerSummaryView viewController];
            
            // Push the detail view controller
            
            TripEndPoint *endpoint = nil;
            
            if (rowType == kRowTripFromHere) {
                endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
            } else {
                endpoint = tripPlanner.tripQuery.userRequest.toPoint;
            }
            
            endpoint.useCurrentLocation = false;
            endpoint.additionalInfo = self.station.station;
            endpoint.locationDesc = self.station.stopIdArray.firstObject;
            
            
            [self.navigationController pushViewController:tripPlanner animated:YES];
            break;
        }
            
        case kRowAllArrivals: {
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
            
            NSString *stopIds = [NSString commaSeparatedStringFromStringEnumerator:self.station.stopIdArray];
            [departureViewController fetchTimesForLocationAsync:self.backgroundTask stopId:stopIds];
            break;
        }
            
        case kRowLocationArrival: {
            if (self.stopIdCallback) {
                if ([self.stopIdCallback respondsToSelector:@selector(selectedStop:desc:)]) {
                    [self.stopIdCallback selectedStop:self.station.stopIdArray[indexPath.row] desc:self.station.station];
                } else {
                    [self.stopIdCallback selectedStop:self.station.stopIdArray[indexPath.row]];
                }
            } else if ((indexPath.row - _firstLocationRow) < self.station.stopIdArray.count) {
                [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                            stopId:self.station.stopIdArray[indexPath.row - _firstLocationRow]];
            }
            
            break;
        }
            
        case kRowNearbyStops: {
            CLLocation *here = [AllRailStationView locationFromStopId:self.station.stopIdArray.firstObject];
            
            if (here != nil) {
                FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:here description:self.station.station];
                
                [self.navigationController pushViewController:find animated:YES];
            } else {
                UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Nearby stops", @"alert title")
                                                                        message:NSLocalizedString(@"No location info is availble for that stop.", @"alert message")];
                [self presentViewController:alert animated:YES completion:nil];

            }
            
            break;
        }
            
        case kRowNearbyVehicles: {
            CLLocation *here = [AllRailStationView locationFromStopId:self.station.stopIdArray.firstObject];
            
            if (here != nil) {
                [[VehicleTableView viewController] fetchNearestVehiclesAsync:self.backgroundTask
                                                                    location:here
                                                                 maxDistance:Settings.vehicleLocatorDistance
                                                           backgroundRefresh:NO
                 ];
            } else {
                UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Nearby vehicles", @"alert title")
                                                                        message:NSLocalizedString(@"No location info is availble for that stop.", @"alert message")];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            break;
        }
            
        case kRowWikiLink: {
            [WebViewController displayPage:[NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", self.station.wikiLink ]
                                      full:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/%@", self.station.wikiLink ]
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
        }
            
        case kRowProximityAlarm: {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            [taskList userAlertForProximity:self source:[tableView cellForRowAtIndexPath:indexPath]
                                 completion:^(bool cancelled, bool accurate) {
                if (!cancelled) {
                    NSString *stopId = self.station.stopIdArray.firstObject;
                    CLLocation *here = [AllRailStationView locationFromStopId:stopId];
                    
                    [taskList addTaskForStopIdProximity:stopId loc:here desc:self.station.station accurate:accurate];
                }
                
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
            }];
            break;
        }
            
        case kRowRoute: {
            RAILLINES line = self.routes[indexPath.row].intValue;
            NSString *route = [TriMetInfo routeString:[TriMetInfo infoForLine:line]];
            
            DirectionView *dirView = [DirectionView viewController];
            dirView.stopIdCallback = self.stopIdCallback;
            [dirView fetchDirectionsAsync:self.backgroundTask route:route];
            break;
        }
    }
}

#pragma mark ReturnStop callbacks

- (void)chosenStop:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdCallback) {
        /*
         if ([self.callback getController] != nil)
         {
         [self.navigationController popToViewController:[self.callback getController] animated:YES];
         }
         */
        if ([self.stopIdCallback respondsToSelector:@selector(selectedStop:desc:)]) {
            [self.stopIdCallback selectedStop:stop.stopId desc:self.station.station];
        } else {
            [self.stopIdCallback selectedStop:stop.stopId];
        }
        
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:progress stopId:stop.stopId];
}

- (NSString *)actionText {
    if (self.stopIdCallback) {
        return [self.stopIdCallback actionText];
    }
    
    return @"Show departures";
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[RoutePolyline class]]) {
        return [(RoutePolyline *)overlay renderer];
    }
    
    return [[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (void)maybeFetchRouteShapesAsync:(id<TaskController>)taskController {
    bool needsFetching = NO;
    
    KMLRoutes *kml = 0;
    
    if (Settings.kmlRoutes) {
        kml = [KMLRoutes xml];
        
        needsFetching = !kml.cached;
    }
    
    if (needsFetching) {
        [taskController taskRunAsync:^(TaskState *taskState) {
            [taskState startAtomicTask:NSLocalizedString(@"started to get route shapes", @"progress message")];
            kml.oneTimeDelegate = taskState;
            [kml fetchInBackground:NO];
            [taskState atomicTaskItemDone];
            return (UIViewController *)self;
        }];
    } else {
        [taskController taskCompleted:self];
    }
}

@end

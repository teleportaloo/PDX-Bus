//
//  RailStationTableViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStationTableViewController.h"
#import "AlarmTaskList.h"
#import "AllRailStationViewController.h"
#import "DepartureTimesViewController.h"
#import "Detour+iOSUI.h"
#import "DetourTableViewCell.h"
#import "DirectionViewController.h"
#import "FindByLocationViewController.h"
#import "Icons.h"
#import "KMLRoutes.h"
#import "MapViewController.h"
#import "MapViewControllerWithStops.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "RailMapViewController.h"
#import "RailStation+UI.h"
#import "RunParallelBlocks.h"
#import "SimpleAnnotation.h"
#import "SimpleStop.h"
#import "StationData.h"
#import "Stop+UI.h"
#import "TaskState.h"
#import "TriMetInfo.h"
#import "TripPlannerSummaryViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UITableViewCell+Icons.h"
#import "VehicleTableViewController.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "WebViewController.h"
#import "XMLDetours.h"

#define kDetourId @"D"

@interface RailStationTableViewController () {
    NSInteger _firstLocationRow;
}

@property(nonatomic, strong) NSArray<NSValue *> *routeInfo;

@property(nonatomic, strong) NSMutableArray<ShapeRoutePath *> *shapes;

@property(nonatomic, strong) XMLDetoursAndMessages *detourData;

@end

@implementation RailStationTableViewController

enum SECTIONS_AND_ROWS {
    kSectionStation,
    kSectionArrivals,
    kSectionDetours,
    kSectionTripPlanner,
    kSectionRoute,
    kSectionWikiLink,
    kSectionTransfers,
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
    kRowTransfer,
    kRowDetour,
    kRowMap
};

#define kDirectionCellHeight 45.0
#define DIRECTION_TAG 1
#define ID_TAG 2

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Station Details", @"page title");
        self.refreshFlags = kRefreshNoTimer;
    }

    return self;
}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        self.backgroundRefresh = YES;
        [self fetchShapesAndDetoursAsync:self.backgroundTask];
    }
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle)style {
    return UITableViewStylePlain;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems
        addObject:[UIToolbar mapButtonWithTarget:self
                                          action:@selector(showMap:)]];
    [toolbarItems addObject:[UIToolbar flexSpace]];

    if (self.map != nil) {
        [toolbarItems addObject:[[UIBarButtonItem alloc]
                                    initWithTitle:NSLocalizedString(
                                                      @"Next", @"button text")
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(showNext:)]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }

    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
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

    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kSystemDetourResuseIdentifier];
    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kDetourResuseIdentifier];

    if (self.stopIdStringCallback) {
        self.title =
            NSLocalizedString(@"Choose a stop below:", @"main page title");
    }

    [self clearSectionMaps];

    [self addSectionType:kSectionStation];
    [self addRowType:kRowStation];
    [self addRowType:kRowMap];

    NSInteger arrivalSection = [self addSectionType:kSectionArrivals];

    NSInteger rows = self.station.stopIdArray.count;

    if ((rows + self.station.transferStopIdArray.count) > 1 &&
        self.stopIdStringCallback == nil) {
        [self addRowType:kRowAllArrivals];
    }

    _firstLocationRow = [self rowsInSection:arrivalSection];
    [self addRowType:kRowLocationArrival count:rows];

    if (self.stopIdStringCallback == nil) {
        [self addRowType:kRowNearbyStops];

        if (Settings.vehicleLocations) {
            [self addRowType:kRowNearbyVehicles];
        }
    }

    if (self.station.transferStopIdArray.count > 0) {
        [self addSectionType:kSectionTransfers];
        [self addRowType:kRowTransfer
                   count:self.station.transferStopIdArray.count];
    }

    if (self.detourData.items.count > 0) {
        [self addSectionType:kSectionDetours];
        [self addRowType:kRowDetour count:self.detourData.items.count];
    }

    if (self.stopIdStringCallback == nil) {
        [self addSectionType:kSectionTripPlanner];
        [self addRowType:kRowTripToHere];
        [self addRowType:kRowTripFromHere];
    }

    if (self.station.wikiLink) {
        [self addSectionType:kSectionWikiLink];
        [self addRowType:kRowWikiLink];
    }

    if (self.routeInfo.count > 0) {
        [self addSectionType:kSectionRoute];
        [self addRowType:kRowRoute count:self.routeInfo.count];
    }

    if ([AlarmTaskList proximitySupported]) {
        [self addSectionType:kSectionAlarm];
        [self addRowType:kRowProximityAlarm];
    }

    [super viewDidLoad];
}

#pragma mark UI helper functions

- (UITableViewCell *)plainCell:(UITableView *)tableView {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"Cell"];

    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.font = self.basicFont;
    return cell;
}

- (void)showMap:(id)sender {
    int i;
    CLLocation *here;
    bool tp;

    MapViewController *mapPage = [MapViewController viewController];

    for (i = 0; i < self.station.stopIdArray.count; i++) {
        here = [StationData locationFromStopId:self.station.stopIdArray[i]];
        tp = [StationData tpFromStopId:self.station.stopIdArray[i]];

        if (here) {
            Stop *a = [Stop new];

            a.stopId = self.station.stopIdArray[i];
            a.desc = self.station.name;
            a.dir = self.station.dirArray[i];
            a.location = here;
            a.stopObjectCallback = self;
            a.timePoint = tp;

            [mapPage addPin:a];
        }
    }

    if (self.shapes) {
        mapPage.shapes = self.shapes;
        mapPage.lineOptions = MapViewNoFitLines;
    }

    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    [self.navigationController pushViewController:mapPage animated:YES];
}

- (void)showNext:(id)sender {
    self.map.showNextOnAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];

    switch (sectionType) {
    case kSectionRoute:
        return NSLocalizedString(@"Routes", @"section header");

    case kSectionStation:
        return nil;

    case kSectionTripPlanner:
        return NSLocalizedString(@"Trip Planner", @"section header");

    case kSectionArrivals:

        if (self.stopIdStringCallback) {
            return NSLocalizedString(@"Choose from one of these stop(s):",
                                     @"section header");
        }

        return NSLocalizedString(@"Departures", @"section header");

    case kSectionWikiLink:
        return NSLocalizedString(@"More Information", @"section header");

    case kSectionAlarm:
        return NSLocalizedString(@"Alarms", @"section header");

    case kSectionTransfers:
        return NSLocalizedString(@"Rail Transfers", @"section header");

    case kSectionDetours:
        return NSLocalizedString(@"Detours", @"section header");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kRowMap) {
        return [self mapCellHeight];
    }

    return UITableViewAutomaticDimension;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    NSInteger rowType = [self rowType:indexPath];

    switch (rowType) {
    case kRowStation:
    default: {
        RailStationViewCell *railCell =
            [RailStation tableView:tableView
                cellWithReuseIdentifier:MakeCellId(kRowStation)
                              rowHeight:[self basicRowHeight]
                            rightMargin:YES];

        [railCell
            populateCellWithStation:self.station.name.safeEscapeForMarkUp
                              lines:[StationData railLines:self.station.index]];

        cell = railCell;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = nil;
        break;
    }

    case kRowTripToHere:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Plan a trip to here", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.systemIcon = kSFIconTripPlanner;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowTripFromHere:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Plan a trip from here", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.systemIcon = kSFIconTripPlanner;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowAllArrivals:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Show all departures", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.systemIcon = kSFIconRecent;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowLocationArrival: {
        NSInteger stopIndex = indexPath.row - _firstLocationRow;
        NSString *stopId = self.station.stopIdArray[stopIndex];

        RailStationViewCell *railCell =
            [RailStation tableView:tableView
                cellWithReuseIdentifier:MakeCellId(kRowTransfer)
                              rowHeight:[self basicRowHeight]
                            rightMargin:NO];

        [railCell
            populateCellWithStation:
                [NSString stringWithFormat:@"%@ #A#[(ID %@)#]",
                                           self.station.dirArray[stopIndex],
                                           stopId]
                              lines:[StationData railLinesForStopId:stopId]];
        cell = railCell;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.systemIcon = kSFIconRecent;
        if (self.stopIdStringCallback == nil) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        cell.systemIcon = kSFIconRecent;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;
    }

    case kRowNearbyStops:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Nearby stops", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.systemIcon = kSFIconLocateNearby;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowTransfer: {
        RailStationViewCell *railCell =
            [RailStation tableView:tableView
                cellWithReuseIdentifier:MakeCellId(kRowTransfer)
                              rowHeight:[self basicRowHeight]
                            rightMargin:NO];

        [railCell
            populateCellWithStation:
                [NSString
                    stringWithFormat:@"%@ - #A#[%@#]",
                                     self.station
                                         .transferNameArray[indexPath.row],
                                     self.station
                                         .transferDirArray[indexPath.row]]
                              lines:[StationData
                                        railLinesForStopId:
                                            self.station.transferStopIdArray
                                                [indexPath.row]]];
        cell = railCell;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.systemIcon = kSFIconRecent;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
    }

    case kRowDetour: {

        Detour *det = self.detourData.items[indexPath.row];

        DetourTableViewCell *dcell = [self detourCell:det indexPath:indexPath];

        dcell.includeHeaderInDescription = YES;

        cell = dcell;

        break;
    }

    case kRowNearbyVehicles:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Nearby vehicles", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.systemIcon = kSFIconLocateMe;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowWikiLink:
        cell = [self plainCell:tableView];
        cell.textLabel.text =
            NSLocalizedString(@"Wikipedia article", @"main menu item");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [Icons characterIcon:@"W"];
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowProximityAlarm:
        cell = [self plainCell:tableView];
        cell.textLabel.text = kUserProximityCellText;
        cell.systemIcon = kSFIconAlarm;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessibilityLabel = cell.textLabel.text.phonetic;
        break;

    case kRowRoute: {
        TriMetInfo_ColoredLines line =
            self.routeInfo[indexPath.row].PtrConstRouteInfoValue->line_bit;

        RailStationViewCell *railCell =
            [RailStation tableView:tableView
                cellWithReuseIdentifier:MakeCellId(kRowRoute)
                              rowHeight:[self basicRowHeight]
                            rightMargin:NO];

        [railCell
            populateCellWithStation:[NSString
                                        stringWithFormat:@"%@ info",
                                                         [TriMetInfo
                                                             infoForLine:line]
                                                             ->full_name]
                              lines:line];

        cell = railCell;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = nil;
        break;
    }

    case kRowMap: {
        cell = [self getMapCell:MakeCellId(kRowMap)
               withUserLocation:NO
                     completion:^(MKMapView *map) {
                       self.mapFlyTo = MKMapRectNull;

                       NSArray<SimpleAnnotation *> *pins = self.makePins;

                       for (SimpleAnnotation *pin in pins) {
                           [self.mapView addAnnotation:pin];
                           MKMapPoint annotationPoint =
                               MKMapPointForCoordinate(pin.coordinate);
                           MKMapRect busRect = MakeMapRectWithPointAtCenter(
                               annotationPoint.x, annotationPoint.y, 300, 2000);
                           self.mapFlyTo =
                               MKMapRectUnion(self.mapFlyTo, busRect);
                       }

                       if (Settings.kmlRoutes) {
                           NSMutableArray *overlays = [NSMutableArray array];

                           if (self.shapes == nil) {
                               self.shapes = self.makeShapes;
                           }

                           for (ShapeRoutePath *path in self.shapes) {
                               [path addPolylines:overlays];
                           }
                           [self.mapView addOverlays:overlays];
                       }

                       [self centerMap];
                     }];

        break;
    }
    }

    return cell;
}

- (NSMutableArray *)makeShapes {

    NSMutableArray<ShapeRoutePath *> *shapes = [NSMutableArray array];
    KMLRoutes *kml = [KMLRoutes xml];
    NSMutableSet<RailStation *> *stations = [NSMutableSet set];
    ShapeRoutePath *path = nil;

    [stations addObject:self.station];

    for (NSString *tranferStopId in self.station.transferStopIdArray) {
        RailStation *otherStation =
            [StationData railstationFromStopId:tranferStopId];
        if (otherStation) {
            [stations addObject:otherStation];
        }
    }

    for (PtrConstRouteInfo info = TriMetInfoColoredLines.allLines;
         info->route_number != kNoRoute; info++) {
        NSString *route = [TriMetInfo routeIdString:info];

        for (RailStation *station in stations) {

            TriMetInfo_ColoredLines line0 =
                [StationData railLines0:station.index];
            TriMetInfo_ColoredLines line1 =
                [StationData railLines1:station.index];

            if ((line0 & info->line_bit) != 0) {
                path = [kml lineCoordsForRoute:route
                                     direction:kKmlFirstDirection];

                if (path) {
                    [shapes addObject:path];
                }
            }

            if ((line1 & info->line_bit) != 0) {
                path = [kml lineCoordsForRoute:route
                                     direction:kKmlOptionalDirection];
                if (path) {
                    [shapes addObject:path];
                }
            }
        }
    }
    return shapes;
}

- (NSArray *)makePins {
    NSMutableArray *pins = [NSMutableArray array];

    NSMutableArray *stops = [NSMutableArray array];
    [stops addObjectsFromArray:self.station.stopIdArray];
    [stops addObjectsFromArray:self.station.transferStopIdArray];

    NSMutableArray *dirs = [NSMutableArray array];
    [dirs addObjectsFromArray:self.station.dirArray];
    [dirs addObjectsFromArray:self.station.transferDirArray];

    NSMutableArray *names = [NSMutableArray array];
    for (NSInteger i = 0; i < self.station.stopIdArray.count; i++) {
        [names addObject:self.station.name];
    }

    for (NSInteger i = 0; i < self.station.transferStopIdArray.count; i++) {
        [names addObject:self.station.transferNameArray[i]];
    }

    for (int i = 0; i < stops.count; i++) {
        NSString *stopId = stops[i];
        NSString *dir = dirs[i];

        CLLocation *loc = [StationData locationFromStopId:stopId];
        bool tp = [StationData tpFromStopId:stopId];

        SimpleStop *annotLoc = [SimpleStop annotation];

        annotLoc.pinTitle = names[i];
        annotLoc.pinSubtitle = dir;
        annotLoc.stopId = stopId;

        if ([self.station.transferStopIdArray containsObject:stopId]) {
            annotLoc.pinColor = MAP_PIN_COLOR_PURPLE;
        } else {
            annotLoc.pinColor = tp ? MAP_PIN_COLOR_BLUE : MAP_PIN_COLOR_RED;
        }
        annotLoc.coordinate = loc.coordinate;

        [pins addObject:annotLoc];
    }

    return pins;
}

- (void)showMap {
    MapViewController *mapPage = [MapViewController viewController];

    mapPage.title = self.station.name;
    mapPage.stopIdStringCallback = self.stopIdStringCallback;

    NSArray *pins = self.makePins;

    for (SimpleAnnotation *pin in pins) {
        [mapPage addPin:pin];
    }

    mapPage.shapes = self.makeShapes;
    mapPage.lineOptions = MapViewNoFitLines;

    [self.navigationController pushViewController:mapPage animated:YES];
}

- (void)didTapMap:(id)sender {
    [self showMap];
}

- (void)centerMap {
    UIEdgeInsets insets = {30, 10, 10, 20};

    [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:self.mapFlyTo
                                                      edgePadding:insets]
                           animated:YES];
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view
    // controller. AnotherViewController *anotherViewController =
    // [[AnotherViewController alloc] initWithNibName:@"AnotherView"
    // bundle:nil]; [self.navigationController
    // pushViewController:anotherViewController]; [anotherViewController
    // release];

    NSInteger rowType = [self rowType:indexPath];

    switch (rowType) {
    case kRowStation:
        break;

    case kRowTripToHere:
    case kRowTripFromHere: {
        TripPlannerSummaryViewController *tripPlanner =
            [TripPlannerSummaryViewController viewController];

        // Push the detail view controller

        TripEndPoint *endpoint = nil;

        if (rowType == kRowTripFromHere) {
            endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
        } else {
            endpoint = tripPlanner.tripQuery.userRequest.toPoint;
        }

        endpoint.useCurrentLocation = false;
        endpoint.additionalInfo = self.station.name;
        endpoint.locationDesc = self.station.stopIdArray.firstObject;

        [self.navigationController pushViewController:tripPlanner animated:YES];
        break;
    }

    case kRowAllArrivals: {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];

        NSString *stopIds = [NSString
            commaSeparatedStringFromStringEnumerator:self.station.stopIdArray];

        if (self.station.transferStopIdArray.count > 0) {
            stopIds = [NSString
                stringWithFormat:@"%@,%@", stopIds,
                                 [NSString
                                     commaSeparatedStringFromStringEnumerator:
                                         self.station.transferStopIdArray]];
        }

        [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                     stopId:stopIds];
        break;
    }

    case kRowLocationArrival: {
        if (self.stopIdStringCallback) {
            [self.stopIdStringCallback
                returnStopIdString:self.station.stopIdArray[indexPath.row -
                                                            _firstLocationRow]
                              desc:self.station.name];
        } else if ((indexPath.row - _firstLocationRow) <
                   self.station.stopIdArray.count) {
            [[DepartureTimesViewController viewController]
                fetchTimesForLocationAsync:self.backgroundTask
                                    stopId:self.station
                                               .stopIdArray[indexPath.row -
                                                            _firstLocationRow]];
        }

        break;
    }

    case kRowTransfer: {
        if (self.stopIdStringCallback) {
            [self.stopIdStringCallback
                returnStopIdString:self.station
                                       .transferStopIdArray[indexPath.row]
                              desc:self.station
                                       .transferNameArray[indexPath.row]];
        } else if (indexPath.row < self.station.transferStopIdArray.count) {
            [[DepartureTimesViewController viewController]
                fetchTimesForLocationAsync:self.backgroundTask
                                    stopId:self.station.transferStopIdArray
                                               [indexPath.row]];
        }

        break;
    }

    case kRowNearbyStops: {
        CLLocation *here = [StationData
            locationFromStopId:self.station.stopIdArray.firstObject];

        if (here != nil) {
            FindByLocationViewController *find =
                [[FindByLocationViewController alloc]
                    initWithLocation:here
                         description:self.station.name];

            [self.navigationController pushViewController:find animated:YES];
        } else {
            UIAlertController *alert = [UIAlertController
                simpleOkWithTitle:NSLocalizedString(@"Nearby stops",
                                                    @"alert title")
                          message:NSLocalizedString(@"No location info is "
                                                    @"availble for that stop.",
                                                    @"alert message")];
            [self presentViewController:alert animated:YES completion:nil];
        }

        break;
    }

    case kRowNearbyVehicles: {
        CLLocation *here = [StationData
            locationFromStopId:self.station.stopIdArray.firstObject];

        if (here != nil) {
            [[VehicleTableViewController viewController]
                fetchNearestVehiclesAsync:self.backgroundTask
                                 location:here
                              maxDistance:Settings.vehicleLocatorDistance
                        backgroundRefresh:NO];
        } else {
            UIAlertController *alert = [UIAlertController
                simpleOkWithTitle:NSLocalizedString(@"Nearby vehicles",
                                                    @"alert title")
                          message:NSLocalizedString(@"No location info is "
                                                    @"availble for that stop.",
                                                    @"alert message")];
            [self presentViewController:alert animated:YES completion:nil];
        }

        break;
    }

    case kRowWikiLink: {
        [WebViewController displayNamedPage:@"Wikipedia"
                                  parameter:self.station.wikiLink
                                  navigator:self.navigationController
                             itemToDeselect:self
                                   whenDone:self.callbackWhenDone];
        break;
    }

    case kRowProximityAlarm: {
        AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
        [taskList
            userAlertForProximity:self
                           source:[tableView cellForRowAtIndexPath:indexPath]
                       completion:^(bool cancelled, bool accurate) {
                         if (!cancelled) {
                             NSString *stopId =
                                 self.station.stopIdArray.firstObject;
                             CLLocation *here =
                                 [StationData locationFromStopId:stopId];

                             [taskList
                                 addTaskForStopIdProximity:stopId
                                                       loc:here
                                                      desc:self.station.name
                                                  accurate:accurate];
                         }

                         [self.tableView deselectRowAtIndexPath:indexPath
                                                       animated:YES];
                       }];
        break;
    }

    case kRowRoute: {
        NSString *route = [TriMetInfo
            routeIdString:self.routeInfo[indexPath.row].PtrConstRouteInfoValue];

        DirectionViewController *dirView =
            [DirectionViewController viewController];
        dirView.stopIdStringCallback = self.stopIdStringCallback;
        [dirView fetchDirectionsAsync:self.backgroundTask route:route];
        break;
    }

    case kRowDetour:
        [self detourToggle:self.detourData[indexPath.row]
                 indexPath:indexPath
             reloadSection:NO];
        break;
    }
}

#pragma mark ReturnStopObject callbacks

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        [self.stopIdStringCallback returnStopIdString:stop.stopId
                                                 desc:self.station.name];
        return;
    }

    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];

    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:progress
                                                 stopId:stop.stopId];
}

- (NSString *)returnStopObjectActionText {
    if (self.stopIdStringCallback) {
        return [self.stopIdStringCallback returnStopIdStringActionText];
    }

    return kNoAction;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[RouteMultiPolyline class]]) {
        return [(RouteMultiPolyline *)overlay renderer];
    }

    return [[MKCircleRenderer alloc]
        initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (void)fetchShapesAndDetoursAsync:(id<TaskController>)taskController {
    bool gettingShapes = NO;

    KMLRoutes *kml = 0;

    if (Settings.kmlRoutes) {
        kml = [KMLRoutes xml];

        gettingShapes = !kml.cached;
    }

    [taskController taskRunAsync:^(TaskState *taskState) {
      XML_DEBUG_INIT();

      [taskState setTotal:gettingShapes ? 2 : 1];

      [taskState startTask:@"Fetching station data"];

      RunParallelBlocks *blocks = RunParallelBlocks.instance;

      if (gettingShapes) {
          [blocks startBlock:^{
            [taskState
                taskSubtext:NSLocalizedString(@"started to get route paths",
                                              @"progress message")];
            kml.oneTimeDelegate = taskState;
            [kml fetchNowForced:NO];
            [taskState incrementItemsDoneAndDisplay];
          }];
      }

      [blocks startBlock:^{
        self.routeInfo = [self.station routeInfoWithTransfers];

        NSMutableArray *routeIDs = NSMutableArray.array;

        [self.routeInfo enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj,
                                                     NSUInteger idx,
                                                     BOOL *_Nonnull stop) {
          [routeIDs
              addObject:[TriMetInfo routeIdString:obj.PtrConstRouteInfoValue]];
        }];

        self.detourData = [XMLDetoursAndMessages xmlWithRoutes:routeIDs];
        [self.detourData fetchDetoursAndMessages:taskState];
        [self.detourData.items sortUsingSelector:@selector(compare:)];

        XML_DEBUG_RAW_DATA(self.detourData.messages);
        XML_DEBUG_RAW_DATA(self.detourData.detours);

        [taskState incrementItemsDoneAndDisplay];
      }];

      [blocks waitForBlocksWithState:taskState];

      return (UIViewController *)self;
    }];
}

@end

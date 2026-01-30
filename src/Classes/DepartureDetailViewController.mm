//
//  DepartureDetailViewController.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "DepartureDetailViewController.h"
#import "DepartureData+iOSUI.h"
#import "DepartureTimesViewController.h"
#import "Detour.h"
#import "DirectionViewController.h"
#import "StopViewController.h"
#import "WebViewController.h"
#import "XMLDetours.h"

#import "AlarmMinutesViewController.h"
#import "AlarmTaskList.h"
#import "BearingAnnotationView.h"
#import "BigRouteViewController.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "Detour+DTData.h"
#import "Detour+iOSUI.h"
#import "DetourTableViewCell.h"
#import "FormatDistance.h"
#import "Icons.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"
#import "MapViewController.h"
#import "MapViewControllerWithStops.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "PDXBus-Swift.h"
#import "RunParallelBlocks.h"
#import "SimpleAnnotation.h"
#import "TaskState.h"
#import "TextViewLinkCell.h"
#import "TriMetInfo+UI.h"
#import "TriMetInfo.h"
#import "TripPlannerSummaryViewController.h"
#import "UIBarButtonItem+Icons.h"
#import "UITableViewCell+Icons.h"
#import "Vehicle+iOSUI.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "ViewControllerBase+LinkCell.h"
#import "XMLLocateVehicles.h"

#define kFontName @"Arial"
#define kTextViewFontSize 16.0

#define kBlockRowFeet 0
#define kCellIdSimple @"Simple"

enum SECTIONS_AND_ROWS {
    kSectionRoute,
    kSectionTrips,
    kSectionInfo,
    kSectionSystemAlert,
    kRowRouteName,
    kRowRouteTimeInfo,
    kSectionRowDetour,
    kSectionRowLocation,
    kRowMap,
    kSectionAction,
    kRowTag,
    kRowSectionVehicle,
    kRowAlarm,
    kRowDestArrival,
    kRowNextStops,
    kRowOneStop,
    kRowMapAndSchedule,
    kRowBrowse,
    kRowPlanTrip,
    kRowMapWithStops,
    kRowTrip,
    kRowOpposite,
    kRowSiriAlertsForRoute,
    kRowNoDeeper,
    kSectionRowDisclaimerType
};

@interface DepartureDetailViewController () {
    NSInteger _firstDetourRow;
}

@property (nonatomic, strong) Departure *departure;
@property (nonatomic, strong) NSArray *allDepartures;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy) NSIndexPath *indexPathOfLocationCell;
@property (nonatomic, strong) NSMutableArray<ShapeRoutePath *> *shapes;
@property (nonatomic, strong) NSSet<NSString *> *streetcarRoutes;

- (void)showMap:(id)sender;
- (void)refreshAction:(id)unused;
- (void)updateSections;

@end

@implementation DepartureDetailViewController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Details", @"Departure details screen title");
        self.refreshFlags = kRefreshAll;
    }

    return self;
}

- (void)dealloc {
    if (_displayLink) {
        [_displayLink invalidate];
    }
}

#pragma mark Data fetchers

- (void)addPathToShape:(ShapeRoutePath *)path {
    if (path != nil) {
        [self.shapes addObject:path];
    }
}

- (void)setupShape:(id<TaskController>)taskController {
    KMLRoutes *kml = [KMLRoutes xmlWithOneTimeDelegate:taskController];

    [kml fetchInBackgroundForced:NO];

    PtrConstRouteInfo info = [TriMetInfo infoForRoute:self.departure.route];

    Departure *dep = self.departure;

    self.shapes = [NSMutableArray array];

    if (self.departure.blockPositionRouteNumber == nil) {
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:kKmlFirstDirection]];
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:kKmlOptionalDirection]];

        if (info && info->interlined_route) {
            [self addPathToShape:[kml lineCoordsForRoute:[TriMetInfo interlinedRouteString:info]
                                               direction:kKmlFirstDirection]];
            [self addPathToShape:[kml lineCoordsForRoute:[TriMetInfo interlinedRouteString:info]
                                               direction:kKmlOptionalDirection]];
        }
    } else if (dep.trips.count != 0) {
        for (DepartureTrip *trip in dep.trips) {
            [self addPathToShape:[kml lineCoordsForRoute:trip.route direction:trip.dir]];
        }
    } else {
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:dep.dir]];

        if (![dep.route isEqualToString:dep.blockPositionRouteNumber] ||
            ![dep.dir isEqualToString:dep.blockPositionDir]) {
            [self addPathToShape:[kml lineCoordsForRoute:self.departure.blockPositionRouteNumber
                                               direction:self.departure.blockPositionDir]];
        }
    }
}

- (void)subTaskCalculcateTotalTasks:(TaskState *)taskState {
    if (self.departure.route == nil) {
        taskState.total = 1;
    } else {
        if (self.backgroundRefresh) {
            taskState.total++;
        }

        if (self.departure.vehicleInfo->check_for_multiple &&
            !self.departure.fetchedAdditionalVehicles && self.departure.block &&
            !self.departure.streetcar) {
            taskState.total++;
        }

        if (self.departure.nextBusFeedInTriMetData && self.allDepartures != nil &&
            self.departure.status == ArrivalStatusEstimated) {
            self.streetcarRoutes =
                [XMLStreetcarLocations getStreetcarRoutesInXMLDeparturesArray:self.allDepartures];

            taskState.total += (int)self.streetcarRoutes.count + 1;
        } else if (self.departure.nextBusFeedInTriMetData) {
            self.streetcarRoutes = [NSSet setWithObject:self.departure.route];
            taskState.total += 2;
        } else if (Settings.kmlRoutes && self.shapes == nil) {
            taskState.total++;
        }
    }
}

- (void)subTaskFetchDepartureIfNeeded:(TaskState *)taskState {
    if (self.backgroundRefresh || self.departure.route == nil) {
        XMLDepartures *newXml = [XMLDepartures xmlWithOneTimeDelegate:taskState];
        [newXml getDeparturesForStopId:self.departure.stopId block:self.departure.block];

        taskState.itemsDone++;
        [taskState displayItemsDone];

        Departure *oldDep = self.departure;
        Departure *newDep = [newXml getFirstDepartureForDirection:oldDep.dir];

        if (newDep) {
            self.departure = newDep;
            self.departure.streetcarId = oldDep.streetcarId;
            self.departure.vehicleIds = [self.departure vehicleIdsForStreetcar];

            if (self.departure.vehicleInfo->check_for_multiple) {
                self.departure.vehicleIds = oldDep.vehicleIds;
                self.departure.fetchedAdditionalVehicles = oldDep.fetchedAdditionalVehicles;
            }

            if (oldDep.route == nil) {
                self.streetcarRoutes = [NSSet setWithObject:self.departure.route];
            }
        } else {
            [self.departure makeInvalid:newXml.queryTime];
        }

        if (self.departure.blockPosition == nil &&
            self.departure.status == ArrivalStatusEstimated) {
            taskState.total++;
        }

        [taskState displayTotal];

        [self debugXmlAddParser:newXml];
    }
}

- (void)subTaskFetchStreetcarLocations:(TaskState *)taskState {

    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

    if (self.departure.streetcarId == nil) {
        // First get the arrivals via next bus to see if we can get the correct
        // vehicle ID Not using auto release pool

        [parallelBlocks startBlock:^{
          XMLStreetcarPredictions *streetcarArrivals =
              [XMLStreetcarPredictions xmlWithOneTimeDelegate:taskState];
          [streetcarArrivals getDeparturesForStopId:self.departure.stopId];

          [taskState incrementItemsDoneAndDisplay];

          for (Departure *vehicle in streetcarArrivals) {
              if ([vehicle.block isEqualToString:self.departure.block]) {
                  self.departure.streetcarId = vehicle.streetcarId;
                  self.departure.vehicleIds = [vehicle vehicleIdsForStreetcar];
                  break;
              }
          }
          [self debugXmlAddParser:streetcarArrivals];
        }];
    }

    for (NSString *route in self.streetcarRoutes) {
        [parallelBlocks startBlock:^{
          XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
          locs.oneTimeDelegate = taskState;
          [locs getLocations];
          [taskState incrementItemsDoneAndDisplay];
          [self debugXmlAddParser:locs];
        }];
    }

    [parallelBlocks waitForBlocksWithState:taskState];

    if (self.allDepartures != nil) {
        [XMLStreetcarLocations insertLocationsIntoXmlDeparturesArray:self.allDepartures
                                                           forRoutes:self.streetcarRoutes];
    } else {
        XMLStreetcarLocations *locs =
            [XMLStreetcarLocations sharedInstanceForRoute:self.departure.route];
        [locs insertLocation:self.departure];
    }

    self.allDepartures = nil;
    [taskState displayItemsDone];
}

- (void)subTaskFetchAdditionalVehicles:(TaskState *)taskState {
    if (self.departure.vehicleInfo->check_for_multiple &&
        !self.departure.fetchedAdditionalVehicles && self.departure.block &&
        !self.departure.streetcar) {
        XMLLocateVehicles *locator = [XMLLocateVehicles xmlWithOneTimeDelegate:taskState];
        [locator findNearestVehicles:nil
                           direction:nil
                              blocks:[NSSet setWithObject:self.departure.block]
                            vehicles:nil
                               since:nil];

        NSMutableArray *vehicles = [NSMutableArray arrayWithArray:self.departure.vehicleIds];

        for (Vehicle *vehicle in locator) {
            bool found = NO;

            for (NSString *known in vehicles) {
                if ([vehicle.vehicleId isEqualToString:known]) {
                    found = YES;
                    break;
                }
            }

            if (!found) {
                [vehicles addObject:vehicle.vehicleId];
            }
        }

        self.departure.fetchedAdditionalVehicles = YES;
        self.departure.vehicleIds = vehicles;

        [taskState incrementItemsDoneAndDisplay];

        [self debugXmlAddParser:locator];
    }
}

- (void)subTaskFetchTriMetLocations:(TaskState *)taskState {
    XMLLocateVehicles *vehicles = [XMLLocateVehicles xmlWithOneTimeDelegate:taskState];
    [vehicles findNearestVehicles:nil
                        direction:nil
                           blocks:[NSSet setWithObject:self.departure.block]
                         vehicles:nil
                            since:nil];

    if (vehicles.count > 0) {
        Vehicle *data = vehicles.items.firstObject;

        [self.departure insertLocation:data];
    }

    [taskState incrementItemsDoneAndDisplay];

    [self debugXmlAddParser:vehicles];
}

- (void)fetchDataAsync:(id<TaskController>)taskController
     backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
      DEBUG_FUNC();

      [self debugXmlInit];
      self.streetcarRoutes = nil;
      self.backgroundRefresh = backgroundRefresh;

      [self subTaskCalculcateTotalTasks:taskState];

      [taskState startTask:NSLocalizedString(@"getting details", @"Progress indication")];

      [self subTaskFetchDepartureIfNeeded:taskState];

      [self subTaskFetchAdditionalVehicles:taskState];

      if (self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil &&
          self.departure.status == ArrivalStatusEstimated) {
          [self subTaskFetchStreetcarLocations:taskState];
      } else if (!self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil &&
                 self.departure.status == ArrivalStatusEstimated && Settings.useVehicleLocator) {
          [self subTaskFetchTriMetLocations:taskState];
      }

      if (Settings.kmlRoutes && self.shapes == nil) {
          [taskState
              taskSubtext:NSLocalizedString(@"started to get route paths", @"progress message")];
          [self setupShape:taskState];
          [taskState incrementItemsDoneAndDisplay];
      }

      [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        [self updateSections];
      }];

      if (!self.departure.shortSign) {
          [taskState taskCancel];
          [taskState
              taskSetErrorMsg:NSLocalizedString(@"No departure found - it has already departed.",
                                                @"error message")];
      }

      [self updateRefreshDate:nil];
      DEBUG_LOG(@"done %p", self);
      DEBUG_LOG_ADDRESS(taskController);

      self.streetcarRoutes = nil;

      return (UIViewController *)self;

      DEBUG_FUNCEX();
    }];
}

- (void)updateSections {
    [self clearSectionMaps];

    for (int alert = 0; alert < self.departure.sortedDetours.systemWideCount; alert++) {
        [self addSectionType:kSectionSystemAlert];
        [self addRowType:kSectionRowDetour];
        ;
    }

    [self addSectionType:kSectionRoute];
    [self addRowType:kRowRouteName];

    [self addRowType:kRowRouteTimeInfo];

    if (self.departure.hasBlock && self.departure.blockPosition != nil) {
        [self addSectionType:kSectionRowLocation];
        [self addRowType:kRowMap];
        [self addRowType:kSectionRowLocation];
    }
    // Set index path back to nil, as we have to create it again (or not)
    self.indexPathOfLocationCell = nil;

    if ((self.departure.sortedDetours.detourIds.count -
         self.departure.sortedDetours.systemWideCount) > 0) {
        [self addSectionType:kSectionRowDetour];
        _firstDetourRow = self.rowsInLastSection;
        [self addRowType:kSectionRowDetour
                   count:self.departure.sortedDetours.detourIds.count -
                         self.departure.sortedDetours.systemWideCount];
    }

    bool actionSection = NO;

    if (self.departure.block != nil) {
        [self addSectionType:kSectionAction];
        actionSection = YES;
        [self addRowType:kRowTag];
    }

    if (self.departure.block && [AlarmTaskList supported] && self.departure.secondsToArrival > 0) {
        if (!actionSection) {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }

        [self addRowType:kRowAlarm];
    }

    // On refresh the allowDest may be NO but that's cause we don't know
    if (self.allowBrowseForDestination) {
        if (!actionSection) {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }

        [self addRowType:kRowDestArrival];
    }

    // On refresh the allowDest may be NO but that's cause we don't know
    if (self.departure.nextStopId != nil && [DepartureTimesViewController canGoDeeper]) {
        if (!actionSection) {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }

        [self addRowType:kRowNextStops];
    }

    if ([DepartureTimesViewController canGoDeeper]) {
        if (!actionSection) {
            [self addSectionType:kSectionAction];
        }

        [self addRowType:kRowOpposite];
        [self addRowType:kRowPlanTrip];

    } else {
        if (!actionSection) {
            [self addSectionType:kSectionAction];
        }

        [self addRowType:kRowNoDeeper];
    }

    [self addRowType:kRowSiriAlertsForRoute];

    [self addSectionType:kSectionInfo];
    [self addRowType:kRowMapAndSchedule];
    [self addRowType:kRowBrowse];
    [self addRowType:kRowMapWithStops];

    if (self.departure.trips.count > 0 && Settings.showTrips) {
        [self addSectionType:kSectionTrips];
        [self addRowType:kRowTrip count:self.departure.trips.count];
    }

    DEBUG_LOG_description(self.departure.vehicleIds);

    if (self.departure.vehicleIds && self.departure.vehicleIds.count > 0) {
        [self addSectionType:kRowSectionVehicle];
        [self addRowType:kRowSectionVehicle count:self.departure.vehicleIds.count];
    }

    [self addRowType:kSectionRowDisclaimerType];
}

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                     stopId:(NSString *)stopId
                      block:(NSString *)block
                        dir:(NSString *)dir
          backgroundRefresh:(bool)backgroundRefresh {
    self.departure = [Departure new];
    self.departure.stopId = stopId;
    self.departure.block = block;
    self.departure.dir = dir;

    DEBUG_LOG_ADDRESS(taskController);
    [self fetchDataAsync:taskController backgroundRefresh:backgroundRefresh];
}

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                        dep:(Departure *)dep
              allDepartures:(NSArray *)deps
          backgroundRefresh:(bool)backgroundRefresh {
    if (!self.backgroundRefresh) {
        self.departure = dep;
        self.allDepartures = deps;
    }

    KMLRoutes *kml = [KMLRoutes xml];

    if (dep == nil || (dep.streetcar && dep.blockPosition == nil) || self.backgroundRefresh ||
        (dep.vehicleInfo->check_for_multiple && !dep.fetchedAdditionalVehicles) ||
        (Settings.kmlRoutes && !kml.cached)) {
        DEBUG_LOG_ADDRESS(taskController);
        [self fetchDataAsync:taskController backgroundRefresh:backgroundRefresh];
    } else if (!self.backgroundRefresh) {
        if (Settings.kmlRoutes) {
            [self setupShape:taskController];
        }

        [self updateSections];

        [self updateRefreshDate:dep.queryTime];

        [taskController taskCompleted:self];
    }
}

#pragma mark Helper functions

- (void)showStops:(NSString *)route {
    if ([DepartureTimesViewController canGoDeeper]) {
        [[DirectionViewController viewController] fetchDirectionsAsync:self.backgroundTask
                                                                 route:route];
    }
}

- (void)showMapWithStops:(bool)withStops {
    MapViewControllerWithStops *mapPage = [MapViewControllerWithStops viewController];
    SimpleAnnotation *pin = [SimpleAnnotation annotation];

    mapPage.title = self.departure.fullSign;
    mapPage.stopIdStringCallback = self.stopIdStringCallback;

    if (self.departure.blockPosition) {
        pin.coordinate = self.departure.blockPosition.coordinate;
    }

    if (self.departure.blockPositionHeading) {
        pin.pinBearing = self.departure.blockPositionHeading.doubleValue;
    }

    pin.pinTitle = self.departure.shortSign;

    if (self.departure.blockPositionFeet > 0) {
        // A bug in the view means we add a newl as it will not be visable.
        pin.pinMarkedUpSubtitle = [NSString
            stringWithFormat:NSLocalizedString(@"#D%@ away\nLocated at #b%@",
                                               @"<distance> of vehicle"),
                             [FormatDistance formatFeet:self.departure.blockPositionFeet],
                             [NSDateFormatter localizedStringFromDate:self.departure.blockPositionAt
                                                            dateStyle:NSDateFormatterNoStyle
                                                            timeStyle:NSDateFormatterMediumStyle]];
    }

    pin.pinMarkedUpType = kPinTypeDeparture;

    pin.pinColor = MAP_PIN_COLOR_PURPLE;
    pin.pinTint = [TriMetInfo colorForRoute:self.departure.route];
    pin.pinBlobTint = [[BlockColorDb sharedInstance] colorForBlock:self.departure.block];

    if (self.departure.blockPosition) {
        [mapPage addPin:self.departure];
    }

    SimpleAnnotation *stopPin = [SimpleAnnotation annotation];

    stopPin.coordinate = self.departure.stopLocation.coordinate;
    stopPin.pinTitle = self.departure.locationDesc;
    stopPin.pinSubtitle = nil;
    stopPin.pinColor = MAP_PIN_COLOR_PURPLE;
    stopPin.pinMarkedUpType = kPinTypeStop;

    [mapPage addPin:stopPin];

    if (self.shapes) {
        mapPage.shapes = self.shapes.mutableCopy;
        mapPage.lineOptions = MapViewNoFitLines;
    }

    if (withStops) {
        [mapPage fetchStopsAsync:self.backgroundTask
                           route:self.departure.route
                       direction:self.departure.dir
                      returnStop:self];
    } else {
        [self.navigationController pushViewController:mapPage animated:YES];
    }
}

- (void)showMap:(id)sender {
    [self showMapWithStops:NO];
}

- (void)showBig:(id)sender {
    BigRouteViewController *bigPage = [BigRouteViewController viewController];

    bigPage.departure = self.departure;

    [self.navigationController pushViewController:bigPage animated:YES];
}

#pragma mark TableView methods

- (UITableViewCell *)uniqueTextCell:(UITableView *)tableView
                         identifier:(NSString *)ident
                               text:(NSString *)text
                               icon:(BoxedIcon *)icon {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:ident];

    if (cell.imageView.image == nil) {
        cell.textLabel.font = self.basicFont;
        cell.icon = icon;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor modeAwareGrayText];
        cell.backgroundColor = [UIColor modeAwareCellBackground];
    }

    cell.textLabel.text = text;

    return cell;
}

- (Detour *)detourForRow:(NSInteger)sectionType indexPath:(NSIndexPath *)indexPath {
    NSInteger detourIndex =
        (sectionType == kSectionSystemAlert)
            ? indexPath.section
            : (indexPath.row - _firstDetourRow + self.departure.sortedDetours.systemWideCount);
    NSNumber *detourId = self.departure.sortedDetours.detourIds[detourIndex];

    return self.departure.sortedDetours.allDetours[detourId];
}

- (void)didTapMap:(id)sender {
    [self showMap:nil];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[RouteMultiPolyline class]]) {
        return [(RouteMultiPolyline *)overlay renderer];
    }

    return [[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];

    switch (sectionType) {
    case kSectionSystemAlert: {
        Detour *detour = [self detourForRow:sectionType
                                  indexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        return detour.depGetSectionHeader;
    }

    case kSectionAction:
        return NSLocalizedString(@"Actions:", @"section title");

    case kSectionRowDetour:
        return NSLocalizedString(@"Route Alerts:", @"section title");

    case kSectionRoute:
        return self.departure.descAndDir;

    case kSectionTrips:
        return NSLocalizedString(@"Remaining trips before departure:", @"section title");

    case kSectionInfo:
        return self.departure.fullSign;

    case kRowSectionVehicle:
        return NSLocalizedString(@"Vehicle info:", @"section title");

    case kSectionRowLocation:
        return [NSString
            stringWithFormat:NSLocalizedString(@"Vehicle is %@ away",
                                               @"distance that the vehicle is away"),
                             [FormatDistance formatFeet:self.departure.blockPositionFeet]];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView
    willDisplayHeaderView:(UIView *)view
               forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;

    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

#pragma mark View functions

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(displayLinkFired:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark TableViewWithToolbar functions

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    // match each of the toolbar item's style match the selection in the
    // "UIBarButtonItemStyle" segmented control
    bool needSpace = NO;

    if (self.departure.hasBlock) {
        [toolbarItems addObject:[UIBarButtonItem mapButtonWithTarget:self
                                                              action:@selector(showMap:)]];
        needSpace = YES;
    }

    if (Settings.debugXML) {
        if (needSpace) {
            [toolbarItems addObject:[UIBarButtonItem flexSpace]];
        }

        [toolbarItems addObject:[self debugXmlButton]];
    }

    [toolbarItems addObject:[UIBarButtonItem flexSpace]];

    UIBarButtonItem *magnifyButton = [UIBarButtonItem magnifyButtonWithTarget:self
                                                                       action:@selector(showBig:)];

    [toolbarItems addObject:magnifyButton];

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark Stop callback function

- (NSString *)returnStopObjectActionText {
    return @"";
}

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];

    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:self.backgroundTask stopId:stop.stopId];
}

- (void)refreshAction:(id)unused {
    if (!self.backgroundTask.running) {
        [super refreshAction:nil];
        self.backgroundRefresh = YES;
        [self fetchDepartureAsync:self.backgroundTask
                              dep:nil
                    allDepartures:nil
                backgroundRefresh:YES];
    }
}

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled {
    if (self.backgroundRefresh && !cancelled) {
    }

    [super backgroundTaskDone:viewController cancelled:cancelled];
}

- (void)displayLinkFired:(id)sender {
    if (self.mapView) {
        double difference = ABS(self.previousHeading - self.mapView.camera.heading);

        if (difference < .001) {
            return;
        }

        self.previousHeading = self.mapView.camera.heading;

        [self updateAnnotations:self.mapView];
    }
}

- (void)countDownTimer {
    if (self.indexPathOfLocationCell && self.tableView) {
        // If the  cell is not visable we will not update it this time. It
        // will get updated in a second anyway.

        // It crashes here a lot according to the logs, so this may also
        // protect against the exception.

        if (self.indexPathOfLocationCell.section < self.sections &&
            [self.tableView cellForRowAtIndexPath:self.indexPathOfLocationCell] != nil) {

            [self.tableView reloadRowsAtIndexPaths:@[ self.indexPathOfLocationCell ]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS DepartureDetailViewController

//--------------------------------------------------------------------------------------------------
#pragma mark kRowRouteName

CELL_CONFIG_METHOD(kRowRouteName) {
    DepartureCell *cell = [DepartureCell tableView:tableView
                           cellWithReuseIdentifier:MakeCellId(kRowRouteName)
                                    tallRouteLabel:YES];
    [self.departure populateCell:cell decorate:NO busName:YES fullSign:YES];
    return cell;
}

STATIC_VTABLE_VC_H(kRowRouteName, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowRouteTimeInfo

PARA_CELL(kRowRouteTimeInfo, self.departure.getMarkedUpExplaination, nil);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowLocation

CELL_CONFIG_METHOD(kSectionRowLocation) {
    NSString *lastSeen = [Vehicle locatedSomeTimeAgo:self.departure.blockPositionAt];

    self.indexPathOfLocationCell = indexPath;

    return [self uniqueTextCell:tableView
                     identifier:MakeCellId(kRowLocation)
                           text:lastSeen
                           icon:kIconMap];
}

CELL_SELECT_METHOD(kSectionRowLocation) { [self showMap:nil]; }

STATIC_VTABLE_VCS_H(kSectionRowLocation, basic);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTag

CELL_CONFIG_METHOD(kRowTag) {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kRowTag)];

    NSString *text = nil;
    UIImage *image = nil;

    UIColor *color = [[BlockColorDb sharedInstance] colorForBlock:self.departure.block];

    if (color == nil) {
        text = NSLocalizedString(@"Tag this " kBlockName " with a color", @"menu item");
        image = [BlockColorDb imageWithColor:[UIColor grayColor]];
    } else {
        text = NSLocalizedString(@"Remove " kBlockName " color tag", @"menu item");
        image = [BlockColorDb imageWithColor:color];
    }

    [self actionCell:cell
                  text:text
                  icon:[BoxedImageIcon withImage:image]
         accessoryType:UITableViewCellAccessoryDetailDisclosureButton
        selectionStyle:UITableViewCellSelectionStyleBlue];

    return cell;
}

CELL_SELECT_METHOD(kRowTag) {
    if ([[BlockColorDb sharedInstance] colorForBlock:self.departure.block] != nil) {
        [[BlockColorDb sharedInstance] addColor:nil forBlock:self.departure.block description:nil];
        [self userStateChanged];
        [self reloadData];

        if (_delegate) {
            [_delegate detailsChanged];
        }
    } else {

        __weak __typeof(self) weakSelf = self;

        UIViewController *picker = [SimpleColorPickerCoordinator
            createWithInitialColor:UIColor.randomColor
                             title:NSLocalizedString(@"Pick tag color", @"window title")
                          onPicked:^(UIColor *selectedColor) {
                            __strong __typeof(self) strongSelf = weakSelf;

                            if (!strongSelf)
                                return;

                            if (selectedColor) {
                                [[BlockColorDb sharedInstance]
                                       addColor:selectedColor
                                       forBlock:strongSelf.departure.block
                                    description:strongSelf.departure.fullSign];

                                if (strongSelf->_delegate) {
                                    [strongSelf->_delegate detailsChanged];
                                }

                                [strongSelf userStateChanged];
                            }
                            [strongSelf reloadData];
                          }];

        [self presentViewController:picker
                           animated:YES
                         completion:^{
                         }];
    }
}

CELL_ACCESSORY_METHOD(kRowTag) {
    _reloadOnAppear = YES;
    CELL_PUSH([BlockColorViewController viewController]);
}

CELL_STATIC_VTABLE(kRowTag){
    SET_CELL_CONFIG_SEL(kRowTag),
    SET_CELL_SELECT_SEL(kRowTag),
    SET_CELL_ACCESSORY_SEL(kRowTag),
    SET_CELL_HEIGHT_SEL(basic),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowDetour

CELL_CONFIG_METHOD(kSectionRowDetour) {
    Detour *det = self.departure.sortedDetours.detourIds != nil
                      ? [self detourForRow:[self sectionType:indexPath.section] indexPath:indexPath]
                      : nil;

    return [self detourCell:det route:nil indexPath:indexPath];
}

CELL_SELECT_METHOD(kSectionRowDetour) {
    Detour *det = [self detourForRow:[self sectionType:indexPath.section] indexPath:indexPath];
    [self detourToggle:det indexPath:indexPath reloadSection:NO];
}

CELL_STATIC_VTABLE(kSectionRowDetour){
    SET_CELL_CONFIG_SEL(kSectionRowDetour),
    SET_CELL_SELECT_SEL(kSectionRowDetour),
    SET_CELL_HEIGHT_SEL(auto),
    SET_CELL_REG_SEL(DetourTableViewCell),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kRowSectionVehicle

TEXT_CELL(kRowSectionVehicle,
          [TriMetInfo markedUpVehicleString:self.departure.vehicleIds[indexPath.row]]);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTrip

CELL_CONFIG_METHOD(kRowTrip) {
    DepartureCell *cell = [DepartureCell tableView:tableView
                        genericWithReuseIdentifier:MakeCellId(kRowTrip)];
    [self.departure populateTripCell:cell item:indexPath.row];
    return cell;
}

STATIC_VTABLE_VC_H(kRowTrip, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowDisclaimerType

CELL_CONFIG_METHOD(kSectionRowDisclaimerType) {
    UITableViewCell *cell = [self disclaimerCell:tableView];

    NSString *date = [NSDateFormatter localizedStringFromDate:self.departure.queryTime
                                                    dateStyle:NSDateFormatterNoStyle
                                                    timeStyle:NSDateFormatterMediumStyle];

    if (self.departure.block != nil) {
        [self addTextToDisclaimerCell:cell
                                 text:[NSString stringWithFormat:NSLocalizedString(
                                                                     @"Stop ID %@. Updated: "
                                                                     @"%@\n" kBlockNameC " ID %@",
                                                                     @"infomation at the end "
                                                                     @"of the departures"),
                                                                 self.departure.stopId,
                                                                 date,
                                                                 self.departure.block]
                                lines:2];
    } else {
        [self addTextToDisclaimerCell:cell
                                 text:[NSString stringWithFormat:NSLocalizedString(
                                                                     @"Stop ID %@. Updated: %@",
                                                                     @"infomation at the end of "
                                                                     @"the departures"),
                                                                 self.departure.stopId,
                                                                 date]];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;

    if (self.departure.streetcar && self.departure.copyright != nil) {
        [self addStreetcarTextToDisclaimerCell:cell
                                          text:self.departure.copyright
                              trimetDisclaimer:YES];
    }

    [self updateDisclaimerAccessibility:cell];

    return cell;
}

STATIC_VTABLE_VC_H(kSectionRowDisclaimerType, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowMapWithStops

ACTION_CELL_SELECT(kRowMapWithStops,
                   NSLocalizedString(@"Map with route stops", @"menu item"),
                   kIconMap,
                   UITableViewCellAccessoryDisclosureIndicator) {
    [self showMapWithStops:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowOpposite

ACTION_CELL_SELECT(kRowOpposite,
                   NSLocalizedString(@"Departures going the other way", @"menu item"),
                   kIconArrivals,
                   UITableViewCellAccessoryDisclosureIndicator) {
    DepartureTimesViewController *opposite = [DepartureTimesViewController viewController];
    opposite.stopIdStringCallback = self.stopIdStringCallback;
    [opposite fetchTimesForStopInOtherDirectionAsync:self.backgroundTask departure:self.departure];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowSiriAlertsForRoute

ACTION_CELL_SELECT(kRowSiriAlertsForRoute,
                   NSLocalizedString(@"Add route alerts to Siri", @"menu item"),
                   kIconSiri,
                   UITableViewCellAccessoryDisclosureIndicator) {
    [self tableView:tableView
        siriAlertsForRoute:self.departure.shortSign
               routeNumner:self.departure.route];
    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowNoDeeper

CALL_CELL_SELECT(kRowNoDeeper,
                 kActionCellId,
                 nil,
                 actionCell,
                 narrow,
                 NSLocalizedString(@"Too many windows are open", @"button text"),
                 kIconCancel,
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleBlue) {
    CELL_POP();
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowBrowse

ACTION_CELL_SELECT(kRowBrowse,
                   NSLocalizedString(@"Browse stops", @"menu item"),
                   kIconBrowse,
                   UITableViewCellAccessoryDisclosureIndicator) {
    [self showStops:self.departure.route];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowPlanTrip

ACTION_CELL_SELECT(kRowPlanTrip,
                   NSLocalizedString(@"Plan a trip from here", @"menu item"),
                   kIconTripPlanner,
                   UITableViewCellAccessoryDisclosureIndicator) {
    TripPlannerSummaryViewController *tripPlanner =
        [TripPlannerSummaryViewController viewController];

    // Push the detail view controller

    TripEndPoint *endpoint = tripPlanner.tripQuery.userRequest.fromPoint;

    tripPlanner.tripQuery.userRequest.arrivalTime = FALSE;
    tripPlanner.tripQuery.userRequest.dateAndTime =
        [self.departure.departureTime dateByAddingTimeInterval:60.0];
    endpoint.useCurrentLocation = false;
    endpoint.locationDesc = self.departure.stopId;
    endpoint.additionalInfo = nil;

    [self.navigationController pushViewController:tripPlanner animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowMapAndSchedule

ACTION_CELL_SELECT(kRowMapAndSchedule,
                   NSLocalizedString(@"TriMet map & schedule page", @"menu item"),
                   kIconTriMetLink,
                   UITableViewCellAccessoryNone) {
    [self showRouteSchedule:self.departure.route];
    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowDestArrival

ACTION_CELL_SELECT(kRowDestArrival,
                   NSLocalizedString(@"Browse for destination time", @"menu item"),
                   kIconArrivals,
                   UITableViewCellAccessoryDisclosureIndicator) {
    StopViewController *stopViewController = [StopViewController viewController];

    stopViewController.stopIdStringCallback = self.stopIdStringCallback;

    [stopViewController fetchDestinationsAsync:self.backgroundTask dep:self.departure];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowNextStops

ACTION_CELL_SELECT(kRowNextStops,
                   NSLocalizedString(@"Show vehicle's next stops before departure", @"menu item"),
                   kIconArrivals,
                   UITableViewCellAccessoryDisclosureIndicator) {
    if (self.departure.trips != nil) {
        [[DepartureTimesViewController viewController] fetchTimesForVehicleAsync:self.backgroundTask
                                                                           route:nil
                                                                       direction:nil
                                                                      nextStopId:nil
                                                                           block:nil
                                                                 targetDeparture:self.departure];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowAlarm

ACTION_CELL_SELECT(kRowAlarm,
                   ([[AlarmTaskList sharedInstance] hasTaskForStopId:self.departure.stopId
                                                               block:self.departure.block
                                                                 dir:self.departure.dir]
                        ? NSLocalizedString(@"Edit departure alarm", @"menu item")
                        : NSLocalizedString(@"Set departure alarm", @"menu item")),
                   kIconAlarm,
                   UITableViewCellAccessoryDisclosureIndicator) {
    // Create a an alert
    AlarmMinutesViewController *alarmViewMins = [AlarmMinutesViewController viewController];
    alarmViewMins.dep = self.departure;

    [self.navigationController pushViewController:alarmViewMins animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowMap

CREATE_CELL_WITH_CONFIG(kRowMap, nil, mapCell) {
    return [self
              getMapCell:MakeCellId(kRowMap)
        withUserLocation:NO
              completion:^(MKMapView *map) {
                map.delegate = self;

                SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];

                annotLoc.pinTitle = self.departure.locationDesc;
                annotLoc.pinColor = MAP_PIN_COLOR_PURPLE;
                annotLoc.coordinate = self.departure.stopLocation.coordinate;

                [map addAnnotation:annotLoc];
                [map addAnnotation:self.departure];

                DEBUG_LOG_ulong(map.annotations.count);

                if (self.shapes) {
                    NSMutableArray *overlays = [NSMutableArray array];

                    for (ShapeRoutePath *path in self.shapes) {
                        [path addPolylines:overlays];
                    }

                    [self.mapView addOverlays:overlays];
                }

                {
                    MKMapRect flyTo = MKMapRectNull;
                    MKMapPoint annotationPoint =
                        MKMapPointForCoordinate(self.departure.stopLocation.coordinate);
                    flyTo =
                        MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 50, 50);
                    annotationPoint =
                        MKMapPointForCoordinate(self.departure.blockPosition.coordinate);
                    MKMapRect busRect =
                        MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 50, 50);
                    flyTo = MKMapRectUnion(flyTo, busRect);

                    UIEdgeInsets insets = {30, 10, 10, 20};

                    [map setVisibleMapRect:[map mapRectThatFits:flyTo edgePadding:insets]
                                  animated:YES];
                }
              }];
}

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kRowRouteName),
    CELL_MAP(kRowRouteTimeInfo),
    CELL_MAP(kSectionRowLocation),
    CELL_MAP(kRowTag),
    CELL_MAP(kSectionRowDetour),
    CELL_MAP(kRowSectionVehicle),
    CELL_MAP(kRowTrip),
    CELL_MAP(kSectionRowDisclaimerType),
    CELL_MAP(kRowMapWithStops),
    CELL_MAP(kRowOpposite),
    CELL_MAP(kRowSiriAlertsForRoute),
    CELL_MAP(kRowNoDeeper),
    CELL_MAP(kRowBrowse),
    CELL_MAP(kRowPlanTrip),
    CELL_MAP(kRowMapAndSchedule),
    CELL_MAP(kRowDestArrival),
    CELL_MAP(kRowNextStops),
    CELL_MAP(kRowAlarm),
    CELL_MAP(kRowMap),
};

@end

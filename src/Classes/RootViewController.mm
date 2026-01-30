//
//  RootViewController.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "RootViewController.h"
#import "AboutViewController.h"
#import "AddressBook/AddressBook.h"
#import "AlarmAccurateStopProximity.h"
#import "AlarmMinutesViewController.h"
#import "AllRailStationViewController.h"
#import "BlockColorDb.h"
#import "CLLocation+Helper.h"
#import "CLPlacemark+SimpleAddress.h"
#import "CellTextField.h"
#import "DebugLogging.h"
#import "DepartureHistoryViewController.h"
#import "DepartureTimesViewController.h"
#import "DetoursViewController.h"
#import "DirectionViewController.h"
#import "EditBookMarkViewController.h"
#import "EditableTableViewCell.h"
#import "FindByLocationViewController.h"
#import "FlashViewController.h"
#import "Icons.h"
#import "KMLRoutes.h"
#import "LocationServicesDebugViewController.h"
#import "MainQueueSync.h"
#import "NSString+Core.h"
#import "NSString+DocPath.h"
#import "NSString+MoreMarkup.h"
#import "NearestVehiclesMapViewController.h"
#import "PDXBus-Swift.h"
#import "PDXBusAppDelegate+Methods.h"
#import "ProgressModalView.h"
#import "QrCodeReaderViewController.h"
#import "RailMapViewController.h"
#import "RailStationTableViewController.h"
#import "RouteViewController.h"
#import "SupportViewController.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerDateViewController.h"
#import "TripPlannerFetcher.h"
#import "TripPlannerHistoryViewController.h"
#import "TripPlannerResultsViewController.h"
#import "TripPlannerSummaryViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UITableViewCell+Icons.h"
#import "UserParams.h"
#import "UserState.h"
#import "VehicleIdsViewController.h"
#import "VehicleTableViewController.h"
#import "WatchAppContext.h"
#import "WatchConnectivity/WatchConnectivity.h"
#import "WebViewController.h"
#import "WhatsNewViewController.h"
#import "XMLTrips.h"
#import <AddressBook/ABPerson.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <Intents/Intents.h>
#import <MobileCoreServices/MobileCoreServices.h>

enum SECTIONS_AND_ROWS {
    kTableSectionStopId,
    kTableSectionVehicleId,

    kTableSectionFaves,
    kTableSectionAbout,
    kTableSectionPlanner,
    kTableSectionRowAlarms,
    kTableSectionTriMet,
    kTableSectionStreetcar,

    kTableTriMetDetours,
    kTableTriMetLink,
    kTableStreetcarLink,
    kTableTriMetFacebook,
    kTableTriMetInstagram,

    kTableTriMetCustomerService,
    kTableTriMetCall,
    kTableTriMetBluesky,
    kTableStreetcarInstagram,

    kTableAboutSettings,
    kTableAboutRowAbout,
    kTableAboutSupport,
    kTableAboutRate,
    kTableTipJar,

    kTableFindRowId,
    kTableFindRowBrowse,
    kTableFindRowLocate,
    kTableFindRowRailStops,
    kTableFindRowRailMap,
    kTableFindRowQR,
    kTableFindRowHistory,
    kTableFindRowVehicle,
    kTableFindRowVehicleId,

    kTableFaveBookmark,
    kTableFaveButtons,
    kTableFaveAddStop,
    kTableFaveAddTrip,
    kTableFaveAddTakeMeHome,

    kTableTripRowPlanner,
    kTableTripRowCache
};

#define kUIEditHeight 50.0
#define kUIRowHeight 40.0

#define kTextFieldId @"TextField"
#define kAlarmCellId @"Alarm"

#define kSearchItemBookmark @"org.teleportaloo.pdxbus.bookmark"

// #define LOADINGSCREEN

@interface RootViewController () {
    NSInteger _faveSection;
    NSInteger _editSection;
    AlarmTaskList *_taskList;
    bool _keyboardUp;
    bool _updatedWatch;
}

@property (nonatomic, strong) UITextField *editWindow;
@property (nonatomic, strong) CellTextField *editCell;
@property (nonatomic, strong) NSArray *alarmKeys;
@property (nonatomic, strong) ProgressModalView *progressView;
@property (nonatomic) bool delayedInitialAction;

@property (nonatomic, strong) UIBarButtonItem *goButton;
@property (nonatomic, strong) UIBarButtonItem *helpButton;
@property (nonatomic, strong) UIButton *editBookmarksButton;
@property (nonatomic, strong) UIButton *emailBookmarksButton;
@property (nonatomic) bool iCloudFaves;

@end

@implementation RootViewController

@dynamic view;

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [toolbarItems removeAllObjects];
    bool spaceNeeded = NO;

    if (Settings.locateToolbarIcon) {
        [toolbarItems addObject:[UIBarButtonItem locateButtonWithTarget:self
                                                                 action:@selector(autoLocate:)]];
        spaceNeeded = YES;
    }

    if (spaceNeeded) {
        [toolbarItems addObject:[UIBarButtonItem flexSpace]];
    }

    [toolbarItems addObject:[UIBarButtonItem settingsButtonWithTarget:self
                                                               action:@selector(settingsAction:)]];
    spaceNeeded = YES;

    if (Settings.commuteButton) {
        if (spaceNeeded) {
            [toolbarItems addObject:[UIBarButtonItem flexSpace]];
        }

        [toolbarItems
            addObject:[UIBarButtonItem commuteButtonWithTarget:self
                                                        action:@selector(commuteAction:)]];
        spaceNeeded = YES;
    }

    if (spaceNeeded) {
        [toolbarItems addObject:[UIBarButtonItem flexSpace]];
    }

    [toolbarItems
        addObject:[UIBarButtonItem qrScannerButtonWithTarget:self
                                                      action:@selector(QRScannerAction:)]];
    spaceNeeded = YES;

    [self maybeAddFlashButtonWithSpace:spaceNeeded buttons:toolbarItems big:YES];

    if (toolbarItems.count == 1 && !Settings.locateToolbarIcon) {
        [toolbarItems insertObject:[UIBarButtonItem flexSpace] atIndex:0];
        [toolbarItems addObject:[UIBarButtonItem flexSpace]];
    }

    if (self.goButton == nil) {
        self.goButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(editGoAction:)];
    }

    if (self.helpButton == nil) {
        self.helpButton = [UIBarButtonItem textButton:NSLocalizedString(@"Help", @"button text")
                                               target:self
                                               action:@selector(helpAction:)];
    }
}

#pragma mark UI Helper functions

- (void)delayedQRScanner:(NSObject *)arg {
    QrCodeReaderViewController *qrView = [[QrCodeReaderViewController alloc] init];

    [self presentViewController:qrView animated:YES completion:nil];
}

- (bool)QRCodeScanner {
    if (self.videoCaptureSupported) {
        QrCodeReaderViewController *qrView = [[QrCodeReaderViewController alloc] init];

        [self.navigationController pushViewController:qrView animated:YES];
    } else {

        bool ipad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
        [UIAlertController
            simpleOkWithTitle:nil
                      message:ipad ? NSLocalizedString(
                                         @"The camera is not currently available. "
                                         @"Note: apps must be full screen to access the camera.",
                                         @"error")
                                   : NSLocalizedString(@"The camera is not currently available.",
                                                       @"error")
               viewController:self
                   completion:nil];
        return NO;
    }

    return YES;
}

- (bool)showMapWithAll {
    NearestVehiclesMapViewController *mapView = [NearestVehiclesMapViewController viewController];

    mapView.staticOverlays = YES;
    mapView.alwaysFetch = YES;
    mapView.allRoutes = YES;
    [mapView fetchNearestVehiclesAsync:self.backgroundTask];
    return YES;
}

- (bool)showDetoursForRoute:(NSString *)route {
    if (route == nil) {
        [[DetoursViewController viewController] fetchDetoursAsync:self.backgroundTask];
    } else {
        [[DetoursViewController viewController] fetchDetoursAsync:self.backgroundTask route:route];
    }

    return YES;
}

- (NSString *)addressFromMapItem:(MKMapItem *)mapItem {
    if (mapItem.name != nil) {
        return mapItem.name;
    }

    return mapItem.placemark.simpleAddress;
}

- (void)launchTripPlannerFromAppleURL {
    MKDirectionsRequest *directionsInfo =
        [[MKDirectionsRequest alloc] initWithContentsOfURL:self.routingURL];

    self.routingURL = nil;

    TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

    XMLTrips *query = [XMLTrips xml];

    if (directionsInfo.source.isCurrentLocation) {
        query.userRequest.fromPoint.useCurrentLocation = YES;
    } else {
        query.userRequest.fromPoint.locationDesc = [self addressFromMapItem:directionsInfo.source];
        query.userRequest.fromPoint.coordinates = directionsInfo.source.placemark.location;
        DEBUG_LOG(@"From desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }

    if (directionsInfo.destination.isCurrentLocation) {
        query.userRequest.toPoint.useCurrentLocation = YES;
    } else {
        query.userRequest.toPoint.locationDesc =
            [self addressFromMapItem:directionsInfo.destination];
        query.userRequest.toPoint.coordinates = directionsInfo.destination.placemark.location;
        DEBUG_LOG(@"To desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }

    query.userRequest.timeChoice = TripDepartAfterTime;
    query.userRequest.dateAndTime = [NSDate date];

    fetcher.tripQuery = query;

    [fetcher nextScreen:self.navigationController
           forceResults:NO
              postQuery:NO
          taskContainer:self.backgroundTask];
}

- (void)launchTripPlannerFromRouteURL {
    NSString *strUrl = self.routingURL.absoluteString;

    self.routingURL = nil;

    NSScanner *scanner = [NSScanner scannerWithString:strUrl];
    NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
    NSCharacterSet *ampersand = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSCharacterSet *equalsOrAmpersand = [NSCharacterSet characterSetWithCharactersInString:@"=&"];

    NSString *section;
    NSString *protocol;
    NSString *value;

    NSString *from_lon = nil;
    NSString *from_lat = nil;
    NSString *from_name = nil;
    NSString *to_lon = nil;
    NSString *to_lat = nil;
    NSString *to_name = nil;
    bool from_here = NO;
    bool to_here = NO;

    // skip up to first colon
    [scanner scanUpToCharactersFromSet:colon intoString:&protocol];

    if (scanner.atEnd) {
        DEBUG_LOG(@"Badly formed route URL %@ - no :\n", strUrl);
        return;
    }

    scanner.scanLocation++;

    // Skip slashes
    while (!scanner.atEnd && [strUrl characterAtIndex:scanner.scanLocation] == '/') {
        scanner.scanLocation++;
    }

    if (scanner.atEnd) {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after :\n", strUrl);
        return;
    }

    [scanner scanUpToCharactersFromSet:query intoString:&section];

    if ([section caseInsensitiveCompare:@"route"] != NSOrderedSame) {
        DEBUG_LOG(@"Badly formed route URL %@ - route command missing\n", strUrl);
        return;
    }

    scanner.scanLocation++;

    if (scanner.atEnd) {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after route?\n", strUrl);
        return;
    }

    while (!scanner.atEnd) {
        value = nil;

        [scanner scanUpToCharactersFromSet:equalsOrAmpersand intoString:&section];

        if (!scanner.atEnd) {
            if ([strUrl characterAtIndex:scanner.scanLocation] == '=') {
                scanner.scanLocation++;

                if (scanner.atEnd) {
                    DEBUG_LOG(@"Badly formed route URL %@ - nothing after =\n", strUrl);
                    return;
                }

                [scanner scanUpToCharactersFromSet:ampersand intoString:&value];

                if (!scanner.atEnd) {
                    scanner.scanLocation++;
                }
            } else {
                scanner.scanLocation++;
            }
        }

        if ([section caseInsensitiveCompare:@"from_lon"] == NSOrderedSame && value != nil) {
            from_lon = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_lon"] == NSOrderedSame && value != nil) {
            to_lon = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_lat"] == NSOrderedSame && value != nil) {
            from_lat = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_lat"] == NSOrderedSame && value != nil) {
            to_lat = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_name"] == NSOrderedSame && value != nil) {
            from_name = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_name"] == NSOrderedSame && value != nil) {
            to_name = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_here"] == NSOrderedSame) {
            from_here = YES;
        } else if ([section caseInsensitiveCompare:@"to_here"] == NSOrderedSame) {
            to_here = YES;
        }
    }

    bool error = false;

    if (from_name == nil && (from_lat == nil || from_lon == nil) && !from_here) {
        error = true;
    }

    if (to_name == nil && (to_lat == nil || to_lon == nil) && !to_here) {
        error = true;
    }

    if (from_here && (from_lat != nil || from_lon != nil || from_name != nil)) {
        error = true;
    }

    if (to_here && (to_lat != nil || to_lon != nil || to_name != nil)) {
        error = true;
    }

    if (to_here && from_here) {
        error = true;
    }

    if (error) {
        DEBUG_LOG(@"Badly formed route URL %@ - bad value from_name %@ "
                  @"from_lat %@ from_lon %@ to_name %@ to_lat %@ to_lon %@ "
                  @"from_here %d to_here %d\n",
                  strUrl,
                  from_name,
                  from_lat,
                  from_lon,
                  to_name,
                  to_lat,
                  to_lon,
                  (int)from_here,
                  (int)to_here);
        return;
    }

    DEBUG_LOG(@"Route URL %@ - from_name %@ from_lat %@ from_lon %@ to_name %@ "
              @"to_lat %@ to_lon %@ from_here %d to_here %d\n",
              strUrl,
              from_name,
              from_lat,
              from_lon,
              to_name,
              to_lat,
              to_lon,
              (int)from_here,
              (int)to_here);

    TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

    XMLTrips *tripQuery = [XMLTrips xml];

    tripQuery.userRequest.fromPoint.locationDesc = from_name;

    if (from_lat != nil && from_lon != nil) {
        tripQuery.userRequest.fromPoint.coordinates = [CLLocation fromStringsLat:from_lat
                                                                             lng:from_lon];
    }

    tripQuery.userRequest.toPoint.locationDesc = to_name;

    if (to_lat != nil && to_lon != nil) {
        tripQuery.userRequest.toPoint.coordinates = [CLLocation fromStringsLat:to_lat lng:to_lon];
    }

    if (from_here) {
        tripQuery.userRequest.fromPoint.useCurrentLocation = YES;
    }

    if (to_here) {
        tripQuery.userRequest.toPoint.useCurrentLocation = YES;
    }

    tripQuery.userRequest.timeChoice = TripDepartAfterTime;
    tripQuery.userRequest.dateAndTime = [NSDate date];

    fetcher.tripQuery = tripQuery;

    [fetcher nextScreen:self.navigationController
           forceResults:NO
              postQuery:NO
          taskContainer:self.backgroundTask];
}

- (void)launchTripPlannerFromURL {
    Class dirClass = (NSClassFromString(@"MKDirectionsRequest"));

    if (dirClass && [MKDirectionsRequest isDirectionsRequestURL:self.routingURL]) {
        [self launchTripPlannerFromAppleURL];
    } else {
        [self launchTripPlannerFromRouteURL];
    }
}

- (void)launchFromURL {
    [[DepartureTimesViewController viewController]
        fetchTimesForLocationAsync:self.backgroundTask
                            stopId:self.launchStops
                             title:NSLocalizedString(@"Launching...", @"progress message")];
    self.launchStops = nil;
}

- (void)QRScannerAction:(id)sender {
    [self QRCodeScanner];
}

- (void)autoLocate:(id)sender {
    if (self.initialActionArgs) {
        FindByLocationViewController *findView = [[FindByLocationViewController alloc] init];

        [findView actionArgs:self.initialActionArgs];
        self.initialActionArgs = nil;

        [self.navigationController pushViewController:findView animated:YES];
    } else if (Settings.autoLocateShowOptions) {
        // Push the detail view controller
        [self.navigationController pushViewController:[FindByLocationViewController viewController]
                                             animated:YES];
    } else {
        FindByLocationViewController *findView = [[FindByLocationViewController alloc] init];

        [findView actionArgs:@{}];

        // Push the detail view controller
        [self.navigationController pushViewController:findView animated:YES];
    }
}

- (void)settingsAction:(id)sender {
    [[UIApplication sharedApplication]
        compatOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)commuteAction:(id)sender {
    NSDictionary *commuteBookmark = [UserState.sharedInstance checkForCommuterFaveShowOnlyOnce:NO];

    if (commuteBookmark != nil) {
        UserParams *params = commuteBookmark.userParams;
        NSString *name = [NSString stringWithFormat:@"Commuter: %@", params.valChosenName];
        [[DepartureTimesViewController viewController]
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:params.valLocation
                                 title:name];
    } else {
        [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"Commute", @"alert title")
                      message:NSLocalizedString(@"No commuter bookmark was found for the current "
                                                @"day of the week and time. To create a commuter "
                                                @"bookmark, edit a bookmark to set which days to "
                                                @"use it for the morning or evening commute.",
                                                @"alert text")
               viewController:self
                   completion:nil];
    }
}

- (void)helpAction:(id)sender {
    // Push the detail view controller
    [self.navigationController pushViewController:[SupportViewController viewController]
                                         animated:YES];
}

#pragma mark - Initial Action

- (void)executeInitialAction {
    DEBUG_LOG_BOOL(self.commuterBookmark);

    if (!self.viewLoaded) {
        self.delayedInitialAction = YES;
        return;
    }

    [self performMaintenanceIfNeeded];

    if ([self tryShowHelpOrWhatsNew]) {
        [self finishInitialAction];
        return;
    }

    if ([self tryHandleDeepLink]) { // routingURL / launchStops
        [self finishInitialAction];
        return;
    }

    if ([self handleInitialActionCase]) {
        [self finishInitialAction];
        return;
    }

    if ([self tryHandleCommuterBookmark]) {
        [self finishInitialAction];
        return;
    }

    [self finishInitialAction];
}

#pragma mark - Maintenance

- (void)performMaintenanceIfNeeded {
    // Weekly re-index key: app version + searchStations + week/year
    NSDateComponents *now =
        [[NSCalendar currentCalendar] components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYear)
                                        fromDate:[NSDate date]];

    NSString *weeklyKey = [NSString
        stringWithFormat:@"%@ %d %d %d",
                         [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                         (int)Settings.searchStations,
                         (int)now.weekOfYear,
                         (int)now.year];

    BOOL reIndexStations = [self newVersion:@"stationIndex.plist" version:weeklyKey any:YES];
    if (reIndexStations) {
        [[AllRailStationViewController viewController] indexStations];
    }
}

#pragma mark - First-run / WhatsNew

- (BOOL)tryShowHelpOrWhatsNew {
    BOOL showHelp = [self newVersion:@"lastRun.plist" version:kAboutVersion any:NO];

    BOOL showWhatsNew = [self newVersion:@"whatsNew.plist"
                                 version:[WhatsNewViewController version]
                                     any:NO];

    if (showHelp) {
        [self.navigationController pushViewController:[SupportViewController viewController]
                                             animated:NO];
        return YES;
    }

    if (showWhatsNew) {
        [TriMetXML deleteCacheFile];
        [KMLRoutes deleteCacheFile];
        [self.navigationController pushViewController:[WhatsNewViewController viewController]
                                             animated:NO];
        return YES;
    }

    return NO;
}

#pragma mark - Deep links

- (BOOL)tryHandleDeepLink {
    if (self.routingURL) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self launchTripPlannerFromURL];
        return YES;
    }

    if (self.launchStops) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self launchFromURL];
        return YES;
    }

    return NO;
}

#pragma mark - Commuter bookmark

- (BOOL)tryHandleCommuterBookmark {
    if (!self.commuterBookmark)
        return NO;

    UserParams *params = self.commuterBookmark.userParams;

    [self.navigationController popToRootViewControllerAnimated:NO];
    DEBUG_LOG(@"popToRootViewControllerAnimated");

    [[DepartureTimesViewController viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                       stopId:params.valLocation
                                                                        title:params.valChosenName];

    self.commuterBookmark = nil;
    return YES;
}

#pragma mark - InitialAction switch

- (bool)handleInitialActionCase {
    switch (self.initialAction) {
    case InitialAction_TripPlanner:
        [self tripPlanner:YES];
        return true;
        break;

    case InitialAction_Commute:
        [self commuteAction:nil];
        break;

    case InitialAction_Locate:
        [self autoLocate:nil];
        return true;
        break;

    case InitialAction_QRCode:
        [self QRCodeScanner];
        return true;
        break;

    case InitialAction_Map:
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self showMapWithAll];
        return true;
        break;

    case InitialAction_BookmarkIndex:
        [self openFave:self.initialBookmarkIndex allowEdit:NO];
        return true;
        break;

    case InitialAction_UserActivityBookmark:
        [self openUserActivityBookmark:self.initialActionArgs];
        self.initialActionArgs = nil;
        return true;
        break;

    case InitialAction_UserActivitySearch:
        [self openSearchItem:self.initialActionArgs];
        self.initialActionArgs = nil;
        return true;
        break;

    case InitialAction_UserActivityAlerts:
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self showDetoursForRoute:self.initialActionArgs[kUserInfoAlertRoute]];
        self.initialActionArgs = nil;
        return true;
        break;

    case InitialAction_None:
    default:
        return [self handleDefaultInitialBookmarkOrRefresh];
        break;
    }
    return false;
}

- (bool)handleDefaultInitialBookmarkOrRefresh {
    if (self.initialBookmarkName.length > 0) {
        __block BOOL found = NO;
        __block NSInteger foundItem = 0;

        [_userState accessArray:_userState.faves
                          block:^(NSMutableArray<NSMutableDictionary *> *safeArray) {
                            for (NSInteger i = 0; i < safeArray.count; i++) {
                                UserParams *item = safeArray[i].userParams;
                                NSString *name = item.valChosenName;
                                if (name && [self.initialBookmarkName isEqualToString:name]) {
                                    found = YES;
                                    foundItem = i;
                                    break;
                                }
                            }
                          }];

        if (found) {
            [self openFave:(int)foundItem allowEdit:NO];
            return true;
        }
    }

    // User might have changed settings outside the app
    [self reloadData];
    [self updateToolbar];
    return false;
}

#pragma mark - Finish / cleanup

- (void)finishInitialAction {
    self.delayedInitialAction = NO;
    self.initialAction = InitialAction_None;
    self.initialBookmarkName = nil;
}

- (UITextField *)createTextField_Rounded {
    CGRect frame = CGRectMake(30.0, 0.0, 50.0, [CellTextField editHeight]);
    UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];

    returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor modeAwareText];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = NSLocalizedString(@"<enter stop ID>", @"default text");
    returnTextField.backgroundColor = [UIColor modeAwareGrayBackground];
    returnTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support

    returnTextField.keyboardType = UIKeyboardTypeNumberPad;
    returnTextField.returnKeyType = UIReturnKeyGo;

    returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing; // has a clear 'x' button to
                                                                       // the right
    self.editWindow = returnTextField;

    return returnTextField;
}

- (void)tripPlanner:(bool)animated {
    TripPlannerSummaryViewController *tripStart = [TripPlannerSummaryViewController viewController];
    tripStart.tripQuery.userFaves = _userState.stopsFromFaves;

    // Push the detail view controller
    [self.navigationController pushViewController:tripStart animated:YES];
}

- (void)updatePlaceholderRows:(bool)add {
    NSArray *indexPaths = @[
        [NSIndexPath indexPathForRow:_userState.faves.count inSection:_faveSection],
        [NSIndexPath indexPathForRow:_userState.faves.count + 1 inSection:_faveSection],
        [NSIndexPath indexPathForRow:_userState.faves.count + 2 inSection:_faveSection]
    ];

    NSInteger addRow = [self firstRowOfType:kTableFaveAddStop inSection:_faveSection];

    if (add && addRow == kNoRowSectionTypeFound) {
        // Show the placeholder rows

        [self clearSection:_faveSection];

        [self addRowType:kTableFaveAddStop forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTrip forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTakeMeHome forSectionType:kTableSectionFaves];

        [self addRowType:kTableFaveButtons forSectionType:kTableSectionFaves];

        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationTop];
    } else if (!add) { // && (_userData.faves).count!=0) {
        [self clearSection:_faveSection];
        [self addRowType:kTableFaveButtons forSectionType:kTableSectionFaves];

        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationTop];
    }

    [self setEditBookmarksButtonTitle];
}

- (void)editGoAction:(id)sender {
    [self.editWindow resignFirstResponder];
}

// Invoked before editing begins. The delegate may return NO to prevent
// editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell {
    _keyboardUp = YES;
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelAction:)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = self.goButton;

    [self.tableView
        scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self firstRowOfType:kTableFindRowId
                                                                       inSection:_editSection]
                                                  inSection:_editSection]
              atScrollPosition:UITableViewScrollPositionTop
                      animated:YES];

    return YES;
}

#pragma mark View methods

- (void)addStopIdRows {
    [self addRowType:kTableFindRowId];
    [self addRowType:kTableFindRowLocate];
    [self addRowType:kTableFindRowBrowse];
    [self addRowType:kTableFindRowRailMap];
    [self addRowType:kTableFindRowQR];

    [self addRowType:kTableFindRowHistory];
}

- (NSInteger)rowType:(NSIndexPath *)indexPath {
    NSInteger sectionType = [self sectionType:indexPath.section];

    switch (sectionType) {
    case kTableSectionFaves:
        if (indexPath.row < _userState.faves.count) {
            return kTableFaveBookmark;
        }
        return [super rowType:[NSIndexPath indexPathForRow:(indexPath.row - _userState.faves.count)
                                                 inSection:indexPath.section]];
    case kTableSectionRowAlarms:
        if (indexPath.row < self.alarmKeys.count) {
            return kTableSectionRowAlarms;
        }
        return kNoRowSectionTypeFound;
    }

    return [super rowType:indexPath];
}

- (void)mapSections {
    [self clearSectionMaps];

    if (_taskList) {
        self.alarmKeys = _taskList.taskKeys;
    }

    if (Settings.bookmarksAtTheTop) {
        if (self.alarmKeys != nil && self.alarmKeys.count > 0) {
            [self addSectionType:kTableSectionRowAlarms];
        }

        _faveSection = [self addSectionType:kTableSectionFaves];

        if (self.editing) {
            [self addRowType:kTableFaveAddStop];
            [self addRowType:kTableFaveAddTrip];
            [self addRowType:kTableFaveAddTakeMeHome];
        }

        [self addRowType:kTableFaveButtons];
        _editSection = [self addSectionType:kTableSectionStopId];
        [self addStopIdRows];
        [self addSectionType:kTableSectionPlanner];
        [self addRowType:kTableTripRowPlanner];
        [self addRowType:kTableTripRowCache];
    } else {
        if (_taskList != nil && _taskList.taskCount > 0) {
            [self addSectionType:kTableSectionRowAlarms];
        }

        _editSection = [self addSectionType:kTableSectionStopId];
        [self addStopIdRows];
        [self addSectionType:kTableSectionPlanner];
        [self addRowType:kTableTripRowPlanner];
        [self addRowType:kTableTripRowCache];
        _faveSection = [self addSectionType:kTableSectionFaves];

        if (self.editing) {
            [self addRowType:kTableFaveAddStop];
            [self addRowType:kTableFaveAddTrip];
            [self addRowType:kTableFaveAddTakeMeHome];
        }

        [self addRowType:kTableFaveButtons];
    }

    if (Settings.vehicleLocations) {
        [self addSectionType:kTableSectionVehicleId];

        [self addRowType:kTableFindRowVehicle];
        [self addRowType:kTableFindRowVehicleId];
    }

    [self addSectionType:kTableSectionTriMet];
    [self addRowType:kTableTriMetDetours];
    [self addRowType:kTableTriMetLink];
    [self addRowType:kTableTriMetInstagram];
    [self addRowType:kTableTriMetFacebook];
    [self addRowType:kTableTriMetBluesky];

    if ([self canCallTriMet]) {
        [self addRowType:kTableTriMetCall];
    }

    [self addRowType:kTableTriMetCustomerService];

    [self addSectionType:kTableSectionStreetcar];
    [self addRowType:kTableStreetcarLink];
    [self addRowType:kTableStreetcarInstagram];

    [self addSectionType:kTableSectionAbout];
    [self addRowType:kTableAboutSettings];
    [self addRowType:kTableAboutRowAbout];
    [self addRowType:kTableAboutSupport];
    [self addRowType:kTableAboutRate];
    [self addRowType:kTableTipJar];

#ifdef COFFEE
    [self addRowType:kTableBuyMeACoffee];
#endif // COFFEE
}

- (bool)memberInit {
    bool result = [super memberInit];

    if ([AlarmTaskList supported]) {
        _taskList = [AlarmTaskList sharedInstance];
    }

    if (self.session == nil) {
        Class wcClass = (NSClassFromString(@"WCSession"));

        if (wcClass) {
            if ([WCSession isSupported]) {
                self.session = [WCSession defaultSession];
                self.session.delegate = self;
                [self.session activateSession];
            }
        }
    }

    return result;
}

- (void)addBookmarksToIndex {
    if (Settings.searchBookmarks) {
        UserParams *bookmark = nil;
        NSMutableArray *index = [NSMutableArray array];
        int i;

        for (i = 0; i < self->_userState.faves.count; i++) {
            bookmark = self->_userState.faves[i].userParams;

            CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc]
                initWithItemContentType:UTTypeText.identifier];
            attributeSet.title = bookmark.valChosenName;

            if (bookmark.valLocation != nil) {
                attributeSet.contentDescription = @"Departure bookmark";
            } else {
                attributeSet.contentDescription = @"Trip Planner bookmark";
            }

            NSString *uniqueId = [NSString stringWithFormat:@"%@:%d", kSearchItemBookmark, i];

            CSSearchableItem *item =
                [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId
                                                  domainIdentifier:@"bookmark"
                                                      attributeSet:attributeSet];

            [index addObject:item];
        }

        [[CSSearchableIndex defaultSearchableIndex]
            indexSearchableItems:index
               completionHandler:^(NSError *__nullable error) {
                 if (error != nil) {
                     ERROR_LOG(@"Failed to create "
                               @"bookmark index %@\n",
                               error.description);
                 }
               }];
    }
}

- (void)indexBookmarks {
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));

    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable]) {
        return;
    }

    CSSearchableIndex *searchableIndex = [CSSearchableIndex defaultSearchableIndex];

    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[ @"bookmark" ]
                                              completionHandler:^(NSError *__nullable error) {
                                                if (error != nil) {
                                                    ERROR_LOG(@"Failed to delete bookmark "
                                                              @"index %@\n",
                                                              error.description);
                                                }
                                                [self addBookmarksToIndex];
                                              }];

    UIApplication *app = [UIApplication sharedApplication];

    if ([app respondsToSelector:@selector(setShortcutItems:)]) {
        NSMutableArray *shortCutItems = [NSMutableArray array];
        UserParams *bookmark = nil;

        int i;

        for (i = 0; i < _userState.faves.count && i < 4; i++) {
            bookmark = _userState.faves[i].userParams;
            UIMutableApplicationShortcutItem *aMutableShortcutItem =
                [[UIMutableApplicationShortcutItem alloc] initWithType:@"bookmark"
                                                        localizedTitle:bookmark.valChosenName];

            if (bookmark.valLocation != nil) {
                aMutableShortcutItem.localizedSubtitle =
                    NSLocalizedString(@"Departure bookmark", @"button text");
            } else {
                aMutableShortcutItem.localizedSubtitle =
                    NSLocalizedString(@"Trip Planner bookmark", @"button text");
            }

            aMutableShortcutItem.userInfo = bookmark.dictionary;

            [shortCutItems addObject:aMutableShortcutItem];
        }

        [UIApplication sharedApplication].shortcutItems = shortCutItems;
    }
}

- (void)reloadData {
    [self mapSections];
    [self setTheme];
    [super reloadData];
    [self indexBookmarks];
    [self setEditBookmarksButtonTitle];
}

static __weak RootViewController *staticInstance;

- (void)loadView {
    DO_ONCE(^{
      [BoxedIcon initializeIcons];
    });

    staticInstance = self;
    [self memberInit];
    [self mapSections];
    [super loadView];
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)writeLastRun:(NSDictionary *)dict file:(NSString *)lastRun {
    bool written = false;

    @try {
        written = [dict writeToFile:lastRun atomically:YES];
    } @catch (NSException *exception) {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason);
    }

    if (!written) {
        ERROR_LOG(@"Failed to write to %@\n", lastRun);
    }
}

- (bool)changedEnoughToShowWhatsNewFirst:(NSString *)first second:(NSString *)second {
    NSString *verSeparator = @".";
    NSArray *firstFields = [first componentsSeparatedByString:verSeparator];
    NSArray *secondFields = [second componentsSeparatedByString:verSeparator];

    if (firstFields.count != 3 || secondFields.count != 3) {
        return ![first isEqualToString:second];
    }

    if (![firstFields[0] isEqualToString:secondFields[0]]) {
        return true;
    }

    if (![firstFields[1] isEqualToString:secondFields[1]]) {
        return true;
    }

    return false;
}

- (bool)newVersion:(NSString *)file version:(NSString *)version any:(bool)any {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *lastRun = file.fullDocPath;

    NSMutableDictionary *dict = nil;
    bool newVersion = NO;

    if ([fileManager fileExistsAtPath:lastRun] == NO) {
        dict = [NSMutableDictionary dictionary];
        dict[kVersion] = version;

        [self writeLastRun:dict file:lastRun];

        newVersion = YES;
    } else {
        dict = [[NSMutableDictionary alloc] initWithContentsOfFile:lastRun];
        NSString *lastVerRun = dict[kVersion];

        if ((any && ![lastVerRun isEqualToString:version]) ||
            [self changedEnoughToShowWhatsNewFirst:lastVerRun second:version]) {
            newVersion = YES;
            dict[kVersion] = version;
            [self writeLastRun:dict file:lastRun];
        }
    }

    return newVersion;
}

- (void)setupiCloud {
    // iCloud Data
    NSFileManager *fileManager = [NSFileManager defaultManager];

    id currentiCloudToken = fileManager.ubiquityIdentityToken;

    // Archiving iCloud availability in the user defaults database
    Settings.iCloudToken = currentiCloudToken;

    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];

    DO_ONCE(^{
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(handleiCloudStateChange:)
                                                   name:NSUbiquityIdentityDidChangeNotification
                                                 object:nil];

      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(handleChangesFromiCloud:)
                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
               object:store];
    });

    if (currentiCloudToken && Settings.firstLaunchWithiCloudAvailable) {
        [store synchronize];
        self.iCloudFaves = YES;
        [self iCloudInitialMerge];
    } else if (currentiCloudToken) {
        [store synchronize];
        self.iCloudFaves = YES;
        self->_userState.canWriteToCloud = YES;
        [self->_userState mergeWithCloud:nil];
    } else { // no iCloud
        self.iCloudFaves = NO;
        self->_userState.canWriteToCloud = NO;
        Settings.firstLaunchWithiCloudAvailable = YES;
    }
}

- (void)viewDidLoad {
#ifndef LOADINGSCREEN
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.title = NSLocalizedString(@"PDX Bus", @"Main Screen title");
#else
    self.title = @"Loading PDX Bus";
#endif // LOADINGSCREEN

    [super viewDidLoad];

    self.tableView.rowHeight = UITableViewAutomaticDimension;

    if (self.delayedInitialAction) {
        [self executeInitialAction];
        self.delayedInitialAction = NO;
    }

    // Prime the icon database now

#if !TARGET_OS_MACCATALYST
    [INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status){
    }];
#endif // !TARGET_OS_MACCATALYST

    [self setupiCloud];

    [TipJarManager.shared fetchProductsAndStartListener:@[
        @"org.teleportaloo.pdxbus.tip.small",
        @"org.teleportaloo.pdxbus.tip.medium",
        @"org.teleportaloo.pdxbus.tip.large"
    ]
                                                 parent:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    DEBUG_LOG_long(self.tableView.contentOffset.y);
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    DEBUG_LOG_long(self.tableView.contentOffset.y);
    [super viewWillAppear:animated];

    DEBUG_FUNC();
}

- (void)handleChangeInUserSettingsOnMainThread:(NSNotification *)notfication {
    [super handleChangeInUserSettingsOnMainThread:notfication];
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    DEBUG_LOG_long(self.tableView.contentOffset.y);
    [super viewDidAppear:animated];

    DEBUG_FUNC();

    if (_taskList) {
        _taskList.observer = self;
    }

    if (_userState.dirty || !_updatedWatch) {
        [_userState cacheState];

        if (!_updatedWatch) {
            [WatchAppContext updateWatch:self.session];
        }

        _userState.dirty = NO;
        _updatedWatch = YES;
    }

#ifndef LOADINGSCREEN
    self.navigationItem.rightBarButtonItem = self.helpButton;
#endif // LOADINGSCREEN

    [self reloadData];
    [self updateToolbar];

    [self iOS7workaroundPromptGap];

    DEBUG_FUNCEX();
}

- (void)cloudToLocal {
    Settings.firstLaunchWithiCloudAvailable = NO;
    _userState.canWriteToCloud = YES;
    [_userState mergeWithCloud:nil];
    self.iCloudFaves = YES;
    [_userState cacheState];
    [self userStateChanged];
    [self reloadData];
}

- (void)iCloudInitialMerge {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSNumber *total = [store objectForKey:kiCloudTotal];

    DEBUG_FUNC();

    if (total != nil && _userState.faves.count == 0) {
        DEBUG_LOG(@"Found iCloud bookmarks; merging");
        [self cloudToLocal];
    } else if (total != nil) {
        if (!_userState.hasEverChanged) {
            DEBUG_LOG(@"Found iCloud bookmarks; local ones are unchanged so "
                      @"merging.");
            [self cloudToLocal];
        } else {
            DEBUG_LOG(@"Found iCloud bookmarks; local ones are changed "
                      @"- using "
                      @"local.");
            Settings.firstLaunchWithiCloudAvailable = NO;
            self->_userState.canWriteToCloud = YES;
            self.iCloudFaves = YES;
            [self->_userState cacheState];
            [self userStateChanged];
            [self reloadData];
        }
    } else {
        // Just write it now.  We will get an initial sync warning.
        DEBUG_LOG(@"No iCloud bookmarks; writing local and hopng for sync.");
        Settings.firstLaunchWithiCloudAvailable = NO;
        self->_userState.canWriteToCloud = YES;
        self.iCloudFaves = YES;
        [self->_userState cacheState];
        [self userStateChanged];
        [self reloadData];
    }
}

- (void)handleiCloudStateChange:(NSNotification *)notification {
    DEBUG_FUNC();
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
      [self setupiCloud];
    }];
}

- (void)handleChangesFromiCloud:(NSNotification *)notification {
    DEBUG_FUNC();
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
      NSDictionary *userInfo = [notification userInfo];
      NSInteger reason =
          [[userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey] integerValue];
      NSArray *keys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

      DEBUG_LOG_long(reason);
      // 4 reasons:
      switch (reason) {
      case NSUbiquitousKeyValueStoreInitialSyncChange:
          DEBUG_CASE(NSUbiquitousKeyValueStoreInitialSyncChange);
          // First launch and the default bookmarks were overwritten
          [self->_userState mergeWithCloud:nil];
          [self userStateChanged];
          [self reloadData];
          break;

      case NSUbiquitousKeyValueStoreServerChange:
          // Updated values
          DEBUG_CASE(NSUbiquitousKeyValueStoreServerChange);
          [self->_userState mergeWithCloud:keys];
          [self userStateChanged];
          [self reloadData];
          break;

      case NSUbiquitousKeyValueStoreQuotaViolationChange: {
          DEBUG_CASE(NSUbiquitousKeyValueStoreQuotaViolationChange);
          // No free space
          // Probably delete items from the store

          [UIAlertController simpleOkWithTitle:NSLocalizedString(@"iCloud", @"alert title")
                                       message:NSLocalizedString(@"You have too many bookmarks to "
                                                                 @"store in the "
                                                                 @"cloud. You should delete some "
                                                                 @"bookmarks.",
                                                                 @"error message")
                                viewController:self
                                    completion:nil];
          self.iCloudFaves = NO;
          break;
      }

      case NSUbiquitousKeyValueStoreAccountChange:
          DEBUG_CASE(NSUbiquitousKeyValueStoreAccountChange);
          // iCloud account changed
          // Ask the user what to do
          [self setupiCloud];
          break;

      default:
          DEBUG_DEFAULT(reason);
          break;
      }
#ifdef DEBUGLOGGING

      for (NSString *key in keys) {
          DEBUG_LOG(@"Value for key %@ changed", key);
      }

#endif // DEBUGLOGGING
    }];
}

- (void)viewWillLayoutSubviews {
    DEBUG_LOG_long(self.tableView.contentOffset.y);
}

- (void)viewDidDisappear:(BOOL)animated {
    if (_taskList) {
        _taskList.observer = nil;
    }

    DEBUG_LOG_long(self.tableView.contentOffset.y);

    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't
                                     // have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Editing callbacks
// Set the editing state of the view controller. We pass this down to
// the table view and also modify the content of the table to insert a
// placeholder row for adding content when in editing mode.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    [self.tableView setEditing:editing animated:animated];
    [self.tableView beginUpdates];
    [self updatePlaceholderRows:editing];
    [self setEditBookmarksButtonTitle];

    [self.tableView endUpdates];
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell {
    UITextView *textView = (UITextView *)((CellTextField *)cell).view;

    [self postEditingAction:textView];
}

- (void)cancelAction:(id)sender {
    self.navigationItem.rightBarButtonItem = self.helpButton;
    [self.editWindow resignFirstResponder];
}

- (void)postEditingAction:(UITextView *)textView;
{
    NSString *editText = [textView.text justNumbers];

    if (editText.length != 0 &&
        (!_keyboardUp || self.navigationItem.rightBarButtonItem != self.helpButton)) {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];
        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask stopId:editText];
    } else if (_keyboardUp) {
        [self.editWindow resignFirstResponder];
    }

    self.navigationItem.rightBarButtonItem = self.helpButton;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    _keyboardUp = NO;
}

#pragma mark TableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;

    switch ([self sectionType:section]) {
    case kTableSectionFaves: {
        NSInteger cnt = _userState.faves.count;
        // DEBUG_LOG(@"Cnt %ld Editing self %d tableview %d\n",
        // (long)cnt, self.editing, tableView.editing);
        rows = cnt + [self rowsInSection:section];
        // DEBUG_LOG(@"Rows %ld\n", (long)rows);

        break;
    }

    case kTableSectionRowAlarms: {
        if (_taskList) {
            rows = self.alarmKeys.count;
        }

        break;
    }
    default:
        rows = [self rowsInSection:section];
        break;
    }
    // printf("Section %d rows %d\n", section, rows);
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kTableSectionStopId:
        return NSLocalizedString(@"Show departures for stop:", @"section header");

    case kTableSectionVehicleId:
        return NSLocalizedString(@"Locate vehicle you are on (not Streetcar)", @"section header");

    case kTableSectionRowAlarms:
        return NSLocalizedString(@"Alarms:", @"section header");

    case kTableSectionFaves:

        if (self.iCloudFaves) {
            return NSLocalizedString(@"iCloud Bookmarks:", @"section header");
        } else {
            return NSLocalizedString(@"Bookmarks:", @"section header");
        }

    case kTableSectionTriMet:
        return NSLocalizedString(@"More from TriMet:", @"section header");

    case kTableSectionStreetcar:
        return NSLocalizedString(@"More from Portland Streetcar:", @"section header");

    case kTableSectionAbout:
        return NSLocalizedString(@"More app info:", @"section header");

    case kTableSectionPlanner:
        return NSLocalizedString(@"Trips:", @"section header");
    }
    return nil;
}

- (void)setEditBookmarksButtonTitle {
    if (self.editing) {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Done editing", @"button text")
                                  forState:UIControlStateNormal];
    } else if (_userState.faves.count > 0) {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Edit bookmarks", @"button text")
                                  forState:UIControlStateNormal];
    } else {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Add bookmarks", @"button text")
                                  forState:UIControlStateNormal];
    }

    if (_userState.faves.count > 0) {
        [self.emailBookmarksButton setTitle:NSLocalizedString(@"Email bookmarks", @"button text")
                                   forState:UIControlStateNormal];
        self.emailBookmarksButton.enabled = YES;
    } else {
        [self.emailBookmarksButton setTitle:@"" forState:UIControlStateNormal];
        self.emailBookmarksButton.enabled = NO;
    }
}

- (void)editBookmarks:(id)sender {
    [self setEditing:!self.editing animated:YES];
}

- (void)emailBookmarks:(id)sender {
    [_userState
        accessArray:_userState.faves
              block:^(NSMutableArray<NSMutableDictionary *> *safeArray) {
                if (safeArray.count > 0) {
                    if (![MFMailComposeViewController canSendMail]) {
                        [UIAlertController
                            simpleOkWithTitle:NSLocalizedString(@"email", @"alert title")
                                      message:NSLocalizedString(@"Cannot send email on "
                                                                @"this device",
                                                                @"error message")
                               viewController:self
                                   completion:nil];
                        return;
                    }

                    MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];

                    email.mailComposeDelegate = self;

                    [email setSubject:NSLocalizedString(@"PDX Bus Bookmarks", @"email subject")];

                    NSMutableString *body = [[NSMutableString alloc] init];
                    UserParams *item;

                    [body appendFormat:NSLocalizedString(@"Click on a link to add a bookmark to "
                                                         @"PDXBus "
                                                         @"running on a another device.<br><br>",
                                                         @"email body")];

                    int i;

                    for (i = 0; i < safeArray.count; i++) {
                        item = safeArray[i].userParams;

                        if (item.valLocation != nil) {
                            [body appendFormat:@"<a href=\"pdxbus2://?d%@/\">%@</a> - "
                                               @"%@<br>",
                                               [self propertyListToHex:item.dictionary],
                                               item.valChosenName,
                                               item.valLocation];
                        } else {
                            [body appendFormat:NSLocalizedString(@"<a "
                                                                 @"href=\"pdxbus2://?d%@/\">%@</a> "
                                                                 @"- "
                                                                 @"Trip Planner Bookmark<br>",
                                                                 @"email body"),
                                               [self propertyListToHex:item.dictionary],
                                               item.valChosenName];
                        }
                    }

                    [body appendFormat:@"<br><br>"];

                    [body appendFormat:@"<a href = \"pdxbus2://"];

                    for (i = 0; i < safeArray.count; i++) {
                        item = safeArray[i].userParams;
                        [body appendFormat:@"?d%@/", [self propertyListToHex:item.dictionary]];
                    }

                    [body
                        appendFormat:NSLocalizedString(@"\">Add all bookmarks</a>", @"email body")];

                    [email setMessageBody:body isHTML:YES];

                    [self presentViewController:email animated:YES completion:nil];

                    DEBUG_LOG(@"BODY\n%@\n", body);
                }
              }];
}

#define kEditButtonTag 1
#define kEmailButtonTag 2

- (UITableViewCell *)buttonCell:(NSString *)cellId buttons:(NSArray *)items height:(CGFloat)height {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:cellId];
    static const CGFloat xgap = 10;
    static const CGFloat ymargin = 2;

    CGFloat screenWidth = self.navigationController.view.frame.size.width;

    CGFloat width = ((screenWidth - xgap * 2) / items.count) - ((items.count - 1) * xgap);

    int i = 0;

    for (UIButton *button in items) {
        CGRect buttonRect =
            CGRectMake(xgap + (xgap + width) * i, ymargin, width, height - (ymargin * 2));

        button.frame = buttonRect;

        [cell.contentView addSubview:button];
        i++;
    }

    [cell layoutSubviews];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.isAccessibilityElement = NO;
    cell.backgroundView = [self clearView];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];

    return cell;
}

#pragma mark - Section Handlers

- (UITableViewCell *)tableView:(UITableView *)tableView
              editCellWithText:(NSString *)text
                          icon:(BoxedIcon *)icon {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kNewBookMark];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.editingAccessoryType = cell.accessoryType;

    cell.textLabel.text = text;
    cell.icon = icon;
    [self updateAccessibility:cell];
    return cell;
}

#pragma mark - Small Helpers

- (UITableViewCell *)standardizeBaseCell:(UITableViewCell *)cell {
    cell.textLabel.font = self.basicFont;
    [self updateAccessibility:cell];
    return cell;
}

- (NSString *)propertyListToHex:(NSDictionary *)item {
    NSError *error = nil;

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:item
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:&error];

    LOG_NSError(error);

    if (data != nil) {
        NSMutableString *hex = [NSMutableString string];

        for (int i = 0; i < data.length; i++) {
            [hex appendFormat:@"%02X", ((unsigned char *)data.bytes)[i]];
        }

        return hex;
    }

    return nil;
}

- (bool)validBookmark:(NSDictionary *)item {
    UserParams *params = item.userParams;
    NSString *location = params.valLocation;
    NSDictionary *tripItem = params.immutableTrip;
    TripUserRequest *req = [TripUserRequest fromDictionary:tripItem];

    return !((tripItem == nil && item != nil && ((location == nil) || (location.length == 0))) ||
             (tripItem != nil && req != nil && req.fromPoint.locationDesc == nil &&
              req.fromPoint.useCurrentLocation == false) ||
             (tripItem != nil && req != nil && req.toPoint.locationDesc == nil &&
              req.toPoint.useCurrentLocation == false));
}

- (void)openFave:(int)index allowEdit:(bool)allowEdit {
    __block MutableUserParams *item = nil;
    __block NSString *stopIds = nil;
    __block TripUserRequest *req = nil;
    __block NSDictionary *tripItem = nil;

    NSInteger rowType = [self rowType:[NSIndexPath indexPathForRow:index inSection:_faveSection]];

    DEBUG_LOG_long(_userState.faves.count);

    if (DEBUG_AND(self.iCloudFaves)) {
        DEBUG_LOG_long(
            ((NSNumber *)[[NSUbiquitousKeyValueStore defaultStore] objectForKey:kiCloudTotal])
                .integerValue);
    }

    if (rowType == kTableFaveBookmark) {
        [_userState accessArray:_userState.faves
                          block:^(NSMutableArray<NSMutableDictionary *> *safeArray) {
                            item = safeArray[index].mutableUserParams;
                            stopIds = item.valLocation;
                            tripItem = item.valTrip;
                            req = [TripUserRequest fromDictionary:tripItem];
                          }];
    }

    DEBUG_LOG_BOOL(self.tableView.editing);

    bool validItem = [self validBookmark:item.dictionary];

    if (allowEdit && (self.tableView.editing || _userState.faves.count == 0 || !validItem)) {
        switch (rowType) {
        case kTableFaveBookmark: {
            EditBookMarkViewController *edit = [EditBookMarkViewController viewController];
            edit.invalidItem = !validItem;
            [edit editBookMark:item.mutableDictionary item:index];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddStop: {
            EditBookMarkViewController *edit = [EditBookMarkViewController viewController];
            [edit addBookMark];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddTrip: {
            EditBookMarkViewController *edit = [EditBookMarkViewController viewController];
            [edit addTripBookMark];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddTakeMeHome: {
            EditBookMarkViewController *edit = [EditBookMarkViewController viewController];
            [edit addTakeMeHomeBookMark];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        default:
            break;
        }
    } else if (stopIds != nil) {
        [[DepartureTimesViewController viewController]
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:stopIds
                                 title:item.valChosenName];
    } else {
        TripPlannerDateViewController *tripDate = [TripPlannerDateViewController viewController];

        [tripDate initializeFromBookmark:req];
        tripDate.tripQuery.userFaves = _userState.stopsFromFaves;

        // Push the detail view controller
        [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
    }
}

- (void)openSearchItem:(NSDictionary *)item {
    NSString *uniqueId = item[CSSearchableItemActivityIdentifier];

    NSScanner *scanner = [NSScanner scannerWithString:uniqueId];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSString *prefix = nil;

    if ([scanner scanUpToCharactersFromSet:colon intoString:&prefix]) {
        int arg = -1;

        if (!scanner.atEnd) {
            scanner.scanLocation++;
        }

        if ([scanner scanInt:&arg]) {
            if ([prefix isEqualToString:kSearchItemStation]) {
                RailStation *station = [RailStation fromHotSpotIndex:arg];

                if (station == nil) {
                    return;
                }

                RailStationTableViewController *railView =
                    [RailStationTableViewController viewController];
                railView.station = station;
                [self.navigationController popToRootViewControllerAnimated:NO];

                [railView fetchShapesAndDetoursAsync:self.backgroundTask];
                // [self.navigationController
                // pushViewController:railView animated:YES];
            } else if ([prefix isEqualToString:kSearchItemBookmark]) {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self openFave:arg allowEdit:NO];
            } else if ([prefix isEqualToString:kSearchItemRoute]) {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [[DirectionViewController viewController]
                    fetchDirectionsAsync:self.backgroundTask
                                   route:[NSString stringWithFormat:@"%d", arg]];
            }
        }
    }
}

- (void)openUserActivityBookmark:(NSDictionary *)item {
    UserParams *params = item.userParams;
    NSString *location = params.valLocation;
    NSDictionary *tripItem = params.immutableTrip;
    NSString *block = params.valBlock;
    NSString *dir = params.valDir;

    if (location != nil && block != nil) {
        [[DepartureDetailViewController viewController] fetchDepartureAsync:self.backgroundTask
                                                                     stopId:location
                                                                      block:block
                                                                        dir:dir
                                                          backgroundRefresh:NO];
    } else if (location != nil) {
        [[DepartureTimesViewController viewController]
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:location
                                 title:params.valChosenName];
    } else {
        TripUserRequest *req = [TripUserRequest fromDictionary:tripItem];

        [req clearGpsNames];

        TripPlannerDateViewController *tripDate = [TripPlannerDateViewController viewController];

        [tripDate initializeFromBookmark:req];
        tripDate.tripQuery.userFaves = _userState.stopsFromFaves;

        // Push the detail view controller
        [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationItem.rightBarButtonItem == self.goButton) {
        self.navigationItem.rightBarButtonItem = self.helpButton;
        [self.editWindow resignFirstResponder];
    }

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionFaves: {
        [self openFave:(int)indexPath.row allowEdit:YES];
        break;
    }

    default:
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        break;
    }
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    DEBUG_LOG(@"delete r %ld  s %ld\n", (long)indexPath.row, (long)indexPath.section);

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        switch ([self sectionType:indexPath.section]) {
        case kTableSectionFaves: {
            [_userState accessArray:_userState.faves
                              block:^(NSMutableArray *safeArray) {
                                [safeArray removeObjectAtIndex:indexPath.row];
                              }];
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationNone];
            [_userState cacheState];
            [WatchAppContext updateWatch:self.session];
            [self setEditBookmarksButtonTitle];
            break;
        }
        case kTableSectionRowAlarms:
            [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
            NSMutableArray *newKeys = [NSMutableArray arrayWithArray:self.alarmKeys];
            [newKeys removeObjectAtIndex:indexPath.row];
            self.alarmKeys = newKeys;
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationNone];

            if (self.alarmKeys.count == 0) {
                [self reloadData];
            }

            break;
        }
    }

    if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
                         toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    NSInteger srcSection = [self sectionType:sourceIndexPath.section];

    int sectionMax = 1;

    switch (srcSection) {
    case kTableSectionFaves:
        sectionMax = (int)_userState.faves.count;
        break;
    }

    if (proposedDestinationIndexPath.section < sourceIndexPath.section) {
        return [NSIndexPath indexPathForRow:0 inSection:sourceIndexPath.section];
    }

    if (proposedDestinationIndexPath.section > sourceIndexPath.section) {
        return [NSIndexPath indexPathForRow:sectionMax - 1 inSection:sourceIndexPath.section];
    }

    if (proposedDestinationIndexPath.row >= sectionMax) {
        return [NSIndexPath indexPathForRow:sectionMax - 1 inSection:sourceIndexPath.section];
    }

    return proposedDestinationIndexPath;
}

/*
 // Have an accessory view for the second section only
 - (UITableViewCellAccessoryType)tableView:(UITableView *)tableView
 accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath { return
 (sectionMap[indexPath.section] == kTableSectionFaves && indexPath.row <
 [self.userFaves count] && self.editing) ?
 UITableViewCellAccessoryDisclosureIndicator :
 UITableViewCellAccessoryNone ;
 }
 */

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath {
    //    [self dumpPath:@"moveRowAtIndexPath from" path:fromIndexPath];
    //    [self dumpPath:@"moveRowAtIndexPath to  " path:toIndexPath];

    switch ([self sectionType:fromIndexPath.section]) {
    case kTableSectionFaves: {
        if ([self sectionType:toIndexPath.section] == kTableSectionFaves) {

            [_userState accessArray:_userState.faves
                              block:^(NSMutableArray *safeArray) {
                                NSMutableDictionary *move = safeArray[fromIndexPath.row];

                                if (fromIndexPath.row < toIndexPath.row) {
                                    [safeArray insertObject:move atIndex:toIndexPath.row + 1];
                                    [safeArray removeObjectAtIndex:fromIndexPath.row];
                                } else {
                                    [safeArray removeObjectAtIndex:fromIndexPath.row];
                                    [safeArray insertObject:move atIndex:toIndexPath.row];
                                }
                              }];

            [_userState cacheState];
            [WatchAppContext updateWatch:self.session];
        }
        break;
    }
    }
    //    [tableView reloadData];
}

#pragma mark Mail Composer callbacks

// Dismisses the email composition interface when users tap Cancel or
// Send. Proceeds to update the message field with the result of the
// operation.
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Alarm tasks callbacks
- (void)taskUpdate:(id)task {
    AlarmTask *realTask = (AlarmTask *)task;

    NSInteger alarmSection = [self firstSectionOfType:kTableSectionRowAlarms];

    if (alarmSection != kNoRowSectionTypeFound) {
        int i = 0;

        for (NSString *key in self.alarmKeys) {
            if ([key isEqualToString:[realTask key]]) {
                NSIndexPath *cellIndex = [NSIndexPath indexPathForRow:i inSection:alarmSection];

                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellIndex];

                if (!cell.showingDeleteConfirmation && !cell.editing) {
                    [self.tableView reloadRowsAtIndexPaths:@[ cellIndex ]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            }

            i++;
        }
    }
}

- (void)taskStarted:(id)task {
}

- (void)taskDone:(id)task {
    if (!self.tableView.editing) {
        [self reloadData];
    }
}

- (void)didEnterBackground {
    [self.progressView removeFromSuperview];
    self.progressView = nil;
    [self dismissViewControllerAnimated:YES completion:nil];

    if (self.backgroundTask) {
        [self.backgroundTask taskCancel];
        [self.backgroundTask.progressModal removeFromSuperview];
        self.backgroundTask.progressModal = nil;
    }

    ;
}

// Watch Kit delegate
- (void)session:(WCSession *)session
    activationDidCompleteWithState:(WCSessionActivationState)activationState
                             error:(nullable NSError *)error {
}

/** Called when the session can no longer be used to modify or add any
 * new transfers and, all interactive messages will be cancelled, but
 * delegate callbacks for background transfers can still occur. This
 * will happen when the selected watch is being changed. */
- (void)sessionDidBecomeInactive:(WCSession *)session {
}

/** Called when all delegate callbacks for the previously selected watch
 * has occurred. The session can be re-activated for the now selected
 * watch using activateSession. */
- (void)sessionDidDeactivate:(WCSession *)session {
}

/** Called when any of the Watch state properties change. */
- (void)sessionWatchStateDidChange:(WCSession *)session {
    [WatchAppContext updateWatch:self.session];
}

/** Called on the sending side after the user info transfer has
 * successfully completed or failed with an error. Will be called on
 * next launch if the sender was not running when the user info
 * finished. */
- (void)session:(WCSession *__nonnull)session
    didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer
                        error:(nullable NSError *)error {
}

/** Called on the delegate of the receiver. Will be called on startup if
 * the user info finished transferring when the receiver was not
 * running. */
- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    if (userInfo != nil) {
        NSDictionary *dict = userInfo.userParams.valRecent;

        if (dict) {
            UserParams *recent = dict.userParams;
            NSString *stopId = recent.valLocation;
            NSString *desc = recent.valOriginalName;

            if (stopId && desc) {
                [UserState.sharedInstance addToRecentStops:stopId description:desc];
            }
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        self.editCell = nil;
    }
    [super traitCollectionDidChange:previousTraitCollection];
}

+ (RootViewController *)currentRootViewController {
    return staticInstance;
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS RootViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetCustomerService

LINK_CELL(kTableTriMetCustomerService,
          kIconTriMetLink,
          NSLocalizedString(@"Contact TriMet Customer Service", @"main menu item"),
          @"TriMet Customer Service");

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetLink

LINK_CELL(kTableTriMetLink,
          kIconTriMetLink,
          NSLocalizedString(@"TriMet's website", @"main menu item"),
          @"TriMet");

//--------------------------------------------------------------------------------------------------
#pragma mark kTableStreetcarLink

LINK_CELL(kTableStreetcarLink,
          kIconStreetcar,
          NSLocalizedString(@"Portland Streetcar's website", @"main menu item"),
          @"Portland Streetcar");

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetBluesky

LINK_CELL_SELECT(kTableTriMetBluesky,
                 kIconBluesky,
                 NSLocalizedString(@"@trimet.org on Bluesky", @"main menu item")) {
    [self triMetBluesky];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableStreetcarInstagram

LINK_CELL_SELECT(kTableStreetcarInstagram,
                 kIconInstagram,
                 NSLocalizedString(@"@PDXStreetcar on Instagram", @"main menu item")) {
    [self instagramAt:@"PDXStreetcar"];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetFacebook

LINK_CELL_SELECT(kTableTriMetFacebook,
                 kIconFacebook,
                 NSLocalizedString(@"TriMet's Facebook page", @"main menu item")) {
    [self facebookTriMet];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetInstagram

LINK_CELL_SELECT(kTableTriMetInstagram,
                 kIconInstagram,
                 NSLocalizedString(@"TriMet's Instagram", @"main menu item")) {
    [self instagramAt:@"trimet"];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetCall

BASIC_CELL_SELECT(kTableTriMetCall,
                  (NSLocalizedString(@"Call TriMet on 503-238-RIDE", @"main menu item")),
                  kIconPhone,
                  UITableViewCellAccessoryNone) {
    [self callTriMet];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTriMetDetours

MARKUP_CELL_SELECT(kTableTriMetDetours,
                   basic,
                   NSLocalizedString(@"#RDetours, delays and closures", @"main menu item"),
                   kIconDetour,
                   UITableViewCellAccessoryDisclosureIndicator) {
    [[DetoursViewController viewController] fetchDetoursAsync:self.backgroundTask];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableAboutSettings

BASIC_CELL_SELECT(kTableAboutSettings,
                  NSLocalizedString(@"Settings", @"main menu item"),
                  kIconSettings,
                  UITableViewCellAccessoryNone) {
    [self settingsAction:nil];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableAboutRowAbout

BASIC_CELL_SELECT(kTableAboutRowAbout,
                  NSLocalizedString(@"About & legal", @"main menu item"),
                  kIconAbout,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([AboutViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableAboutSupport

BASIC_CELL_SELECT(kTableAboutSupport,
                  NSLocalizedString(@"Help, Tips & support", @"main menu item"),
                  kIconXml,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([SupportViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableAboutRate

// We don't use a link cell as we don't want to show the link
BASIC_CELL_SELECT(kTableAboutRate,
                  NSLocalizedString(@"Rate PDX Bus in the App Store", @"main menu item"),
                  kIconAward,
                  UITableViewCellAccessoryNone) {
    [WebViewController openNamedURL:@"PDX Bus App Store Review"];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTipJar

CELL_TIP_JAR(kTableTipJar, basic);

//--------------------------------------------------------------------------------------------------
#pragma mark kTableSectionRowAlarms

CELL_CONFIG_METHOD(kTableSectionRowAlarms) {
    UITableViewCell *cell = nil;

    if (indexPath.row < self.alarmKeys.count) {
        AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
        if (task != nil) {
            NSString *cellId = [task cellReuseIdentifier:kAlarmCellId width:SCREEN_WIDTH];
            cell = [tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil) {
                cell = [AlarmCell tableviewCellWithReuseIdentifier:cellId];
            }
            [task populateCell:(AlarmCell *)cell];
            cell.icon = task.icon;
        }
    }

    if (cell == nil) {
        return [self simpleCell:[self tableView:tableView cellWithReuseIdentifier:kSimpleId]
                           text:NSLocalizedString(@"Alarm completed", @"button text")
                           icon:nil
                  accessoryType:UITableViewCellAccessoryNone
                 selectionStyle:UITableViewCellSelectionStyleNone];
    }

    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.editingAccessoryType = cell.accessoryType;
    [self updateAccessibility:cell];
    return cell;
}

CELL_SELECT_METHOD(kTableSectionRowAlarms) {
    if (indexPath.row < self.alarmKeys.count) {
        AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];

        if (task != nil) {
            [task showToUser:self.backgroundTask];
        }
    }
}

CELL_HEIGHT_METHOD(kTableSectionRowAlarms) { return [AlarmCell rowHeight]; }

CELL_WILL_DISPLAY_METHOD(kTableSectionRowAlarms) {
    if (indexPath.row < self.alarmKeys.count) {
        AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];

        if (task != nil & task.alarmState == AlarmFired) {
            cell.backgroundColor = [UIColor yellowColor];
        } else {
            cell.backgroundColor = [UIColor modeAwareCellBackground];
        }
    }
}

CELL_ACCESSORY_METHOD(kTableSectionRowAlarms) {
    if (self.navigationItem.rightBarButtonItem == self.goButton) {
        self.navigationItem.rightBarButtonItem = self.helpButton;
        [self.editWindow resignFirstResponder];
    }

    if (indexPath.row < self.alarmKeys.count) {
#ifdef DEBUG_ALARMS
        AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
        LocationServicesDebugViewController *debugView =
            [[LocationServicesDebugViewController alloc] init];
        debugView.data = task;
        CELL_PUSH(debugView);
#else
        [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
#endif // DEBUG_ALARMS
    }
}

CELL_STATIC_VTABLE(kTableSectionRowAlarms){
    SET_CELL_CONFIG_SEL(kTableSectionRowAlarms),
    SET_CELL_SELECT_SEL(kTableSectionRowAlarms),
    SET_CELL_HEIGHT_SEL(kTableSectionRowAlarms),
    SET_CELL_WILL_DISPLAY_SEL(kTableSectionRowAlarms),
    SET_CELL_EDITING_STYLE_SEL(delete),
    SET_CELL_ACCESSORY_SEL(kTableSectionRowAlarms),
    SET_CELL_CAN_EDIT_SEL(yes),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTripRowPlanner

BASIC_CELL_SELECT(kTableTripRowPlanner,
                  NSLocalizedString(@"Trip planner", @"main menu item"),
                  kIconTripPlanner,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self tripPlanner:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableTripRowCache

BASIC_CELL_SELECT(kTableTripRowCache,
                  NSLocalizedString(@"Recent trips", @"main menu item"),
                  kIconTripPlanner,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([TripPlannerHistoryViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowId

CELL_CONFIG_METHOD(kTableFindRowId) {
    if (self.editCell == nil) {
        self.editCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:kTextFieldId];
        self.editCell.view = [self createTextField_Rounded];
        self.editCell.delegate = self;
        self.editCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.editCell.icon = kIconEnterStopID;
        self.editCell.cellLeftOffset = 50.0;
    }
    return self.editCell;
}

CELL_SELECT_METHOD(kTableFindRowId) {
    UITextView *textView = (UITextView *)(self.editCell).view;

    NSString *editText = [textView.text justNumbers];

    if (editText.length == 0) {
        return;
    }

    if (_keyboardUp) {
        [self.editWindow resignFirstResponder];
    } else {
        // UITextView *textView = (UITextView*)[self.editCell
        // view];
        [self postEditingAction:textView];
    }
}

CELL_HEIGHT_METHOD(kTableFindRowId) { return [CellTextField cellHeight]; }

CELL_STATIC_VTABLE(kTableFindRowId){
    SET_CELL_CONFIG_SEL(kTableFindRowId),
    SET_CELL_SELECT_SEL(kTableFindRowId),
    SET_CELL_HEIGHT_SEL(kTableFindRowId),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowBrowse

BASIC_CELL_SELECT(kTableFindRowBrowse,
                  NSLocalizedString(@"Lookup stop by route", @"main menu item"),
                  kIconBrowse,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [[RouteViewController viewController] fetchRoutesAsync:self.backgroundTask
                                         backgroundRefresh:NO];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowRailMap

BASIC_CELL_SELECT(kTableFindRowRailMap,
                  NSLocalizedString(@"Lookup rail stop from map or A-Z", @"main menu item"),
                  kIconMaxMap,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([RailMapViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowRailStops

BASIC_CELL_SELECT(kTableFindRowRailStops,
                  NSLocalizedString(@"Search all rail stations (A-Z)", @"main menu item"),
                  kIconRailStations,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([AllRailStationViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowVehicle

BASIC_CELL_SELECT(kTableFindRowVehicle,
                  NSLocalizedString(@"Locate the vehicle you're on", @"main menu item"),
                  kIconLocateMe,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [[VehicleTableViewController viewController]
        fetchNearestVehiclesAsync:self.backgroundTask
                         location:nil
                      maxDistance:Settings.vehicleLocatorDistance
                backgroundRefresh:NO];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowVehicleId

BASIC_CELL_SELECT(kTableFindRowVehicleId,
                  NSLocalizedString(@"Locate the vehicle by ID", @"main menu item"),
                  kIconLocateMe,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([VehicleIdsViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowLocate

BASIC_CELL_SELECT(kTableFindRowLocate,
                  NSLocalizedString(@"Locate nearby stops", @"main menu item"),
                  kIconLocateMe,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([FindByLocationViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowHistory

BASIC_CELL_SELECT(kTableFindRowHistory,
                  NSLocalizedString(@"Recent stops", @"main menu item"),
                  kIconArrivals,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([DepartureHistoryViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFindRowQR

BASIC_CELL_SELECT(kTableFindRowQR,
                  NSLocalizedString(@"Scan TriMet QR code", @"main menu item"),
                  kIconQR,
                  UITableViewCellAccessoryDisclosureIndicator) {
    if (![self QRCodeScanner]) {
        [self clearSelection];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFaveBookmark

CELL_UPDATE_METHOD(kTableFaveBookmark) {
    __block UserParams *item = nil;
    __block BoxedIcon *icon = nil;
    [_userState accessArray:_userState.faves
                      block:^(NSMutableArray<NSMutableDictionary *> *safeArray) {
                        item = safeArray[indexPath.row].userParams;

                        if (item.immutableTrip != nil) {
                            icon = kIconTripPlanner;
                        } else {
                            int morning = item.valMorning;
                            int day = item.valDayOfWeek;

                            if (day != kDayNever) {
                                if (morning) {
                                    icon = kIconMorning;
                                } else {
                                    icon = kIconEvening;
                                }
                            } else {
                                icon = kIconArrivals;
                            }
                        }
                      }];

    [self simpleCell:cell
                  text:item.valChosenName
                  icon:icon
         accessoryType:UITableViewCellAccessoryDisclosureIndicator
        selectionStyle:UITableViewCellSelectionStyleBlue];

    if (![self validBookmark:item.dictionary]) {
        cell.textLabel.textColor = [UIColor redColor];
    }

    [self standardizeBaseCell:cell];
}

CELL_SELECT_METHOD(openFave) { [self openFave:(int)indexPath.row allowEdit:YES]; }

CELL_STATIC_VTABLE(kTableFaveBookmark){
    SET_CELL_UPDATE_SEL(kTableFaveBookmark),
    SET_CELL_SELECT_SEL(openFave),
    SET_CELL_HEIGHT_SEL(basic),
    SET_CELL_EDITING_STYLE_SEL(delete),
    SET_CELL_CAN_EDIT_SEL(yes),
    SET_CELL_CAN_MOVE_SEL(yes),
    .reuseId = kSimpleId,
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFaveButtons

CREATE_CELL_WITH_CONFIG(kTableFaveButtons, nil, basic) {
    NSString *cellIdentifier = [NSString stringWithFormat:@"%@%f", kBookMarkUtil, SCREEN_WIDTH];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        self.emailBookmarksButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.emailBookmarksButton setTitle:NSLocalizedString(@"Email bookmarks", @"button text")
                                   forState:UIControlStateNormal];
        [self.emailBookmarksButton addTarget:self
                                      action:@selector(emailBookmarks:)
                            forControlEvents:UIControlEventTouchUpInside];
        self.emailBookmarksButton.tag = kEmailButtonTag;

        self.editBookmarksButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.editBookmarksButton addTarget:self
                                     action:@selector(editBookmarks:)
                           forControlEvents:UIControlEventTouchUpInside];
        self.editBookmarksButton.tag = kEditButtonTag;

        [self setEditBookmarksButtonTitle];

        cell = [self buttonCell:cellIdentifier
                        buttons:@[ self.editBookmarksButton, self.emailBookmarksButton ]
                         height:[self basicRowHeight]];
    } else {
        self.editBookmarksButton = (UIButton *)[cell.contentView viewWithTag:kEditButtonTag];
        self.emailBookmarksButton = (UIButton *)[cell.contentView viewWithTag:kEmailButtonTag];
    }

    [self standardizeBaseCell:cell];
    return cell;
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFaveAddStop

CELL_CONFIG_METHOD(kTableFaveAddStop) {
    return [self tableView:tableView
          editCellWithText:NSLocalizedString(@"Add new stop", @"main menu item")
                      icon:kIconFave];
}

CELL_STATIC_VTABLE(kTableFaveAddStop){
    SET_CELL_CONFIG_SEL(kTableFaveAddStop),
    SET_CELL_SELECT_SEL(openFave),
    SET_CELL_HEIGHT_SEL(basic),
    SET_CELL_EDITING_STYLE_SEL(insert),
    SET_CELL_CAN_EDIT_SEL(yes),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFaveAddTrip

CELL_CONFIG_METHOD(kTableFaveAddTrip) {
    return [self tableView:tableView
          editCellWithText:NSLocalizedString(@"Add new trip", @"main menu item")
                      icon:kIconTripPlanner];
}

CELL_STATIC_VTABLE(kTableFaveAddTrip){
    SET_CELL_CONFIG_SEL(kTableFaveAddTrip),
    SET_CELL_SELECT_SEL(openFave),
    SET_CELL_HEIGHT_SEL(basic),
    SET_CELL_EDITING_STYLE_SEL(insert),
    SET_CELL_CAN_EDIT_SEL(yes),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableFaveAddTakeMeHome

CELL_CONFIG_METHOD(kTableFaveAddTakeMeHome) {
    return [self tableView:tableView
          editCellWithText:NSLocalizedString(@"Add 'Take me somewhere' trip", @"main menu item")
                      icon:kIconTripPlanner];
}

CELL_STATIC_VTABLE(kTableFaveAddTakeMeHome){
    SET_CELL_CONFIG_SEL(kTableFaveAddTakeMeHome),
    SET_CELL_SELECT_SEL(openFave),
    SET_CELL_HEIGHT_SEL(basic),
    SET_CELL_EDITING_STYLE_SEL(insert),
    SET_CELL_CAN_EDIT_SEL(yes),
};

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kTableTriMetCustomerService), CELL_MAP(kTableTriMetLink),
    CELL_MAP(kTableStreetcarLink),         CELL_MAP(kTableTriMetBluesky),
    CELL_MAP(kTableStreetcarInstagram),    CELL_MAP(kTableTriMetFacebook),
    CELL_MAP(kTableTriMetInstagram),       CELL_MAP(kTableTriMetCall),
    CELL_MAP(kTableTriMetDetours),         CELL_MAP(kTableAboutSettings),
    CELL_MAP(kTableAboutRowAbout),         CELL_MAP(kTableAboutRate),
    CELL_MAP(kTableAboutSupport),          CELL_MAP(kTableTipJar),
    CELL_MAP(kTableSectionRowAlarms),      CELL_MAP(kTableTripRowPlanner),
    CELL_MAP(kTableTripRowCache),          CELL_MAP(kTableFindRowId),
    CELL_MAP(kTableFindRowBrowse),         CELL_MAP(kTableFindRowRailMap),
    CELL_MAP(kTableFindRowRailStops),      CELL_MAP(kTableFindRowVehicle),
    CELL_MAP(kTableFindRowVehicleId),      CELL_MAP(kTableFindRowLocate),
    CELL_MAP(kTableFindRowHistory),        CELL_MAP(kTableFindRowQR),
    CELL_MAP(kTableFaveBookmark),          CELL_MAP(kTableFaveButtons),
    CELL_MAP(kTableFaveAddStop),           CELL_MAP(kTableFaveAddTrip),
    CELL_MAP(kTableFaveAddTakeMeHome),
};

@end

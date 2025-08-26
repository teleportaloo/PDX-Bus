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
#import "AlarmViewMinutes.h"
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
#import "RouteView.h"
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
#import "iOSCompat.h"
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
    kTableSectionAlarms,
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
    kTableAboutFacebook,
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
    kTableFaveAddTakeMeHome
};

enum TRIP_ROWS { kTableTripRowPlanner, kTableTripRowCache, kTableTripRows };

#define kUIEditHeight 50.0
#define kUIRowHeight 40.0

#define kTextFieldId @"TextField"
#define kAboutId @"AboutLink"
#define kPlainId @"Plain"
#define kAlarmCellId @"Alarm"

#define kSearchItemBookmark @"org.teleportaloo.pdxbus.bookmark"

// #define LOADINGSCREEN

@interface RootViewController () {
    NSInteger _faveSection;
    NSInteger _editSection;
    AlarmTaskList *_taskList;
    bool _keyboardUp;
    bool _showingLast;
    bool _updatedWatch;
}

@property(nonatomic, strong) UITextField *editWindow;
@property(nonatomic, strong) CellTextField *editCell;
@property(nonatomic, strong) NSArray *alarmKeys;
@property(nonatomic, strong) ProgressModalView *progressView;
@property(nonatomic) bool delayedInitialAction;

@property(nonatomic, strong) UIBarButtonItem *goButton;
@property(nonatomic, strong) UIBarButtonItem *helpButton;
@property(nonatomic, strong) UIButton *editBookmarksButton;
@property(nonatomic, strong) UIButton *emailBookmarksButton;
@property(nonatomic) bool iCloudFaves;

@end

@implementation RootViewController

@dynamic view;

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (CGFloat)heightOffset {
    return super.heightOffset;
}

- (bool)neverAdjustContentInset {
    return YES;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems removeAllObjects];
    bool spaceNeeded = NO;

    if (Settings.locateToolbarIcon) {
        [toolbarItems addObject:[UIToolbar locateButtonWithTarget:self
                                                           action:@selector
                                                           (autoLocate:)]];
        spaceNeeded = YES;
    }

    if (spaceNeeded) {
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }

    [toolbarItems addObject:[UIToolbar settingsButtonWithTarget:self
                                                         action:@selector
                                                         (settingsAction:)]];
    spaceNeeded = YES;

    if (Settings.commuteButton) {
        if (spaceNeeded) {
            [toolbarItems addObject:[UIToolbar flexSpace]];
        }

        [toolbarItems addObject:[UIToolbar commuteButtonWithTarget:self
                                                            action:@selector
                                                            (commuteAction:)]];
        spaceNeeded = YES;
    }

    if (spaceNeeded) {
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }

    [toolbarItems addObject:[UIToolbar qrScannerButtonWithTarget:self
                                                          action:@selector
                                                          (QRScannerAction:)]];
    spaceNeeded = YES;

    [self maybeAddFlashButtonWithSpace:spaceNeeded
                               buttons:toolbarItems
                                   big:YES];

    if (toolbarItems.count == 1 && !Settings.locateToolbarIcon) {
        [toolbarItems insertObject:[UIToolbar flexSpace] atIndex:0];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }

    if (self.goButton == nil) {
        self.goButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                 target:self
                                 action:@selector(editGoAction:)];
    }

    if (self.helpButton == nil) {
        self.helpButton =
            [UIToolbar textButton:NSLocalizedString(@"Help", @"button text")
                           target:self
                           action:@selector(helpAction:)];
    }
}

#pragma mark UI Helper functions

- (void)delayedQRScanner:(NSObject *)arg {
    QrCodeReaderViewController *qrView =
        [[QrCodeReaderViewController alloc] init];

    [self presentViewController:qrView animated:YES completion:nil];
}

- (bool)QRCodeScanner {
    if (self.videoCaptureSupported) {
        QrCodeReaderViewController *qrView =
            [[QrCodeReaderViewController alloc] init];

        [self.navigationController pushViewController:qrView animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController
            simpleOkWithTitle:nil
                      message:NSLocalizedString(
                                  @"The camera is not currently available.",
                                  @"error")];

        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }

    return YES;
}

- (bool)showMapWithAll {
    NearestVehiclesMapViewController *mapView =
        [NearestVehiclesMapViewController viewController];

    mapView.staticOverlays = YES;
    mapView.alwaysFetch = YES;
    mapView.allRoutes = YES;
    [mapView fetchNearestVehiclesAsync:self.backgroundTask];
    return YES;
}

- (bool)showDetoursForRoute:(NSString *)route {
    if (route == nil) {
        [[DetoursViewController viewController]
            fetchDetoursAsync:self.backgroundTask];
    } else {
        [[DetoursViewController viewController]
            fetchDetoursAsync:self.backgroundTask
                        route:route];
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
        query.userRequest.fromPoint.locationDesc =
            [self addressFromMapItem:directionsInfo.source];
        query.userRequest.fromPoint.coordinates =
            directionsInfo.source.placemark.location;
        DEBUG_LOG(@"From desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }

    if (directionsInfo.destination.isCurrentLocation) {
        query.userRequest.toPoint.useCurrentLocation = YES;
    } else {
        query.userRequest.toPoint.locationDesc =
            [self addressFromMapItem:directionsInfo.destination];
        query.userRequest.toPoint.coordinates =
            directionsInfo.destination.placemark.location;
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
    NSCharacterSet *query =
        [NSCharacterSet characterSetWithCharactersInString:@"?"];
    NSCharacterSet *ampersand =
        [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *colon =
        [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSCharacterSet *equalsOrAmpersand =
        [NSCharacterSet characterSetWithCharactersInString:@"=&"];

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
    while (!scanner.atEnd &&
           [strUrl characterAtIndex:scanner.scanLocation] == '/') {
        scanner.scanLocation++;
    }

    if (scanner.atEnd) {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after :\n", strUrl);
        return;
    }

    [scanner scanUpToCharactersFromSet:query intoString:&section];

    if ([section caseInsensitiveCompare:@"route"] != NSOrderedSame) {
        DEBUG_LOG(@"Badly formed route URL %@ - route command missing\n",
                  strUrl);
        return;
    }

    scanner.scanLocation++;

    if (scanner.atEnd) {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after route?\n",
                  strUrl);
        return;
    }

    while (!scanner.atEnd) {
        value = nil;

        [scanner scanUpToCharactersFromSet:equalsOrAmpersand
                                intoString:&section];

        if (!scanner.atEnd) {
            if ([strUrl characterAtIndex:scanner.scanLocation] == '=') {
                scanner.scanLocation++;

                if (scanner.atEnd) {
                    DEBUG_LOG(@"Badly formed route URL %@ - nothing after =\n",
                              strUrl);
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

        if ([section caseInsensitiveCompare:@"from_lon"] == NSOrderedSame &&
            value != nil) {
            from_lon = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_lon"] ==
                       NSOrderedSame &&
                   value != nil) {
            to_lon = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_lat"] ==
                       NSOrderedSame &&
                   value != nil) {
            from_lat = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_lat"] ==
                       NSOrderedSame &&
                   value != nil) {
            to_lat = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_name"] ==
                       NSOrderedSame &&
                   value != nil) {
            from_name = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"to_name"] ==
                       NSOrderedSame &&
                   value != nil) {
            to_name = value.stringByRemovingPercentEncoding;
        } else if ([section caseInsensitiveCompare:@"from_here"] ==
                   NSOrderedSame) {
            from_here = YES;
        } else if ([section caseInsensitiveCompare:@"to_here"] ==
                   NSOrderedSame) {
            to_here = YES;
        }
    }

    bool error = false;

    if (from_name == nil && (from_lat == nil || from_lon == nil) &&
        !from_here) {
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
                  strUrl, from_name, from_lat, from_lon, to_name, to_lat,
                  to_lon, (int)from_here, (int)to_here);
        return;
    }

    DEBUG_LOG(@"Route URL %@ - from_name %@ from_lat %@ from_lon %@ to_name %@ "
              @"to_lat %@ to_lon %@ from_here %d to_here %d\n",
              strUrl, from_name, from_lat, from_lon, to_name, to_lat, to_lon,
              (int)from_here, (int)to_here);

    TripPlannerFetcher *fetcher = [[TripPlannerFetcher alloc] init];

    XMLTrips *tripQuery = [XMLTrips xml];

    tripQuery.userRequest.fromPoint.locationDesc = from_name;

    if (from_lat != nil && from_lon != nil) {
        tripQuery.userRequest.fromPoint.coordinates =
            [CLLocation fromStringsLat:from_lat lng:from_lon];
    }

    tripQuery.userRequest.toPoint.locationDesc = to_name;

    if (to_lat != nil && to_lon != nil) {
        tripQuery.userRequest.toPoint.coordinates =
            [CLLocation fromStringsLat:to_lat lng:to_lon];
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

    if (dirClass &&
        [MKDirectionsRequest isDirectionsRequestURL:self.routingURL]) {
        [self launchTripPlannerFromAppleURL];
    } else {
        [self launchTripPlannerFromRouteURL];
    }
}

- (void)launchFromURL {
    [[DepartureTimesViewController viewController]
        fetchTimesForLocationAsync:self.backgroundTask
                            stopId:self.launchStops
                             title:NSLocalizedString(@"Launching...",
                                                     @"progress message")];
    self.launchStops = nil;
}

- (void)QRScannerAction:(id)sender {
    [self QRCodeScanner];
}

- (void)autoLocate:(id)sender {
    if (self.initialActionArgs) {
        FindByLocationViewController *findView =
            [[FindByLocationViewController alloc] init];

        [findView actionArgs:self.initialActionArgs];
        self.initialActionArgs = nil;

        [self.navigationController pushViewController:findView animated:YES];
    } else if (Settings.autoLocateShowOptions) {
        // Push the detail view controller
        [self.navigationController
            pushViewController:[FindByLocationViewController viewController]
                      animated:YES];
    } else {
        FindByLocationViewController *findView =
            [[FindByLocationViewController alloc] init];

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
    NSDictionary *commuteBookmark =
        [UserState.sharedInstance checkForCommuterBookmarkShowOnlyOnce:NO];

    if (commuteBookmark != nil) {
        UserParams *params = commuteBookmark.userParams;
        NSString *name =
            [NSString stringWithFormat:@"Commuter: %@", params.valChosenName];
        [[DepartureTimesViewController viewController]
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:params.valLocation
                                 title:name];
    } else {
        UIAlertController *alert = [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"Commute", @"alert title")
                      message:
                          NSLocalizedString(
                              @"No commuter bookmark was found for the current "
                              @"day of the week and time. To create a commuter "
                              @"bookmark, edit a bookmark to set which days to "
                              @"use it for the morning or evening commute.",
                              @"alert text")];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)helpAction:(id)sender {
    // Push the detail view controller
    [self.navigationController
        pushViewController:[SupportViewController viewController]
                  animated:YES];
}

- (void)executeInitialAction {
    DEBUG_LOG_BOOL(self.commuterBookmark);

    if (!self.viewLoaded) {
        self.delayedInitialAction = YES;
        return;
    }

    NSDateComponents *nowDateComponents = [[NSCalendar currentCalendar]
        components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYear)
          fromDate:[NSDate date]];

    bool showHelp = [self newVersion:@"lastRun.plist"
                             version:kAboutVersion
                                 any:NO];
    bool showWhatsNew = [self newVersion:@"whatsNew.plist"
                                 version:[WhatsNewViewController version]
                                     any:NO];

    // The stations need to be re-indexed every so often or they will exipire
    // I'm making it so we do it every week
    bool reIndexStations = [self
        newVersion:@"stationIndex.plist"
           version:[NSString
                       stringWithFormat:@"%@ %d %d %d",
                                        [NSBundle mainBundle].infoDictionary
                                            [@"CFBundleShortVersionString"],
                                        (int)Settings.searchStations,
                                        (int)nowDateComponents.weekOfYear,
                                        (int)nowDateComponents.year]
               any:YES];

    if (reIndexStations) {
        [[AllRailStationViewController viewController] indexStations];
    }

    if (showHelp) {
        [self.navigationController
            pushViewController:[SupportViewController viewController]
                      animated:NO];
    } else if (showWhatsNew) {
        [TriMetXML deleteCacheFile];
        [KMLRoutes deleteCacheFile];
        [self.navigationController
            pushViewController:[WhatsNewViewController viewController]
                      animated:NO];
    } else if (self.routingURL) {
        [self.navigationController popToRootViewControllerAnimated:NO];

        [self launchTripPlannerFromURL];
    } else if (self.launchStops) {
        [self.navigationController popToRootViewControllerAnimated:NO];

        [self launchFromURL];
    } else if (self.commuterBookmark) {
        [_userState clearLastArrivals];
        UserParams *params = self.commuterBookmark.userParams;

        [self.navigationController popToRootViewControllerAnimated:NO];
        DEBUG_LOG(@"popToRootViewControllerAnimated");

        [[DepartureTimesViewController viewController]
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:params.valLocation
                                 title:params.valChosenName];
        _showingLast = true;
        self.commuterBookmark = nil;
    } else if (self.initialAction == InitialAction_TripPlanner) {
        [self tripPlanner:YES];
    } else if (self.initialAction == InitialAction_Commute) {
        [self commuteAction:nil];
    } else if (self.initialAction == InitialAction_Locate) {
        [self autoLocate:nil];
    } else if (self.initialAction == InitialAction_QRCode) {
        [self QRCodeScanner];
    } else if (self.initialAction == InitialAction_Map) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self showMapWithAll];
    } else if (self.initialAction == InitialAction_BookmarkIndex) {
        [self openFave:self.initialBookmarkIndex allowEdit:NO];
    } else if (self.initialAction == InitialAction_UserActivityBookmark) {
        [self openUserActivityBookmark:self.initialActionArgs];
        self.initialActionArgs = nil;
    } else if (self.initialAction == InitialAction_UserActivitySearch) {
        [self openSearchItem:self.initialActionArgs];
        self.initialActionArgs = nil;
    } else if (self.initialAction == InitialAction_UserActivityAlerts) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self showDetoursForRoute:self.initialActionArgs[kUserInfoAlertRoute]];
        self.initialActionArgs = nil;
    } else if (self.initialBookmarkName != nil) {
        bool found = NO;
        int foundItem = 0;
        @synchronized(_userState) {
            for (int i = 0; i < _userState.faves.count; i++) {
                UserParams *item = _userState.faves[i].userParams;
                NSString *name = item.valChosenName;

                if (name != nil &&
                    [self.initialBookmarkName isEqualToString:name]) {
                    found = YES;
                    foundItem = i;
                    break;
                }
            }
        }

        if (found) {
            [self openFave:foundItem allowEdit:NO];
        }
    } else {
        // Reload just in case the user changed the settings outside the app
        [self reloadData];
        [self updateToolbar];
    }

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
    returnTextField.placeholder =
        NSLocalizedString(@"<enter stop ID>", @"default text");
    returnTextField.backgroundColor = [UIColor modeAwareGrayBackground];
    returnTextField.autocorrectionType =
        UITextAutocorrectionTypeNo; // no auto correction support

    returnTextField.keyboardType = UIKeyboardTypeNumberPad;
    returnTextField.returnKeyType = UIReturnKeyGo;

    returnTextField.clearButtonMode =
        UITextFieldViewModeWhileEditing; // has a clear 'x' button to the right
    self.editWindow = returnTextField;

    return returnTextField;
}

- (void)tripPlanner:(bool)animated {
    TripPlannerSummaryViewController *tripStart =
        [TripPlannerSummaryViewController viewController];

    //    tripStart.from = true;
    // tripStart.tripQuery = self.tripQuery;

    // tripStart.tripQuery.userFaves = self.userFaves;
    @synchronized(_userState) {
        [tripStart.tripQuery addStopsFromUserFaves:_userState.faves];
    }

    // Push the detail view controller
    [self.navigationController pushViewController:tripStart animated:YES];
}

- (void)updatePlaceholderRows:(bool)add {
    NSArray *indexPaths = @[
        [NSIndexPath indexPathForRow:_userState.faves.count
                           inSection:_faveSection],
        [NSIndexPath indexPathForRow:_userState.faves.count + 1
                           inSection:_faveSection],
        [NSIndexPath indexPathForRow:_userState.faves.count + 2
                           inSection:_faveSection]
    ];

    NSInteger addRow = [self firstRowOfType:kTableFaveAddStop
                                  inSection:_faveSection];

    if (add && addRow == kNoRowSectionTypeFound) {
        // Show the placeholder rows

        [self clearSection:_faveSection];

        [self addRowType:kTableFaveAddStop forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTrip forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTakeMeHome
            forSectionType:kTableSectionFaves];

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

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell {
    _keyboardUp = YES;
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(cancelAction:)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = self.goButton;

    [self.tableView
        scrollToRowAtIndexPath:
            [NSIndexPath indexPathForRow:[self firstRowOfType:kTableFindRowId
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

    if (sectionType == kTableSectionFaves) {
        if (indexPath.row < _userState.faves.count) {
            return kTableFaveBookmark;
        }

        return [super
            rowType:[NSIndexPath
                        indexPathForRow:(indexPath.row - _userState.faves.count)
                              inSection:indexPath.section]];
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
            [self addSectionType:kTableSectionAlarms];
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
    } else {
        if (_taskList != nil && _taskList.taskCount > 0) {
            [self addSectionType:kTableSectionAlarms];
        }

        _editSection = [self addSectionType:kTableSectionStopId];
        [self addStopIdRows];
        [self addSectionType:kTableSectionPlanner];
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
    [self addRowType:kTableAboutFacebook];
    [self addRowType:kTableAboutRate];
    [self addRowType:kTableTipJar];

#ifdef COFFEE
    [self addRowType:kTableBuyMeACoffee];
#endif
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

            CSSearchableItemAttributeSet *attributeSet =
                [[CSSearchableItemAttributeSet alloc]
                    initWithItemContentType:UTTypeText.identifier];
            attributeSet.title = bookmark.valChosenName;

            if (bookmark.valLocation != nil) {
                attributeSet.contentDescription = @"Departure bookmark";
            } else {
                attributeSet.contentDescription = @"Trip Planner bookmark";
            }

            NSString *uniqueId =
                [NSString stringWithFormat:@"%@:%d", kSearchItemBookmark, i];

            CSSearchableItem *item = [[CSSearchableItem alloc]
                initWithUniqueIdentifier:uniqueId
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

    CSSearchableIndex *searchableIndex =
        [CSSearchableIndex defaultSearchableIndex];

    [searchableIndex
        deleteSearchableItemsWithDomainIdentifiers:@[ @"bookmark" ]
                                 completionHandler:^(
                                     NSError *__nullable error) {
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
                [[UIMutableApplicationShortcutItem alloc]
                      initWithType:@"bookmark"
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

- (void)loadView {
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

- (bool)changedEnoughToShowWhatsNewFirst:(NSString *)first
                                  second:(NSString *)second {
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

    DoOnce(^{
      [[NSNotificationCenter defaultCenter]
          addObserver:self
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
#endif

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
#endif

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
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    DEBUG_LOG_long(self.tableView.contentOffset.y);
    [super viewDidAppear:animated];

    DEBUG_FUNC();

    if (_taskList) {
        _taskList.observer = self;
    }

    if (_userState.favesChanged || !_updatedWatch) {
        [_userState cacheState];

        if (!_updatedWatch) {
            [WatchAppContext updateWatch:self.session];
        }

        _userState.favesChanged = NO;
        _updatedWatch = YES;
    }

    if (!_showingLast) {
        [_userState clearLastArrivals];
        //[[(RootViewController *)[self.navigationController topViewController]
        // table] reloadData];
    }

#ifndef LOADINGSCREEN
    self.navigationItem.rightBarButtonItem = self.helpButton;
#endif

    [self reloadData];
    [self updateToolbar];
    _showingLast = false;

    [self iOS7workaroundPromptGap];

    DEBUG_FUNCEX();
}

- (void)cloudToLocal {
    Settings.firstLaunchWithiCloudAvailable = NO;
    _userState.canWriteToCloud = YES;
    [_userState mergeWithCloud:nil];
    self.iCloudFaves = YES;
    [_userState cacheState];
    [self favesChanged];
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
            DEBUG_LOG(@"Found iCloud bookmarks; local ones are changed - using "
                      @"local.");
            Settings.firstLaunchWithiCloudAvailable = NO;
            self->_userState.canWriteToCloud = YES;
            self.iCloudFaves = YES;
            [self->_userState cacheState];
            [self favesChanged];
            [self reloadData];
        }
    } else {
        // Just write it now.  We will get an initial sync warning.
        DEBUG_LOG(@"No iCloud bookmarks; writing local and hopng for sync.");
        Settings.firstLaunchWithiCloudAvailable = NO;
        self->_userState.canWriteToCloud = YES;
        self.iCloudFaves = YES;
        [self->_userState cacheState];
        [self favesChanged];
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
      NSInteger reason = [[userInfo
          objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey] integerValue];
      NSArray *keys =
          [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

      DEBUG_LOG_long(reason);
      // 4 reasons:
      switch (reason) {
      case NSUbiquitousKeyValueStoreInitialSyncChange:
          DEBUG_CASE(NSUbiquitousKeyValueStoreInitialSyncChange);
          // First launch and the default bookmarks were overwritten
          [self->_userState mergeWithCloud:nil];
          [self favesChanged];
          [self reloadData];
          break;

      case NSUbiquitousKeyValueStoreServerChange:
          // Updated values
          DEBUG_CASE(NSUbiquitousKeyValueStoreServerChange);
          [self->_userState mergeWithCloud:keys];
          [self favesChanged];
          [self reloadData];
          break;

      case NSUbiquitousKeyValueStoreQuotaViolationChange: {
          DEBUG_CASE(NSUbiquitousKeyValueStoreQuotaViolationChange);
          // No free space
          // Probably delete items from the store

          UIAlertController *alert = [UIAlertController
              simpleOkWithTitle:NSLocalizedString(@"iCloud", @"alert title")
                        message:
                            NSLocalizedString(
                                @"You have too many bookmarks to store in the "
                                @"cloud. You should delete some bookmarks.",
                                @"error message")];

          [self presentViewController:alert animated:YES completion:nil];

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

#endif
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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a
                                     // superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Editing callbacks
// Set the editing state of the view controller. We pass this down to the table
// view and also modify the content of the table to insert a placeholder row for
// adding content when in editing mode.
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
        (!_keyboardUp ||
         self.navigationItem.rightBarButtonItem != self.helpButton)) {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];
        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                     stopId:editText];
    } else if (_keyboardUp) {
        [self.editWindow resignFirstResponder];
    }

    self.navigationItem.rightBarButtonItem = self.helpButton;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    _keyboardUp = NO;
}

#pragma mark TableView methods

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;

    switch ([self sectionType:section]) {
    case kTableSectionStopId:
    case kTableSectionVehicleId:
        rows = [self rowsInSection:section];
        break;

    case kTableSectionFaves: {
        NSInteger cnt = _userState.faves.count;
        // DEBUG_LOG(@"Cnt %ld Editing self %d tableview %d\n", (long)cnt,
        // self.editing, tableView.editing);
        rows = cnt + [self rowsInSection:section];
        // DEBUG_LOG(@"Rows %ld\n", (long)rows);

        break;
    }

    case kTableSectionAlarms: {
        if (_taskList) {
            rows = self.alarmKeys.count;
        }

        break;
    }

    case kTableSectionAbout:
    case kTableSectionTriMet:
    case kTableSectionStreetcar:
        rows = [self rowsInSection:section];
        break;

    case kTableSectionPlanner:
        rows = kTableTripRows;
        break;
    }
    // printf("Section %d rows %d\n", section, rows);
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kTableSectionStopId:
        return NSLocalizedString(@"Show departures for stop:",
                                 @"section header");

    case kTableSectionVehicleId:
        return NSLocalizedString(@"Locate vehicle you are on (not Streetcar)",
                                 @"section header");

    case kTableSectionAlarms:
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
        return NSLocalizedString(@"More from Portland Streetcar:",
                                 @"section header");

    case kTableSectionAbout:
        return NSLocalizedString(@"More app info:", @"section header");

    case kTableSectionPlanner:
        return NSLocalizedString(@"Trips:", @"section header");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = UITableViewAutomaticDimension;

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionStopId:
    case kTableSectionVehicleId: {
        NSInteger rowType = [self rowType:indexPath];

        if (rowType == kTableFindRowId) {
            result = [CellTextField cellHeight];
        } else {
            result = [self basicRowHeight];
        }

        break;
    }
    case kTableSectionAbout:
    case kTableSectionPlanner:
    case kTableSectionFaves:
        result = [self basicRowHeight];
        break;

    case kTableSectionTriMet:
    case kTableSectionStreetcar:
        result = UITableViewAutomaticDimension;
        break;

    case kTableSectionAlarms:
        result = [AlarmCell rowHeight];

        break;
    }
    return result;
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView
          willDisplayCell:cell
        forRowAtIndexPath:indexPath];

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionAlarms:

        if (indexPath.row < self.alarmKeys.count) {
            AlarmTask *task =
                [_taskList taskForKey:self.alarmKeys[indexPath.row]];

            if (task != nil & task.alarmState == AlarmFired) {
                cell.backgroundColor = [UIColor yellowColor];
            } else {
                cell.backgroundColor = [UIColor modeAwareCellBackground];
            }
        }

        break;

    default:
        cell.backgroundColor = [UIColor modeAwareCellBackground];
        break;
    }
}

- (void)setEditBookmarksButtonTitle {
    if (self.editing) {
        [self.editBookmarksButton
            setTitle:NSLocalizedString(@"Done editing", @"button text")
            forState:UIControlStateNormal];
    } else if (_userState.faves.count > 0) {
        [self.editBookmarksButton
            setTitle:NSLocalizedString(@"Edit bookmarks", @"button text")
            forState:UIControlStateNormal];
    } else {
        [self.editBookmarksButton
            setTitle:NSLocalizedString(@"Add bookmarks", @"button text")
            forState:UIControlStateNormal];
    }

    if (_userState.faves.count > 0) {
        [self.emailBookmarksButton
            setTitle:NSLocalizedString(@"Email bookmarks", @"button text")
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
    {
        @synchronized(_userState) {
            if (_userState.faves.count > 0) {
                if (![MFMailComposeViewController canSendMail]) {
                    UIAlertController *alert = [UIAlertController
                        simpleOkWithTitle:NSLocalizedString(@"email",
                                                            @"alert title")
                                  message:
                                      NSLocalizedString(
                                          @"Cannot send email on this device",
                                          @"error message")];

                    [self presentViewController:alert
                                       animated:YES
                                     completion:nil];
                    return;
                }

                MFMailComposeViewController *email =
                    [[MFMailComposeViewController alloc] init];

                email.mailComposeDelegate = self;

                [email setSubject:NSLocalizedString(@"PDX Bus Bookmarks",
                                                    @"email subject")];

                NSMutableString *body = [[NSMutableString alloc] init];
                UserParams *item;

                [body appendFormat:
                          NSLocalizedString(
                              @"Click on a link to add a bookmark to PDXBus "
                              @"running on a another device.<br><br>",
                              @"email body")];

                int i;

                for (i = 0; i < _userState.faves.count; i++) {
                    item = _userState.faves[i].userParams;

                    if (item.valLocation != nil) {
                        [body
                            appendFormat:
                                @"<a href=\"pdxbus2://?d%@/\">%@</a> - %@<br>",
                                [self propertyListToHex:item.dictionary],
                                item.valChosenName, item.valLocation];
                    } else {
                        [body appendFormat:
                                  NSLocalizedString(
                                      @"<a href=\"pdxbus2://?d%@/\">%@</a> - "
                                      @"Trip Planner Bookmark<br>",
                                      @"email body"),
                                  [self propertyListToHex:item.dictionary],
                                  item.valChosenName];
                    }
                }

                [body appendFormat:@"<br><br>"];

                [body appendFormat:@"<a href = \"pdxbus2://"];

                for (i = 0; i < _userState.faves.count; i++) {
                    item = _userState.faves[i].userParams;
                    [body
                        appendFormat:@"?d%@/",
                                     [self propertyListToHex:item.dictionary]];
                }

                [body
                    appendFormat:NSLocalizedString(@"\">Add all bookmarks</a>",
                                                   @"email body")];

                [email setMessageBody:body isHTML:YES];

                [self presentViewController:email animated:YES completion:nil];

                DEBUG_LOG(@"BODY\n%@\n", body);
            }
        }
    }
}

#define kEditButtonTag 1
#define kEmailButtonTag 2

- (UITableViewCell *)buttonCell:(NSString *)cellId
                        buttons:(NSArray *)items
                         height:(CGFloat)height {
    UITableViewCell *cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:cellId];
    static const CGFloat xgap = 10;
    static const CGFloat ymargin = 2;

    CGRect tableRect = self.middleWindowRect;

    CGFloat width = ((tableRect.size.width - xgap * 2) / items.count) -
                    ((items.count - 1) * xgap);

    int i = 0;

    for (UIButton *button in items) {
        CGRect buttonRect = CGRectMake(xgap + (xgap + width) * i, ymargin,
                                       width, height - (ymargin * 2));

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

- (UITableViewCell *)plainCell:(UITableView *)tableView
                    imageNamed:(NSString *)name
                          text:(NSString *)text
                     accessory:(UITableViewCellAccessoryType)accType {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:kPlainId];

    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor modeAwareText];
    cell.namedIcon = name;
    cell.textLabel.text = text;
    cell.accessoryType = accType;
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    cell.textLabel.adjustsFontForContentSizeCategory = NO;
    [self updateAccessibility:cell];

    DEBUG_LOG(@"Font size: %.2f %@", cell.textLabel.font.pointSize,
              cell.textLabel.font.fontDescriptor);

    return cell;
}

- (UITableViewCell *)plainCell:(UITableView *)tableView
                   systemImage:(NSString *)name
                          text:(NSString *)text
                     accessory:(UITableViewCellAccessoryType)accType {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:kPlainId];

    cell.textLabel.font = self.basicFont;
    // cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [UIColor modeAwareText];
    cell.imageView.image = [UIImage systemImageNamed:name];
    cell.imageView.tintColor = nil;
    cell.textLabel.text = text;
    cell.accessoryType = accType;
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    cell.textLabel.adjustsFontForContentSizeCategory = NO;
    [self updateAccessibility:cell];

    DEBUG_LOG(@"Font size: %.2f %@", cell.textLabel.font.pointSize,
              cell.textLabel.font.fontDescriptor);

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // DEBUG_LOG(@"cellForRowAtIndexPath %d %d\n", indexPath.section,
    // indexPath.row); [self dumpPath:@"cellForRowAtIndexPath" path:indexPath];

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionStopId:
    case kTableSectionVehicleId: {
        NSInteger rowType = [self rowType:indexPath];
        switch (rowType) {
        case kTableFindRowId: {
            if (self.editCell == nil) {
                self.editCell = [[CellTextField alloc]
                      initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:kTextFieldId];
                self.editCell.view = [self createTextField_Rounded];
                self.editCell.delegate = self;
                self.editCell.accessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;
                self.editCell.systemIcon = kSFIconEnterStopID;
                self.editCell.cellLeftOffset = 50.0;
            }

            // printf("kTableFindRowId %p\n", sourceCell);
            return self.editCell;
        }

        case kTableFindRowBrowse: {
            return [self plainCell:tableView
                       systemImage:kSFIconBrowse
                              text:NSLocalizedString(@"Lookup stop by route",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowRailMap: {
            return [self plainCell:tableView
                        imageNamed:kIconMaxMap
                              text:NSLocalizedString(
                                       @"Lookup rail stop from map or A-Z",
                                       @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowRailStops: {
            return [self
                 plainCell:tableView
                imageNamed:kIconRailStations
                      text:NSLocalizedString(@"Search all rail stations (A-Z)",
                                             @"main menu item")
                 accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowVehicle: {
            return [self
                  plainCell:tableView
                systemImage:kSFIconLocateMe
                       text:NSLocalizedString(@"Locate the vehicle you're on",
                                              @"main menu item")
                  accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowVehicleId: {
            return
                [self plainCell:tableView
                    systemImage:kSFIconLocateMe
                           text:NSLocalizedString(@"Locate the vehicle by ID",
                                                  @"main menu item")
                      accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowLocate: {
            return [self plainCell:tableView
                       systemImage:kSFIconLocateMe
                              text:NSLocalizedString(@"Locate nearby stops",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowHistory: {
            return [self plainCell:tableView
                       systemImage:kSFIconArrivals
                              text:NSLocalizedString(@"Recent stops",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }

        case kTableFindRowQR: {
            return [self plainCell:tableView
                       systemImage:kSFIconQR
                              text:NSLocalizedString(@"Scan TriMet QR code",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }
        }
    }

    case kTableSectionFaves: {
        // printf("fave row: %d count %d\n", indexPath.row, [self.userFaves
        // count]);
        UITableViewCell *cell = nil;
        NSInteger rowType = [self rowType:indexPath];

        switch (rowType) {
        default:
            cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            break;

        case kTableFaveBookmark: {
            // Set up the cell
            @synchronized(_userState) {
                UserParams *item = _userState.faves[indexPath.row].userParams;
                // printf("item %p\n", item);

                cell = [self
                     plainCell:tableView
                    imageNamed:nil
                          text:item.valChosenName
                     accessory:UITableViewCellAccessoryDisclosureIndicator];

                cell.editingAccessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;

                if (![self validBookmark:item.dictionary]) {
                    cell.textLabel.textColor = [UIColor redColor];
                }

                if (item.immutableTrip != nil) {
                    cell.systemIcon = kSFIconTripPlanner;
                } else { // if ([item valueForKey:kUserFavesLocation] != nil)
                    int morning = item.valMorning;
                    int day = item.valDayOfWeek;

                    if (day != kDayNever) {
                        if (morning) {
                            [cell systemIcon:kSFIconMorning
                                        tint:kSFIconMorningTint];
                        } else {
                            [cell systemIcon:kSFIconEvening
                                        tint:kSFIconEveningTint];
                        }
                    } else {
                        cell.systemIcon = kSFIconArrivals;
                    }
                }
            }
            break;
        }

        case kTableFaveAddStop:
        case kTableFaveAddTrip:
        case kTableFaveAddTakeMeHome: {
            cell = [self tableView:tableView
                cellWithReuseIdentifier:kNewBookMark];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = self.basicFont;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment =
                UIBaselineAdjustmentAlignCenters;
            cell.editingAccessoryType = cell.accessoryType;
            switch (rowType) {
            case kTableFaveAddStop:
                cell.textLabel.text =
                    NSLocalizedString(@"Add new stop", @"main menu item");
                cell.systemIcon = kSFIconFave;
                break;

            case kTableFaveAddTrip:
                cell.textLabel.text =
                    NSLocalizedString(@"Add new trip", @"main menu item");
                cell.systemIcon = kSFIconTripPlanner;
                break;

            case kTableFaveAddTakeMeHome:
                cell.textLabel.text = NSLocalizedString(
                    @"Add 'Take me somewhere' trip", @"main menu item");
                cell.systemIcon = kSFIconTripPlanner;
                break;
            }
            [self updateAccessibility:cell];
            break;
        }

        case kTableFaveButtons: {
            NSString *cellIdentifier =
                [NSString stringWithFormat:@"%@%f", kBookMarkUtil,
                                           self.screenInfo.appWinWidth];

            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

            if (cell == nil) {
                self.emailBookmarksButton =
                    [UIButton buttonWithType:UIButtonTypeSystem];
                [self.emailBookmarksButton
                    setTitle:NSLocalizedString(@"Email bookmarks",
                                               @"button text")
                    forState:UIControlStateNormal];
                [self.emailBookmarksButton
                           addTarget:self
                              action:@selector(emailBookmarks:)
                    forControlEvents:UIControlEventTouchUpInside];
                self.emailBookmarksButton.tag = kEmailButtonTag;

                self.editBookmarksButton =
                    [UIButton buttonWithType:UIButtonTypeSystem];

                [self.editBookmarksButton
                           addTarget:self
                              action:@selector(editBookmarks:)
                    forControlEvents:UIControlEventTouchUpInside];
                self.editBookmarksButton.tag = kEditButtonTag;

                [self setEditBookmarksButtonTitle];

                cell = [self
                    buttonCell:cellIdentifier
                       buttons:@[
                           self.editBookmarksButton, self.emailBookmarksButton
                       ]
                        height:[self basicRowHeight]];
            } else {
                self.editBookmarksButton =
                    (UIButton *)[cell.contentView viewWithTag:kEditButtonTag];
                self.emailBookmarksButton =
                    (UIButton *)[cell.contentView viewWithTag:kEmailButtonTag];
            }

            break;
        }
        }

        [self updateAccessibility:cell];
        return cell;
    }

    case kTableSectionStreetcar:
    case kTableSectionTriMet: {

        NSInteger rowType = [self rowType:indexPath];

        switch (rowType) {
        case kTableTriMetCustomerService:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconTriMetLink
                systemImage:NO
                      title:NSLocalizedString(
                                @"Contact TriMet Customer Service",
                                @"main menu item")
                  namedLink:@"TriMet Customer Service"];
        case kTableTriMetLink:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconTriMetLink
                systemImage:NO
                      title:NSLocalizedString(@"TriMet's website",
                                              @"main menu item")
                  namedLink:@"TriMet"];
        case kTableStreetcarLink:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconStreetcar
                systemImage:NO
                      title:NSLocalizedString(@"Portland Streetcar's website",
                                              @"main menu item")
                  namedLink:@"Portland Streetcar"];
        case kTableTriMetBluesky:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconBluesky
                systemImage:NO
                      title:NSLocalizedString(@"@trimet.org on Bluesky",
                                              @"main menu item")
                       link:nil];
        case kTableStreetcarInstagram:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconInstagram
                systemImage:NO
                      title:NSLocalizedString(@"@PDXStreetcar on Instagram",
                                              @"main menu item")
                       link:nil];
        case kTableTriMetFacebook:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconFacebook
                systemImage:NO
                      title:NSLocalizedString(@"TriMet's Facebook page",
                                              @"main menu item")
                       link:nil];

        case kTableTriMetInstagram:
            return [LabelLinkCellWithIcon
                dequeueFrom:tableView
                 imageNamed:kIconInstagram
                systemImage:NO
                      title:NSLocalizedString(@"TriMet's Instagram",
                                              @"main menu item")
                       link:nil];

            break;
        }

        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:kAboutId];

        cell.textLabel.adjustsFontSizeToFitWidth = NO;

        switch (rowType) {

        case kTableTriMetCall:
            cell.textLabel.text = NSLocalizedString(
                @"Call TriMet on 503-238-RIDE", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.systemIcon = kSFIconPhone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;

        case kTableTriMetDetours:
            cell.textLabel.attributedText =
                NSLocalizedString(@"#RDetours, delays and closures",
                                  @"main menu item")
                    .attributedStringFromMarkUp;
            cell.systemIcon = kSFIconDetour;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment =
                UIBaselineAdjustmentAlignCenters;
            break;
        }
        cell.textLabel.font = self.basicFont;
        [self updateAccessibility:cell];
        return cell;
    }

    case kTableSectionAbout: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:kAboutId];

        NSInteger rowType = [self rowType:indexPath];

        cell.textLabel.adjustsFontSizeToFitWidth = NO;

        switch (rowType) {
        case kTableAboutSettings:
            cell.textLabel.text =
                NSLocalizedString(@"Settings", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.systemIcon = kSFIconSettings;
            break;

        case kTableAboutRowAbout:
            cell.textLabel.text =
                NSLocalizedString(@"About & legal", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.systemIcon = kSFIconAbout;
            break;

        case kTableAboutSupport:
            cell.textLabel.text =
                NSLocalizedString(@"Help, Tips & support", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.systemIcon = kSFIconXml;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;

        case kTableAboutFacebook:
            cell.textLabel.text =
                NSLocalizedString(@"PDX Bus Fan Page", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.namedIcon = kIconFacebook;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;

        case kTableAboutRate:
            cell.textLabel.text = NSLocalizedString(
                @"Rate PDX Bus in the App Store", @"main menu item");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment =
                UIBaselineAdjustmentAlignCenters;
            cell.systemIcon = kSFIconAward;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case kTableTipJar:
            [self tipJarCell:cell];
            break;
        }
        cell.textLabel.font = self.basicFont;
        [self updateAccessibility:cell];
        return cell;
    }

    case kTableSectionAlarms: {
        UITableViewCell *cell = nil;

        if (indexPath.row < self.alarmKeys.count) {
            AlarmTask *task =
                [_taskList taskForKey:self.alarmKeys[indexPath.row]];

            if (task != nil) {
                NSString *cellId =
                    [task cellReuseIdentifier:kAlarmCellId
                                        width:self.screenInfo.screenWidth];
                cell = [tableView dequeueReusableCellWithIdentifier:cellId];

                if (cell == nil) {
                    cell = [AlarmCell tableviewCellWithReuseIdentifier:cellId];
                }

                [task populateCell:(AlarmCell *)cell];

                cell.systemIcon = task.systemIcon;
            }
        }

        if (cell == nil) {
            cell = [self tableView:tableView cellWithReuseIdentifier:kAboutId];
            cell.textLabel.text =
                NSLocalizedString(@"Alarm completed", @"button text");
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.textLabel.font = self.basicFont;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.editingAccessoryType = cell.accessoryType;
        [self updateAccessibility:cell];
        return cell;
    }

    case kTableSectionPlanner: {
        switch (indexPath.row) {
        case kTableTripRowPlanner:
            return [self plainCell:tableView
                       systemImage:kSFIconTripPlanner
                              text:NSLocalizedString(@"Trip planner",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];

        case kTableTripRowCache:
            return [self plainCell:tableView
                       systemImage:kSFIconTripPlanner
                              text:NSLocalizedString(@"Recent trips",
                                                     @"main menu item")
                         accessory:UITableViewCellAccessoryDisclosureIndicator];
        }
    }
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (NSString *)propertyListToHex:(NSDictionary *)item {
    NSError *error = nil;

    NSData *data = [NSPropertyListSerialization
        dataWithPropertyList:item
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

    return !(
        (tripItem == nil && item != nil &&
         ((location == nil) || (location.length == 0))) ||
        (tripItem != nil && req != nil && req.fromPoint.locationDesc == nil &&
         req.fromPoint.useCurrentLocation == false) ||
        (tripItem != nil && req != nil && req.toPoint.locationDesc == nil &&
         req.toPoint.useCurrentLocation == false));
}

- (void)openFave:(int)index allowEdit:(bool)allowEdit {
    MutableUserParams *item = nil;
    NSString *stopIds = nil;
    TripUserRequest *req = nil;
    NSDictionary *tripItem = nil;

    NSInteger rowType = [self
        rowType:[NSIndexPath indexPathForRow:index inSection:_faveSection]];

    DEBUG_LOG_long(_userState.faves.count);

    if (DEBUG_AND(self.iCloudFaves)) {
        DEBUG_LOG_long(((NSNumber *)[[NSUbiquitousKeyValueStore defaultStore]
                            objectForKey:kiCloudTotal])
                           .integerValue);
    }

    if (rowType == kTableFaveBookmark) {
        @synchronized(_userState) {
            item = _userState.faves[index].mutableUserParams;
            stopIds = item.valLocation;
            tripItem = item.valTrip;
            req = [TripUserRequest fromDictionary:tripItem];
        }
    }

    DEBUG_LOG_BOOL(self.tableView.editing);

    bool validItem = [self validBookmark:item.dictionary];

    if (allowEdit &&
        (self.tableView.editing || _userState.faves.count == 0 || !validItem)) {
        switch (rowType) {
        case kTableFaveBookmark: {
            EditBookMarkViewController *edit =
                [EditBookMarkViewController viewController];
            edit.invalidItem = !validItem;
            [edit editBookMark:item.mutableDictionary item:index];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddStop: {
            EditBookMarkViewController *edit =
                [EditBookMarkViewController viewController];
            [edit addBookMark];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddTrip: {
            EditBookMarkViewController *edit =
                [EditBookMarkViewController viewController];
            [edit addTripBookMark];
            [self.navigationController pushViewController:edit animated:YES];
            break;
        }

        case kTableFaveAddTakeMeHome: {
            EditBookMarkViewController *edit =
                [EditBookMarkViewController viewController];
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
        TripPlannerDateViewController *tripDate =
            [TripPlannerDateViewController viewController];

        [tripDate initializeFromBookmark:req];
        @synchronized(_userState) {
            [tripDate.tripQuery addStopsFromUserFaves:_userState.faves];
        }

        // Push the detail view controller
        [tripDate nextScreen:self.navigationController
               taskContainer:self.backgroundTask];
    }
}

- (void)openSearchItem:(NSDictionary *)item {
    NSString *uniqueId = item[CSSearchableItemActivityIdentifier];

    NSScanner *scanner = [NSScanner scannerWithString:uniqueId];
    NSCharacterSet *colon =
        [NSCharacterSet characterSetWithCharactersInString:@":"];
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
                // [self.navigationController pushViewController:railView
                // animated:YES];
            } else if ([prefix isEqualToString:kSearchItemBookmark]) {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self openFave:arg allowEdit:NO];
            } else if ([prefix isEqualToString:kSearchItemRoute]) {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [[DirectionViewController viewController]
                    fetchDirectionsAsync:self.backgroundTask
                                   route:[NSString
                                             stringWithFormat:@"%d", arg]];
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
        [[DepartureDetailViewController viewController]
            fetchDepartureAsync:self.backgroundTask
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

        TripPlannerDateViewController *tripDate =
            [TripPlannerDateViewController viewController];

        [tripDate initializeFromBookmark:req];
        @synchronized(_userState) {
            [tripDate.tripQuery addStopsFromUserFaves:_userState.faves];
        }

        // Push the detail view controller
        [tripDate nextScreen:self.navigationController
               taskContainer:self.backgroundTask];
    }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationItem.rightBarButtonItem == self.goButton) {
        self.navigationItem.rightBarButtonItem = self.helpButton;
        [self.editWindow resignFirstResponder];
    }

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionStopId:
    case kTableSectionVehicleId: {
        NSInteger rowType = [self rowType:indexPath];
        switch (rowType) {
        case kTableFindRowId: {
            UITextView *textView = (UITextView *)(self.editCell).view;

            NSString *editText = [textView.text justNumbers];

            if (editText.length == 0) {
                return;
            }

            if (_keyboardUp) {
                [self.editWindow resignFirstResponder];
            } else {
                // UITextView *textView = (UITextView*)[self.editCell view];
                [self postEditingAction:textView];
            }

            break;
        }

        case kTableFindRowBrowse: {
            [[RouteView viewController] fetchRoutesAsync:self.backgroundTask
                                       backgroundRefresh:NO];
            break;
        }

        case kTableFindRowLocate: {
            [self.navigationController
                pushViewController:[FindByLocationViewController viewController]
                          animated:YES];
            break;
        }

        case kTableFindRowVehicle: {
            [[VehicleTableViewController viewController]
                fetchNearestVehiclesAsync:self.backgroundTask
                                 location:nil
                              maxDistance:Settings.vehicleLocatorDistance
                        backgroundRefresh:NO];
            break;
        }

        case kTableFindRowVehicleId: {
            [self.navigationController
                pushViewController:[VehicleIdsViewController viewController]
                          animated:YES];

            break;
        }

        case kTableFindRowRailMap: {
            [self.navigationController
                pushViewController:[RailMapViewController viewController]
                          animated:YES];
            break;
        }

        case kTableFindRowRailStops: {
            [self.navigationController
                pushViewController:[AllRailStationViewController viewController]
                          animated:YES];
            break;
        }

        case kTableFindRowHistory: {
            [self.navigationController
                pushViewController:[DepartureHistoryViewController
                                       viewController]
                          animated:YES];
            break;
        }

        case kTableFindRowQR: {
            if (![self QRCodeScanner]) {
                [self clearSelection];
            }
        }
        }

        break;
    }

    case kTableSectionFaves: {
        [self openFave:(int)indexPath.row allowEdit:YES];
        break;
    }

    case kTableSectionAlarms: {
        if (indexPath.row < self.alarmKeys.count) {
            AlarmTask *task =
                [_taskList taskForKey:self.alarmKeys[indexPath.row]];

            if (task != nil) {
                [task showToUser:self.backgroundTask];
            }
        }

        break;
    }

    case kTableSectionStreetcar:
    case kTableSectionTriMet: {
        NSInteger rowType = [self rowType:indexPath];

        switch (rowType) {
        case kTableStreetcarInstagram: {
            [self instagramAt:@"PDXStreetcar"];
            break;
        }

        case kTableTriMetBluesky: {
            UITableViewCell *cell =
                [self.tableView cellForRowAtIndexPath:indexPath];
            [self triMetBlueskyFrom:cell.imageView];
            break;
        }

        case kTableTriMetCall: {
            [self callTriMet];
            break;
        }

        case kTableStreetcarLink:
        case kTableTriMetLink:
        case kTableTriMetCustomerService: {
            LabelLinkCellWithIcon *cell = (LabelLinkCellWithIcon *)[tableView
                cellForRowAtIndexPath:indexPath];

            [WebViewController displayPage:cell.link
                                      full:cell.link
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
        }
        case kTableTriMetDetours: {
            [[DetoursViewController viewController]
                fetchDetoursAsync:self.backgroundTask];
            break;
        }

        case kTableTriMetFacebook: {
            [self facebookTriMet];
            break;
        }

        case kTableTriMetInstagram: {
            [self instagramAt:@"trimet"];
            break;
        }
        }
        break;
    }

    case kTableSectionAbout: {
        NSInteger rowType = [self rowType:indexPath];

        switch (rowType) {
        case kTableAboutSettings: {
            [self settingsAction:nil];
            break;
        }

        case kTableAboutRowAbout: {
            [self.navigationController
                pushViewController:[AboutViewController viewController]
                          animated:YES];
            break;
        }

        case kTableAboutSupport: {
            [self.navigationController
                pushViewController:[SupportViewController viewController]
                          animated:YES];
            break;
        }

        case kTableAboutRate: {
            [WebViewController openNamedURL:@"PDX Bus App Store Review"];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }

        case kTableTipJar: {
            [self tipJar];
            break;
        }

        case kTableAboutFacebook: {
            [self facebookPDXBus];
            break;
        }
        }
        break;
    }

    case kTableSectionPlanner:

        if (indexPath.row == kTableTripRowPlanner) {
            [self tripPlanner:YES];
        } else {
            [self.navigationController
                pushViewController:[TripPlannerHistoryViewController
                                       viewController]
                          animated:YES];
        }

        break;
    }
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    DEBUG_LOG(@"delete r %ld  s %ld\n", (long)indexPath.row,
              (long)indexPath.section);

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        switch ([self sectionType:indexPath.section]) {
        case kTableSectionFaves:
            @synchronized(_userState) {
                [_userState.faves removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                 withRowAnimation:UITableViewRowAnimationNone];
                [_userState cacheState];
                [WatchAppContext updateWatch:self.session];
                [self setEditBookmarksButtonTitle];
            }
            break;

        case kTableSectionAlarms:
            [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
            NSMutableArray *newKeys =
                [NSMutableArray arrayWithArray:self.alarmKeys];
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

// The editing style for a row is the kind of button displayed to the left of
// the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:indexPath.section]) {
    case kTableSectionFaves:
        switch ([self rowType:indexPath]) {
        case kTableFaveBookmark:
            return UITableViewCellEditingStyleDelete;

        case kTableFaveAddStop:
        case kTableFaveAddTrip:
        case kTableFaveAddTakeMeHome:
            return UITableViewCellEditingStyleInsert;

        case kTableFaveButtons:
            return UITableViewCellEditingStyleNone;
        }
        return UITableViewCellEditingStyleNone;

    case kTableSectionAlarms:
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.

    switch ([self sectionType:indexPath.section]) {
    case kTableSectionStopId:
        return NO;

    case kTableSectionFaves:
        switch ([self rowType:indexPath]) {
        case kTableFaveButtons:
            return NO;

        default:
            return YES;
        }

    case kTableSectionAlarms:
        return YES;

    case kTableSectionAbout:
        return NO;

    default:
        return NO;
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
                         toProposedIndexPath:
                             (NSIndexPath *)proposedDestinationIndexPath {
    NSInteger srcSection = [self sectionType:sourceIndexPath.section];

    int sectionMax = 1;

    switch (srcSection) {
    case kTableSectionFaves:
        sectionMax = (int)_userState.faves.count;
        break;
    }

    if (proposedDestinationIndexPath.section < sourceIndexPath.section) {
        return [NSIndexPath indexPathForRow:0
                                  inSection:sourceIndexPath.section];
    }

    if (proposedDestinationIndexPath.section > sourceIndexPath.section) {
        return [NSIndexPath indexPathForRow:sectionMax - 1
                                  inSection:sourceIndexPath.section];
    }

    if (proposedDestinationIndexPath.row >= sectionMax) {
        return [NSIndexPath indexPathForRow:sectionMax - 1
                                  inSection:sourceIndexPath.section];
    }

    return proposedDestinationIndexPath;
}

/*
 // Have an accessory view for the second section only
 - (UITableViewCellAccessoryType)tableView:(UITableView *)tableView
 accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath { return
 (sectionMap[indexPath.section] == kTableSectionFaves && indexPath.row <
 [self.userFaves count] && self.editing) ?
 UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
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
            @synchronized(_userState) {
                NSMutableDictionary *move = _userState.faves[fromIndexPath.row];

                if (fromIndexPath.row < toIndexPath.row) {
                    [_userState.faves insertObject:move
                                           atIndex:toIndexPath.row + 1];
                    [_userState.faves removeObjectAtIndex:fromIndexPath.row];
                } else {
                    [_userState.faves removeObjectAtIndex:fromIndexPath.row];
                    [_userState.faves insertObject:move
                                           atIndex:toIndexPath.row];
                }

                [_userState cacheState];
                [WatchAppContext updateWatch:self.session];
            }
        }

        break;
    }
    }
    //    [tableView reloadData];
}

// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView
    canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    switch ([self sectionType:indexPath.section]) {
    case kTableSectionFaves: {
        NSInteger rowType = [self rowType:indexPath];

        if (rowType == kTableFaveBookmark) {
            return YES;
        }

        return NO;
    }

    default:
        break;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:indexPath.section]) {
    case kTableSectionAlarms: {
        if (self.navigationItem.rightBarButtonItem == self.goButton) {
            self.navigationItem.rightBarButtonItem = self.helpButton;
            [self.editWindow resignFirstResponder];
        }

        if (indexPath.row < self.alarmKeys.count) {
#ifdef DEBUG_ALARMS
            AlarmTask *task =
                [_taskList taskForKey:self.alarmKeys[indexPath.row]];
            LocationServicesDebugViewController *debugView =
                [[LocationServicesDebugViewController alloc] init];
            debugView.data = task;
            [self.navigationController pushViewController:debugView
                                                 animated:YES];
#else
            [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
#endif
        }

        break;
    }

    case kTableSectionStopId: {
        UITextView *textView = (UITextView *)(self.editCell).view;

        NSString *editText = [textView.text justNumbers];

        if (editText.length == 0) {
            return;
        }

        if (_keyboardUp) {
            [self.editWindow resignFirstResponder];
        } else {
            // UITextView *textView = (UITextView*)[self.editCell view];
            [self postEditingAction:textView];
        }

        break;
    }
    }
}

#pragma mark Mail Composer callbacks

// Dismisses the email composition interface when users tap Cancel or Send.
// Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Alarm tasks callbacks
- (void)taskUpdate:(id)task {
    AlarmTask *realTask = (AlarmTask *)task;

    NSInteger alarmSection = [self firstSectionOfType:kTableSectionAlarms];

    if (alarmSection != kNoRowSectionTypeFound) {
        int i = 0;

        for (NSString *key in self.alarmKeys) {
            if ([key isEqualToString:[realTask key]]) {
                NSIndexPath *cellIndex =
                    [NSIndexPath indexPathForRow:i inSection:alarmSection];

                UITableViewCell *cell =
                    [self.tableView cellForRowAtIndexPath:cellIndex];

                if (!cell.showingDeleteConfirmation && !cell.editing) {
                    [self.tableView
                        reloadRowsAtIndexPaths:@[ cellIndex ]
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

/** Called when the session can no longer be used to modify or add any new
 * transfers and, all interactive messages will be cancelled, but delegate
 * callbacks for background transfers can still occur. This will happen when the
 * selected watch is being changed. */
- (void)sessionDidBecomeInactive:(WCSession *)session {
}

/** Called when all delegate callbacks for the previously selected watch has
 * occurred. The session can be re-activated for the now selected watch using
 * activateSession. */
- (void)sessionDidDeactivate:(WCSession *)session {
}

/** Called when any of the Watch state properties change. */
- (void)sessionWatchStateDidChange:(WCSession *)session {
    [WatchAppContext updateWatch:self.session];
}

/** Called on the sending side after the user info transfer has successfully
 * completed or failed with an error. Will be called on next launch if the
 * sender was not running when the user info finished. */
- (void)session:(WCSession *__nonnull)session
    didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer
                        error:(nullable NSError *)error {
}

/** Called on the delegate of the receiver. Will be called on startup if the
 * user info finished transferring when the receiver was not running. */
- (void)session:(WCSession *)session
    didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    if (userInfo != nil) {
        NSDictionary *dict = userInfo.userParams.valRecent;

        if (dict) {
            UserParams *recent = dict.userParams;
            NSString *stopId = recent.valLocation;
            NSString *desc = recent.valOriginalName;

            if (stopId && desc) {
                [UserState.sharedInstance addToRecentsWithStopId:stopId
                                                     description:desc];
            }
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle !=
        self.traitCollection.userInterfaceStyle) {
        self.editCell = nil;
    }
    [super traitCollectionDidChange:previousTraitCollection];
}

+ (RootViewController *)currentRootViewController {
    return (RootViewController *)UIApplication.rootViewController;
}

@end

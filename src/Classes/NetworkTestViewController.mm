//
//  NetworkTestViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/25/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NetworkTestViewController.h"
#import "CLLocation+Helper.h"
#import "Icons.h"
#import "NSString+Core.h"
#import "ReverseGeoLocator.h"
#import "RunParallelBlocks.h"
#import "TaskState.h"
#import "TriMetInfo+UI.h"
#import "UIApplication+Compat.h"
#import "UITableViewCell+Icons.h"
#import "WebViewController.h"
#import "XMLDetours.h"
#import "XMLStreetcarLocations.h"
#import "XMLTrips.h"

@interface NetworkTestViewController ()

@property (nonatomic, copy) NSString *diagnosticText;
@property (nonatomic, copy) NSString *reverseGeoCodeService;

@property bool trimetQueryOK;
@property bool nextbusQueryOK;
@property bool internetConnectionOK;
@property bool reverseGeoCodeOK;
@property bool trimetTripOK;

@end

@implementation NetworkTestViewController

enum SECTION_ROW {
    kSectionHtmlError,
    kSectionInternet,
    kSectionTriMet,
    kSectionTriMetTrip,
    kSectionNextBus,
    kSectionReverseGeoCode,
    kSectionDiagnose,
};

#pragma mark Data fetchers

- (void)subTaskCheckDepartures:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking departure server", @"progress message")];
    XMLDetours *detours = [XMLDetours xmlWithOneTimeDelegate:taskState];
    detours.giveUp = 7;
    [detours getDetours];

    self.trimetQueryOK = detours.gotData;

    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckTripServer:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking trip server", @"progress message")];

    XMLTrips *trips = [XMLTrips xmlWithOneTimeDelegate:taskState];
    trips.userRequest.dateAndTime = nil;
    trips.userRequest.arrivalTime = NO;
    trips.userRequest.timeChoice = TripDepartAfterTime;
    trips.userRequest.toPoint.locationDesc = @"8336";   // Yamhil District
    trips.userRequest.fromPoint.locationDesc = @"8334"; // Pioneer Square South
    trips.giveUp = 7;
    [trips fetchItineraries:nil];

    self.trimetTripOK = trips.gotData;

    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckNextBus:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking NextBus server", @"progress message")];

    XMLStreetcarLocations *locations =
        [XMLStreetcarLocations sharedInstanceForRoute:[TriMetInfo streetcarRoutes].anyObject];
    locations.giveUp = 7;
    locations.oneTimeDelegate = taskState;
    [locations getLocations];

    self.nextbusQueryOK = locations.gotData;

    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckGeoLocator:(TaskState *)taskState {
    if ([ReverseGeoLocator supported]) {
        [taskState taskSubtext:NSLocalizedString(@"checking geocoder server", @"progress message")];

        ReverseGeoLocator *provider = [[ReverseGeoLocator alloc] init];
        // Pioneer Square!

        CLLocation *loc = [CLLocation withLat:45.519077 lng:-122.678602];
        [provider fetchAddress:loc];
        self.reverseGeoCodeOK = (provider.error == nil);
        self.reverseGeoCodeService = @"Apple Geocoder";
    } else {
        self.reverseGeoCodeService = nil;
        self.reverseGeoCodeOK = YES;
    }

    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckConnectivity:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking connection", @"progress message")];
    self.internetConnectionOK = [TriMetXML isDataSourceAvailable:YES];

    [taskState incrementItemsDoneAndDisplay];
}

- (void)fetchNetworkStatusAsync:(id<TaskController>)taskController
              backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
      self.backgroundRefresh = backgroundRefresh;

      [taskState taskStartWithTotal:5
                              title:NSLocalizedString(@"checking network", @"progress message")];

      RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

      [parallelBlocks startBlock:^{
        [self subTaskCheckConnectivity:taskState];
      }];

      [parallelBlocks startBlock:^{
        [self subTaskCheckDepartures:taskState];
      }];

      [parallelBlocks startBlock:^{
        [self subTaskCheckTripServer:taskState];
      }];

      [parallelBlocks startBlock:^{
        [self subTaskCheckNextBus:taskState];
      }];

      [parallelBlocks startBlock:^{
        [self subTaskCheckGeoLocator:taskState];
      }];

      [parallelBlocks waitForBlocksWithState:taskState];

      NSMutableString *diagnosticString = [NSMutableString string];

      if (!self.internetConnectionOK) {
          [diagnosticString
              appendString:NSLocalizedString(
                               @"The Internet is not available. Check you are not in "
                               @"Airplane mode, and not in the Robertson Tunnel.\n\nIf "
                               @"your device is capable, you could also try switching "
                               @"between WiFi, Edge and 3G.\n\nTouch here to start "
                               @"Safari to check your connection. ",
                               @"error message")];
      } else if (!self.trimetQueryOK || !self.nextbusQueryOK || !self.trimetTripOK) {
          [diagnosticString
              appendString:NSLocalizedString(
                               @"The Internet is available, but PDX Bus is not able to "
                               @"contact TriMet's or NextBus's servers. Touch here to "
                               @"check if www.trimet.org is working.",
                               @"error message")];
      } else {
          [diagnosticString
              appendString:NSLocalizedString(@"The main network services are working at this "
                                             @"time. If you are having problems, touch here "
                                             @"to load www.trimet.org, then restart PDX Bus.",
                                             @"error message")];
      }

      if (self.internetConnectionOK && !self.reverseGeoCodeOK &&
          self.reverseGeoCodeService != nil) {
          [diagnosticString
              appendFormat:NSLocalizedString(@"\n\nApple's GeoCoding service is not responding.",
                                             @"error message")];
      }

      self.diagnosticText = diagnosticString;

      [self updateSections];

      [self updateRefreshDate:nil];
      return (UIViewController *)self;
    }];
}

- (void)updateSections {

    [self clearSectionMaps];

    if (self.networkErrorFromQuery != nil) {
        [self addSectionTypeWithRow:kSectionHtmlError];
    }

    [self addSectionTypeWithRow:kSectionInternet];

    [self addSectionTypeWithRow:kSectionTriMet];

    [self addSectionTypeWithRow:kSectionTriMetTrip];

    [self addSectionTypeWithRow:kSectionNextBus];

    [self addSectionTypeWithRow:kSectionReverseGeoCode];

    [self addSectionTypeWithRow:kSectionDiagnose];
}

#pragma mark View Methods

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Network", @"page title");
        self.refreshFlags = kRefreshNoTimer;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark Helper functions

- (void)refreshAction:(id)sender {
    self.backgroundRefresh = YES;
    self.networkErrorFromQuery = nil;
    [self fetchNetworkStatusAsync:self.backgroundTask backgroundRefresh:YES];
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (UITableViewCell *)networkStatusCell:(bool)good
                              goodText:(NSString *)goodText
                               badText:(NSString *)badText {

    UITableViewCell *cell = [self tableView:self.tableView
                    cellWithReuseIdentifier:MakeCellId(networkStatusCell)];

    // Set up the cell...
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = self.basicFont;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (good) {
        cell.textLabel.text = goodText;
        cell.icon = kIconNetworkOk;
        cell.textLabel.textColor = [UIColor modeAwareText];
    } else {
        cell.textLabel.text = badText;
        cell.textLabel.textColor = [UIColor redColor];
        cell.icon = kIconNetworkBad;
    }

    return cell;
}

#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self sectionType:section] == kSectionHtmlError) {
        return NSLocalizedString(@"There was a network problem:", @"section title");
    }

    return nil;
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS NetworkTestViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDiagnose

MULTI_CELL_SELECT(kSectionDiagnose,
                  auto,
                  self.diagnosticText,
                  nil,
                  UITableViewCellAccessoryNone,
                  UITableViewCellSelectionStyleBlue) {
    [WebViewController openNamedURL:@"TriMet"];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionHtmlError

MULTI_CELL(kSectionHtmlError, auto, self.networkErrorFromQuery, nil);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionInternet

CREATE_CELL_WITH_CONFIG(kSectionInternet, nil, basic) {
    return [self
        networkStatusCell:self.internetConnectionOK
                 goodText:NSLocalizedString(@"Internet access is available", @"network error")
                  badText:NSLocalizedString(@"Not able to access the Internet", @"network error")];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionTriMet

CREATE_CELL_WITH_CONFIG(kSectionTriMet, nil, basic) {
    return [self networkStatusCell:self.trimetQueryOK
                          goodText:NSLocalizedString(@"TriMet departure servers are available",
                                                     @"network errror")
                           badText:NSLocalizedString(@"Not able to access TriMet departure servers",
                                                     @"network error")];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionTriMetTrip

CREATE_CELL_WITH_CONFIG(kSectionTriMetTrip, nil, basic) {
    return [self
        networkStatusCell:self.trimetTripOK
                 goodText:NSLocalizedString(@"TriMet trip servers are available", @"network errror")
                  badText:NSLocalizedString(@"Not able to access TriMet trip servers",
                                            @"network errror")];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionNextBus

CREATE_CELL_WITH_CONFIG(kSectionNextBus, nil, basic) {
    return
        [self networkStatusCell:self.nextbusQueryOK
                       goodText:NSLocalizedString(@"Not able to access Umo IQ (Streetcar) servers",
                                                  @"network errror")
                        badText:NSLocalizedString(@"Umo IQ (Streetcar) servers are available",
                                                  @"network errror")];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionReverseGeoCode

CREATE_CELL_WITH_CONFIG(kSectionReverseGeoCode, nil, basic) {
    if (self.reverseGeoCodeService == nil) {
        return [self
            networkStatusCell:TRUE
                     goodText:NSLocalizedString(@"No Reverse GeoCoding service is not supported.",
                                                @"network errror")
                      badText:@""];
    } else {
        return [self
            networkStatusCell:self.reverseGeoCodeOK
                     goodText:NSLocalizedString(@"Apple's Geocoding servers are available.",
                                                @"network errror")
                      badText:NSLocalizedString(@"Not able to access Apple's Geocoding servers.",
                                                @"network errror")];
    }
}

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionHtmlError),
    CELL_MAP(kSectionInternet),
    CELL_MAP(kSectionDiagnose),
    CELL_MAP(kSectionTriMet),
    CELL_MAP(kSectionTriMetTrip),
    CELL_MAP(kSectionNextBus),
    CELL_MAP(kSectionReverseGeoCode),
};

@end

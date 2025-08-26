//
//  VehicleTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleTableViewController.h"
#import "BlockColorDb.h"
#import "DepartureCell.h"
#import "DepartureTimesViewController.h"
#import "FormatDistance.h"
#import "RouteColorBlobView.h"
#import "TaskLocator.h"
#import "TaskState.h"
#import "UIApplication+Compat.h"
#import "Vehicle+iOSUI.h"
#import "XMLLocateVehicles.h"

@interface VehicleTableViewController () {
    bool _firstTime;
}

@end

@implementation VehicleTableViewController

enum SECTION_ROWS { kSectionVehicles, kSectionDisclaimer };

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Nearest Vehicles", @"page title");
        _firstTime = YES;
    }

    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.prompt =
        NSLocalizedString(@"Which vehicle are you on?", @"page prompt");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationItem.prompt = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_firstTime && self.locator.count == 1) {
        Vehicle *vehicle = self.locator[0];

        [vehicle pinAction:self.backgroundTask];
    }

    _firstTime = NO;
}

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController
                         location:(CLLocation *)here
                      maxDistance:(double)dist
                backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
      self.backgroundRefresh = backgroundRefresh;

      CLLocation *location = here;

      NSString *title =
          NSLocalizedString(@"getting vehicles", @"progress message");

      if (location == nil) {
          [taskState taskStartWithTotal:2 title:title];

          location = [TaskLocator locateWithAccuracy:200.0
                                           taskState:taskState];

      } else {
          [taskState startAtomicTask:title];
      }

      if (location != nil) {
          self.locator = [XMLLocateVehicles xml];

          self.locator.location = location;
          self.locator.dist = dist;

          [self.locator findNearestVehicles:nil
                                  direction:nil
                                     blocks:nil
                                   vehicles:nil
                                      since:nil];

          if (self.locator.count == 0) {
              [taskState taskCancel];
              [taskState taskSetErrorMsg:kNoVehicles];
          }

          [self createSections];
      }

      return (UIViewController *)self;
    }];
}

- (void)createSections {
    [self clearSectionMaps];
    [self addSectionType:kSectionVehicles];
    [self addRowType:kSectionVehicles count:self.locator.count];

    [self addSectionTypeWithRow:kSectionDisclaimer];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
    case kSectionVehicles:
        return UITableViewAutomaticDimension;

    case kSectionDisclaimer:
        return kDisclaimerCellHeight;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch ([self rowType:indexPath]) {
    case kSectionVehicles: {
        DepartureCell *dcell =
            [DepartureCell tableView:tableView
                genericWithReuseIdentifier:MakeCellId(kSectionVehicles)];
        cell = dcell;

        // Configure the cell
        Vehicle *vehicle = self.locator[indexPath.row];

        if (LARGE_SCREEN) {
            dcell.routeLabel.text = vehicle.signMessageLong;
        } else {
            dcell.routeLabel.text = vehicle.signMessage;
        }

        dcell.timeLabel.text = [NSString
            stringWithFormat:@"Vehicle ID %@ Distance %@",
                             vehicle.vehicleId ? vehicle.vehicleId : @"none",
                             [FormatDistance formatMetres:vehicle.distance]];
        [dcell.routeColorView setRouteColor:vehicle.routeNumber];
        dcell.blockColorView.color =
            [[BlockColorDb sharedInstance] colorForBlock:vehicle.block];
        dcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
    }

    default:
    case kSectionDisclaimer:
        cell = [self disclaimerCell:tableView];

        [self addTextToDisclaimerCell:cell
                                 text:[self.locator
                                          displayDate:self.locator.cacheTime]];

        if (self.locator.items == nil) {
            [self noNetworkDisclaimerCell:cell];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        [self updateDisclaimerAccessibility:cell];
        break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
    case kSectionVehicles: {
        Vehicle *vehicle = self.locator[indexPath.row];

        [vehicle pinAction:self.backgroundTask];
        break;
    }

    case kSectionDisclaimer: {
        if (self.locator.items == nil) {
            [self networkTips:self.locator.htmlError
                 networkError:self.locator.networkErrorMsg];
            [self clearSelection];
        }

        break;
    }
    }
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add the following line if you want the list to be editable
    // self.navigationItem.leftBarButtonItem = self.editButtonItem;
    // self.title = originalName;

    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Refresh", @"")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(refreshAction:)];

    self.navigationItem.rightBarButtonItem = refreshButton;
    self.searchableItems = self.locator.items;

    [self reloadData];

    if (self.locator.count > 0) {
        [self safeScrollToTop];
    }
}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        XMLLocateVehicles *locator = self.locator;

        [self fetchNearestVehiclesAsync:self.backgroundTask
                               location:locator.location
                            maxDistance:locator.dist
                      backgroundRefresh:YES];
    }
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void)appendXmlData:(NSMutableData *)buffer {
    [self.locator appendQueryAndData:buffer];
}

@end

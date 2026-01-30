//
//  NearestRoutesView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NearestRoutesViewController.h"
#import "DepartureCell.h"
#import "DepartureTimesViewController.h"
#import "FindByLocationViewController.h"
#import "RouteDistance+iOSUI.h"
#import "TaskLocator.h"
#import "TaskState.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

enum SECTION_ROWS { kSectionRoutes, kSectionDisclaimer };

@interface NearestRoutesViewController ()

@property (nonatomic, strong) XMLLocateStops *routeData;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *checked;

- (void)showArrivalsAction:(id)sender;

@end

@implementation NearestRoutesViewController

#pragma mark -
#pragma mark Initialization

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Routes", @"page title");
    }

    return self;
}

#pragma mark -
#pragma mark Fetch data

- (void)fetchNearestRoutesAsync:(id<TaskController>)taskController
                       location:(CLLocation *)here
                      maxToFind:(int)max
                    minDistance:(double)min
                           mode:(TripMode)mode {
    [taskController taskRunAsync:^(TaskState *taskState) {
      CLLocation *location = here;

      if (location == nil) {
          [taskState taskStartWithTotal:2 title:@"getting routes"];

          location = [TaskLocator locateWithAccuracy:min taskState:taskState];

      } else {
          [taskState startAtomicTask:NSLocalizedString(@"getting routes", @"progress message")];
      }

      if (!taskState.taskCancelled && location) {
          self.routeData = [XMLLocateStops xml];

          self.routeData.maxToFind = max;
          self.routeData.location = location;
          self.routeData.mode = mode;
          self.routeData.minDistance = min;

          [self.routeData findNearestRoutes];
          [self.routeData displayErrorIfNoneFound:taskState];
          self.checked = [NSMutableArray array];

          for (int i = 0; i < self.routeData.routes.count; i++) {
              self.checked[i] = @NO;
          }
      }
      return (UIViewController *)self;
    }];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add the following line if you want the list to be editable
    // self.navigationItem.leftBarButtonItem = self.editButtonItem;
    // self.title = originalName;

    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *refreshButton =
        [UIBarButtonItem textButton:NSLocalizedString(@"Get departures", @"button text")
                             target:self
                             action:@selector(showArrivalsAction:)];

    self.navigationItem.rightBarButtonItem = refreshButton;

    [self createSections];
}

- (void)createSections {
    [self clearSectionMaps];

    [self addSectionType:kSectionRoutes];
    [self addRowType:kSectionRoutes count:self.routeData.routes.count];

    [self addSectionTypeWithRow:kSectionDisclaimer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.prompt = NSLocalizedString(@"Select the routes you need:", "page prompt");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationItem.prompt = nil;
}

#pragma mark UI callbacks

- (void)showArrivalsAction:(id)sender {
    NSMutableArray *multipleStops = [NSMutableArray array];

    for (int i = 0; i < self.routeData.routes.count; i++) {
        RouteDistance *rd = (RouteDistance *)self.routeData.routes[i];

        if (self.checked[i].boolValue) {
            [multipleStops addObjectsFromArray:rd.stops];
        }
    }

    [multipleStops sortUsingSelector:@selector(compareUsingDistance:)];

    // remove duplicates, they are sorted so the dups will be adjacent
    NSMutableArray *uniqueStops = [NSMutableArray array];

    NSString *lastStop = nil;

    for (StopDistance *sd in multipleStops) {
        if (lastStop == nil || ![sd.stopId isEqualToString:lastStop]) {
            [uniqueStops addObject:sd];
        }

        lastStop = sd.stopId;
    }

    while (uniqueStops.count > kMaxStops) {
        [uniqueStops removeLastObject];
    }

    if (uniqueStops.count > 0) {
        [[DepartureTimesViewController viewController]
            fetchTimesForNearestStopsAsync:self.backgroundTask
                                     stops:uniqueStops];
    } else {
        [UIAlertController simpleOkWithTitle:nil
                                     message:NSLocalizedString(@"Please select a route", @"error")
                              viewController:self
                                  completion:nil];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void)appendDebugXmlData:(NSMutableData *)buffer {
    [self.routeData appendQueryAndData:buffer];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS NearestRoutesViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRoutes

CELL_CONFIG_METHOD(kSectionRoutes) {
    RouteDistance *rd = (RouteDistance *)self.routeData.routes[indexPath.row];
    DepartureCell *dcel = [DepartureCell tableView:tableView
                        genericWithReuseIdentifier:MakeCellId(XkSectionRoutes)];
    [rd populateCell:dcel];

    if (self.checked[indexPath.row].boolValue) {
        dcel.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        dcel.accessoryType = UITableViewCellAccessoryNone;
    }
    return dcel;
}

CELL_SELECT_METHOD(kSectionRoutes) {
    self.checked[indexPath.row] = self.checked[indexPath.row].boolValue ? @NO : @YES;
    [self reloadData];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

STATIC_VTABLE_VCS_H(kSectionRoutes, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDisclaimer

DISCLAIMER_CELL(kSectionDisclaimer, self.routeData, nil);

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kSectionRoutes),
    CELL_MAP(kSectionDisclaimer),
};

@end

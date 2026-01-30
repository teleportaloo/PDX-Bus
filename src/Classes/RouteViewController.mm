//
//  RouteView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "RouteViewController.h"
#import "AllRailStationViewController.h"
#import "DebugLogging.h"
#import "DirectionViewController.h"
#import "Route+iOS.h"
#import "RouteColorBlobView.h"
#import "TaskDispatch.h"
#import "TaskState.h"
#import "TriMetInfo+UI.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIBarButtonItem+Auto.h"
#import "XMLRoutes.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface RouteViewController ()

@property (nonatomic, strong) XMLRoutes *routeData;

- (void)refreshAction:(id)sender;

@end

@implementation RouteViewController

enum {
    kSectionAllStations = 0,
    kSectionRoutes = 1,
    kSectionDisclaimer = 2,
};

#define kMainSections 3
#define kSearchSections 1

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Routes", @"page title");
        self.enableSearch = YES;
        self.refreshFlags = kRefreshButton | kRefreshShake;
    }

    return self;
}

- (NSInteger)tableView:(UITableView *)tableview sectionType:(NSInteger)section {
    if (tableview == self.tableView) {
        return section;
    }

    return section + 1;
}

#pragma mark Data fetchers

- (void)fetchRoutesAsync:(id<TaskController>)taskController
       backgroundRefresh:(bool)backgroundRefresh {
    self.routeData = [XMLRoutes xml];

    if (!backgroundRefresh && [self.routeData getRoutesCacheAction:TriMetXMLCheckRouteCache]) {
        self.backgroundRefresh = backgroundRefresh;
        [self updateRefreshDate:self.routeData.cacheTime];
        [taskController taskCompleted:self];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
          self.backgroundRefresh = backgroundRefresh;
          [taskState startAtomicTask:NSLocalizedString(@"getting routes", @"activity text")];

          DEBUG_PROGRESS(taskController, @"fetching");
          self.routeData.oneTimeDelegate = taskController;
          [self.routeData getRoutesCacheAction:TriMetXMLForceFetchAndUpdateRouteCache];

          DEBUG_PROGRESS(taskController, @"indexing");

          [self.routeData.items sortUsingSelector:@selector(compare:)];

          if (self.routeData.gotData && self.routeData.count > 0) {
              MAIN_TASK(^{
                [self indexRoutes];
              });
          }

          DEBUG_PROGRESS(taskController, @"updating time");
          [self updateRefreshDate:self.routeData.cacheTime];

          DEBUG_PROGRESS(taskController, @"complete");
          return (UIViewController *)self;
        }];
    }
}

#pragma mark Table View methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kMainSections;
    }

    return kSearchSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ([self tableView:tableView sectionType:section]) {
    case kSectionRoutes: {
        NSArray *items = [self filteredData:tableView];
        return items ? items.count : 0;
    }

    case kSectionAllStations:
    case kSectionDisclaimer:
        return 1;
    }
    return 1;
}

#pragma mark View methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addRoutesToIndex {
    if (Settings.searchRoutes) {
        NSMutableArray *index = [NSMutableArray array];

        for (Route *route in self.routeData) {
            CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc]
                initWithItemContentType:UTTypeText.identifier];
            attributeSet.title = route.desc;

            attributeSet.contentDescription = @"TriMet route";

            NSString *uniqueId =
                [NSString stringWithFormat:@"%@:%@", kSearchItemRoute, route.routeId];

            CSSearchableItem *item =
                [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId
                                                  domainIdentifier:@"route"
                                                      attributeSet:attributeSet];

            [index addObject:item];
        }

        [[CSSearchableIndex defaultSearchableIndex]
            indexSearchableItems:index
               completionHandler:^(NSError *__nullable error) {
                 if (error != nil) {
                     ERROR_LOG(@"Failed to create "
                               @"route index %@\n",
                               error.description);
                 }
               }];
    }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    // Whatever short labels you want on the right
    if (tableView != self.tableView) {
        return nil;
    }

    NSMutableArray *titles = NSMutableArray.array;
    NSArray *items = [self filteredData:tableView];

    [titles addObject:@"All"];

    if (items) {
        for (Route *route in items) {
            [titles addObject:[TriMetInfo tinyNameForRoute:route.routeId]];
        }
    }
    return titles;
}

- (NSInteger)tableView:(UITableView *)tableView
    sectionForSectionIndexTitle:(NSString *)title
                        atIndex:(NSInteger)index {

    if (index == 0) {
        return kSectionAllStations;
    }

    NSInteger rowToScroll = index - 1;
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowToScroll
                                                         inSection:kSectionRoutes]
                     atScrollPosition:UITableViewScrollPositionTop
                             animated:NO];

    return NSNotFound;
}

- (void)indexRoutes {

    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));

    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable]) {
        return;
    }

    CSSearchableIndex *searchableIndex = [CSSearchableIndex defaultSearchableIndex];

    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[ @"route" ]
                                              completionHandler:^(NSError *__nullable error) {
                                                if (error != nil) {
                                                    ERROR_LOG(@"Failed to delete route index %@\n",
                                                              error.description);
                                                }
                                                [self addRoutesToIndex];
                                              }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add the following line if you want the list to be editable
    // self.navigationItem.leftBarButtonItem = self.editButtonItem;
    // self.title = originalName;

    self.searchableItems = self.routeData.items;

    [self reloadData];

    if (self.routeData.count > 0) {
        [self safeScrollToTop];
    }
}

#pragma mark UI callbacks

- (void)refreshAction:(id)unused {
    if (!self.backgroundTask.running) {
        [self fetchRoutesAsync:self.backgroundTask backgroundRefresh:YES];
    }
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {

    [toolbarItems addObject:[UIBarButtonItem textButton:NSLocalizedString(@"info", @"button text")
                                                 target:self
                                                 action:@selector(infoAction:)]];

    if (Settings.debugXML) {
        [toolbarItems addObjectsFromArray:@[ [UIBarButtonItem flexSpace], [self debugXmlButton] ]];
    }

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)appendDebugXmlData:(NSMutableData *)buffer {
    [self.routeData appendQueryAndData:buffer];
}

- (void)infoAction:(id)sender {
    [UIAlertController
        simpleOkWithTitle:NSLocalizedString(@"Frequent Service", @"Alert title")
                  message:NSLocalizedString(@"Routes with blue text have frequent service.",
                                            @"route info")
           viewController:self
               completion:nil];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS RouteViewController
//--------------------------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView
          vTableOffset:(NSIndexPath *)indexPath
              extraOut:(__autoreleasing id *)extra {
    return [self tableView:tableView sectionType:indexPath.section];
}
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionAllStations

BASIC_CELL_SELECT(kSectionAllStations,
                  NSLocalizedString(@"All Rail Stations (A-Z)", @"menu item"),
                  nil,
                  UITableViewCellAccessoryDisclosureIndicator) {
    AllRailStationViewController *view = [AllRailStationViewController viewController];
    view.stopIdStringCallback = self.stopIdStringCallback;
    [self.navigationController pushViewController:view animated:YES];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRoutes

#define COLOR_STRIPE_TAG 1

CELL_CONFIG_METHOD(kSectionRoutes) {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:MakeCellId(kSectionRoutes)];

    if ([cell.contentView viewWithTag:COLOR_STRIPE_TAG] == nil) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        CGRect rect = CGRectMake(
            0, 0, ROUTE_COLOR_WIDTH, [self tableView:tableView heightForRowAtIndexPath:indexPath]);

        RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
        colorStripe.tag = COLOR_STRIPE_TAG;
        [cell.contentView addSubview:colorStripe];
    }

    // Configure the cell
    Route *route = [self filteredData:tableView][indexPath.row];

    cell.textLabel.text = route.desc;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;

    if (route.frequentService && route.frequentService.boolValue) {
        cell.textLabel.textColor = [UIColor modeAwareBlue];
    } else {
        cell.textLabel.textColor = [UIColor modeAwareText];
    }
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    RouteColorBlobView *colorStripe =
        (RouteColorBlobView *)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
    [colorStripe setRouteColor:route.routeId];
    [self updateAccessibility:cell];
    return cell;
}

CELL_SELECT_METHOD(kSectionRoutes) {
    DirectionViewController *directionViewController = [DirectionViewController viewController];
    Route *route = [self filteredData:tableView][indexPath.row];
    // directionViewController.route = [self.routeData
    // itemAtIndex:indexPath.row];
    directionViewController.stopIdStringCallback = self.stopIdStringCallback;
    [directionViewController fetchDirectionsAsync:self.backgroundTask
                                            route:route.routeId
                                backgroundRefresh:NO];
}

STATIC_VTABLE_VCS_H(kSectionRoutes, basic);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionDisclaimer

DISCLAIMER_CELL(kSectionDisclaimer, self.routeData, nil);

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionAllStations),
    CELL_MAP(kSectionRoutes),
    CELL_MAP(kSectionDisclaimer),
};

@end

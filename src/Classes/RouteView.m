//
//  RouteView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "RouteView.h"
#import "AllRailStationViewController.h"
#import "DebugLogging.h"
#import "DirectionViewController.h"
#import "Route+iOS.h"
#import "RouteColorBlobView.h"
#import "TaskDispatch.h"
#import "TaskState.h"
#import "TriMetInfo+UI.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIToolbar+Auto.h"
#import "XMLRoutes.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface RouteView ()

@property(nonatomic, strong) XMLRoutes *routeData;

- (void)refreshAction:(id)sender;

@end

@implementation RouteView

#define kSectionAllStations 0
#define kSectionRoutes 1
#define kSectionDisclaimer 2

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

    if (!backgroundRefresh &&
        [self.routeData getRoutesCacheAction:TriMetXMLCheckRouteCache]) {
        self.backgroundRefresh = backgroundRefresh;
        [self updateRefreshDate:self.routeData.cacheTime];
        [taskController taskCompleted:self];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
          self.backgroundRefresh = backgroundRefresh;
          [taskState startAtomicTask:NSLocalizedString(@"getting routes",
                                                       @"activity text")];

          DEBUG_PROGRESS(taskController, @"fetching");
          self.routeData.oneTimeDelegate = taskController;
          [self.routeData
              getRoutesCacheAction:TriMetXMLForceFetchAndUpdateRouteCache];

          DEBUG_PROGRESS(taskController, @"indexing");

          [self.routeData.items sortUsingSelector:@selector(compare:)];

          if (self.routeData.gotData && self.routeData.count > 0) {
              MainTask(^{
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

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
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

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self tableView:tableView sectionType:indexPath.section]) {
    case kSectionRoutes:
    case kSectionAllStations:
        return [self basicRowHeight];

    case kSectionDisclaimer:
        return kDisclaimerCellHeight;
    }
    return 1;
}

#define COLOR_STRIPE_TAG 1

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch ([self tableView:tableView sectionType:indexPath.section]) {
    case kSectionAllStations: {
        cell = [self tableView:tableView
            cellWithReuseIdentifier:MakeCellId(kSectionAllStations)];

        cell.textLabel.text =
            NSLocalizedString(@"All Rail Stations (A-Z)", @"menu item");
        cell.textLabel.font = self.basicFont;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [self updateAccessibility:cell];
        break;
    }

    case kSectionRoutes: {
        cell = [self tableView:tableView
            cellWithReuseIdentifier:MakeCellId(kSectionRoutes)];

        if ([cell.contentView viewWithTag:COLOR_STRIPE_TAG] == nil) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            CGRect rect = CGRectMake(0, 0, ROUTE_COLOR_WIDTH,
                                     [self tableView:tableView
                                         heightForRowAtIndexPath:indexPath]);

            RouteColorBlobView *colorStripe =
                [[RouteColorBlobView alloc] initWithFrame:rect];
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
            (RouteColorBlobView *)[cell.contentView
                viewWithTag:COLOR_STRIPE_TAG];
        [colorStripe setRouteColor:route.routeId];
        [self updateAccessibility:cell];
    } break;

    case kSectionDisclaimer:
    default:
        cell = [self disclaimerCell:tableView];

        [self
            addTextToDisclaimerCell:cell
                               text:[self.routeData
                                        displayDate:self.routeData.cacheTime]];

        if (self.routeData.items == nil) {
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
    switch ([self tableView:tableView sectionType:indexPath.section]) {
    case kSectionAllStations: {
        AllRailStationViewController *view =
            [AllRailStationViewController viewController];
        view.stopIdStringCallback = self.stopIdStringCallback;
        [self.navigationController pushViewController:view animated:YES];
        break;
    }

    case kSectionRoutes: {
        DirectionViewController *directionViewController =
            [DirectionViewController viewController];
        Route *route = [self filteredData:tableView][indexPath.row];
        // directionViewController.route = [self.routeData
        // itemAtIndex:indexPath.row];
        directionViewController.stopIdStringCallback =
            self.stopIdStringCallback;
        [directionViewController fetchDirectionsAsync:self.backgroundTask
                                                route:route.routeId
                                    backgroundRefresh:NO];
        break;
    }

    case kSectionDisclaimer: {
        if (self.routeData.items == nil) {
            [self networkTips:self.routeData.htmlError
                 networkError:self.routeData.networkErrorMsg];
            [self clearSelection];
        }

        break;
    }
    }
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
            CSSearchableItemAttributeSet *attributeSet =
                [[CSSearchableItemAttributeSet alloc]
                    initWithItemContentType:UTTypeText.identifier];
            attributeSet.title = route.desc;

            attributeSet.contentDescription = @"TriMet route";

            NSString *uniqueId = [NSString
                stringWithFormat:@"%@:%@", kSearchItemRoute, route.routeId];

            CSSearchableItem *item = [[CSSearchableItem alloc]
                initWithUniqueIdentifier:uniqueId
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

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:
    (UITableView *)tableView {
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
    [tableView
        scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowToScroll
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

    CSSearchableIndex *searchableIndex =
        [CSSearchableIndex defaultSearchableIndex];

    [searchableIndex
        deleteSearchableItemsWithDomainIdentifiers:@[ @"route" ]
                                 completionHandler:^(
                                     NSError *__nullable error) {
                                   if (error != nil) {
                                       ERROR_LOG(
                                           @"Failed to delete route index %@\n",
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

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {

    UIBarButtonItem *info = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"info", @"button text")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(infoAction:)];

    [toolbarItems addObject:info];

    if (Settings.debugXML) {
        [toolbarItems addObjectsFromArray:@[
            [UIToolbar flexSpace], [self debugXmlButton]
        ]];
    }

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)appendXmlData:(NSMutableData *)buffer {
    [self.routeData appendQueryAndData:buffer];
}

- (void)infoAction:(id)sender {
    UIAlertController *alert = [UIAlertController
        simpleOkWithTitle:NSLocalizedString(@"Frequent Service", @"Alert title")
                  message:NSLocalizedString(
                              @"Routes with blue text have frequent service.",
                              @"route info")];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

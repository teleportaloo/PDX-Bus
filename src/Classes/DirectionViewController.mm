//
//  DirectionView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DirectionViewController.h"
#import "DebugLogging.h"
#import "Detour+iOSUI.h"
#import "Detour.h"
#import "DetourTableViewCell.h"
#import "DetoursViewController.h"
#import "Icons.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "RailStation+UI.h"
#import "RailStation.h"
#import "RunParallelBlocks.h"
#import "StopViewController.h"
#import "TaskState.h"
#import "TriMetInfo+UI.h"
#import "UITableViewCell+Icons.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "WebViewController.h"

@interface DirectionViewController () {
    CacheAction _cacheAction;
    bool _appeared;
}

@property (nonatomic, strong) Route *route;
@property (nonatomic, strong) NSArray *directionKeys;
@property (nonatomic, strong) XMLRoutes *directionData;
@property (nonatomic, strong) XMLDetoursAndMessages *detourData;
@property (nonatomic, copy) NSString *routeId;

@end

@implementation DirectionViewController

enum {
    kSectionRowName,
    kRowFrequent,
    kSectionRowDirection,
    kSectionOther,
    kSectionRowDetour,
    kRowSiriDetour,
    kSectionRowDisclaimer,
    kOtherRowMap,
    kOtherRowWiki
};

#define kDirectionId @"Direction"

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Route Info", @"screen title");
        _cacheAction = TrIMetXMLRouteCacheReadOrFetch;
        self.refreshFlags = kRefreshNoTimer;
    }

    return self;
}

#pragma mark Data fetchers

- (void)fetchDirectionsAsync:(id<TaskController>)taskController route:(NSString *)route {
    [self fetchDirectionsAsync:taskController route:route backgroundRefresh:NO];
}

- (void)subTaskFetchDirections:(NSString *)route taskState:(TaskState *)taskState {
    [taskState startTask:NSLocalizedString(@"getting directions", @"progress message")];
    self.directionData.oneTimeDelegate = taskState;
    [self.directionData getDirections:route cacheAction:self->_cacheAction];

    if (self.directionData.count > 0) {
        self.route = self.directionData[0];
    }

    if (taskState.total > 1) {
        [taskState incrementItemsDoneAndDisplay];
    }
}

- (void)subTaskFetchDetours:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking detours", @"progress message")];
    self.detourData.oneTimeDelegate = taskState;
    [self.detourData fetchDetoursAndMessages:taskState];

    [self.detourData.items sortUsingSelector:@selector(compare:)];

    if (taskState.total > 1) {
        [taskState incrementItemsDoneAndDisplay];
    }
}

- (void)fetchDirectionsAsync:(id<TaskController>)taskController
                       route:(NSString *)route
           backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
      self.backgroundRefresh = backgroundRefresh;

      self.directionData = [XMLRoutes xml];
      self.detourData = [XMLDetoursAndMessages xmlWithRoutes:@[ route ]];

      self.routeId = route;
      taskState.total = 2;

      if (!self.backgroundRefresh && [self.directionData getDirections:route
                                                           cacheAction:TriMetXMLCheckRouteCache]) {
          taskState.total = 1;
      }

      RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

      [parallelBlocks startBlock:^{
        [self subTaskFetchDirections:route taskState:taskState];
      }];

      [parallelBlocks startBlock:^{
        [self subTaskFetchDetours:taskState];
      }];

      [parallelBlocks waitForBlocksWithState:taskState];

      [self clearSectionMaps];

      [self addSectionType:kSectionRowName];
      [self addRowType:kSectionRowName];

      [self addSectionType:kSectionRowDirection];

      if (self.route) {
          [self addRowType:kSectionRowDirection count:self.route.directions.count];
      }

      [self addSectionType:kSectionOther];
      [self addRowType:kOtherRowMap];

      if (self.route) {
          PtrConstRouteInfo info = self.route.rawColor;

          if (info != nil && info->wiki != nil) {
              [self addRowType:kOtherRowWiki];
          }

          if (self.route.frequentService && self.route.frequentService.boolValue) {
              [self addRowType:kRowFrequent];
          }

          self.directionKeys =
              [self.route.directions keysSortedByValueUsingSelector:@selector(compare:)];
      }

      [self addSectionType:kSectionRowDetour];

      if (self.detourData.count > 0) {
          [self addRowType:kSectionRowDetour count:self.detourData.count];
      }

      [self addRowType:kRowSiriDetour];

      [self addRowType:kSectionRowDisclaimer];

      [self updateRefreshDate:self.directionData.cacheTime];

      return (UIViewController *)self;
    }];
}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        NSString *route = self.routeId;
        _cacheAction = TriMetXMLForceFetchAndUpdateRouteCache;
        [self fetchDirectionsAsync:self.backgroundTask route:route backgroundRefresh:YES];
    }
}

#pragma mark TableView callbacks

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.route == nil) {
        [self networkTips:self.directionData.htmlError
             networkError:self.directionData.networkErrorMsg];
        [self clearSelection];
        return;
    }

    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.route == nil) {
        return nil;
    }

    NSInteger sectionType = [self sectionType:section];

    switch (sectionType) {
    case kSectionRowName:
        return nil;

    case kSectionRowDirection:
        return NSLocalizedString(@"Directions (touch for stops and map):", @"section title");

    case kSectionOther:
        return NSLocalizedString(@"Additional route info:", @"section title");

    case kSectionRowDetour:
        return NSLocalizedString(@"Detours, delays and closures:", @"section title");

        break;

    default:
        return nil;
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

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];

    [self reloadData];

    if (self.route.directions.count > 0) {
        [self safeScrollToTop];
    }

    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kSystemDetourResuseIdentifier];
    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kDetourResuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // iPhone 4S does not show the first cell sometimes.  Quick fix.
    if (!_appeared) {
        _appeared = YES;
        [self safeScrollToTop];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark XML debug methods

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void)appendDebugXmlData:(NSMutableData *)buffer {
    [self.directionData appendQueryAndData:buffer];
    [self.detourData appendQueryAndData:buffer];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS DirectionViewController
//--------------------------------------------------------------------------------------------------

#pragma mark kSectionRowName

CREATE_CELL_WITH_CONFIG(kSectionRowName, nil, basic) {
    RailStationViewCell *railCell = [RailStation tableView:tableView
                                   cellWithReuseIdentifier:MakeCellId(kSectionRowName)
                                                 rowHeight:[self tableView:tableView
                                                               heightForRowAtIndexPath:indexPath]
                                               rightMargin:YES];

    PtrConstRouteInfo info = self.route.rawColor;
    [railCell populateCellWithStation:self.route.desc.safeEscapeForMarkUp
                                lines:info ? info->line_bit : 0];
    railCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return railCell;
};

//--------------------------------------------------------------------------------------------------
#pragma mark kRowFrequent

BASIC_CELL(kRowFrequent, NSLocalizedString(@"Frequent Service", @"menu item"), kIconTriMetLink);

//--------------------------------------------------------------------------------------------------
#pragma mark kOtherRowMap

BASIC_CELL_SELECT(kOtherRowMap,
                  NSLocalizedString(@"TriMet map & schedule page", @"menu item"),
                  kIconTriMetLink,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self showRouteSchedule:self.route.routeId];
    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kOtherRowWiki

BASIC_CELL_SELECT(kOtherRowWiki,
                  NSLocalizedString(@"Wikipedia page", @"Link to English wikipedia page"),
                  [BoxedCharacterIcon withName:@"W"],
                  UITableViewCellAccessoryDisclosureIndicator) {
    NSString *wiki = [TriMetInfo infoForRoute:self.route.routeId]->wiki;

    [WebViewController displayNamedPage:@"Wikipedia"
                              parameter:wiki
                              navigator:self.navigationController
                         itemToDeselect:self
                               whenDone:self.callbackWhenDone];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kRowSiriDetour

BASIC_CELL_SELECT(kRowSiriDetour,
                  NSLocalizedString(@"Add route alerts to Siri", @"menu item"),
                  kIconSiri,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self tableView:tableView siriAlertsForRoute:self.route.desc routeNumner:self.route.routeId];
    [self showRouteSchedule:self.route.routeId];
    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionRowDirection

BASIC_CELL_SELECT(kSectionRowDirection,
                  self.route.directions[self.directionKeys[indexPath.row]].desc,
                  nil,
                  UITableViewCellAccessoryDisclosureIndicator) {
    StopViewController *stopViewController = [StopViewController viewController];

    NSString *rt = self.route.routeId;
    NSString *dr = self.directionKeys[indexPath.row];
    NSString *rd = self.route.desc;

    stopViewController.stopIdStringCallback = self.stopIdStringCallback;
    [stopViewController
          fetchStopsAsync:self.backgroundTask
                    route:rt
                direction:dr
              description:rd
            directionName:self.route.directions[self.directionKeys[indexPath.row]].desc
        backgroundRefresh:NO];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionRowDetour

CELL_CONFIG_METHOD(kSectionRowDetour) {
    Detour *det = self.detourData.gotData ? self.detourData[indexPath.row] : nil;
    return [self detourCell:det route:nil indexPath:indexPath showHeader:YES showRoute:NO];
}

CELL_SELECT_METHOD(kSectionRowDetour) {
    [self detourToggle:self.detourData[indexPath.row] indexPath:indexPath reloadSection:NO];
}

STATIC_VTABLE_VCS_H(kSectionRowDetour, auto);

//--------------------------------------------------------------------------------------------------
DISCLAIMER_CELL(kSectionRowDisclaimer, self.directionData, nil);

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionRowName),
    CELL_MAP(kRowFrequent),
    CELL_MAP(kOtherRowMap),
    CELL_MAP(kOtherRowWiki),
    CELL_MAP(kRowSiriDetour),
    CELL_MAP(kSectionRowDirection),
    CELL_MAP(kSectionRowDetour),
    CELL_MAP(kSectionRowDisclaimer),
};

@end

//
//  StopView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopView.h"
#import "Stop.h"
#import "DepartureTimesView.h"
#import "XMLStops.h"
#import "Departure.h"
#import "MapViewController.h"
#import "RailStation.h"
#import "TriMetInfo.h"
#import "NearestVehiclesMap.h"
#import "NSString+Helper.h"
#import "TaskState.h"
#import "WebViewController.h"

#define kGettingStops      @"getting stops"

enum {
    kSectionRowRouteName,
    kSectionStops,
    kRowStopDummy,
    kRowStop,
    kSectionRowTimePoint,
    kSectionRowDisclaimer
};
    
@interface StopView ()

@property (nonatomic, strong) XMLStops *stopData;
@property (nonatomic, strong) Departure *departure;
@property (nonatomic, copy)   NSString *directionName;
@property (nonatomic) bool hasTimePoint;

- (void)refreshAction:(id)sender;

@end

@implementation StopView

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Stops", @"page title");
        self.enableSearch = YES;
        self.refreshFlags = kRefreshButton | kRefreshShake;
    }
    
    return self;
}

#pragma mark TableViewWithToolbar methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    UIBarButtonItem *segItem = [self segBarButtonWithItems:@[NSLocalizedString(@"Line", @"sort stops in line order"),
                                                             NSLocalizedString(@"A-Z", @"sort stops in A-Z order")]
                                                    action:@selector(toggleSort:)
                                             selectedIndex:0];
    
    [toolbarItems addObjectsFromArray:@[
        [UIToolbar mapButtonWithTarget:self action:@selector(showMap:)],
        [UIToolbar flexSpace],
        segItem]];
    
    if (Settings.debugXML) {
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [toolbarItems addObject:[self debugXmlButton]];
    }
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)appendXmlData:(NSMutableData *)buffer {
    [self.stopData appendQueryAndData:buffer];
}

#pragma mark Data fetchers

- (void)checkTimePoint {
    if (!self.stopData.gotData) {
        self.hasTimePoint = NO;
    }
    else
    {
        self.hasTimePoint = NO;
        for (Stop *stop in self.stopData)
        {
            if (stop.timePoint)
            {
                self.hasTimePoint = YES;
                break;
            }
        }
    }
}


- (void)createSections
{
    [self clearSectionMaps];
    
    [self addSectionType:kSectionRowRouteName];
    [self addRowType:kSectionRowRouteName];
    
    [self addSectionType:kSectionStops];
    
    if (self.stopData.gotData && self.stopData.items.count == 0) {
        [self addRowType:kRowStopDummy];
    }
    else
    {
        // Filtering may reduce this
        [self addRowType:kRowStop count:self.stopData.items.count];
    }
    
    if (self.hasTimePoint)
    {
        [self addSectionType:kSectionRowTimePoint];
        [self addRowType:kSectionRowTimePoint];
    }
    
    [self addSectionType:kSectionRowDisclaimer];
    [self addRowType:kSectionRowDisclaimer];
    
}

- (void)fetchDestinationsAsync:(id<TaskController>)taskController dep:(Departure *)dep {
    self.stopData = [XMLStops xml];
    
    if (!self.backgroundRefresh && [self.stopData getStopsAfterStopId:dep.stopId route:dep.route direction:dep.dir
                                                            description:dep.shortSign cacheAction:TriMetXMLCheckRouteCache]) {
        self.departure = dep;
        self.title = NSLocalizedString(@"Destinations", @"page title");
        
        [self updateRefreshDate:self.stopData.cacheTime];
        [self checkTimePoint];
        [self createSections];
        [taskController taskCompleted:self];
    } else {
        self.title = NSLocalizedString(@"Destinations", @"page title");
        
        [taskController taskRunAsync:^(TaskState *taskState) {
            [taskState startAtomicTask:kGettingStops];
            self.stopData.oneTimeDelegate = taskState;
            [self.stopData getStopsAfterStopId:dep.stopId route:dep.route direction:dep.dir
                                     description:dep.shortSign cacheAction:TriMetXMLForceFetchAndUpdateRouteCache];
            self.departure = dep;
            
            [self updateRefreshDate:self.stopData.cacheTime];
            [self checkTimePoint];
            [self createSections];
            return (UIViewController *)self;
        }];
    }
}

- (void)fetchStopsAsync:(id<TaskController>)taskController
                  route:(NSString *)routeid
              direction:(NSString *)dir
            description:(NSString *)desc
          directionName:(NSString *)dirName
      backgroundRefresh:(bool)backgroundRefresh {
    self.stopData = [XMLStops xml];
    
    if (!backgroundRefresh && [self.stopData getStopsForRoute:routeid
                                                    direction:dir
                                                  description:desc
                                                  cacheAction:TriMetXMLCheckRouteCache]) {
        self.backgroundRefresh = backgroundRefresh;
        [self checkTimePoint];
        [self createSections];
        [self updateRefreshDate:self.stopData.cacheTime];
        [taskController taskCompleted:self];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
            self.backgroundRefresh = backgroundRefresh;
            [taskState startAtomicTask:kGettingStops];
            self.stopData.oneTimeDelegate = taskState;
            [self.stopData getStopsForRoute:routeid
                                  direction:dir
                                description:desc
                                cacheAction:TriMetXMLForceFetchAndUpdateRouteCache];
            [self checkTimePoint];
            [self createSections];
            [self updateRefreshDate:self.stopData.cacheTime];
            return (UIViewController *)self;
        }];
    }
}

#pragma mark TableView methods


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:indexPath.section]) {
        case kSectionRowRouteName:
        case kSectionStops:
            return [self basicRowHeight];
            
            break;
            
        case kSectionRowDisclaimer:
            return kDisclaimerCellHeight;
            
        case kSectionRowTimePoint:
            return UITableViewAutomaticDimension;
    }
    return kDisclaimerCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];
    
    if (tableView != self.table)
    {
        if (sectionType == kSectionStops)
        {
            NSArray *items = [self filteredData:tableView];
    
            if (items != nil)
            {
                return items.count;
            }
        }
        else
        {
            return 0;
        }
    }
    
    return [self rowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
    UITableViewCell *cell = nil;
    
    switch ([self rowType:indexPath]) {
        default:
        case kSectionRowRouteName: {
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRouteNameSection)
                                rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
            
            
            PtrConstRouteInfo info = [TriMetInfo infoForRoute:self.stopData.routeId];
            [RailStation populateCell:cell
                              station:self.stopData.routeDescription.safeEscapeForMarkUp
                                lines:info ? info->line_bit : 0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
         
        case kRowStopDummy:
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"dummy"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = self.smallFont;
            cell.textLabel.textColor = [UIColor modeAwareText];
            cell.textLabel.text = NSLocalizedString(@"The TriMet data contains no stops for this route.", @"info");
            cell.accessibilityLabel = cell.textLabel.text.phonetic;
            break;
        case kRowStop: {
            NSArray *items = [self filteredData:tableView];
            Stop *stop = items[indexPath.row];
            
            if (stop.timePoint) {
                cell = [self tableView:tableView cellWithReuseIdentifier:@"StopTP"];
                
                if (self.stopIdStringCallback == nil || self.stopIdStringCallback.returnStopIdStringController == nil) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                /*
                 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
                 */
                
                cell.textLabel.font = self.smallFont;
                cell.textLabel.textColor = [UIColor modeAwareBlue];
            } else {
                cell = [self tableView:tableView cellWithReuseIdentifier:@"Stop"];
                
                if (self.stopIdStringCallback == nil || self.stopIdStringCallback.returnStopIdStringController == nil) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                /*
                 [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
                 */
                cell.textLabel.font = self.smallFont;
                cell.textLabel.textColor = [UIColor modeAwareText];
            }
            
            cell.textLabel.text = stop.desc;
            cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", stop.desc, stop.timePoint ? @". Time point" : @""].phonetic;
            break;
        }
            
        case kSectionRowDisclaimer:
            cell = [self disclaimerCell:tableView];
            
            if (self.stopData.items == nil) {
                [self noNetworkDisclaimerCell:cell];
            } else {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"%@",
                                                         [self.stopData displayDate:self.stopData.cacheTime]]];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            [self updateDisclaimerAccessibility:cell];
            break;
            
        case kSectionRowTimePoint: {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"tp" font:self.smallFont];
            cell.textLabel.attributedText = NSLocalizedString(@"#UBlue stops are #iTime Points#i - one of several stops on each route that serves as a benchmark for whether a trip is running on time.#D", @"information").smallAttributedStringFromMarkUp;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [self updateAccessibility:cell];
            break;
        }
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView != self.table) {
        return nil;
    }
    
    switch ([self sectionType:section]) {
        case kSectionRowTimePoint:
            return NSLocalizedString(@"Time Points",@"section header");
            
        case kSectionRowRouteName:
            break;
            
        case kSectionStops: {
            if (self.directionName != nil) {
                return self.directionName;
            }
            
            return NSLocalizedString(@"Destination stops:", @"section header");
        }
            
        case kSectionRowDisclaimer:
            break;
    }
    return nil;
}

- (void)    tableView:(UITableView *)tableView
willDisplayHeaderView:(UIView *)view
           forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
        case kSectionRowRouteName:
            break;
            
        case kRowStop: {
            NSArray *items = [self filteredData:tableView];
            
            if (items != nil && indexPath.row >= items.count) {
                if (self.stopData.items == nil) {
                    [self networkTips:self.stopData.htmlError networkError:self.stopData.networkErrorMsg];
                    [self clearSelection];
                }
                
                return;
            }
            
            Stop *stop = items[indexPath.row];
            
            if (stop.stopId) {
                [self returnStopObject:stop progress:self.backgroundTask];
            }
        }
            
        case kSectionRowDisclaimer:
            
            if (self.stopData.items == nil) {
                [self networkTips:self.stopData.htmlError networkError:self.stopData.networkErrorMsg];
            }
            
            break;
        case kSectionRowTimePoint:
            [WebViewController displayNamedPage:@"TriMet Dashboard"
                                      navigator:self.navigationController
                                 itemToDeselect:self
                                       whenDone:nil];
            break;
    }
}

#pragma mark ReturnStop methods

- (NSString *)returnStopObjectActionText {
    if (self.stopIdStringCallback) {
        return [self.stopIdStringCallback returnStopIdStringActionText];
    } else if (self.departure) {
        return NSLocalizedString(@"Show departure time at this stop", @"menu item");
    }
    
    return kNoAction;
}

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        /*
         if ([self.callback getController] != nil)
         {
         [self.navigationController popToViewController:[self.callback getController] animated:YES];
         }*/
        [self.stopIdStringCallback returnStopIdString:stop.stopId desc:stop.desc];
        return;
    }
    
    if (self.departure == nil) {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
        departureViewController.displayName = stop.desc;
        
        [departureViewController fetchTimesForLocationAsync:progress
                                                        stopId:stop.stopId
                                                      title:stop.desc];
    } else {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
        departureViewController.displayName = stop.desc;
        [departureViewController fetchTimesForBlockAsync:progress block:self.departure.block start:self.departure.stopId stopId:stop.stopId];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add the following line if you want the list to be editable
    // self.navigationItem.leftBarButtonItem = self.editButtonItem;
    // self.title = originalName;
    
    
    self.searchableItems = self.stopData.items;
    [self reloadData];
    [self safeScrollToTop];
}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        NSString *direction = self.stopData.direction;
        NSString *routeId = self.stopData.routeId;
        NSString *routeDescription = self.stopData.routeDescription;
        
        
        [self fetchStopsAsync:self.backgroundTask
                        route:routeId
                    direction:direction
                  description:routeDescription
                directionName:self.directionName backgroundRefresh:YES];
    }
}

- (void)showMap:(id)sender {
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.topViewData];
    NearestVehiclesMap *mapPage = [NearestVehiclesMap viewController];
    
    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    NSMutableArray *itemsWithLocations = [NSMutableArray array];
    
    mapPage.title = self.stopData.routeDescription;
    
    for (int i = 0; items != nil && i < items.count; i++) {
        Stop *p = items[i];
        
        if (p.stopId) {
            p.stopObjectCallback = self;
            [itemsWithLocations addObject:p];
        }
    }
    
    mapPage.annotations = itemsWithLocations;
    
    NSSet<NSString *> *streetcarRoutes = [TriMetInfo streetcarRoutes];
    
    mapPage.direction = self.stopData.direction;
    
    if ([streetcarRoutes containsObject:self.stopData.routeId]) {
        mapPage.streetcarRoutes = [NSSet setWithObject:self.stopData.routeId];
        mapPage.trimetRoutes = [NSSet set];
    } else {
        mapPage.trimetRoutes = [NSSet setWithObject:self.stopData.routeId];
        mapPage.streetcarRoutes = [NSSet set];
    }
    
    [mapPage fetchNearestVehiclesAsync:self.backgroundTask];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)toggleSort:(UISegmentedControl *)sender {
    if (self.stopData.items == nil) {
        return;
    }
    
    switch (sender.selectedSegmentIndex) {
        case 0:    // UIPickerView
        {
            [self.stopData.items sortUsingSelector:@selector(compareUsingIndex:)];
            [self reloadData];
            break;
        }
            
        case 1:    // UIPickerView
        {
            [self.stopData.items sortUsingSelector:@selector(compareUsingStopName:)];
            [self reloadData];
            break;
        }
    }
}

#pragma clang diagnostic pop

@end

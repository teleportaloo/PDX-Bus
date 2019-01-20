//
//  StopView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopView.h"
#import "Stop.h"
#import "DepartureTimesView.h"
#import "XMLStops.h"
#import "DepartureData.h"
#import "MapViewController.h"
#import "RailStation.h"
#import "TriMetInfo.h"
#import "NearestVehiclesMap.h"
#import "StringHelper.h"


#define kGettingStops @"getting stops"

#define kRouteNameSection  0
#define kStopSection       1
#define kTimePointSection  2
#define kDisclaimerSection 3

@implementation StopView


- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Stops", @"page title");
        self.enableSearch = YES;
        self.refreshFlags =  kRefreshButton | kRefreshShake;
    }
    return self;
}

#pragma mark TableViewWithToolbar methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    // add a segmented control to the button bar
    UISegmentedControl    *buttonBarSegmentedControl;
    buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
                                 @[
                                    NSLocalizedString(@"Line", @"sort stops in line order"),
                                    NSLocalizedString(@"A-Z" , @"sort stops in A-Z order"),
                                  ]];
    [buttonBarSegmentedControl addTarget:self action:@selector(toggleSort:) forControlEvents:UIControlEventValueChanged];
    buttonBarSegmentedControl.selectedSegmentIndex = 0.0;    // start by showing the normal picker

    UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];    
    
    
    [toolbarItems addObjectsFromArray:@[
                      [UIToolbar mapButtonWithTarget:self action:@selector(showMap:)],
                      [UIToolbar flexSpace],
                      segItem]];
    
    if ([UserPrefs sharedInstance].debugXML)
    {
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [toolbarItems addObject:[self debugXmlButton]];
    }
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    
    
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.stopData appendQueryAndData:buffer];
}

#pragma mark Data fetchers

- (void)addDummyStop
{
    if (self.stopData.gotData && self.stopData.items.count == 0)
    {
        Stop *dummy = [Stop data];
        
        dummy.desc = NSLocalizedString(@"The TriMet data contains no stops for this route.", @"info");
        
        [self.stopData.items addObject:dummy];
    }
}

- (void)fetchDestinationsAsync:(id<BackgroundTaskController>)task dep:(DepartureData *) dep
{
    
    
    self.stopData = [XMLStops xml];
    
    if (!self.backgroundRefresh && [self.stopData getStopsAfterLocation:dep.locid route:dep.route direction:dep.dir
                                                            description:dep.shortSign cacheAction:TriMetXMLCheckCache])
    {
        self.departure = dep;
        self.title = NSLocalizedString(@"Destinations", @"page title");
        
        [self updateRefreshDate:self.stopData.cacheTime];
        [task taskCompleted:self];
    }
    else
    {
        [task taskRunAsync:^{
            [task taskStartWithItems:1 title:kGettingStops];
            self.stopData.oneTimeDelegate = task;
            [self.stopData getStopsAfterLocation:dep.locid route:dep.route direction:dep.dir
                                     description:dep.shortSign cacheAction:TriMetXMLForceFetchAndUpdateCache];
            self.departure = dep;
            self.title = NSLocalizedString(@"Destinations", @"page title");
            
            [self updateRefreshDate:self.stopData.cacheTime];
            return (UIViewController*)self;
        }];
    }
}


- (void)fetchStopsAsync:(id<BackgroundTaskController>)task route:(NSString*) routeid direction:(NSString*)dir description:(NSString *)desc
          directionName:(NSString *)dirName backgroundRefresh:(bool)backgroundRefresh
{
  
    self.stopData = [XMLStops xml];
    if (!backgroundRefresh && [self.stopData getStopsForRoute:routeid
                                                         direction:dir
                                                       description:desc
                                                       cacheAction:TriMetXMLCheckCache])
    {
        self.backgroundRefresh = backgroundRefresh;
        [self addDummyStop];
        [self updateRefreshDate:self.stopData.cacheTime];
        [task taskCompleted:self];
    }
    else
    {
        [task taskRunAsync:^{
            self.backgroundRefresh = backgroundRefresh;
            [task taskStartWithItems:1 title:kGettingStops];
            self.stopData.oneTimeDelegate = task;
            [self.stopData getStopsForRoute:routeid
                                  direction:dir
                                description:desc
                                cacheAction:TriMetXMLForceFetchAndUpdateCache];
            [self addDummyStop];
            [self updateRefreshDate:self.stopData.cacheTime];
            return (UIViewController*)self;
        }];
    }
}



#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    switch (indexPath.section) {
        case kRouteNameSection:
        case kStopSection:
            return [self basicRowHeight];
            break;
        case kDisclaimerSection:
            return kDisclaimerCellHeight;
        case kTimePointSection:
            return UITableViewAutomaticDimension;
    }
    return kDisclaimerCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch (section) {
        case kRouteNameSection:
            if (tableView == self.table)
            {
                return 1;
            }
            break;
        case kStopSection:
        {
            NSArray *items = [self filteredData:tableView];
            return (items == nil ? 0 : items.count);
        }
        case kDisclaimerSection:
            if (tableView == self.table)
            {
                return 1;
            }
        case kTimePointSection:
            if (tableView == self.table)
            {
                return 1;
            }
    }
    return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{

    // Configure the cell
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) 
    {
        default:
        case kRouteNameSection:
        {
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kRouteNameSection)
                                rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
            
            
            PC_ROUTE_INFO info = [TriMetInfo infoForRoute:self.stopData.routeId];
            [RailStation populateCell:cell
                              station:self.stopData.routeDescription
                                lines:info ? info->line_bit : 0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case kStopSection:
        {
            
            NSArray *items = [self filteredData:tableView];
            Stop *stop = items[indexPath.row];
            if (stop.tp)
            {
                cell =  [self tableView:tableView cellWithReuseIdentifier:@"StopTP"];
                if (self.callback == nil || self.callback.controller == nil)
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else
                {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                /*
                 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
                 */
                
                cell.textLabel.font =  self.smallFont;
                cell.textLabel.textColor = [UIColor blueColor];
            }
            else if (stop.locid)
            {
                cell = [self tableView:tableView cellWithReuseIdentifier:@"Stop"];
                if (self.callback == nil || self.callback.controller == nil)
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else
                {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                /*
                 [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
                 */
                cell.textLabel.font =  self.smallFont;
                cell.textLabel.textColor = [UIColor blackColor];
            }
            else
            {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"dummy"];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                /*
                 [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
                 */
                cell.textLabel.font =  self.smallFont;
                cell.textLabel.textColor = [UIColor blackColor];
            }
            cell.textLabel.text = stop.desc;
            cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", stop.desc, stop.tp ? @". Time point" : @""].phonetic;
            break;
            
        }
        case kDisclaimerSection:
            cell = [self disclaimerCell:tableView];
            
            if (self.stopData.items == nil)
            {
                [self noNetworkDisclaimerCell:cell];
            }
            else
            {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"%@", 
                                                         [self.stopData displayDate:self.stopData.cacheTime]]];    
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            [self updateDisclaimerAccessibility:cell];
            break;
        case kTimePointSection:
        {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"tp" font:self.paragraphFont];
            cell.textLabel.attributedText = [@"#BBlue stops are #iTime Points#i - one of several stops on each route that serves as a benchmark for whether a trip is running on time.#0" formatAttributedStringWithFont:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self updateAccessibility:cell];
            break;
        }
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if (tableView != self.table)
    {
        return nil;
    }
    switch (section) 
    {
        case kTimePointSection:
            return @"Time Points";
        case kRouteNameSection:
            break;
        case kStopSection:
        {
            if (self.directionName!=nil)
            {
                return self.directionName;
            }
            return NSLocalizedString(@"Destination stops:", @"section header");
        }
        case kDisclaimerSection:
            break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.accessibilityLabel = header.textLabel.text.phonetic;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    
    switch (indexPath.section) 
    {
        case kRouteNameSection:
            break;
        case kStopSection:
        {
            NSArray *items = [self filteredData:tableView];
            if (items !=nil && indexPath.row >= items.count)
            {
                if (self.stopData.items == nil)
                {
                    [self networkTips:self.stopData.htmlError networkError:self.stopData.errorMsg];
                    [self clearSelection];
                }
                return;
            }
            
            Stop *stop = items[indexPath.row];
            
            if (stop.locid)
            {
                [self chosenStop:stop progress:self.backgroundTask];
            }
        }
        case kDisclaimerSection:
            if (self.stopData.items == nil)
            {
                [self networkTips:self.stopData.htmlError networkError:self.stopData.errorMsg];
            }
            break;
    }
}


#pragma mark ReturnStop methods

- (NSString *)actionText
{
    if (self.callback)
    {
        return [self.callback actionText];
    }
    return @"Show arrivals";
}

- (void)chosenStop:(Stop*)stop progress:(id<BackgroundTaskController>) progress
{
    if (self.callback)
    {
        /*
         if ([self.callback getController] != nil)
         {
         [self.navigationController popToViewController:[self.callback getController] animated:YES];
         }*/
        
        if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
        {
            [self.callback selectedStop:stop.locid desc:stop.desc];
        }
        else 
        {
            [self.callback selectedStop:stop.locid];
        }

        
        return;
    }
    
    if (self.departure == nil)
    {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
        departureViewController.displayName = stop.desc;
        
        [departureViewController fetchTimesForLocationAsync:progress 
                                                               loc:stop.locid
                                                             title:stop.desc];
    }
    else
    {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
        departureViewController.displayName = stop.desc;
        [departureViewController fetchTimesForBlockAsync:progress block:self.departure.block start:self.departure.locid stop:stop.locid];
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

- (void)refreshAction:(id)sender
{
    if (!self.backgroundTask.running)
    {
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

-(void)showMap:(id)sender
{
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.topViewData];
    NearestVehiclesMap *mapPage = [NearestVehiclesMap viewController];
    mapPage.callback = self.callback;
    NSMutableArray *itemsWithLocations = [NSMutableArray array];
    
    mapPage.title = self.stopData.routeDescription;
    

    for (int i=0; items!=nil && i< items.count; i++)
    {
        Stop *p = items[i];
        if (p.locid)
        {
            p.callback = self;
            [itemsWithLocations addObject:p];
        }
    }
    
    
    mapPage.annotations = itemsWithLocations;
    
    NSSet<NSString*> *streetcarRoutes = [TriMetInfo streetcarRoutes];
    
    mapPage.direction = self.stopData.direction;

    if ([streetcarRoutes containsObject:self.stopData.routeId])
    {
        mapPage.streetcarRoutes = [NSSet setWithObject:self.stopData.routeId];
        mapPage.trimetRoutes = [NSSet set];
    }
    else
    {
        mapPage.trimetRoutes = [NSSet setWithObject:self.stopData.routeId];
        mapPage.streetcarRoutes = [NSSet set];
    }
    
    [mapPage fetchNearestVehiclesAsync:self.backgroundTask];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)toggleSort:(id)sender
{
    UISegmentedControl *segControl = sender;
    
    if (self.stopData.items == nil)
    {
        return;
    }
    switch (segControl.selectedSegmentIndex)
    {
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


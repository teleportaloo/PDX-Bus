//
//  ArrivalDetail.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureDetailView.h"
#import "DepartureData+iOSUI.h"
#import "CellTextView.h"
#import "XMLDetours.h"
#import "WebViewController.h"
#include "Detour.h"
#include "StopView.h"
#import "DepartureTimesView.h"
#import "DirectionView.h"

#import "MapViewController.h"
#import "MapViewWithStops.h"
#import "SimpleAnnotation.h"
#import "BigRouteView.h"
#import "AlarmTaskList.h"
#import "AlarmViewMinutes.h"
#import "BlockColorDb.h"
#import "../InfColorPicker/InfColorPickerController.h"
#import "BlockColorViewController.h"
#import "TriMetInfo.h"
#import "BearingAnnotationView.h"
#import "XMLLocateVehicles.h"
#import "FormatDistance.h"
#import "VehicleData+iOSUI.h"
#import "Detour+iOSUI.h"
#import "StringHelper.h"
#import "TriMetInfo.h"
#import "Detour+DTData.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"

#define kFontName                    @"Arial"
#define kTextViewFontSize            16.0

#define kBlockRowFeet                0
#define kCellIdSimple               @"Simple"

enum SECTIONS_AND_ROWS
{
    kSectionRoute,
    kSectionTrips,
    kSectionInfo,
    kSectionSystemAlert,
    kRowFullSign,
    kRowRouteName,
    kRowRouteTimeInfo,
    kSectionRowDetour,
    kSectionRowLocation,
    kRowMap,
    kSectionAction,
    kRowTag,
    kRowSectionVehicle,
    kRowAlarm,
    kRowDestArrival,
    kRowNextStops,
    kRowOneStop,
    kRowMapAndSchedule,
    kRowBrowse,
    kRowMapWithStops,
    kRowTrip,
    kRowOpposite,
    kRowNoDeeper
};

@implementation DepartureDetailView

- (void)dealloc {
    
    
    if (self.displayLink)
    {
        [self.displayLink invalidate];
    }
    
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Details", @"Departure details screen title");
        self.refreshFlags = kRefreshAll;
    }
    return self;
}

#pragma mark Data fetchers

- (void)addPathToShape:(ShapeRoutePath*)path
{
    if (path!=nil)
    {
        [self.shape addObject:path];
    }
}

- (void)setupShape:(id<BackgroundTaskController>)task
{
    KMLRoutes *kml = [KMLRoutes xml];
    kml.oneTimeDelegate = task;
    [kml fetch];
    
    PC_ROUTE_INFO info = [TriMetInfo infoForRoute:self.departure.route];
    
    DepartureData *dep = self.departure;
    
    self.shape = [NSMutableArray array];
    
    if (self.departure.blockPositionRouteNumber == nil)
    {
        
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:kKmlFirstDirection]];
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:kKmlOptionalDirection]];
        
        if (info && info->interlined_route)
        {
            [self addPathToShape:[kml lineCoordsForRoute:[TriMetInfo interlinedRouteString:info] direction:kKmlFirstDirection]];
            [self addPathToShape:[kml lineCoordsForRoute:[TriMetInfo interlinedRouteString:info] direction:kKmlOptionalDirection]];
        }
    }
    else if (dep.trips.count!=0)
    {
        for (DepartureTrip *trip in dep.trips)
        {
            [self addPathToShape:[kml lineCoordsForRoute:trip.route direction:trip.dir]];
        }
    }
    else
    {
        [self addPathToShape:[kml lineCoordsForRoute:dep.route direction:dep.dir]];
        
        if (![dep.route isEqualToString:dep.blockPositionRouteNumber] || ![dep.dir isEqualToString:dep.blockPositionDir])
        {
            [self addPathToShape:[kml lineCoordsForRoute:self.departure.blockPositionRouteNumber direction:self.departure.blockPositionDir]];
        }
    }
}

- (void)fetchDataAsync:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh
{
    [task taskRunAsync:^{
        DEBUG_FUNC();
        
        int total = 0;
        int items = 0;
        self.xml = [NSMutableArray array];
        
        NSSet<NSString*> *streetcarRoutes = nil;
        
        self.backgroundRefresh = backgroundRefresh;
        
        if (self.departure.route == nil)
        {
            total = 1;
        }
        else
        {
            if (self.backgroundRefresh)
            {
                total++;
            }
            
            if (self.departure.vehicleInfo->check_for_multiple && !self.departure.fetchedAdditionalVehicles && self.departure.block && !self.departure.streetcar)
            {
                total++;
            }
            
            if (self.departure.nextBusFeedInTriMetData && self.allDepartures!=nil && self.departure.status == kStatusEstimated)
            {
                streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.allDepartures];
                total += streetcarRoutes.count + 1;
            }
            else if (self.departure.nextBusFeedInTriMetData)
            {
                streetcarRoutes = [NSSet setWithObject:self.departure.route];
                total += 2;
            }
            else if ([UserPrefs sharedInstance].kmlRoutes)
            {
                total++;
            }
        }
        
        [task taskStartWithItems:total title:NSLocalizedString(@"getting details", @"Progress indication")];
        
        if (self.backgroundRefresh || self.departure.route == nil)
        {
            XMLDepartures *newDep = [XMLDepartures xml];
            // Refetch the detour
            //newDep.allDetours = self.departure.allDetours;
            newDep.oneTimeDelegate = task;
            [newDep getDeparturesForLocation:self.departure.locid block:self.departure.block];
            
            items++;
            [task taskItemsDone:items];
            
            if (newDep.gotData && newDep.count > 0)
            {
                DepartureData *oldDep = self.departure;
                self.departure = newDep.items.firstObject;
                self.departure.streetcarId = oldDep.streetcarId;
                self.departure.vehicleIDs = [self.departure vehicleIdsForStreetcar];
                if (self.departure.vehicleInfo->check_for_multiple)
                {
                    self.departure.vehicleIDs = oldDep.vehicleIDs;
                    self.departure.fetchedAdditionalVehicles = oldDep.fetchedAdditionalVehicles;
                }
                
                if (oldDep.route==nil)
                {
                    streetcarRoutes = [NSSet setWithObject:self.departure.route];
                }
            }
            else
            {
                [self.departure makeInvalid:newDep.queryTime];
            }
            
            if (self.departure.blockPosition == nil && self.departure.status == kStatusEstimated)
            {
                total++;
            }
            
            [task taskTotalItems:total];
            
            XML_DEBUG_RAW_DATA(newDep);
        }
        
        if (self.departure.vehicleInfo->check_for_multiple && !self.departure.fetchedAdditionalVehicles && self.departure.block && !self.departure.streetcar)
        {
            XMLLocateVehicles *locator = [XMLLocateVehicles xml];
            locator.oneTimeDelegate = task;
            [locator findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:self.departure.block] vehicles:nil];
            
            NSMutableArray *vehicles = [NSMutableArray arrayWithArray:self.departure.vehicleIDs];
            
            for (VehicleData *vehicle in locator)
            {
                bool found = NO;
                
                for (NSString *known in vehicles)
                {
                    if ([vehicle.vehicleID isEqualToString:known])
                    {
                        found = YES;
                        break;
                    }
                }
                if (!found)
                {
                    [vehicles addObject:vehicle.vehicleID];
                }
            }
            self.departure.fetchedAdditionalVehicles = YES;
            self.departure.vehicleIDs = vehicles;
            
            
            items++;
            [task taskItemsDone:items];
            
            XML_DEBUG_RAW_DATA(locator);
        }
        
        if (self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil && self.departure.status == kStatusEstimated)
        {
            
            if (self.departure.streetcarId == nil)
            {
                
                // First get the arrivals via next bus to see if we can get the correct vehicle ID
                // Not using auto release pool
                XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
                
                streetcarArrivals.oneTimeDelegate = task;
                
                [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&stopId=%@",self.departure.locid]];
                
                items++;
                
                for (DepartureData *vehicle in streetcarArrivals)
                {
                    if ([vehicle.block isEqualToString:self.departure.block])
                    {
                        self.departure.streetcarId = vehicle.streetcarId;
                        self.departure.vehicleIDs = [vehicle vehicleIdsForStreetcar];
                        break;
                    }
                }
                
                XML_DEBUG_RAW_DATA(streetcarArrivals);
                
            }
            
            for (NSString *route in streetcarRoutes)
            {
                [task taskItemsDone:items];
                XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
                
                locs.oneTimeDelegate = task;
                [locs getLocations];
                
                items++;
                [task taskItemsDone:items];
                 
                XML_DEBUG_RAW_DATA(locs);
            }
            

            if (self.allDepartures != nil)
            {
                [XMLStreetcarLocations insertLocationsIntoDepartureArray:self.allDepartures forRoutes:streetcarRoutes];
            }
            else
            {
                XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:self.departure.route];
                [locs insertLocation:self.departure];
            }
            
            self.allDepartures = nil;
            [task taskItemsDone:items];
        }
        else if (!self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil && self.departure.status == kStatusEstimated
                 && [UserPrefs sharedInstance].useBetaVehicleLocator)
        {
            XMLLocateVehicles *vehicles = [XMLLocateVehicles xml];
            vehicles.oneTimeDelegate = task;
            [vehicles findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:self.departure.block] vehicles:nil];
            
            if (vehicles.count > 0)
            {
                VehicleData *data = vehicles.items.firstObject;
                
                [self.departure insertLocation:data];
            }
            
            items++;
            [task taskItemsDone:items];
            
            XML_DEBUG_RAW_DATA(vehicles);
        }
        
        if ([UserPrefs sharedInstance].kmlRoutes && self.shape==nil)
        {
    
            [task taskSubtext:@"getting route shapes"];
            [self setupShape:task];
            items++;
            [task taskItemsDone:items];
        }
        
        /*
        [self.departure.detours sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber * obj2) {
            return [self.departure.allDetours[obj1] compare:self.departure.allDetours[obj2]];
        }];
        */
        
        [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
            [self updateSections];
        }];
       
        if (!self.departure.shortSign)
        {
            [[NSThread currentThread] cancel];
            [task taskSetErrorMsg:@"No arrival found - it has already departed."];
        }
        
        [self updateRefreshDate:nil];
        DEBUG_LOG(@"done %p", self);
        DEBUG_LOGP(task);
        
        return (UIViewController*)self;
        DEBUG_FUNCEX();
    }];
}

- (void)updateSections
{
    
    [self clearSectionMaps];
    
    for (int alert=0;  alert<self.departure.systemWideDetours; alert++)
    {
        [self addSectionType:kSectionSystemAlert];
        [self addRowType:kSectionRowDetour];;
    }
    
    
    /*
    if (![self.departure.fullSign isEqualToString:self.departure.shortSign])
    {
        [self addRowType:kRowFullSign];
    }
     */
    
    [self addSectionType:kSectionRoute];
    [self addRowType:kRowRouteName];
    
    
    [self addRowType:kRowRouteTimeInfo];
    
    
    if (self.departure.hasBlock && self.departure.blockPosition!=nil)
    {
        [self addSectionType:kSectionRowLocation];
        [self addRowType:kRowMap];
        [self addRowType:kSectionRowLocation];
    }
       
    
    if ((self.departure.detours.count-self.departure.systemWideDetours) > 0)
    {
        [self addSectionType:kSectionRowDetour];
        _firstDetourRow = self.rowsInLastSection;
        [self addRowType:kSectionRowDetour count:self.departure.detours.count-self.departure.systemWideDetours];
    }
    
    bool actionSection = NO;
    
    if (self.departure.block !=nil)
    {
        [self addSectionType:kSectionAction];
        actionSection = YES;
        [self addRowType:kRowTag];
    }
  
    if (self.departure.block && [AlarmTaskList supported] && self.departure.secondsToArrival > 0)
    {
        if (!actionSection)
        {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }
        [self addRowType:kRowAlarm];
    }
    
    // On refresh the allowDest may be NO but that's cause we don't know
    if (self.allowBrowseForDestination)
    {
        if (!actionSection)
        {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }
        [self addRowType:kRowDestArrival];
    }
    
    // On refresh the allowDest may be NO but that's cause we don't know
    if (self.departure.nextLocid!=nil && [DepartureTimesView canGoDeeper])
    {
        if (!actionSection)
        {
            [self addSectionType:kSectionAction];
            actionSection = YES;
        }
        [self addRowType:kRowNextStops];
    }
    
    if ([DepartureTimesView canGoDeeper])
    {
        if (!actionSection)
        {
            [self addSectionType:kSectionAction];
        }
        [self addRowType:kRowOpposite];
    }
    else
    {
        if (!actionSection)
        {
            [self addSectionType:kSectionAction];
        }
        [self addRowType:kRowNoDeeper];
    }
    
    [self addSectionType:kSectionInfo];
    [self addRowType:kRowMapAndSchedule];
    [self addRowType:kRowBrowse];
    [self addRowType:kRowMapWithStops];

    

    if (self.departure.trips.count > 0 && [UserPrefs sharedInstance].showTrips)
    {
        [self addSectionType:kSectionTrips];
        [self addRowType:kRowTrip count:self.departure.trips.count];
    }
    
    DEBUG_LOGO(self.departure.vehicleIDs);
    if (self.departure.vehicleIDs && self.departure.vehicleIDs.count > 0)
    {
        [self addSectionType:kRowSectionVehicle];
        [self addRowType:kRowSectionVehicle count:self.departure.vehicleIDs.count];
    }
    
    [self addRowType:kSectionRowDisclaimerType];
}

- (void)fetchDepartureAsync:(id<BackgroundTaskController>)task location:(NSString *)loc block:(NSString *)block backgroundRefresh:(bool)backgroundRefresh
{
    self.departure = [DepartureData data];
    self.departure.locid = loc;
    self.departure.block = block;

    DEBUG_LOGP(task);
    [self fetchDataAsync:task backgroundRefresh:backgroundRefresh];

}

- (void)fetchDepartureAsync:(id<BackgroundTaskController>)task dep:(DepartureData *)dep allDepartures:(NSArray*)deps backgroundRefresh:(bool)backgroundRefresh
{
    if (!self.backgroundRefresh)
    {
        self.departure = dep;
        self.allDepartures = deps;
    }
    
    KMLRoutes *kml = [KMLRoutes xml];
        
    if (dep==nil || (dep.streetcar && dep.blockPosition==nil) || self.backgroundRefresh || (dep.vehicleInfo->check_for_multiple && !dep.fetchedAdditionalVehicles)  || ([UserPrefs sharedInstance].kmlRoutes && !kml.cached))
    {
        DEBUG_LOGP(task);        
        [self fetchDataAsync:task backgroundRefresh:backgroundRefresh];
    }
    else if (!self.backgroundRefresh)
    {
        if ([UserPrefs sharedInstance].kmlRoutes)
        {
            [self setupShape:task];
        }
    
        [self updateSections];
        
        [self updateRefreshDate:dep.queryTime];
        
        [task taskCompleted:self];
    }
}

#pragma mark Helper functions



- (UIColor*) randomColor
{
    CGFloat red    = (double)(arc4random() % 256 ) / 255.0;
    CGFloat green  = (double)(arc4random() % 256 ) / 255.0;
    CGFloat blue   = (double)(arc4random() % 256 ) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];    
}

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller
{
    [[BlockColorDb sharedInstance] addColor:controller.resultColor
                                   forBlock:self.departure.block
                                description:self.departure.fullSign];
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (_delegate)
    {
        [_delegate detailsChanged];
    }
    [self favesChanged];
    [self reloadData];
}

- (void)showStops:(NSString *)route
{
    if ([DepartureTimesView canGoDeeper])
    {        
        [[DirectionView viewController] fetchDirectionsAsync:self.backgroundTask route:route];
    }
    
}

-(void)showMapWithStops:(bool)withStops
{
    MapViewWithStops *mapPage = [MapViewWithStops viewController];
    SimpleAnnotation *pin = [SimpleAnnotation annotation];
    mapPage.title = self.departure.fullSign;
    mapPage.callback = self.callback;
    pin.coordinate = self.departure.blockPosition.coordinate;
    if (self.departure.blockPositionHeading)
    {
        pin.doubleBearing = self.departure.blockPositionHeading.doubleValue;
    }
    pin.pinTitle = self.departure.shortSign;
    if (self.departure.blockPositionFeet>0)
    {
        pin.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ away", @"<distance> of vehicle"), [FormatDistance formatFeet:self.departure.blockPositionFeet]];
    }
    pin.pinColor = MAP_PIN_COLOR_PURPLE;
    pin.pinTint = [TriMetInfo colorForRoute:self.departure.route];
    pin.pinSubTint = [[BlockColorDb sharedInstance] colorForBlock:self.departure.block];
    
    [mapPage addPin:pin];
    
    
    SimpleAnnotation *stopPin = [SimpleAnnotation annotation];
    stopPin.coordinate = self.departure.stopLocation.coordinate;
    stopPin.pinTitle = self.departure.locationDesc;
    stopPin.pinSubtitle = nil;
    stopPin.pinColor = MAP_PIN_COLOR_RED;
    [mapPage addPin:stopPin];
    
    if (self.shape)
    {
        mapPage.lineCoords = self.shape.mutableCopy;
        mapPage.lineOptions = MapViewNoFitLines;
    }
    
    if (withStops)
    {
        [mapPage fetchStopsAsync:self.backgroundTask route:self.departure.route  direction:self.departure.dir returnStop:self];
    }
    else
    {
        [self.navigationController pushViewController:mapPage animated:YES];
    }
}

-(void)showMap:(id)sender
{
    [self showMapWithStops:NO];
}


-(void)showBig:(id)sender
{
    BigRouteView *bigPage = [BigRouteView viewController];
    
    bigPage.departure = self.departure;
    
    [self.navigationController pushViewController:bigPage animated:YES];
}

#pragma mark TableView methods

- (bool)neverAdjustContentInset
{
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [self sections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsInSection:section];
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    switch ([self rowType:indexPath])
    {
        case kRowTag:
            _reloadOnAppear = YES;
            [self.navigationController pushViewController:[BlockColorViewController viewController] animated:YES];
            break;
        default:
            break;
    }
    
}

- (UITableViewCell *)basicCell:(UITableView *)tableView identifier:(NSString*)ident text:(NSString*)text image:(UIImage *)image indexPath:(NSIndexPath*)indexPath font:(UIFont*)font
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:ident];
    cell.textLabel.font = font;
    cell.textLabel.text = text;
    cell.imageView.image  = image;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor grayColor];
    [self updateAccessibility:cell];
    return cell;
}


- (UITableViewCell *)basicCell:(UITableView *)tableView identifier:(NSString*)ident text:(NSString*)text image:(UIImage *)image indexPath:(NSIndexPath*)indexPath
{
    return [self basicCell:tableView identifier:ident text:text image:image indexPath:indexPath font:self.basicFont];
}
    


- (Detour *)detourForRow:(NSInteger)sectionType indexPath:(NSIndexPath *)indexPath
{
    NSInteger detourIndex = (sectionType == kSectionSystemAlert)
                                ? indexPath.section
                                : (indexPath.row - _firstDetourRow + self.departure.systemWideDetours);
    NSNumber *detourId = self.departure.detours[detourIndex];
    return self.departure.allDetours[detourId];
}

- (void)tableView:tableView detourButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath buttonType:(NSInteger)buttonType
{
    Detour *det = [self detourForRow:[self sectionType:indexPath.section] indexPath:indexPath];
    [self detourAction:det buttonType:buttonType indexPath:indexPath reloadSection:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType     = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowFullSign:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kRowFullSign)];
            cell.textLabel.font = self.basicFont;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.imageView.image = nil;
            cell.textLabel.text = self.departure.fullSign;
            [self updateAccessibility:cell];
            return cell;
        }
            
        case kRowRouteName:
        {
            DepartureCell *cell = [DepartureCell tableView:tableView cellWithReuseIdentifier:MakeCellId(kRowRouteName)];
            [self.departure populateCell:cell decorate:NO busName:YES wide:LARGE_SCREEN];
            return cell;
        }
            
        case kRowRouteTimeInfo:
        {
            UITableViewCell *labelCell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kRowRouteTimeInfo)];
    
            NSString *details = [self.departure getFormattedExplaination];
            labelCell.textLabel.attributedText = [details formatAttributedStringWithFont:self.paragraphFont];
            labelCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self updateAccessibility:labelCell];
            return labelCell;
            break;
        }

        case kSectionRowLocation:
        {
            NSString *lastSeen = [VehicleData locatedSomeTimeAgo:self.departure.blockPositionAt];
            
            self.indexPathOfLocationCell = indexPath;
            
            return [self basicCell:tableView
                        identifier:MakeCellId(kRowLocation)
                              text:lastSeen
                             image:[self getIcon:kIconMap7]
                         indexPath:indexPath
                              font:[UIFont fontWithName:@"Verdana" size:VerdanaScale(self.basicFont.pointSize)]];
        }
        case kRowTag:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kRowTag)];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = self.basicFont;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.textLabel.textColor = [UIColor grayColor];
            
            cell.imageView.image = nil;
            
            UIColor * color = [[BlockColorDb sharedInstance] colorForBlock:self.departure.block];
            if (color == nil)
            {
                cell.textLabel.text = NSLocalizedString(@"Tag this " kBlockName " with a color", @"menu item");
                cell.imageView.image = [BlockColorDb imageWithColor:[UIColor grayColor]];
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Remove " kBlockName " color tag", @"menu item");
                cell.imageView.image = [BlockColorDb imageWithColor:color];
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
            
            return cell;
        }
        case kSectionRowDetour:
        {
            UITableViewCell *cell = nil;
    
            if (self.departure.detours !=nil)
            {
                Detour *det = [self detourForRow:[self sectionType:indexPath.section] indexPath:indexPath];
                
                if (det!=nil)
                {
                    cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                    [det populateCell:cell font:self.paragraphFont routeDisclosure:NO];
                    [self addDetourButtons:det cell:cell routeDisclosure:NO];
                }
                else
                {
                    cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                    NSString *text = @"#0#RThe detour description is missing. ☹️";
                    cell.textLabel.attributedText = [text formatAttributedStringWithFont:self.paragraphFont];
                    cell.textLabel.accessibilityLabel = text.removeFormatting.phonetic;
                }
            }
            else
            {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"detour error"];
                NSString *text = @"#0#RThe detour description is missing. ☹️";
                cell.textLabel.attributedText = [text formatAttributedStringWithFont:self.paragraphFont];
                cell.textLabel.accessibilityLabel = text.removeFormatting.phonetic;
            }
            return cell;
        }
        case kRowSectionVehicle:
        {
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kRowVehicle)];
            NSString *vehicleId = self.departure.vehicleIDs[indexPath.row];
            cell.textLabel.attributedText = [[TriMetInfo vehicleString:vehicleId] formatAttributedStringWithFont:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self updateAccessibility:cell];
            return cell;
        }
        case kRowTrip:
        {
            DepartureCell *cell = [DepartureCell tableView:tableView genericWithReuseIdentifier:MakeCellId(kRowTrip)];
            [self.departure populateTripCell:cell item:indexPath.row];
            return cell;
        }
        case kSectionRowDisclaimerType:
        {
            UITableViewCell *cell  = [self disclaimerCell:tableView];
        
            NSString *date = [NSDateFormatter localizedStringFromDate:self.departure.queryTime
                                                            dateStyle:NSDateFormatterNoStyle
                                                            timeStyle:NSDateFormatterMediumStyle];
            
            if (self.departure.block !=nil)
            {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@. Updated: %@\n" kBlockNameC " ID %@", @"infomation at the end of the arrivals"),
                                                         self.departure.locid,
                                                         date,
                                                         self.departure.block]
                                        lines:2];
                
            }
            else {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@. Updated: %@", @"infomation at the end of the arrivals"),
                                                         self.departure.locid,
                                                         date]];
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            if (self.departure.streetcar && self.departure.copyright !=nil)
            {
                [self addStreetcarTextToDisclaimerCell:cell  text:self.departure.copyright trimetDisclaimer:YES];
            }
            
            [self updateDisclaimerAccessibility:cell];
            
            return cell;
        }
        case kRowMapWithStops:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Map with route stops", @"menu item")
                             image:[self getIcon:kIconEarthMap]
                         indexPath:indexPath];
        case kRowOpposite:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Arrivals going the other way", @"menu item")
                             image:[self getIcon:kIconArrivals]
                         indexPath:indexPath];
        case kRowNoDeeper:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Too many windows open", @"menu item")
                             image:[self getIcon:kIconCancel]
                         indexPath:indexPath];
            
        case kRowBrowse:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Browse stops", @"menu item")
                             image:[self getIcon:kIconBrowse]
                         indexPath:indexPath];
            
            
        case kRowMapAndSchedule:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"TriMet Map & schedule page", @"menu item")
                             image:[self getIcon:kIconTriMetLink]
                         indexPath:indexPath];
            
            
        case kRowDestArrival:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Browse for destination arrival time", @"menu item")
                             image:[self getIcon:kIconArrivals]
                         indexPath:indexPath];
        case kRowNextStops:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Show vehicle's next stops before arrival", @"menu item")
                             image:[self getIcon:kIconArrivals]
                         indexPath:indexPath];
        case kRowAlarm:
        {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            
            if ([taskList hasTaskForStopId:self.departure.locid block:self.departure.block])
            {
                return [self basicCell:tableView
                            identifier:kCellIdSimple
                                  text:NSLocalizedString(@"Edit arrival alarm", @"menu item")
                                 image:[self getIcon:kIconAlarm]
                             indexPath:indexPath];
                
                
            }
            else {
                
                return [self basicCell:tableView
                            identifier:kCellIdSimple
                                  text:NSLocalizedString(@"Set arrival alarm", @"menu item")
                                 image:[self getIcon:kIconAlarm]
                             indexPath:indexPath];
                                  // font:[UIFont fontWithName:@"Verdana" size:self.basicFont.pointSize-2]];
                
                
            }
            break;
        }
        case kRowMap:
        {
            UITableViewCell *cell  = [self getMapCell:MakeCellId(kRowMap) withUserLocation:NO];
            
            MKMapView *map = self.mapView;

            map.delegate = self;
            
            SimpleAnnotation *annotLoc = [SimpleAnnotation annotation];
            
            annotLoc.pinTitle = self.departure.locationDesc;
            annotLoc.pinColor = MAP_PIN_COLOR_RED;
            annotLoc.coordinate = self.departure.stopLocation.coordinate;
            
            [map addAnnotation:annotLoc];
            [map addAnnotation:self.departure];
            
            DEBUG_LOGLU(map.annotations.count);
            
            if (self.shape)
            {
                NSMutableArray *overlays = [NSMutableArray array];
                
                for (ShapeRoutePath *path in self.shape)
                {
                    [path addPolylines:overlays];
                }
                [self.mapView addOverlays:overlays];
            }

            {
                MKMapRect flyTo = MKMapRectNull;
                MKMapPoint annotationPoint = MKMapPointForCoordinate(self.departure.stopLocation.coordinate);
                flyTo = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 50, 50);
                annotationPoint = MKMapPointForCoordinate(self.departure.blockPosition.coordinate);
                MKMapRect busRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 50, 50);
                flyTo = MKMapRectUnion(flyTo, busRect);
                
                UIEdgeInsets insets = {
                    30,
                    10,
                    10,
                    20
                };
                
                [map setVisibleMapRect:[map mapRectThatFits:flyTo edgePadding:insets] animated:YES];
            }
           
            return cell;
            break;
        }
            
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
}

- (void)didTapMap:(id)sender
{
    [self showMap:nil];
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[RoutePolyline class]])
    {
        return [(RoutePolyline *)overlay renderer];
    }
    return [[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSInteger sectionType = [self sectionType:section];
    
    switch (sectionType)
    {
        case kSectionSystemAlert:
        {
            Detour *detour = [self detourForRow:sectionType indexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            return detour.depGetSectionHeader;
        }
        case kSectionAction:
            return NSLocalizedString(@"Actions:", @"section title");
        case kSectionRowDetour:
            return NSLocalizedString(@"Route Alerts:", @"section title");
        case kSectionRoute:
            return self.departure.descAndDir;
        case kSectionTrips:
            return NSLocalizedString(@"Remaining trips before arrival:", @"section title");
        case kSectionInfo:
            return self.departure.fullSign;
        case kRowSectionVehicle:
            return NSLocalizedString(@"Vehicle info:", @"section title");
        case kSectionRowLocation:
            return [NSString stringWithFormat:NSLocalizedString(@"Vehicle is %@ away", @"distance that the vehicle is away"),[FormatDistance formatFeet:self.departure.blockPositionFeet]];
            
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowMapAndSchedule:
            [self showRouteSchedule:self.departure.route];
            [self clearSelection];
            break;
        case kRowBrowse:
            [self showStops:self.departure.route];
            break;
        case kRowMapWithStops:
            [self showMapWithStops:YES];
            break;
        default:
            break;
        case kRowOpposite:
        {
            DepartureTimesView *opposite = [DepartureTimesView viewController];
            opposite.callback = self.callback;
            [opposite fetchTimesForStopInOtherDirectionAsync:self.backgroundTask departure:self.departure];
            break;
        }
        case kRowNoDeeper:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case kRowAlarm:
        {
            // Create a an alert
            AlarmViewMinutes *alertViewMins = [AlarmViewMinutes viewController];
            alertViewMins.dep = self.departure;
            
            [self.navigationController pushViewController:alertViewMins animated:YES];
            break;
        }
        case kRowDestArrival:
        {
            StopView *stopViewController = [StopView viewController];
            
            stopViewController.callback = self.callback;
            
            [stopViewController fetchDestinationsAsync:self.backgroundTask dep:self.departure ];
            break;
        }
        case kRowNextStops:
        {
            if (self.departure.trips!=nil)
            {
                [[DepartureTimesView viewController]  fetchTimesForVehicleAsync:self.backgroundTask
                                                                            route:nil
                                                                        direction:nil
                                                                          nextLoc:nil
                                                                            block:nil
                                                                  targetDeparture:self.departure];
            }
            break;
        }
        case kSectionRowDetour:
        {
            Detour *det = [self detourForRow:[self sectionType:indexPath.section] indexPath:indexPath];
            [self detourToggle:det indexPath:indexPath reloadSection:NO];
            break;
        }
        case kSectionRowLocation:
            [self showMap:nil];
            break;
        case kRowTag:
            if ([[BlockColorDb sharedInstance] colorForBlock:self.departure.block] !=nil)
            {
                [[BlockColorDb sharedInstance] addColor:nil forBlock:self.departure.block description:nil];
                [self favesChanged];
                [self reloadData];
                if (_delegate)
                {
                    [_delegate detailsChanged];
                }
            }
            else
            {
                InfColorPickerController* picker = [ InfColorPickerController colorPickerViewController ];
                
                picker.delegate = self;
                
                picker.sourceColor = [self randomColor];
                
                
                [ picker presentModallyOverViewController: self ];
            }
            break;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowRouteName:
        case kRowTrip:
            return DEPARTURE_CELL_HEIGHT;
        case kRowMapAndSchedule:
        case kRowMapWithStops:
        case kRowBrowse:
        case kRowDestArrival:
        case kRowNextStops:
        case kRowAlarm:
        case kRowTag:
        case kRowFullSign:
        case kRowOpposite:
        case kRowNoDeeper:
        case kSectionRowLocation:
            return [self basicRowHeight];
        case kRowRouteTimeInfo:
        case kRowSectionVehicle:
        case kSectionRowDisclaimerType:
        case kSectionRowDetour:
            return UITableViewAutomaticDimension;
        case kRowMap:
            return [self mapCellHeight];
    }
    
    return 0.0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    NSInteger sectionType = [self sectionType:section];
    
    if (sectionType != kSectionSystemAlert)
    {
        header.textLabel.adjustsFontSizeToFitWidth = YES;
        header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    }
    else
    {
        header.textLabel.adjustsFontSizeToFitWidth = NO;
    }
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

#pragma mark View functions 

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark TableViewWithToolbar functions

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    // match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
    bool needSpace = NO;

    if (self.departure.hasBlock)
    {
        [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
        needSpace = YES;
    }
    
    if ([UserPrefs sharedInstance].ticketAppIcon)
    {
        if (needSpace)
        {
            [toolbarItems addObject:[UIToolbar flexSpace]];
        }
        [toolbarItems addObject:[self ticketAppButton]];
        needSpace = YES;
    }
    
    if ([UserPrefs sharedInstance].debugXML)
    {
        if (needSpace)
        {
            [toolbarItems addObject:[UIToolbar flexSpace]];
        }
        [toolbarItems addObject:[self debugXmlButton]];
    }
    
    
    
    [toolbarItems addObject:[UIToolbar flexSpace]];
    
    UIBarButtonItem *magnifyButton = [[UIBarButtonItem alloc] initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
                                                                      style:(UIBarButtonItemStyle)UIBarButtonItemStylePlain
                                                                     target:self action:@selector(showBig:)];
    
    magnifyButton.accessibilityHint = NSLocalizedString(@"Bus line indentifier", @"accessibilty hint");
    
    TOOLBAR_PLACEHOLDER(magnifyButton, @"mag");
    
    [toolbarItems addObject:magnifyButton];
    
    [self maybeAddFlashButtonWithSpace:needSpace buttons:toolbarItems big:NO];
    
}

#pragma mark Stop callback function

- (NSString *)actionText
{
    return NSLocalizedString(@"Show arrivals", @"menu item");
}

- (void)chosenStop:(Stop*)stop progress:(id<BackgroundTaskController>) progress
{
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:stop.locid];
}

- (void)refreshAction:(id)unused
{
    if (!self.backgroundTask.running)
    {
        [super refreshAction:nil];
        self.backgroundRefresh = YES;
        [self fetchDepartureAsync:self.backgroundTask dep:nil allDepartures:nil backgroundRefresh:YES];
    }
}


-(void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    
    if (self.backgroundRefresh && !cancelled)
    {
        
    }
    
    [super backgroundTaskDone:viewController cancelled:cancelled];
}



- (void)displayLinkFired:(id)sender
{
    if (self.mapView)
    {
    
        double difference = ABS(self.previousHeading - self.mapView.camera.heading);
    
        if (difference < .001)
            return;
    
        self.previousHeading = self.mapView.camera.heading;
    
        [self updateAnnotations:self.mapView];
    }
}

- (void)countDownTimer
{
    if (self.indexPathOfLocationCell && self.table)
    {
        // If the  cell is not visable we will not update it this time. It
        // will get updated in a second anyway.
        
        // It crashes here a lot according to the logs, so this may also
        // protect against the exception.
        
        if ([self.table cellForRowAtIndexPath:self.indexPathOfLocationCell]!=nil)
        {
            [self.table reloadRowsAtIndexPaths:@[self.indexPathOfLocationCell]
                              withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

@end


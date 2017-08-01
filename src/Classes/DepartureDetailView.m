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
#include "CellLabel.h"
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
#import "TriMetRouteColors.h"
#import "BearingAnnotationView.h"
#import "XMLLocateVehicles.h"
#import "FormatDistance.h"
#import "VehicleData+iOSUI.h"
#import "DetourData+iOSUI.h"

#define kFontName					@"Arial"
#define kTextViewFontSize			16.0

#define kBlockRowFeet				0
#define kCellIdSimple               @"Simple"

enum SECTIONS_AND_ROWS
{
    kSectionRoute,
    kSectionTrips,
    kSectionInfo,

    kRowFullSign,
    kRowRouteName,
    kRowRouteTimeInfo,
    kRowDetour,
    kRowLocation,
    kRowMap,
    kRowTag,
    kRowAlarm,
    kRowDestArrival,
    kRowOneStop,
    kRowMapAndSchedule,
    kRowBrowse,
    kRowMapWithStops,
    kRowTrip,
    kRowOpposite,
    kRowNoDeeper
};

@implementation DepartureDetailView

@synthesize departure                   = _departure;
@synthesize detours                     = _detours;
@synthesize stops                       = _stops;
@synthesize allDepartures               = _allDepartures;
@synthesize delegate                    = _delegate;
@synthesize allowBrowseForDestination   = _allowBrowseForDestination;
@synthesize previousHeading             = _previousHeading;
@synthesize displayLink                 = _displayLink;
@synthesize indexPathOfLocationCell     = _indexPathOfLocationCell;




- (void)dealloc {
    
    self.departure = nil;
    self.detours   = nil;
    self.allDepartures = nil;
    
    if (self.displayLink)
    {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
    self.stops = nil;
    self.indexPathOfLocationCell = nil;
    
	[super dealloc];
}

- (instancetype)init
{
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Details", @"Departure details screen title");
	}
	return self;
}

#pragma mark Data fetchers

- (void)workerToFetchData:(id)unused
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	int total = 0;
    int items = 0;
    
	NSSet *streetcarRoutes = nil;
    
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
    
        if (self.departure.detour)
        {
            total++;
        }
    
        if (self.departure.nextBusFeedInTriMetData && self.allDepartures!=nil && self.departure.status == kStatusEstimated)
        {
            streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.allDepartures];
            total += streetcarRoutes.count * 2;
        }
        else if (self.departure.nextBusFeedInTriMetData)
        {
            streetcarRoutes = [NSSet setWithObject:self.departure.route];
            total += 2;
        }
    }
	
    [self.backgroundTask.callbackWhenFetching backgroundStart:total title:NSLocalizedString(@"getting details", @"Progress indication")];
	
    if (self.backgroundRefresh || self.departure.route == nil)
    {
        XMLDepartures *newDep = [XMLDepartures xml];
        
        [newDep getDeparturesForLocation:self.departure.locid block:self.departure.block];
        
        items++;
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
        
        if (newDep.gotData && newDep.count > 0)
        {
            DepartureData *oldDep = [self.departure retain];
            self.departure = newDep.itemArray.firstObject;
            self.departure.streetcarId = oldDep.streetcarId;
            
            if (oldDep.route==nil)
            {
                streetcarRoutes = [NSSet setWithObject:self.departure.route];
            }
            [oldDep release];
        }
        else
        {
            [self.departure makeInvalid:newDep.queryTime];
        }
        
        if (self.departure.detour)
        {
            total++;
        }
        
        if (self.departure.blockPosition == nil && self.departure.status == kStatusEstimated)
        {
            total++;
        }
        
        [self.backgroundTask.callbackWhenFetching backgroundItems:total];
    }
  
    
	if (self.departure.detour)
	{
        self.detours = [XMLDetours xml];
	    [self.detours getDetoursForRoute:self.departure.route];
        
        items++;
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
        
	}
    
	
	if (self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil && self.departure.status == kStatusEstimated)
	{
        for (NSString *route in streetcarRoutes)
        {            
            if (self.departure.streetcarId == nil)
            {
            
                // First get the arrivals via next bus to see if we can get the correct vehicle ID
                // Not using auto release pool
                XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
            
                [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", route,self.departure.locid]];
                
                for (DepartureData *vehicle in streetcarArrivals)
                {                
                    if ([vehicle.block isEqualToString:self.departure.block])
                    {
                        self.departure.streetcarId = vehicle.streetcarId;
                        break;
                    }
                }
            
                [streetcarArrivals release];
            }
            
            items++;
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
            
            XMLStreetcarLocations *locs = [XMLStreetcarLocations singletonForRoute:route];
            [locs getLocations];
            
            items++;
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
        }
        
        if (self.allDepartures != nil)
        {
            [XMLStreetcarLocations insertLocationsIntoDepartureArray:self.allDepartures forRoutes:streetcarRoutes];
        }
        
        XMLStreetcarLocations *locs = [XMLStreetcarLocations singletonForRoute:self.departure.route];
        [locs insertLocation:self.departure];

        
		self.allDepartures = nil;

		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
	}
    else if (!self.departure.nextBusFeedInTriMetData && self.departure.blockPosition == nil && self.departure.status == kStatusEstimated
                && [UserPrefs singleton].useBetaVehicleLocator)
    {
        XMLLocateVehicles *vehicles = [XMLLocateVehicles xml];
        
        [vehicles findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:self.departure.block]];
         
         if (vehicles.count > 0)
         {
             VehicleData *data = vehicles.itemArray.firstObject;
             
             [self.departure insertLocation:data];
         }
        
        
    }
	
    [self updateSections];
    
    if (!self.departure.routeName)
    {
        [[NSThread currentThread] cancel];
        [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:@"No arrival found - it has already departed."];
    }
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)updateSections
{
    
    [self clearSectionMaps];
    
    [self addSectionType:kSectionRoute];
    
    if (![self.departure.fullSign isEqualToString:self.departure.routeName])
    {
        [self addRowType:kRowFullSign];
    }
    
    [self addRowType:kRowRouteName];
    
    
    [self addRowType:kRowRouteTimeInfo];
    
    if (self.departure.hasBlock && self.departure.blockPosition!=nil)
    {
        [self addRowType:kRowLocation];
        [self addRowType:kRowMap];
    }
    
    if (self.departure.detour)
    {
        _firstDetourRow = [self rowsInSection:kSectionRoute];
        
        for (int i=0; i<self.detours.count; i++)
        {
            [self addRowType:kRowDetour];
        }
    }

    
    if (self.departure.block !=nil)
    {
        [self addRowType:kRowTag];
    }
  
    if (self.departure.block && [AlarmTaskList supported] && self.departure.secondsToArrival > 0)
    {
        [self addRowType:kRowAlarm];
    }
    
    // On refresh the allowDest may be NO but that's cause we don't know
    if (self.allowBrowseForDestination)
    {
        [self addRowType:kRowDestArrival];
    }
    
    if ([DepartureTimesView canGoDeeper])
    {
        [self addRowType:kRowOpposite];
    }
    else
    {
        [self addRowType:kRowNoDeeper];
    }
    
    [self addSectionType:kSectionInfo];
    [self addRowType:kRowMapAndSchedule];
    [self addRowType:kRowBrowse];
    [self addRowType:kRowMapWithStops];

    

    if (self.departure.trips.count > 0 && [UserPrefs singleton].showTrips)
    {
        [self addSectionType:kSectionTrips];
        
        
        for (int i=0; i<self.departure.trips.count; i++)
        {
            [self addRowType:kRowTrip];
        }
    }
    
    
    [self addRowType:kSectionRowDisclaimerType];
}

- (void)fetchDepartureAsync:(id<BackgroundTaskProgress>) callback location:(NSString *)loc block:(NSString *)block
{
    self.departure = [DepartureData data];
    self.departure.locid = loc;
    self.departure.block = block;
    
    self.backgroundTask.callbackWhenFetching = callback;
    
    [NSThread detachNewThreadSelector:@selector(workerToFetchData:) toTarget:self withObject:nil];
}

- (void)fetchDepartureAsync:(id<BackgroundTaskProgress>) callback dep:(DepartureData *)dep allDepartures:(NSArray*)deps
{
    if (!self.backgroundRefresh)
    {
        self.departure = dep;
        self.allDepartures = deps;
    }
    
		
    if (dep.detour || (dep.streetcar && dep.blockPosition==nil) || self.backgroundRefresh)
	{
		self.backgroundTask.callbackWhenFetching = callback;
        
		[NSThread detachNewThreadSelector:@selector(workerToFetchData:) toTarget:self withObject:nil];
	}
	else if (!self.backgroundRefresh)
    {
        [self updateSections];
        
        if (self.backgroundTask.callbackWhenFetching == nil)
        {
            [callback backgroundCompleted:self];
        }
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
    [[BlockColorDb singleton] addColor:controller.resultColor
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
	pin.pinTitle = self.departure.routeName;
    if (self.departure.blockPositionFeet>0)
    {
        pin.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ away", @"<distance> of vehicle"), [FormatDistance formatFeet:self.departure.blockPositionFeet]];
    }
    pin.pinColor = MKPinAnnotationColorPurple;
    pin.pinTint = [TriMetRouteColors colorForRoute:self.departure.route];
    pin.pinSubTint = [[BlockColorDb singleton] colorForBlock:self.departure.block];
    
	[mapPage addPin:pin];
	
	
    SimpleAnnotation *stopPin = [SimpleAnnotation annotation];
	stopPin.coordinate = self.departure.stopLocation.coordinate;
	stopPin.pinTitle = self.departure.locationDesc;
	stopPin.pinSubtitle = nil;
	stopPin.pinColor = MKPinAnnotationColorRed;
	[mapPage addPin:stopPin];
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return [self sections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsInSection:section];
}

- (NSString *)detourText:(Detour *)det
{
	return [NSString stringWithFormat:NSLocalizedString(@"Detour: %@", @"detour text"), det.detourDesc];
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if ([self rowType:indexPath] == kRowTag)
    {
        [self.navigationController pushViewController:[BlockColorViewController viewController] animated:YES];
    }
}

- (UITableViewCell *)basicCell:(UITableView *)tableView identifier:(NSString*)ident text:(NSString*)text image:(UIImage *)image indexPath:(NSIndexPath*)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident] autorelease];
        cell.textLabel.font = self.basicFont;;
    }
    
    cell.textLabel.text = text;
    cell.imageView.image  = image;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor grayColor];
    
    
    [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType     = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowFullSign:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kRowFullSign)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowFullSign)] autorelease];
                cell.textLabel.font = self.basicFont;
                cell.textLabel.textColor = [UIColor blackColor];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.imageView.image = nil;
            cell.textLabel.text = self.departure.fullSign;
            
            return cell;
        }
            
        case kRowRouteName:
        {
            NSString *cellId = [self.departure cellReuseIdentifier:MakeCellId(kRowRouteName) width:self.screenInfo.appWinWidth];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
            if (cell == nil) {
                cell = [self.departure bigTableviewCellWithReuseIdentifier:cellId
                                                                  width:self.screenInfo.screenWidth];
            }
            [self.departure populateCell:cell decorate:NO busName:YES wide:NO];
            
            
            //NSString *newVoiceOver = [NSString stringWithFormat:@"%@, %@", self.departure.locationDesc, [cell accessibilityLabel]];
            //[cell setAccessibilityLabel:newVoiceOver];
            return cell;
        }
            
        case kRowRouteTimeInfo:
        {
            CellLabel *labelCell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kRowRouteTimeInfo)];
            if (labelCell == nil) {
                labelCell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowRouteTimeInfo)] autorelease];
                labelCell.view = [Detour create_UITextView:self.paragraphFont];
                
            }
            NSString *details = nil;
            UIColor *color = nil;
            
            [self.departure getExplaination:&color details:&details];
            
            labelCell.view.text = details;
            labelCell.view.textColor = color;
            
            labelCell.accessibilityLabel = details;
            
            labelCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return labelCell;
            break;
        }
            
        case kRowLocation:
        {
            UITableViewCell *cell = nil;
            
            NSString *cellId = [self.departure cellReuseIdentifier:MakeCellId(kRowLocation) width:self.screenInfo.screenWidth];
            cell = [tableView dequeueReusableCellWithIdentifier: cellId];
            
            if (cell == nil) {
                cell = [self.departure tableviewCellWithReuseIdentifier:cellId
                                                        spaceToDecorate:YES
                                                                  width:self.screenInfo.screenWidth];
            }
            NSString *feet = nil;
            
            feet = [NSString stringWithFormat:NSLocalizedString(@"%@ away", @"distance that the vehicle is away"),[FormatDistance formatFeet:self.departure.blockPositionFeet]];
            
            
            NSString *lastSeen = [VehicleData locatedSomeTimeAgo:TriMetToNSDate(self.departure.blockPositionAt)];
            
            
            [self.departure populateCellGeneric:cell
                                          first:feet
                                         second:lastSeen
                                           col1:[UIColor blueColor]
                                           col2:[UIColor blueColor]];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            self.indexPathOfLocationCell = indexPath;
            return cell;
        }
        case kRowTag:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kRowTag)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowTag)] autorelease];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.font = self.basicFont;
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = [UIColor grayColor];
            }
            cell.imageView.image = nil;
            
            UIColor * color = [[BlockColorDb singleton] colorForBlock:self.departure.block];
            if (color == nil)
            {
                cell.textLabel.text = NSLocalizedString(@"Tag this vehicle with a color", @"menu item");
                cell.imageView.image = [BlockColorDb imageWithColor:[UIColor grayColor]];
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Remove vehicle color tag", @"menu item");
                cell.imageView.image = [BlockColorDb imageWithColor:color];
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                
            }
            
            return cell;
        }
        case kRowDetour:
        {
            
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kRowDetour)];
            if (cell == nil) {
                cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowDetour)] autorelease];
                cell.view = [Detour create_UITextView:self.paragraphFont];
                
            }
            
            if (self.detours.detour !=nil)
            {
                Detour *det = self.detours[indexPath.row-_firstDetourRow];
                cell.view.text = [self detourText:det];
                cell.view.textColor = [UIColor orangeColor];
                
                cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
                                             det.routeDesc, det.detourDesc];
            }
            else
            {
                cell.view.text = NSLocalizedString(@"Detour information not known.", @"error message");
            }
            
            
            if ([DepartureTimesView canGoDeeper])
            {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            else
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
            return cell;
        }
        case kRowTrip:
        {
            NSString *cellId = [self.departure cellReuseIdentifier:MakeCellId(kRowTrip) width:self.screenInfo.screenWidth];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
            
            if (cell == nil) {
                cell = [self.departure tableviewCellWithReuseIdentifier:cellId spaceToDecorate:NO
                                                               width:self.screenInfo.screenWidth];
            }
            [self.departure populateTripCell:cell item:indexPath.row];
            [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
            return cell;
        }
        case kSectionRowDisclaimerType:
        {
            UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
            if (cell == nil) {
                cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
            }
            
            NSDateFormatter *dateFormatter = [NSDateFormatter alloc].init.autorelease;
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterMediumStyle;
            NSDate *queryTime = TriMetToNSDate(self.departure.queryTime);
            
            if (self.departure.block !=nil)
            {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"(Trip ID %@) Updated: %@", @"infomation at the end of the arrivals"),
                                                         self.departure.block,
                                                         [dateFormatter stringFromDate:queryTime]]];
            }
            else {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"Updated: %@", @"infomation at the end of the arrivals"),
                                                         [dateFormatter stringFromDate:queryTime]]];
            }
            
            [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            if (self.departure.streetcar && self.departure.copyright !=nil)
            {
                [self addStreetcarTextToDisclaimerCell:cell  text:self.departure.copyright trimetDisclaimer:YES];
            }
            
            return cell;
        }
        case kRowMapWithStops:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Map with route stops", @"menu item")
                             image:[self getActionIcon:kIconEarthMap]
                         indexPath:indexPath];
        case kRowOpposite:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Arrivals going the other way", @"menu item")
                             image:[self getActionIcon:kIconArrivals]
                         indexPath:indexPath];
        case kRowNoDeeper:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Too many windows open", @"menu item")
                             image:[self getActionIcon:kIconCancel]
                         indexPath:indexPath];
            
        case kRowBrowse:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Browse stops", @"menu item")
                             image:[self getActionIcon:kIconBrowse]
                         indexPath:indexPath];
            
            
        case kRowMapAndSchedule:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Map & schedule page", @"menu item")
                             image:[self getActionIcon:kIconLink]
                         indexPath:indexPath];
            
            
        case kRowDestArrival:
            return [self basicCell:tableView
                        identifier:kCellIdSimple
                              text:NSLocalizedString(@"Browse for destination arrival time", @"menu item")
                             image:[self getActionIcon:kIconArrivals]
                         indexPath:indexPath];
        case kRowAlarm:
            
        {
            AlarmTaskList *taskList = [AlarmTaskList singleton];
            
            if ([taskList hasTaskForStopId:self.departure.locid block:self.departure.block])
            {
                return [self basicCell:tableView
                            identifier:kCellIdSimple
                                  text:NSLocalizedString(@"Edit arrival alarm", @"menu item")
                                 image:[self getActionIcon:kIconAlarm]
                             indexPath:indexPath];
                
                
            }
            else {
                
                return [self basicCell:tableView
                            identifier:kCellIdSimple
                                  text:NSLocalizedString(@"Set arrival alarm", @"menu item")
                                 image:[self getActionIcon:kIconAlarm]
                             indexPath:indexPath];
                
                
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
            annotLoc.pinColor = MKPinAnnotationColorRed;
            annotLoc.coordinate = self.departure.stopLocation.coordinate;
            
            [map addAnnotation:annotLoc];
            [map addAnnotation:self.departure];
            
            DEBUG_LOGLU(map.annotations.count);
            
          //  [map addAnnotation:annotBus];
#if 0
            if (0)//[map respondsToSelector:@selector(showAnnotations:animated:)])
            {
                NSArray *annots = @[ui, annotLoc];
                
                [map showAnnotations:annots animated:YES];
            }
            else
#endif
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSInteger sectionType = [self sectionType:section];
    
    switch (sectionType)
    {
        case kSectionRoute:
            return self.departure.descAndDir;
        case kSectionTrips:
            return NSLocalizedString(@"Remaining trips before arrival:", @"section title");
        case kSectionInfo:
            return NSLocalizedString(@"Route info:", @"section title");
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
        case kRowLocation:
            [self showMap:nil];
            break;
        case kRowTag:
            if ([[BlockColorDb singleton] colorForBlock:self.departure.block] !=nil)
            {
                [[BlockColorDb singleton] addColor:nil forBlock:self.departure.block description:nil];
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
        case kRowDetour:
            
            if (self.detours.detour !=nil)
            {
                Detour *detour = self.detours[indexPath.row-_firstDetourRow];
                [self showStops:detour.route];
            }
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowMapAndSchedule:
        case kRowMapWithStops:
        case kRowBrowse:
        case kRowDestArrival:
        case kRowAlarm:
        case kRowTag:
        case kRowFullSign:
        case kRowOpposite:
        case kRowNoDeeper:
            return 35.0;
        case kRowRouteName:
        case kRowTrip:
        case kRowLocation:
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                return kWideDepartureCellHeight;
            }
            else {
                return kDepartureCellHeight;
            }
        case kRowRouteTimeInfo:
        {
            NSString *details = nil;
            UIColor *color = nil;
            
            [self.departure getExplaination:&color details:&details];
            
            return [self getTextHeight:details font:self.paragraphFont];
            
        }
        case kRowDetour:
        {
            Detour *det = self.detours[indexPath.row - _firstDetourRow];
            return [self getTextHeight:[self detourText:det] font:self.paragraphFont];
            // return [Detour getTextHeight:[det detourDesc]];
        }
        case kSectionRowDisclaimerType:
            return kDepartureCellHeight;
        case kRowMap:
            return [self mapCellHeight];
    }
    
    return 0.0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
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
        [toolbarItems addObject:[UIToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
        needSpace = YES;
    }
    
    if ([UserPrefs singleton].ticketAppIcon)
    {
        if (needSpace)
        {
            [toolbarItems addObject:[UIToolbar autoFlexSpace]];
        }
        [toolbarItems addObject:[self autoTicketAppButton]];
        needSpace = YES;
    }
    
    
    
    [toolbarItems addObject:[UIToolbar autoFlexSpace]];
    
    UIBarButtonItem *magnifyButton = [[UIBarButtonItem alloc] initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
                                                                      style:(UIBarButtonItemStyle)UIBarButtonItemStylePlain
                                                                     target:self action:@selector(showBig:)];
    
    magnifyButton.accessibilityHint = NSLocalizedString(@"Bus line indentifier", @"accessibilty hint");
    
    [toolbarItems addObject:magnifyButton];
    
    [self maybeAddFlashButtonWithSpace:needSpace buttons:toolbarItems big:NO];
    
}

#pragma mark Stop callback function

- (NSString *)actionText
{
	return NSLocalizedString(@"Show arrivals", @"menu item");
}

- (void)chosenStop:(Stop*)stop progress:(id<BackgroundTaskProgress>) progress
{
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
		
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:stop.locid];
}

- (void)refresh
{
    [self stopLoading];
    [self refreshAction:nil];
}

- (void)refreshAction:(id)unused
{
    [super refreshAction:nil];
    self.backgroundRefresh = YES;
    [self fetchDepartureAsync:self.backgroundTask dep:nil allDepartures:nil];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ([UserPrefs singleton].shakeToRefresh && event.type == UIEventSubtypeMotionShake) {
        UIViewController * top = self.navigationController.visibleViewController;
        
        if ([top respondsToSelector:@selector(refreshAction:)])
        {
            [top performSelector:@selector(refreshAction:) withObject:nil];
        }
    }
}

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    
    if (self.backgroundRefresh && !cancelled)
    {
        
    }
    
    [super BackgroundTaskDone:viewController cancelled:cancelled];
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *retView = nil;
    
    if (annotation == mv.userLocation)
    {
        return nil;
    }
    else if ([annotation conformsToProtocol:@protocol(MapPinColor)])
    {
        retView = [BearingAnnotationView viewForPin:(id<MapPinColor>)annotation mapView:mv];
    
        retView.canShowCallout = YES;
        
    }
    return retView;
}


- (void)updateAnnotations:(MKMapView *)map
{
    if (map)
    {
        for (id <MKAnnotation> annotation in map.annotations)
        {
            MKAnnotationView *av = [map viewForAnnotation:annotation];
        
            if (av && [av isKindOfClass:[BearingAnnotationView class]])
            {
                BearingAnnotationView *bv = (BearingAnnotationView*)av;
            
                [bv updateDirectionalAnnotationView:map];
            
            }
        }
    }
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


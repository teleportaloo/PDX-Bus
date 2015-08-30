//
//  ArrivalDetail.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureDetailView.h"
#import "DepartureUI.h"
#import "CellTextView.h"
#import "XMLDetour.h"
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

#define kRouteSection				0


#define kFontName					@"Arial"
#define kTextViewFontSize			16.0

#define kBlockRowFeet				0
#define kDepartureDetailsCellId		@"DepDetails"
#define kLocationId					@"Loc"
#define kTripDetailsCellId			@"Trip"

#define kWebId						@"WebId"
#define kColId						@"ColId"

#define kWebAlerts					4 // not used 
#define kWebInfo					0
#define kWebStops					1
#define kWebMap                     2
#define kWebRows					3
#define kWebRowsShort				1


#define kDestBrowseRow				0
#define kDestFilterRow				1

#define kDestAlarm					0

#define kRouteName                  0
#define kRouteColor                 1
#define kRouteRows                  2


@implementation DepartureDetailView

@synthesize departure = _departure;
@synthesize detourData = _detourData;
@synthesize stops = _stops;
@synthesize allDepartures = _allDepartures;
@synthesize delegate    = _delegate;

- (void)dealloc {
	self.departure = nil;
	self.detourData = nil;
	self.allDepartures = nil;
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Details", @"Departure details screen title");
	}
	return self;
}

#pragma mark Data fetchers

- (void)fetchData:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int items = 0;
	NSSet *streetcarRoutes = nil;
    
	if (self.departure.detour)
	{
		items++;
	}
	
	if (self.departure.nextBusFeedInTriMetData && self.allDepartures!=nil && self.departure.status == kStatusEstimated)
	{
		streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.allDepartures];
        items += streetcarRoutes.count * 2;
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:items title:NSLocalizedString(@"getting details", @"Progress indication")];
	
    items = 0;
    
	if (self.departure.detour)
	{
		NSError *parseError = nil;
		self.detourData = [[[XMLDetour alloc] init] autorelease];
	    [self.detourData getDetourForRoute:self.departure.route parseError:&parseError];
		
        items++;
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
        
	}
	
	if (self.departure.nextBusFeedInTriMetData && self.departure.blockPositionLat == nil && self.departure.status == kStatusEstimated)
	{
        for (NSString *route in streetcarRoutes)
        {
            NSError *parseError = nil;
            
            if (self.departure.streetcarId == nil)
            {
            
                // First get the arrivals via next bus to see if we can get the correct vehicle ID
                XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
            
                NSError *error = nil;
            
                [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", route,self.departure.locid]
                                     parseError:&error];
            
                for (NSInteger i=0; i< streetcarArrivals.safeItemCount; i++)
                {
                    DepartureData *vehicle = [streetcarArrivals itemAtIndex:i];
                
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
            
            XMLStreetcarLocations *locs = [XMLStreetcarLocations getSingletonForRoute:route];
            [locs getLocations:&parseError];
            
            items++;
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
        }
            
		[XMLStreetcarLocations insertLocationsIntoDepartureArray:self.allDepartures forRoutes:streetcarRoutes];
        
		self.allDepartures = nil;

		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback dep:(DepartureData *)dep allDepartures:(NSArray*)deps allowDestination:(BOOL)allowDest
{
	self.departure = dep;
	self.allDepartures = deps;
	sections = 1;
	
	if ([dep detour] || (dep.streetcar && dep.blockPositionLat==nil))
	{
		if ([dep detour])
		{
			detourSection = sections;
			sections++;
		}
		else {
			detourSection = -1;
		}
		
		self.backgroundTask.callbackWhenFetching = callback;
		
		[NSThread detachNewThreadSelector:@selector(fetchData:) toTarget:self withObject:nil];
	}
	else
	{
		detourSection = -1;
	}
	
	if (self.departure.hasBlock)
	{
		locationSection = sections;
		sections++;
	}
	else {
		locationSection = -1;
	}
    
    if (self.departure.block !=nil)
    {
        highlightSection = sections;
        sections ++;
    }
    else
    {
        highlightSection = -1;
    }
        
	
	if (dep.block && [AlarmTaskList supported] && dep.secondsToArrival > 0)
	{
		alertSection = sections;
		sections ++;
	}
	else {
		alertSection = -1;
	}
	
	if (allowDest)
	{
		destinationSection = sections;
		sections ++;
	}
	else
	{
		destinationSection = -1;
	}
	
	if ([dep.trips count] > 0)
	{
		tripSection = sections;
		sections ++;
	}
	else 
	{
		tripSection = -1;
	}
	
	webSection = sections;
	sections++;
	
	
	
	disclaimerSection = sections;
	sections++;
	
	if (self.backgroundTask.callbackWhenFetching == nil)
	{
		[callback backgroundCompleted:self];
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
    [[BlockColorDb getSingleton] addColor:controller.resultColor
                                 forBlock:self.departure.block
                              description:self.departure.description];
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (_delegate)
    {
        [_delegate detailsChanged];
    }
    [self reloadData];
}

- (void)showStops:(NSString *)route
{
	if ([DepartureTimesView canGoDeeper])
	{
		// Detour *detour = [self.detourData itemAtIndex:indexPath.row];
		DirectionView *directionViewController = [[DirectionView alloc] init];
		
		// directionViewController.route = [detour route];
		[directionViewController fetchDirectionsInBackground:self.backgroundTask route:route];
		[directionViewController release];	
	}
	
}

-(void)showMapWithStops:(bool)withStops
{
    MapViewWithStops *mapPage = [[MapViewWithStops alloc] init];
	SimpleAnnotation *pin = [[[SimpleAnnotation alloc] init] autorelease];
	mapPage.title = self.departure.fullSign;
	mapPage.callback = self.callback;
	[pin setCoordinateLat:self.departure.blockPositionLat lng:self.departure.blockPositionLng ];
	pin.pinTitle = [self.departure routeName];
	pin.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ away", @"<distance> of vehicle"), [self.departure formatDistance:self.departure.blockPositionFeet]];
	pin.pinColor = MKPinAnnotationColorPurple;
	[mapPage addPin:pin];
	
	
	SimpleAnnotation *stopPin = [[[SimpleAnnotation alloc] init] autorelease];
	[stopPin setCoordinateLat:self.departure.stopLat lng:self.departure.stopLng ];
	stopPin.pinTitle = self.departure.locationDesc;
	stopPin.pinSubtitle = nil;
	stopPin.pinColor = MKPinAnnotationColorRed;
	[mapPage addPin:stopPin];
    
    if (withStops)
    {
        [mapPage fetchStopsInBackground:self.backgroundTask route:self.departure.route  direction:self.departure.dir returnStop:self];
    }
    else
    {
        [[self navigationController] pushViewController:mapPage animated:YES];
    }
	[mapPage release];

}

-(void)showMap:(id)sender
{
	[self showMapWithStops:NO];
}


-(void)showBig:(id)sender
{
	BigRouteView *bigPage = [[BigRouteView alloc] init];
	
	bigPage.departure = self.departure;
	
	[[self navigationController] pushViewController:bigPage animated:YES];
	[bigPage release];
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kRouteSection)
	{
		return kRouteRows;
	}
	
	if (section == locationSection)
	{
		return 1;
	}
    
    if (section == highlightSection)
	{
		return 1;
	}
	
	if (section == alertSection)
	{
		return 1;
	}
	
	if (section == destinationSection)
	{
		if (self.stops == nil)
		{
			return 1;
		}
		return 2;
	}
	
	if (section == webSection)
	{
		if ([DepartureTimesView canGoDeeper])
		{
			return kWebRows;
		}
		else
		{
			return kWebRowsShort;
		}
	}
	if (section == detourSection)
	{
		return [self.detourData safeItemCount];
	}
	if (section == tripSection)
	{
		return [self.departure.trips count];
	}	
	if (section ==  disclaimerSection)
	{
		return 1;
	}
	return 0;
}

- (NSString *)detourText:(Detour *)det
{
	return [NSString stringWithFormat:NSLocalizedString(@"Detour: %@", @"detour text"), [det detourDesc]];
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == highlightSection)
    {
        BlockColorViewController *blockTable = [[BlockColorViewController alloc] init];
        [[self navigationController] pushViewController:blockTable animated:YES];
        [blockTable release];
    }
}

static NSString *detourId = @"detour";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == kRouteSection)
	{
        UITableViewCell *cell = nil;
        
        switch (indexPath.row)
        {
            case kRouteName:
            {
                DepartureUI *departureUI = [DepartureUI createFromData:self.departure];
                
                NSString *cellId = [departureUI cellReuseIdentifier:kDepartureCellId width:[self screenWidth]];
                cell = [tableView dequeueReusableCellWithIdentifier: cellId];
                if (cell == nil) {
                    cell = [departureUI tableviewCellWithReuseIdentifier:cellId
                                                            spaceToDecorate:NO
                                                                      width:[self screenWidth]];
                }
                [departureUI populateCell:cell decorate:NO big:NO busName:YES wide:NO];
                
                
                //NSString *newVoiceOver = [NSString stringWithFormat:@"%@, %@", self.departure.locationDesc, [cell accessibilityLabel]];
                //[cell setAccessibilityLabel:newVoiceOver];
                return cell;
                break;
            }
            case kRouteColor:
            {
                CellLabel *labelCell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:detourId];
                if (labelCell == nil) {
                    labelCell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:detourId] autorelease];
                    labelCell.view = [Detour create_UITextView:[self getParagraphFont]];
                    
                }
                NSString *details = nil;
                UIColor *color = nil;
                
                DepartureUI *departureUI = [DepartureUI createFromData:self.departure];
                
                [departureUI getExplaination:&color details:&details];
                
                labelCell.view.text = details;
                labelCell.view.textColor = color;
                
                [labelCell setAccessibilityLabel:details];
                
                labelCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                cell = labelCell;
                break;
            }
        }
		return cell;
	}
	else if (indexPath.section == locationSection)
	{
        UITableViewCell *cell = nil;
        DepartureUI * departureUI = [DepartureUI createFromData:self.departure];
		
        NSString *cellId = [departureUI cellReuseIdentifier:kLocationId width:[self screenWidth]];
        cell = [tableView dequeueReusableCellWithIdentifier: cellId];
		
        if (cell == nil) {
            cell = [departureUI tableviewCellWithReuseIdentifier:cellId
                                                    spaceToDecorate:YES
                                                              width:[self screenWidth]];
        }
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		
        [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        NSDate *lastPosition = [NSDate dateWithTimeIntervalSince1970: self.departure.blockPositionAt / 1000];
		
        [departureUI    populateCellGeneric:cell
                                      first:[NSString stringWithFormat:NSLocalizedString(@"Last known location at %@", @"the time of the vehicle location"), [dateFormatter stringFromDate:lastPosition]]
                                     second:[NSString stringWithFormat:NSLocalizedString(@"%@ away", @"distance that the vehicle is away"),[self.departure formatDistance:self.departure.blockPositionFeet]]
                                       col1:[UIColor blueColor]
                                       col2:[UIColor blueColor]];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    else if (indexPath.section == highlightSection)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kColId];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kColId] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [self getBasicFont];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
        }
        cell.imageView.image = nil;
        
        UIColor * color = [[BlockColorDb getSingleton] colorForBlock:self.departure.block];
        if (color == nil)
        {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.text = NSLocalizedString(@"Tag this vehicle with a color", @"menu item");
            cell.imageView.image = [BlockColorDb imageWithColor:[UIColor grayColor]];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        else
        {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.text = NSLocalizedString(@"Remove vehicle color tag", @"menu item");
            cell.imageView.image = [BlockColorDb imageWithColor:color];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            
        }
        
        return cell;
	}
	else if (indexPath.section == detourSection)
	{
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:detourId];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:detourId] autorelease];
			cell.view = [Detour create_UITextView:[self getParagraphFont]];
									
		}
			
		if (self.detourData.detour !=nil)
		{
			Detour *det = [self.detourData itemAtIndex:indexPath.row];
			cell.view.text = [self detourText:det];
			cell.view.textColor = [UIColor orangeColor];
			
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@",
										 [det routeDesc], [det detourDesc]]];
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
	else if (indexPath.section == tripSection)
	{
        DepartureUI * departureUI = [DepartureUI createFromData:self.departure];
        
		NSString *cellId = [departureUI cellReuseIdentifier:kDepartureCellId width:[self screenWidth]];
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
		
		if (cell == nil) {
			cell = [departureUI tableviewCellWithReuseIdentifier:cellId spaceToDecorate:NO
															  width:[self screenWidth]];
		}
		[departureUI populateTripCell:cell item:indexPath.row];
		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
		return cell;
	}
	else if (indexPath.section == disclaimerSection)
	{
		UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
		if (cell == nil) {
			cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
		}
		
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		NSDate *queryTime = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.departure.queryTime)]; 
		
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
	else if (indexPath.section == webSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];;
		}	
		
		switch (indexPath.row)
		{
		case kWebAlerts:
				cell.textLabel.text = NSLocalizedString(@"Route alerts", @"menu item");
				cell.imageView.image = [self getActionIcon:kIconAlerts];
				break;
		case kWebInfo:
				cell.textLabel.text = NSLocalizedString(@"Map & schedule", @"menu item");
				cell.imageView.image = [self getActionIcon:kIconEarthMap];
				break;
		case kWebStops:
				cell.textLabel.text = NSLocalizedString(@"Browse stops", @"menu item");
				cell.imageView.image = [self getActionIcon:kIconBrowse];
				break;
        case kWebMap:
				cell.textLabel.text = NSLocalizedString(@"Show map with route stops", @"menu item");
				cell.imageView.image = [self getActionIcon:kIconMap];
				break;
		}
		[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
		return cell;
	}
	else if (indexPath.section == destinationSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.textColor = [UIColor grayColor];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
		}
		
		switch (indexPath.row)
		{
			case kDestBrowseRow:
				cell.textLabel.text = NSLocalizedString(@"Browse for destination arrival time", @"menu item");
				break;
			case kDestFilterRow:
				cell.textLabel.text = NSLocalizedString(@"Show arrivals with just this trip", @"menu item");
				break;
		}
		return cell;
	}
	else if (indexPath.section == alertSection)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWebId];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebId] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.textColor = [UIColor grayColor];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
		}
		
		switch (indexPath.row)
		{
			case kDestAlarm:
			{
				AlarmTaskList *taskList = [AlarmTaskList getSingleton];
				
				if ([taskList hasTaskForStopId:self.departure.locid block:self.departure.block])
				{
					cell.textLabel.text = NSLocalizedString(@"Edit arrival alarm", @"menu item");
				}
				else {
					cell.textLabel.text = NSLocalizedString(@"Set arrival alarm", @"menu item");
				}
				cell.imageView.image = [self getActionIcon:kIconAlarm];
				break;
			}
		}
		return cell;
	}
	
	// Configure the cell
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == kRouteSection)
	{
		return self.departure.locationDesc;
	}
	if (section == tripSection)
	{
		return NSLocalizedString(@"Remaining trips before arrival:", @"section title");
	}
	if (section == webSection)
	{
		return NSLocalizedString(@"Route info:", @"section title");
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == webSection)
	{
			switch (indexPath.row) {
				case kWebAlerts:
					[self showRouteAlerts:self.departure.route fullSign:self.departure.fullSign];
					break;
				case kWebInfo:
				    [self showRouteSchedule:self.departure.route];
                    [self clearSelection];
					break;
				case kWebStops:
					[self showStops:self.departure.route];
					break;
                case kWebMap:
					[self showMapWithStops:YES];
					break;
				default:
					break;
			}
	}
	else if (indexPath.section == alertSection)
	{
		switch (indexPath.row)
		{
			case kDestAlarm:
			{
				// Create a an alert
				AlarmViewMinutes *alertViewMins = [[[AlarmViewMinutes alloc] init] autorelease];
				alertViewMins.dep = self.departure;
				
				[[self navigationController] pushViewController:alertViewMins animated:YES];
				break;
				
			}
		}
	}
	else if (indexPath.section == destinationSection)
	{
		switch (indexPath.row)
		{
			case kDestBrowseRow:
			{
				StopView *stopViewController = [[StopView alloc] init];
				
				stopViewController.callback = self.callback;
				
				[stopViewController fetchDestinationsInBackground:self.backgroundTask dep:self.departure ];
				[stopViewController release];	
				break;
			}
			case kDestFilterRow:
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				
				departureViewController.callback = self.callback;
				
				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:self.stops block:self.departure.block];
				
				[departureViewController release];
				break;
				
			}
		}
	}
	else if (indexPath.section == locationSection)
	{
		[self showMap:nil];
	}
    else if (indexPath.section == highlightSection)
    {
        
        if ([[BlockColorDb getSingleton] colorForBlock:self.departure.block] !=nil)
        {
            [[BlockColorDb getSingleton] addColor:nil forBlock:self.departure.block description:nil];
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
            
    }
	else if (indexPath.section == detourSection)
	{
		if (self.detourData.detour !=nil)
		{
			Detour *detour = [self.detourData itemAtIndex:indexPath.row];
			[self showStops:detour.route];
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;
	
	if (indexPath.section == webSection)
	{
		return 35.0;
	}
	else if (indexPath.section == destinationSection)
	{
		return 35.0;
	}
	else if (indexPath.section == alertSection || indexPath.section == highlightSection)
	{
		return 35.0;
	}
	else if ((indexPath.section == kRouteSection && indexPath.row == kRouteName) || indexPath.section == tripSection || indexPath.section == locationSection)
	{
		if (LargeScreenStyle([self screenWidth]))
		{
			return kWideDepartureCellHeight;
		}
		else {
			return kDepartureCellHeight;
		}
	}
    else if (indexPath.section == kRouteSection && indexPath.row == kRouteColor)
    {
        NSString *details = nil;
        UIColor *color = nil;
        
        [[DepartureUI createFromData:self.departure] getExplaination:&color details:&details];
        
        return [self getTextHeight:details font:[self getParagraphFont]];

    }
    else if (indexPath.section == detourSection)
	{		
		Detour *det = [self.detourData itemAtIndex:indexPath.row];
		return [self getTextHeight:[self detourText:det] font:[self getParagraphFont]];
		// return [Detour getTextHeight:[det detourDesc]];
	}
	else if (indexPath.section == disclaimerSection)
	{
		return kDepartureCellHeight;
	}
	
	return result;
}

#pragma mark View functions 

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	UIBarButtonItem *magnifyButton = [[UIBarButtonItem alloc] initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
																	  style:(UIBarButtonItemStyle)UIBarButtonItemStyleBordered 
																	 target:self action:@selector(showBig:)];

	magnifyButton.accessibilityHint = NSLocalizedString(@"Bus line indentifier", @"accessibilty hint");
	self.navigationItem.rightBarButtonItem = magnifyButton;

    [magnifyButton release];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self reloadData];
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
        [toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
        needSpace = YES;
    }
    
    if ([UserPrefs getSingleton].ticketAppIcon)
    {
        if (needSpace)
        {
            [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        }
        [toolbarItems addObject:[self autoTicketAppButton]];
        needSpace = YES;
    }
    
    [self maybeAddFlashButtonWithSpace:needSpace buttons:toolbarItems big:NO];
}

#pragma mark Stop callback function

- (NSString *)actionText
{
	return NSLocalizedString(@"Show arrivals", @"menu item");
}

- (void)chosenStop:(Stop*)stop progress:(id<BackgroundTaskProgress>) progress
{
	DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
    departureViewController.displayName = stop.desc;
    [departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:stop.locid];
		
    [departureViewController release];
}


@end


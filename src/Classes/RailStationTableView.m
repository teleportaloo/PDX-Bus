//
//  RailStationTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStationTableView.h"
#import "DepartureTimesView.h"
#import "WebViewController.h"
#import "SimpleAnnotation.h"
#import "MapViewController.h"
#import "RailMapView.h"
#import "AllRailStationView.h"
#import "TriMetRouteColors.h"
#import "DirectionView.h"
#import "AlarmTaskList.h"
#import "TripPlannerSummaryView.h"
#import "FindByLocationView.h"



@implementation RailStationTableView

@synthesize station			= _station;
@synthesize from			= _from;
@synthesize locationsDb		= _locationsDb;
@synthesize map				= _map;
@synthesize routes			= _routes;

#define kSections				5
#define kSectionsProximity		6

#define kStation				0
#define kStops					1
#define kTripPlanner            2
#define kWikiLink				4
#define kRouteSection			3
#define kProximitySection		5    

#define kDirectionCellHeight	45.0
#define DIRECTION_TAG			1
#define ID_TAG					2

#define kRowWikiLink			0

#define kRowTripToHere          0
#define kRowTripFromHere        1

- (void)dealloc {
	self.locationsDb = nil;
	self.station = nil;
	self.map = nil;
	self.routes = nil;
    [_sectionMap release];
	[super dealloc];
}


- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Station Details";
		
		_rowNearby = -1;
		_rowShowAll = -1;
		_rowOffset = 0;
	}
	return self;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle) getStyle
{
	return UITableViewStylePlain;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{	
	[toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
    
    
	if (self.map != nil)
	{
		[toolbarItems addObject: [[[UIBarButtonItem alloc]
				   initWithTitle:@"Next" style:UIBarButtonItemStyleBordered 
				   target:self action:@selector(showNext:)] autorelease]];
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
	}
	
	
    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AlarmTaskList *taskList = [AlarmTaskList getSingleton];
	NSString *stopId = [self.station.locList objectAtIndex:0];
	CLLocation *here = [self.locationsDb getLocation:stopId];
	
	
	
	[taskList userAlertForProximityAction:buttonIndex 
								   stopId:stopId 
									  lat:[NSString stringWithFormat:@"%f", here.coordinate.latitude] 
									  lng:[NSString stringWithFormat:@"%f", here.coordinate.longitude] 
									 desc:self.station.station];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)addLineToRoutes:(RAILLINES)line
{
	if (self.station.line & line) 
	{
		[self.routes addObject:[NSNumber numberWithInt:line]];
	}
}


- (void)viewDidLoad
{
	// Workout if we have any routes
	
	self.routes = [[[NSMutableArray alloc] init] autorelease];

	
	[self addLineToRoutes:kBlueLine];
	[self addLineToRoutes:kRedLine];
	[self addLineToRoutes:kGreenLine];
	[self addLineToRoutes:kYellowLine];
	[self addLineToRoutes:kStreetcarNsLine];
    [self addLineToRoutes:kStreetcarClLine];
	[self addLineToRoutes:kWesLine];
}

#pragma mark UI helper functions

- (UITableViewCell *)plainCell:(UITableView *)tableView
{
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.font = [self getBasicFont];
	
	return cell;
	
}

-(void)showMap:(id)sender
{
	if (self.locationsDb.isEmpty)
	{
		[self noLocations:@"Show on map" delegate:self];
	}
	else {
		
		int i;
		CLLocation *here;
		
		MapViewController *mapPage = [[MapViewController alloc] init];
		
		for (i=0; i< [self.station.locList count];  i++)
		{
			here = [self.locationsDb getLocation:[self.station.locList objectAtIndex:i]];
			
			if (here)
			{
				Stop *a = [[[Stop alloc] init] autorelease];
				
				a.locid = [self.station.locList objectAtIndex:i];
				a.desc  = self.station.station;
				a.dir   = [self.station.dirList objectAtIndex:i];
				a.lat   = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
				a.lng   = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
				a.callback = self;
			
				[mapPage addPin:a];
			}
		}
		mapPage.callback = self.callback;
		[[self navigationController] pushViewController:mapPage animated:YES];
		[mapPage release];	
	}
	
}

-(void)showNext:(id)sender
{
    self.map.showNextOnAppearance = YES;
	[[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSNumber * sect = [_sectionMap objectAtIndex:section];
	switch (sect.intValue)
    {
		case kRouteSection:
			if (self.routes.count==0)
			{
				return nil;
			}
			return @"Routes";
		case kStation:
			return nil;
        case kTripPlanner:
            return @"Trip Planner";
		case kStops:
			
			if (self.callback)
			{
				return @"Stops";
			}
			return @"Arrivals";
		case kWikiLink:
			if (self.station.wikiLink == nil)
			{
				return nil;
			}
			return @"More Information";
		case kProximitySection:
			return @"Alarms";
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (_sectionMap == nil)
    {
        _sectionMap = [[NSMutableArray alloc] init];
        
        [_sectionMap addObject:  [NSNumber numberWithInt:kStation] ];
        [_sectionMap addObject:  [NSNumber numberWithInt:kStops]   ];
        
        if (self.callback ==nil)
        {
          [_sectionMap addObject:  [NSNumber numberWithInt:kTripPlanner]   ];  
        }
        
        [_sectionMap addObject:  [NSNumber numberWithInt:kWikiLink]   ];
        [_sectionMap addObject:  [NSNumber numberWithInt:kRouteSection]   ];
        
        if ([AlarmTaskList proximitySupported])
        {
           [_sectionMap addObject:  [NSNumber numberWithInt:kProximitySection]   ]; 
        }
        
    }
	
    return _sectionMap.count;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSNumber * sect = [_sectionMap objectAtIndex:section];
	switch (sect.intValue)
	{
        case kTripPlanner:
            return 2;
		case kStation:
		case kProximitySection:
			return 1;
		case kStops:
			_rows = [self.station.locList count];
			if (_rows > 1 && self.callback == nil)
			{
				_rowShowAll = 0;
				_rowOffset = 1;
				_rows++;
			}
			else {
				_rowOffset = 0;
			}

			
			if (self.callback == nil)
			{
				_rowNearby = _rows;
				_rows++;
			}
			return _rows;
		case kWikiLink:
			if (self.station.wikiLink != nil)
			{
				return 1;
			}
			break;
		case kRouteSection:
			return self.routes.count;
	}
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    NSNumber * sect = [_sectionMap objectAtIndex:indexPath.section];
	switch (sect.intValue)
	{
		case kStation:
		{
			NSString *cellId = [NSString stringWithFormat:@"station%d", [self screenWidth]];
			cell = [tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:cellId 
														   rowHeight:[self basicRowHeight] 
														 screenWidth:[self screenWidth]
														 rightMargin:NO
																font:[self getBasicFont]];
				
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
			}
			
			
			// cell = [self plainCell:tableView];
			//cell.textLabel.text =  self.station.station;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.imageView.image = nil;
			//cell.textLabel.textAlignment = UITextAlignmentCenter;
			
			
			[RailStation populateCell:cell 
							  station:self.station.station
								lines:[AllRailStationView railLines:self.station.index]];
			
			break;
		}
        case kTripPlanner:
            cell = [self plainCell:tableView];
            
            if (indexPath.row == kRowTripFromHere)
            {
                cell.textLabel.text = @"Plan trip from here";
            }
            else {
                cell.textLabel.text = @"Plan trip to here";
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconTripPlanner];
            break;
            
		case kStops:
			if (indexPath.row == _rowShowAll)
			{
				cell = [self plainCell:tableView];
				cell.textLabel.text = @"All arrivals";
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.imageView.image = [self getActionIcon:kIconRecent];
			}
			else if ((indexPath.row-_rowOffset) < [self.station.dirList count])
			{
				cell = [self plainCell:tableView];
				// cell = [self directionCellWithReuseIdentifier:@"dcell"];
				
				cell.textLabel.text = [NSString stringWithFormat:@"%@ (ID %@)", [self.station.dirList objectAtIndex:indexPath.row-_rowOffset]
									   ,[self.station.locList objectAtIndex:indexPath.row-_rowOffset]];
				
				
				
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.imageView.image = [self getActionIcon:kIconRecent];
			}
			else if (indexPath.row == _rowNearby)
			{
				cell = [self plainCell:tableView];
				cell.textLabel.text = @"Nearby stops";
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];

            }
			break;
		case kWikiLink:
			switch (indexPath.row)
			{
				case kRowWikiLink:
					cell = [self plainCell:tableView];
					cell.textLabel.text = @"Wikipedia article";
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconWiki];
					break;
			}
			break;
		case kProximitySection:
			cell = [self plainCell:tableView];
			cell.textLabel.text = kUserProximityCellText;
			cell.imageView.image = [self getActionIcon:kIconAlarm];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case kRouteSection:
		{
			RAILLINES line = [((NSNumber*)[self.routes objectAtIndex:indexPath.row]) intValue];
			
			NSString *cellId = [NSString stringWithFormat:@"route%d", [self screenWidth]];
			cell = [tableView dequeueReusableCellWithIdentifier:cellId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:cellId 
														   rowHeight:[self basicRowHeight] 
														 screenWidth:[self screenWidth]
														 rightMargin:YES
																font:[self getBasicFont]];
				
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
			}
			
			
			// cell = [self plainCell:tableView];
			//cell.textLabel.text =  self.station.station;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = nil;
			//cell.textLabel.textAlignment = UITextAlignmentCenter;
			
			
			[RailStation populateCell:cell 
							  station:[NSString stringWithFormat:@"%@ info", [TriMetRouteColors rawColorForLine:line]->name]
								lines:line];
			
		}
				
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
    
    NSNumber * sect = [_sectionMap objectAtIndex:indexPath.section];
	switch (sect.intValue)
	{
		case kStation:
			break;
        case kTripPlanner:
        {
            TripPlannerSummaryView *tripPlanner = [[[TripPlannerSummaryView alloc] init] autorelease];
			
			// Push the detail view controller
            
			TripEndPoint *endpoint = nil;
			
			if (indexPath.row == kRowTripFromHere)
			{
				endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
			}
			else 
			{
				endpoint = tripPlanner.tripQuery.userRequest.toPoint;
			}
            
			
			endpoint.useCurrentLocation = false;
			endpoint.additionalInfo     = self.station.station;
			endpoint.locationDesc       = [self.station.locList objectAtIndex:0];
			
			
			[[self navigationController] pushViewController:tripPlanner animated:YES];
			break;
        }
		case kStops:
			if (self.callback)
			{
								
				if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
				{
					[self.callback selectedStop:[self.station.locList objectAtIndex:indexPath.row] desc:self.station.station];
				}
				else 
				{
					[self.callback selectedStop:[self.station.locList objectAtIndex:indexPath.row]];

				}
			}
			else if (indexPath.row == _rowShowAll)
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				
				NSMutableString *locs = [[[NSMutableString alloc] init] autorelease];
				
				int i;
				
				[locs appendString:[self.station.locList objectAtIndex:0]];
				
				for (i=1; i< [self.station.locList count]; i++)
				{
					[locs appendFormat:@",%@", [self.station.locList objectAtIndex:i]];
				}
				
				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:locs];
				[departureViewController release];
			}
			else if ((indexPath.row-_rowOffset) < [self.station.locList count])
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				
				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:[self.station.locList objectAtIndex:indexPath.row-_rowOffset]];
				[departureViewController release];
			}
			
			else if (indexPath.row == _rowNearby)
			{
				CLLocation *here = [self.locationsDb getLocation:[self.station.locList objectAtIndex:0]];
				
				if (here !=nil)
				{                    
                    FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:here description:self.station.station];
                    
                    [[self navigationController] pushViewController:find animated:YES];
                    
                    [find release];
                }
				else 
				{
					UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
																	   message:@"No location info is availble for that stop."
																	  delegate:nil
															 cancelButtonTitle:@"OK"
															 otherButtonTitles:nil] autorelease];
					[alert show];
					
				}
			}
			break;
		case kWikiLink:
		{
			switch (indexPath.row)
			{
				case kRowWikiLink:
				{
					WebViewController *webPage = [[WebViewController alloc] init];
					
					[webPage setURLmobile:[NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki/%@", self.station.wikiLink ] 
									 full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", self.station.wikiLink ]];
					
					
					if (self.callback)
					{
						webPage.whenDone = [self.callback getController];
					}
                    
                    [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
					
					[webPage release];
					break;
				}
			}
			break;
			
		}
		case kProximitySection:
		{
			AlarmTaskList *taskList = [AlarmTaskList getSingleton];
			[taskList userAlertForProximity:self];
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
			break;
		}
		case kRouteSection:
		{
			RAILLINES line = [((NSNumber*)[self.routes objectAtIndex:indexPath.row]) intValue];
			NSString *route = [TriMetRouteColors rawColorForLine:line]->route;
			
			DirectionView *dirView = [[DirectionView alloc] init];
			dirView.callback = self.callback;
			[dirView fetchDirectionsInBackground:self.backgroundTask route:route];
			[dirView release];
			break;
		}
			

			
	}
	
}


#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress
{
	if (self.callback)
	{
		/*
		 if ([self.callback getController] != nil)
		 {
		 [[self navigationController] popToViewController:[self.callback getController] animated:YES];
		 }
		 */		
		if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
		{
			[self.callback selectedStop:stop.locid desc:self.station.station];
		}
		else {
			[self.callback selectedStop:stop.locid];
		}

		
		return;
	}
	
	DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
	
	departureViewController.displayName = stop.desc;
	
	[departureViewController fetchTimesForLocationInBackground:progress loc:stop.locid];
	[departureViewController release];
	
}

- (NSString *)actionText
{
	if (self.callback)
	{
		return [self.callback actionText];
	}
	return @"Show arrivals";
	
}

@end


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
#import "Departure.h"
#import "MapViewController.h"
#import "RailStation.h"
#import "TriMetRouteColors.h"


#define kGettingStops @"getting stops"

#define kRouteNameSection  0
#define kStopSection	   1
#define kTimePointSection  2
#define kDisclaimerSection 3

@implementation StopView

@synthesize stopData = _stopData;
@synthesize departure = _departure;
@synthesize directionName = _directionName;

- (void)dealloc {
	self.stopData = nil;
	self.departure = nil;
	self.directionName = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Stops";
		self.enableSearch = YES;
	}
	return self;
}

#pragma mark TableViewWithToolbar methods


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	// add a segmented control to the button bar
	UISegmentedControl	*buttonBarSegmentedControl;
	buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
								 [NSArray arrayWithObjects:@"Line", @"A-Z" , nil]];
	[buttonBarSegmentedControl addTarget:self action:@selector(toggleSort:) forControlEvents:UIControlEventValueChanged];
	buttonBarSegmentedControl.selectedSegmentIndex = 0.0;	// start by showing the normal picker
	buttonBarSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [self setSegColor:buttonBarSegmentedControl];
	
	UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];	
	
	
	[toolbarItems addObjectsFromArray:[NSMutableArray arrayWithObjects:
					  [CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)],
					  [CustomToolbar autoFlexSpace],
					  segItem,
                       nil]];
    
    if ([UserPrefs getSingleton].debugXML)
    {
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
		[toolbarItems addObject:[self autoXmlButton]];
    }
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    
	[segItem release];
	[buttonBarSegmentedControl release];
	
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.stopData appendQueryAndData:buffer];
}

#pragma mark Data fetchers

- (void)fetchDestinations:(Departure*) dep
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingStops];
	
	NSError *parseError = nil;
	[self.stopData getStopsAfterLocation:dep.locid route:dep.route direction:dep.dir 
							 description:dep.routeName parseError:&parseError cacheAction:TriMetXMLUpdateCache];	
	self.departure = dep;
	self.title = @"Destinations";
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)fetchDestinationsInBackground:(id<BackgroundTaskProgress>) callback dep:(Departure*) dep
{
	
	self.backgroundTask.callbackWhenFetching = callback;
	
	self.stopData = [[[XMLStops alloc] init] autorelease];

	
	NSError *parseError = nil;
	if (!self.backgroundRefresh && [self.stopData getStopsAfterLocation:dep.locid route:dep.route direction:dep.dir 
															description:dep.routeName parseError:&parseError cacheAction:TriMetXMLOnlyReadFromCache])
	{
		self.departure = dep;
		self.title = @"Destinations";

		[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	}
	else 
	{
		[NSThread detachNewThreadSelector:@selector(fetchDestinations:) toTarget:self withObject:dep];
	}
	
	
}

- (void)fetchStops:(NSArray*) args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingStops];

	
    NSString *routeid = [args objectAtIndex:0];
	NSString *dir     = [args objectAtIndex:1];
	NSString *desc    = [args objectAtIndex:2];
	
	
	NSError *parseError = nil;
	
	[self.stopData getStopsForRoute:routeid 
						  direction:dir 
						description:desc 
						 parseError:&parseError 
						cacheAction:TriMetXMLUpdateCache];	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];

	[pool release];
}


- (void)fetchStopsInBackground:(id<BackgroundTaskProgress>) callback route:(NSString*) routeid direction:(NSString*)dir description:(NSString *)desc
																directionName:(NSString *)dirName
{
	self.backgroundTask.callbackWhenFetching = callback;
	self.stopData = [[[XMLStops alloc] init] autorelease];
	self.directionName = dirName;
	
	NSError *parseError = nil;
	if (!self.backgroundRefresh && [self.stopData getStopsForRoute:routeid 
														 direction:dir 
													   description:desc 
														parseError:&parseError 
													   cacheAction:TriMetXMLOnlyReadFromCache])
	{
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	}
	else 
	{
		id args[] = {routeid, dir, desc };	
		
		[NSThread detachNewThreadSelector:@selector(fetchStops:) 
								 toTarget:self 
							   withObject:[NSArray arrayWithObjects:args count:sizeof(args)/sizeof(id)]];

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
		case kTimePointSection:
			return [self basicRowHeight];
			break;
		case kDisclaimerSection:
			return kDisclaimerCellHeight;
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
			return 1;
		case kTimePointSection:
			return 1;
	}
	return 0;
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{

	// Configure the cell
	UITableViewCell *cell = nil;
	
	switch (indexPath.section) 
	{
		case kRouteNameSection:
		{
			NSString *stopId = [NSString stringWithFormat:@"stop%d", [self screenWidth]];
			
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
														   rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:[self screenWidth]
														 rightMargin:NO
																font:[self getBasicFont]];
				
			}
			ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.stopData.routeId];
			[RailStation populateCell:cell 
							  station:self.stopData.routeDescription
								lines:col ? col->line : 0];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		}	
		case kStopSection:
		{
			
			NSArray *items = [self filteredData:tableView];
			Stop *stop = [items objectAtIndex:indexPath.row];	
			if (stop.tp)
			{
				static NSString *stopTpId = @"StopTP";
				
				cell = [tableView dequeueReusableCellWithIdentifier:stopTpId];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:stopTpId] autorelease];
					if (self.callback == nil || [self.callback getController] == nil)
					{
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					else
					{
						cell.accessoryType = UITableViewCellAccessoryNone;
					}
					/*
					 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					
					cell.textLabel.font =  [self getSmallFont];
					cell.textLabel.textColor = [UIColor blueColor];
				}
			}
			else
			{
				static NSString *stopId = @"Stop";
				cell = [tableView dequeueReusableCellWithIdentifier:stopId];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:stopId] autorelease];
					if (self.callback == nil || [self.callback getController] == nil)
					{
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					else
					{
						cell.accessoryType = UITableViewCellAccessoryNone;
					}
					
					/*
					 [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					cell.textLabel.font =  [self getSmallFont];
					cell.textLabel.textColor = [UIColor blackColor];
				}
			}
			cell.textLabel.text = [stop desc];
			break;
			
		}
		case kDisclaimerSection:
			cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
			if (cell == nil) {
				cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
			}
			
			if (self.stopData.itemArray == nil)
			{
				[self noNetworkDisclaimerCell:cell];
			}
			else
			{
				[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"%@", 
														 [self.stopData displayDate:self.stopData.cacheTime]]];	
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			break;
		case kTimePointSection:
		{
			static NSString *tpId = @"tp";
			cell = [tableView dequeueReusableCellWithIdentifier:tpId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tpId] autorelease];
			}
			
			
			
			/*
			 [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
			 */
			cell.textLabel.font =			[self getSmallFont];
			cell.textLabel.textColor =		[UIColor orangeColor];
			cell.textLabel.text =			@"Blue stops are \'Time Points\', touch for info";
			break;
		}
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	switch (section) 
	{
		case kRouteNameSection:
			break;
		case kStopSection:
		{
			if (self.directionName!=nil)
			{
				return self.directionName;
			}
			return @"Desination stops:";
		}
		case kDisclaimerSection:
			break;
	}
	return nil;
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
				if (self.stopData.itemArray == nil)
				{
					[self networkTips:self.stopData.htmlError networkError:self.stopData.errorMsg];
                    [self clearSelection];
				}
				return;
			}
			
			[self chosenStop:[items objectAtIndex:indexPath.row] progress:self.backgroundTask];
		}
		case kDisclaimerSection:
			if (self.stopData.itemArray == nil)
			{
				[self networkTips:self.stopData.htmlError networkError:self.stopData.errorMsg];
			}
			break;
		case kTimePointSection:
		{
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Blue stops are 'Time Points'"
															   message:@"One of several stops on each route that serves as a benchmark for whether a trip is running on time."	
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil ] autorelease];
			[alert show];
            
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            
			break;
			
		}
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

- (void)chosenStop:(Stop*)stop progress:(id<BackgroundTaskProgress>) progress
{
	if (self.callback)
	{
		/*
		 if ([self.callback getController] != nil)
		 {
		 [[self navigationController] popToViewController:[self.callback getController] animated:YES];
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
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
		departureViewController.displayName = stop.desc;
		
		[departureViewController fetchTimesForLocationInBackground:progress 
															   loc:stop.locid
															 title:stop.desc];
		[departureViewController release];
	}
	else
	{
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
		departureViewController.displayName = stop.desc;
		[departureViewController fetchTimesForBlockInBackground:progress block:self.departure.block start:self.departure.locid stop:stop.locid];
		
		[departureViewController release];
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
	
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	self.searchableItems = self.stopData.itemArray;
	[refreshButton release];
	[self reloadData];
	

	[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
				atScrollPosition:UITableViewScrollPositionTop 
						animated:NO];

}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
	NSString *direction = self.stopData.direction;
	NSString *routeId = self.stopData.routeId;
	NSString *routeDescription = self.stopData.routeDescription;
	
	[routeDescription retain];
	[direction retain];
	[routeId retain];
	
	self.backgroundRefresh = YES;
	[self fetchStopsInBackground:self.backgroundTask route:routeId direction:direction description:routeDescription
				   directionName:self.directionName];
	[routeDescription release];
	[direction release];
	[routeId release];
}

-(void)showMap:(id)sender
{
	NSMutableArray *items = [self topViewData];
	MapViewController *mapPage = [[MapViewController alloc] init];
	mapPage.callback = self.callback;
	mapPage.annotations = items;
	mapPage.title = self.stopData.routeDescription;
	

	for (int i=0; items!=nil && i< items.count; i++)
	{
		Stop *p = [items objectAtIndex:i];
		
		p.callback = self;
	}
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];
}



- (void)toggleSort:(id)sender
{
	UISegmentedControl *segControl = sender;
	
	if (self.stopData.itemArray == nil)
	{
		return;
	}
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	// UIPickerView
		{
			[self.stopData.itemArray sortUsingSelector:@selector(compareUsingIndex:)];
			[self reloadData];
			break;
		}
		case 1:	// UIPickerView
		{
			[self.stopData.itemArray sortUsingSelector:@selector(compareUsingStopName:)];
			[self reloadData];
			break;
		}
	}
}



@end


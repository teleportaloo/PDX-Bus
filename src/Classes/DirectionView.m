//
//  DirectionView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DirectionView.h"
#import "StopView.h"
#import "DetoursView.h"
#import "RailStation.h"
#import "TriMetRouteColors.h"
#import "WebViewController.h"
#import "DebugLogging.h"

@implementation DirectionView

@synthesize route = _route;
@synthesize directionKeys = _directionKeys;
@synthesize directionData = _directionData;
@synthesize routeId = _routeId;

#define kSectionName		0
#define kSectionDirection   1
#define kSectionDisclaimer  3
#define kSectionOther		2
#define kDirectionId		@"Direction"
#define kOtherRowDetours    0
#define kOtherRowMap		1
#define kOtherRowWiki		2

- (void)dealloc {
	self.route = nil;
	self.routeId = nil;
	self.directionKeys = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Route Info", @"screen title");
	}
	return self;
}

#pragma mark Data fetchers

- (void)fetchDirections:(NSString *)route
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.routeId = route;
    [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:NSLocalizedString(@"getting directions", @"progress message")];
	
	[self.directionData getDirections:route cacheAction:TriMetXMLForceFetchAndUpdateCache];
 	
	if ([self.directionData safeItemCount] > 0)
	{
		self.route = [self.directionData itemAtIndex:0];
	}	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)fetchDirectionsInBackground:(id<BackgroundTaskProgress>) callback route:(NSString *)route
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	self.directionData = [[[XMLRoutes alloc] init] autorelease];
	
	if (!self.backgroundRefresh && [self.directionData getDirections:route cacheAction:TriMetXMLCheckCache])
	{
		if ([self.directionData safeItemCount] > 0)
		{
			self.route = [self.directionData itemAtIndex:0];
		}
		
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	}
	else 
	{
		[NSThread detachNewThreadSelector:@selector(fetchDirections:) toTarget:self withObject:route];

	}
}


#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
	NSString *route = self.routeId;
	
	[route retain];	
	self.backgroundRefresh = YES;
	[self fetchDirectionsInBackground:self.backgroundTask route:route]; 
	[route release];
}
	 
#pragma mark TableView callbacks
	 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}
	

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	
	switch (section)
	{
		case kSectionName:
		{
			return 1;
			break;
		}	
		case kSectionDirection:
		{
			if (self.route)
			{
				return [self.route.directions count];
			}
			break;
		}			
		case kSectionDisclaimer:
		{
			return 1;
			break;
		}
		case kSectionOther:
		{
			if (self.route)
			{
				ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.route.route];
				if (col==nil || col->wiki == nil)
				{
					return 2;
				}
				return 3;
			} 
			break;
		}
	}	
	
	return 0;
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	switch (indexPath.section)
	{
		case kSectionName:
		{
			NSString *stopId = [NSString stringWithFormat:@"stop%d", self.screenInfo.screenWidth];
			
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
														   rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:self.screenInfo.screenWidth
														 rightMargin:NO
																font:[self getBasicFont]];
				
			}
			ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.route.route];
			[RailStation populateCell:cell 
							  station:self.route.desc
								lines:col ? col->line : 0];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			//	DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
			//				  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
			break;
		}
		case kSectionDirection:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kDirectionId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDirectionId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			
			if ([self directionKeys] == nil)
			{
				self.directionKeys = [self.route.directions keysSortedByValueUsingSelector:@selector(compare:)];
			}
			cell.textLabel.textColor = [UIColor blackColor];
			cell.textLabel.text = [self.route.directions objectForKey:[self.directionKeys objectAtIndex:indexPath.row]];
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			break;
		}			
		case kSectionDisclaimer:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
			if (cell == nil) {
				cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
			}
			
			if (self.directionData.itemArray == nil)
			{
				[self noNetworkDisclaimerCell:cell];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
				[self addTextToDisclaimerCell:cell text:[self.directionData displayDate:self.directionData.cacheTime]];	
			}
			break;
		}
		case kSectionOther:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kDirectionId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDirectionId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			cell.textLabel.textColor = [UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont];
			switch (indexPath.row)
			{
				case kOtherRowMap:
					cell.textLabel.text = NSLocalizedString(@"Map & schedule page", @"button text");
					cell.imageView.image = [self getActionIcon:kIconEarthMap];
					break;
				case kOtherRowDetours:
					cell.textLabel.text = NSLocalizedString(@"Detours", @"button text");
					cell.imageView.image = [self getActionIcon:kIconDetour];
					break;
				case kOtherRowWiki:
					cell.textLabel.text = NSLocalizedString(@"Wikipedia page", @"Link to English wikipedia page");
					cell.imageView.image = [self getActionIcon:kIconWiki];
					break;
			}
		}	
	}	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.route == nil)
	{
		[self networkTips:self.directionData.htmlError networkError:self.directionData.errorMsg] ;
        [self clearSelection];
		return;
	}
	switch (indexPath.section)
	{
		case kSectionName:
			break;
		case kSectionDirection:
		{
			StopView *stopViewController = [[StopView alloc] init];
			
			NSString *rt = [self.route route];
			NSString *dr = [self.directionKeys objectAtIndex:indexPath.row];
			NSString *rd = [self.route desc];
			
			[stopViewController setCallback:self.callback];
			[stopViewController fetchStopsInBackground:self.backgroundTask route:rt direction:dr 
										   description:rd
										 directionName:[self.route.directions objectForKey:[self.directionKeys objectAtIndex:indexPath.row]]];
			[stopViewController release];	
			break;
		}		
		case kSectionOther:
			switch (indexPath.row)
			{
				case kOtherRowWiki:
				{
					NSString *wiki = [TriMetRouteColors rawColorForRoute:self.route.route]->wiki;
                    
                    [WebViewController displayPage:[NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", wiki]
                                              full:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/%@", wiki ]
                                         navigator:self.navigationController
                                    itemToDeselect:self
                                          whenDone:self.callbackWhenDone];
                    
        
                    break;
				}
				case kOtherRowMap:
					[self showRouteSchedule:[self.route route]];
                    [self clearSelection];
					break;
				case kOtherRowDetours:
				{
					DetoursView *detourView = [[DetoursView alloc] init];
					[detourView fetchDetoursInBackground:self.backgroundTask route:[self.route route]];
					detourView.callback = self.callback;
					[detourView release];
					break;
				}
			}	
			break;
		case kSectionDisclaimer:
		{
			if (self.directionData.itemArray == nil)
			{
				[self networkTips:self.directionData.htmlError networkError:self.directionData.errorMsg] ;
                [self clearSelection];
			}
			break;
		}
	}	
	
	
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.route == nil)
	{
		return nil;
	}
	switch (section)
	{
	case kSectionName:
		return nil;
	case kSectionDirection:
            return NSLocalizedString(@"Directions (touch for stops and map):", @"section title");
	case kSectionOther:
            return NSLocalizedString(@"Additional route info:", @"section title");
	default:
		return nil;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section)
	{
		case kSectionName:
		case kSectionDirection:
		case kSectionOther:
			return [self basicRowHeight];
		case kSectionDisclaimer:
			return kDisclaimerCellHeight;
	}
	return 1;
	
}

#pragma mark View methods

- (void)viewDidLoad {
	[super viewDidLoad];
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"button text")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	
	[self reloadData];
	
	if ([self.route.directions count] > 0)
	{
	
		[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionDirection] 
						  atScrollPosition:UITableViewScrollPositionTop 
								  animated:NO];
	}
	
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark XML debug methods

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void) appendXmlData:(NSMutableData*)buffer
{
    [self.directionData appendQueryAndData:buffer];
}

@end


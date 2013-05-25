//
//  DirectionView.m
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "DirectionView.h"
#import "StopView.h"
#import "DetoursView.h"
#import "RailStation.h"
#import "TriMetRouteColors.h"
#import "WebViewController.h"

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
		self.title = @"Route Info";
	}
	return self;
}

#pragma mark Data fetchers

- (void)fetchDirections:(NSString *)route
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.routeId = route;
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting directions"];
	
	NSError *parseError = nil;
    
	[self.directionData getDirections:route error:&parseError cacheAction:TriMetXMLUpdateCache];
	
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
	
	NSError *parseError = nil;
	if (!self.backgroundRefresh && [self.directionData getDirections:route error:&parseError cacheAction:TriMetXMLOnlyReadFromCache])
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
			NSString *stopId = [NSString stringWithFormat:@"stop%d", [self screenWidth]];
			
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
														   rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:[self screenWidth]
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
					cell.textLabel.text = @"Map & schedule page";
					cell.imageView.image = [self getActionIcon:kIconEarthMap];
					break;
				case kOtherRowDetours:
					cell.textLabel.text = @"Detours";
					cell.imageView.image = [self getActionIcon:kIconDetour];
					break;
				case kOtherRowWiki:
					cell.textLabel.text = @"Wikipedia page";
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
					WebViewController *webPage = [[WebViewController alloc] init];
					
					NSString *wiki = [TriMetRouteColors rawColorForRoute:self.route.route]->wiki;
					
					[webPage setURLmobile:[NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki/%@", wiki ] 
									 full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", wiki ] 
									title:@"Wikipedia"];
					
					if (self.callback)
					{
						webPage.whenDone = [self.callback getController];
					}
					[webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
					[webPage release];
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
		return @"Directions (touch for stops):";
	case kSectionOther:
		return @"Additional route info:";
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
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
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

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark XML debug methods

- (void)createToolbarItems
{
    [self createToolbarItemsWithXml];
}

- (void) appendXmlData:(NSMutableData*)buffer
{
    [self.directionData appendQueryAndData:buffer];
}

@end


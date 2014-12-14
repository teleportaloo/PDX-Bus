//
//  RouteView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RouteView.h"
#import "Route.h"
#import "XMLRoutes.h"
#import "DirectionView.h"
#import "RouteColorBlobView.h"

#define kRouteCellId @"RouteCell"

@implementation RouteView


#define kSectionRoutes	   0
#define kSectionDisclaimer 1
#define kSections		   2


@synthesize routeData = _routeData;

- (void)dealloc {
	self.routeData = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Routes";
		self.enableSearch = YES;
	}
	return self;
}


#pragma mark Data fetchers

- (void)fetchRoutes:(id)arg
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting routes"];
	
	NSError *parseError = nil;
	
	[self.routeData getRoutes:&parseError cacheAction:TriMetXMLUpdateCache];
													   
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)fetchRoutesInBackground:(id<BackgroundTaskProgress>)callback
{	
	self.backgroundTask.callbackWhenFetching = callback;
	self.routeData = [[[XMLRoutes alloc] init] autorelease];

	NSError *parseError = nil;
	if (!self.backgroundRefresh && [self.routeData getRoutes:&parseError cacheAction:TriMetXMLOnlyReadFromCache])
	{
		[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	}
	else 
	{
		[NSThread detachNewThreadSelector:@selector(fetchRoutes:) toTarget:self withObject:nil];
	}
}

#pragma mark Table View methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {	
	switch (section)
	{
		case kSectionRoutes:
		{
			NSArray *items = [self filteredData:tableView];
			return items ? items.count : 0;
		}
		case kSectionDisclaimer:
			return 1;
	}
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case kSectionRoutes:
			return [self basicRowHeight];
		case kSectionDisclaimer:
			return kDisclaimerCellHeight;
	}
	return 1;
	
}

#define COLOR_STRIPE_TAG 1


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	switch (indexPath.section)
	{
	case kSectionRoutes:
		{		
			cell = [tableView dequeueReusableCellWithIdentifier:kRouteCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRouteCellId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				CGRect rect = CGRectMake(0, 0, COLOR_STRIPE_WIDTH, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
				
				RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
				colorStripe.tag = COLOR_STRIPE_TAG;
				[cell.contentView addSubview:colorStripe];
				[colorStripe release];
				
			}
			// Configure the cell
			Route *route = [[self filteredData:tableView] objectAtIndex:indexPath.row];
			
			cell.textLabel.text = route.desc; 
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
			[colorStripe setRouteColor:route.route];
		}
		break;
	case kSectionDisclaimer:
		cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
		if (cell == nil) {
			cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
		}
			
		[self addTextToDisclaimerCell:cell text:[self.routeData displayDate:self.routeData.cacheTime]];	
			
		if (self.routeData.itemArray == nil)
		{
			[self noNetworkDisclaimerCell:cell];
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		break;
	}
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionRoutes:
		{
			DirectionView *directionViewController = [[DirectionView alloc] init];
			Route * route = [[self filteredData:tableView] objectAtIndex:indexPath.row];
			// directionViewController.route = [self.routeData itemAtIndex:indexPath.row];
			[directionViewController setCallback:self.callback];
			[directionViewController fetchDirectionsInBackground:self.backgroundTask route:[route route]];
			[directionViewController release];
			break;
		}
		case kSectionDisclaimer:
		{
			if (self.routeData.itemArray == nil)
			{
				[self networkTips:self.routeData.htmlError networkError:self.routeData.errorMsg];
                [self clearSelection];
			}
			break;
		}
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
	[refreshButton release];
	self.searchableItems = self.routeData.itemArray;
	
	[self reloadData];
	
	if ([self.routeData safeItemCount] > 0)
	{
		[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						  atScrollPosition:UITableViewScrollPositionTop 
								  animated:NO];
	}

	
}

#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
	self.backgroundRefresh = true;
	[self fetchRoutesInBackground:self.backgroundTask];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self updateToolbarItemsWithXml:toolbarItems];
}

-(void) appendXmlData:(NSMutableData *)buffer
{
    [self.routeData appendQueryAndData:buffer];
}

@end


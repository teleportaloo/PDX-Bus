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
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h> 
#import "DebugLogging.h"

@implementation RouteView


#define kSectionRoutes	   0
#define kSectionDisclaimer 1
#define kSections		   2


@synthesize routeData = _routeData;

- (void)dealloc {
	self.routeData = nil;
	[super dealloc];
}

- (instancetype)init {
	if ((self = [super init]))
	{
        self.title = NSLocalizedString(@"Routes", @"page title");
		self.enableSearch = YES;
	}
	return self;
}


#pragma mark Data fetchers

- (void)fetchRoutesAsync:(id<BackgroundTaskProgress>)callback
{	
    self.backgroundTask.callbackWhenFetching = callback;
    self.routeData = [XMLRoutes xml];
    
    if (!self.backgroundRefresh && [self.routeData getRoutesCacheAction:TriMetXMLCheckCache])
    {
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    }
    else
    {
        [self runAsyncOnBackgroundThread:^{
            [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:NSLocalizedString(@"getting routes", @"activity text")];
            
            [self.routeData getRoutesCacheAction:TriMetXMLForceFetchAndUpdateCache];
            
            [self indexRoutes];
            
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
        }];
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
			cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionRoutes)];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionRoutes)] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				CGRect rect = CGRectMake(0, 0, ROUTE_COLOR_WIDTH, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
				
				RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
				colorStripe.tag = COLOR_STRIPE_TAG;
				[cell.contentView addSubview:colorStripe];
				[colorStripe release];
				
			}
			// Configure the cell
			Route *route = [self filteredData:tableView][indexPath.row];
			
			cell.textLabel.text = route.desc; 
			cell.textLabel.font = self.basicFont;
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
			[colorStripe setRouteColor:route.route];
		}
		break;
	case kSectionDisclaimer:
    default:
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
            DirectionView *directionViewController = [DirectionView viewController];
			Route * route = [self filteredData:tableView][indexPath.row];
			// directionViewController.route = [self.routeData itemAtIndex:indexPath.row];
			directionViewController.callback = self.callback;
			[directionViewController fetchDirectionsAsync:self.backgroundTask route:route.route];
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


- (void)indexRoutes
{
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));
    
    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable])
    {
        return;
    }
    
    CSSearchableIndex * searchableIndex = [CSSearchableIndex defaultSearchableIndex];
    
    
    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[@"route"] completionHandler:^(NSError * __nullable error) {
        if (error != nil)
        {
            ERROR_LOG(@"Failed to delete route index %@\n", error.description);
        }
        
        if ([UserPrefs sharedInstance].searchRoutes)
        {
            NSMutableArray *index = [NSMutableArray array];
            
            for (Route *route in self.routeData)
            {
                CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeText];
                attributeSet.title = route.desc;
                
                attributeSet.contentDescription = @"TriMet route";
                
                NSString *uniqueId = [NSString stringWithFormat:@"%@:%@", kSearchItemRoute, route.route];
                
                CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId domainIdentifier:@"route" attributeSet:attributeSet];
                
                [index addObject:item];
                
                [item release];
                [attributeSet release];
            }
            
            [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:index completionHandler: ^(NSError * __nullable error) {
                if (error != nil)
                {
                    ERROR_LOG(@"Failed to create route index %@\n", error.description);
                }
            }];
        }
        
    }];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Add the following line if you want the list to be editable
	// self.navigationItem.leftBarButtonItem = self.editButtonItem;
	// self.title = originalName;
	
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	self.searchableItems = self.routeData.itemArray;
	
	[self reloadData];
	
	if (self.routeData.count > 0)
	{
		[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						  atScrollPosition:UITableViewScrollPositionTop 
								  animated:NO];
	}
}

#pragma mark UI callbacks

- (void)refreshAction:(id)unused
{
	self.backgroundRefresh = true;
	[self fetchRoutesAsync:self.backgroundTask];
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


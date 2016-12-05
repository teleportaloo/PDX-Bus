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
#import "Detour.h"
#import "DetourData+iOSUI.h"

#import "CellLabel.h"

@implementation DirectionView

@synthesize route = _route;
@synthesize directionKeys = _directionKeys;
@synthesize directionData = _directionData;
@synthesize detourData = _detourData;
@synthesize routeId = _routeId;

enum {
    kSectionRowName,
    kSectionRowDirection,
    kSectionOther,
    kSectionRowDetour,
    kSectionRowDisclaimer,
    kOtherRowMap,
    kOtherRowWiki
};

#define kDirectionId		@"Direction"


- (void)dealloc {
	self.route = nil;
	self.routeId = nil;
	self.directionKeys = nil;
    self.detourData = nil;
    self.directionData = nil;
	[super dealloc];
}

- (instancetype)init {
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Route Info", @"screen title");
        _cacheAction = TrIMetXMLCacheReadOrFetch;
	}
	return self;
}

#pragma mark Data fetchers

- (void)workerToFetchDirections:(NSString *)route
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.routeId = route;
    int items = 2;
    
    if (!self.backgroundRefresh && [self.directionData getDirections:route cacheAction:TriMetXMLCheckCache])
    {
        items = 1;
    }
    
    [self.backgroundTask.callbackWhenFetching backgroundStart:items title:NSLocalizedString(@"getting directions", @"progress message")];
	
	[self.directionData getDirections:route cacheAction:_cacheAction];
    
	if (self.directionData.count > 0)
	{
		self.route = self.directionData[0];
	}
    
    if (items > 1)
    {
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
    }
    
    [self.detourData getDetoursForRoute:route];
    
    if (items > 1)
    {
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
    }
    
    [self clearSectionMaps];
    
    [self addSectionType:kSectionRowName];
    [self addRowType:kSectionRowName];
    
    [self addSectionType:kSectionRowDirection];
    
    if (self.route)
    {
        for (int i=0; i < self.route.directions.count; i++)
        {
            [self addRowType:kSectionRowDirection];
        }
    }
    
    [self addSectionType:kSectionOther];
    [self addRowType:kOtherRowMap];
    
    if (self.route)
    {
        const ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.route.route];
        if (col!=nil && col->wiki != nil)
        {
            [self addRowType:kOtherRowWiki];
        }
    }
    
    if (self.detourData.count > 0)
    {
        [self addSectionType:kSectionRowDetour];
        for (int i=0; i < self.detourData.count; i++)
        {
            [self addRowType:kSectionRowDetour];
        }
    }
    
    [self addRowType:kSectionRowDisclaimer];
    
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void)fetchDirectionsAsync:(id<BackgroundTaskProgress>) callback route:(NSString *)route
{
	self.backgroundTask.callbackWhenFetching = callback;
	
    self.directionData = [XMLRoutes xml];
    self.detourData    = [XMLDetours xml];
	
    [NSThread detachNewThreadSelector:@selector(workerToFetchDirections:) toTarget:self withObject:route];
}


#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
	NSString *route = self.routeId;
	
	[route retain];	
	self.backgroundRefresh = YES;
    _cacheAction = TriMetXMLForceFetchAndUpdateCache;
	[self fetchDirectionsAsync:self.backgroundTask route:route]; 
	[route release];
}
	 
#pragma mark TableView callbacks
	 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}
	

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self rowsInSection:section];
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
    
    NSInteger rowType = [self rowType:indexPath];
	
	switch (rowType)
	{
		case kSectionRowName:
        default:
		{
			NSString *stopId = [NSString stringWithFormat:@"stop%d", self.screenInfo.screenWidth];
			
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
				
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
														   rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:self.screenInfo.screenWidth
														 rightMargin:NO
																font:self.basicFont];
				
			}
			const ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.route.route];
			[RailStation populateCell:cell 
							  station:self.route.desc
								lines:col ? col->line : 0];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			//	DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
			//				  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
			break;
		}
		case kSectionRowDirection:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kDirectionId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDirectionId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			
			if (self.directionKeys == nil)
			{
				self.directionKeys = [self.route.directions keysSortedByValueUsingSelector:@selector(compare:)];
			}
			cell.textLabel.textColor = [UIColor blackColor];
			cell.textLabel.text = self.route.directions[self.directionKeys[indexPath.row]];
			cell.textLabel.font = self.basicFont;
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			break;
		}			
		case kSectionRowDisclaimer:
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
		case kOtherRowMap:
        case kOtherRowWiki:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kDirectionId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDirectionId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			cell.textLabel.textColor = [UIColor darkGrayColor];
			cell.textLabel.font = self.basicFont;
			switch (rowType)
			{
				case kOtherRowMap:
					cell.textLabel.text = NSLocalizedString(@"Map & schedule page", @"button text");
					cell.imageView.image = [self getActionIcon:kIconLink];
					break;
				case kOtherRowWiki:
					cell.textLabel.text = NSLocalizedString(@"Wikipedia page", @"Link to English wikipedia page");
					cell.imageView.image = [self getActionIcon:kIconWiki];
					break;
			}
            break;
        }
        case kSectionRowDetour:
        {
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kRowDetour)];
            if (cell == nil) {
                cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowDetour)] autorelease];
                cell.view = [Detour create_UITextView:self.paragraphFont];
                
            }
            
            if (self.detourData.detour !=nil)
            {
                Detour *det = self.detourData[indexPath.row];
                cell.view.text = det.detourDesc;
                cell.view.textColor = [UIColor orangeColor];
                
                cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
                                             det.routeDesc, det.detourDesc];
            }
            else
            {
                cell.view.text = NSLocalizedString(@"Detour information not known.", @"error message");
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
            [self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
            return cell;
            
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
    
    NSInteger rowType = [self rowType:indexPath];
    
	switch (rowType)
    {
        case kSectionRowName:
            break;
        case kSectionRowDirection:
        {
            StopView *stopViewController = [StopView viewController];
            
            NSString *rt = self.route.route;
            NSString *dr = self.directionKeys[indexPath.row];
            NSString *rd = self.route.desc;
            
            stopViewController.callback = self.callback;
            [stopViewController fetchStopsAsync:self.backgroundTask route:rt direction:dr
                                           description:rd
                                         directionName:self.route.directions[self.directionKeys[indexPath.row]]];
            break;
        }
        case kOtherRowWiki:
        {
            
            NSString *wiki = [TriMetRouteColors rawColorForRoute:self.route.route]->wiki;
            
            [WebViewController displayPage:[NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", wiki]
                                      full:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/%@", wiki ]
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            
        }
        break;
        case kOtherRowMap:
            [self showRouteSchedule:self.route.route];
            [self clearSelection];
            break;
        case kSectionRowDisclaimer:
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
    NSInteger sectionType = [self sectionType:section];
    
	switch (sectionType)
	{
	case kSectionRowName:
		return nil;
	case kSectionRowDirection:
            return NSLocalizedString(@"Directions (touch for stops and map):", @"section title");
	case kSectionOther:
            return NSLocalizedString(@"Additional route info:", @"section title");
    case kSectionRowDetour:
            if (self.detourData.count > 1)
            {
                return NSLocalizedString(@"Detours:", @"section title");
            }
            else
            {
                return NSLocalizedString(@"Detour:", @"section title");

            }
            break;
	default:
		return nil;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self rowType:indexPath])
	{
		case kSectionRowName:
		case kSectionRowDirection:
		case kOtherRowMap:
        case kOtherRowWiki:
			return [self basicRowHeight];
		case kSectionRowDisclaimer:
			return kDisclaimerCellHeight;
        case kSectionRowDetour:
        {
            Detour *det = self.detourData[indexPath.row];
            return [self getTextHeight:det.detourDesc font:self.paragraphFont];
        }
	}
	return 1;
	
}

#pragma mark View methods

- (void)viewDidLoad {
	[super viewDidLoad];
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"button text")
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	
	[self reloadData];
	
	if (self.route.directions.count > 0)
	{
		[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self firstSectionOfType:kSectionRowDirection]]
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


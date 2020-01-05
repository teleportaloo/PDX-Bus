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
#import "TriMetInfo.h"
#import "WebViewController.h"
#import "DebugLogging.h"
#import "Detour.h"
#import "Detour+iOSUI.h"
#import "NSString+Helper.h"

@implementation DirectionView

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


- (instancetype)init {
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Route Info", @"screen title");
        _cacheAction = TrIMetXMLCacheReadOrFetch;
        self.refreshFlags =  kRefreshNoTimer;
	}
	return self;
}

#pragma mark Data fetchers

- (void)fetchDirectionsAsync:(id<BackgroundTaskController>)task route:(NSString *)route
{
    [self fetchDirectionsAsync:task route:route backgroundRefresh:NO];
}

- (void)fetchDirectionsAsync:(id<BackgroundTaskController>)task route:(NSString *)route backgroundRefresh:(bool)backgroundRefresh
{
    [task taskRunAsync:^{
        self.backgroundRefresh = backgroundRefresh;
        
        self.directionData = [XMLRoutes xml];
        self.detourData    = [XMLDetoursAndMessages XmlWithRoutes:@[route]];
        
        self.routeId = route;
        int items = 2;
        
        if (!self.backgroundRefresh && [self.directionData getDirections:route cacheAction:TriMetXMLCheckCache])
        {
            items = 1;
        }
        
        [task taskStartWithItems:items title:NSLocalizedString(@"getting directions", @"progress message")];
        self.directionData.oneTimeDelegate = task;
        [self.directionData getDirections:route cacheAction:self->_cacheAction];
        
        if (self.directionData.count > 0)
        {
            self.route = self.directionData[0];
        }
        
        if (items > 1)
        {
            [task taskItemsDone:1];
        }
        
        [task taskSubtext:@"checking detours"];
        self.detourData.oneTimeDelegate = task;
        [self.detourData fetchDetoursAndMessages];
        
        [self.detourData.items sortUsingSelector:@selector(compare:)];
        
        if (items > 1)
        {
            [task taskItemsDone:2];
        }
        
        [self clearSectionMaps];
        
        [self addSectionType:kSectionRowName];
        [self addRowType:kSectionRowName];
        
        [self addSectionType:kSectionRowDirection];
        
        if (self.route)
        {
            [self addRowType:kSectionRowDirection count:self.route.directions.count];
        }
        
        [self addSectionType:kSectionOther];
        [self addRowType:kOtherRowMap];
        
        if (self.route)
        {
            PC_ROUTE_INFO info = self.route.rawColor;
            if (info!=nil && info->wiki != nil)
            {
                [self addRowType:kOtherRowWiki];
            }
        }
        
        if (self.detourData.count > 0)
        {
            [self addSectionType:kSectionRowDetour];
            [self addRowType:kSectionRowDetour count:self.detourData.count];
        }
        
        [self addRowType:kSectionRowDisclaimer];
        
        [self updateRefreshDate:self.directionData.cacheTime];
        return (UIViewController*)self;
    }];
}


#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
    if (!self.backgroundTask.running)
    {
        NSString *route = self.routeId;
        _cacheAction = TriMetXMLForceFetchAndUpdateCache;
        [self fetchDirectionsAsync:self.backgroundTask route:route backgroundRefresh:YES];
    }
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
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kSectionRowName)
                                rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
            
            PC_ROUTE_INFO info = self.route.rawColor;
            [RailStation populateCell:cell
                              station:self.route.desc
                                lines:info ? info->line_bit : 0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //	DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
            //				  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
            break;
        }
		case kSectionRowDirection:
		{
			cell = [self tableView:tableView cellWithReuseIdentifier:kDirectionId];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			if (self.directionKeys == nil)
			{
				self.directionKeys = [self.route.directions keysSortedByValueUsingSelector:@selector(compare:)];
			}
			cell.textLabel.textColor = [UIColor modeAwareText];
			cell.textLabel.text = self.route.directions[self.directionKeys[indexPath.row]];
			cell.textLabel.font = self.basicFont;
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            [self updateAccessibility:cell];
			break;
		}			
		case kSectionRowDisclaimer:
		{
			cell = [self disclaimerCell:tableView];
			
			if (self.directionData.items == nil)
			{
				[self noNetworkDisclaimerCell:cell];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
				[self addTextToDisclaimerCell:cell text:[self.directionData displayDate:self.directionData.cacheTime]];	
			}
            [self updateDisclaimerAccessibility:cell];
			break;
		}
		case kOtherRowMap:
        case kOtherRowWiki:
		{
			cell = [self tableView:tableView cellWithReuseIdentifier:kDirectionId];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.textColor = [UIColor darkGrayColor];
			cell.textLabel.font = self.basicFont;
			switch (rowType)
			{
				case kOtherRowMap:
					cell.textLabel.text = NSLocalizedString(@"Map & schedule page", @"button text");
					cell.imageView.image = [self getIcon:kIconLink];
					break;
				case kOtherRowWiki:
					cell.textLabel.text = NSLocalizedString(@"Wikipedia page", @"Link to English wikipedia page");
					cell.imageView.image = [self getIcon:kIconLink];
					break;
			}
            [self updateAccessibility:cell];
            break;
        }
        case kSectionRowDetour:
        {
            UITableViewCell *cell = nil;
            if (self.detourData.gotData)
            {
                Detour *det = self.detourData[indexPath.row];
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                [det populateCell:cell font:self.paragraphFont routeDisclosure:NO];
                [self addDetourButtons:det cell:cell routeDisclosure:NO];
            }
            else
            {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kRowDetour)];
                cell.textLabel.text = NSLocalizedString(@"Detour information not known.", @"error message");
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            return cell;
            
        }
	}	
	return cell;
}

- (void) tableView:(UITableView *)tableView detourButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath buttonType:(NSInteger)buttonType
{
    Detour *det = self.detourData[indexPath.row];
    [self detourAction:det buttonType:buttonType indexPath:indexPath reloadSection:NO];
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
                                  directionName:self.route.directions[self.directionKeys[indexPath.row]]
                              backgroundRefresh:NO];
            break;
        }
        case kOtherRowWiki:
        {
            
            NSString *wiki = [TriMetInfo infoForRoute:self.route.route]->wiki;
            
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
            if (self.directionData.items == nil)
            {
                [self networkTips:self.directionData.htmlError networkError:self.directionData.errorMsg] ;
                [self clearSelection];
            }
            break;
        }
        case kSectionRowDetour:
            [self detourToggle:self.detourData[indexPath.row] indexPath:indexPath reloadSection:NO];
            break;
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
            return NSLocalizedString(@"Detours, delays and closures:", @"section title");
            break;
	default:
		return nil;
	}
	
	return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.accessibilityLabel = header.textLabel.text.phonetic;
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
            return UITableViewAutomaticDimension;
	}
	return 1;
	
}

#pragma mark View methods

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self reloadData];
	
	if (self.route.directions.count > 0)
	{
        [self safeScrollToTop];
	}
	
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    // iPhone 4S does not show the first cell sometimes.  Quick fix.
    if (!_appeared)
    {
        _appeared = YES;
        [self safeScrollToTop];
    }
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
    [self.detourData appendQueryAndData:buffer];
}

@end


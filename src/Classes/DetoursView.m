//
//  DetoursView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetoursView.h"
#import "Detour.h"
#import "DirectionView.h"
#import "DebugLogging.h"
#include "Detour+iOSUI.h"
#import "NSString+Helper.h"
#import "TriMetInfo.h"
#import "WebViewController.h"
#import "NSString+Helper.h"
#import "MapViewWithDetourStops.h"
#import "XMLDetoursAndMessages.h"

#define kGettingDetours NSLocalizedString(@"getting detours", @"progress message")

@implementation DetoursView

- (bool)tableView:(UITableView*)tableView disclaimerSection:(NSInteger)section
{
    if (section == _disclaimerSection && tableView == self.table)
    {
        return YES;
    }
    return NO;
}



- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index
{
    DetoursForRoute *result = [DetoursForRoute data];
    DetoursForRoute *item   = (DetoursForRoute*)i;
    
    if ([item.route.desc hasCaseInsensitiveSubstring:searchText])
    {
        return i;
    }
    
    result.route = item.route;
    
    for (Detour * d in item.detours)
    {
        if ([d.formattedDescriptionWithHeader.removeFormatting hasCaseInsensitiveSubstring:searchText])
        {
            [result.detours addObject:d];
        }
    }
    
    if (result.detours.count == 0)
    {
        result = nil;
    }
    
    return result;
}

- (void)initSearchArray
{
    self.searchableItems = self.sortedDetours;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.enableSearch = YES;
        self.refreshFlags =  kRefreshButton | kRefreshShake;
    }
    
    return self;
}


#pragma mark Data fetchers

- (void)sort:(NSArray *)routes
{
    // Sort the detours
    self.sortedDetours = [NSMutableArray array];
    
    bool found = NO;
    
    NSMutableSet *detoursNoLongerFound = [UserPrefs sharedInstance].hiddenSystemWideDetours.mutableCopy;
    
    for (Detour *d in self.detours)
    {
        if (d.systemWideFlag)
        {
            [detoursNoLongerFound removeObject:d.detourId];
        }
        for (Route *r in d.routes)
        {
            found = NO;
            for (DetoursForRoute *detoursForRoute in self.sortedDetours)
            {
                if ([r.route isEqualToString:detoursForRoute.route.route])
                {
                    [detoursForRoute.detours addObject:d];
                    found = YES;
                    break;
                }
            }
            
            if (!found)
            {
                DetoursForRoute *detours = [DetoursForRoute data];
                detours.route = r;
                [detours.detours addObject:d];
                [self.sortedDetours addObject:detours];
            }
        }
    }
    
    if (routes)
    {
        [[UserPrefs sharedInstance] removeOldSystemWideDetours:detoursNoLongerFound];
    }
    
    // Remove any not in our route list
    if (routes)
    {
        NSSet<NSString*> *routeSet = [NSSet setWithArray:routes];
        
        NSInteger i;
        
        for (i=0; i<self.sortedDetours.count; )
        {
            DetoursForRoute *d = self.sortedDetours[i];
            
            if (![routeSet containsObject:d.route.route] && !d.route.systemWide)
            {
                [self.sortedDetours removeObjectAtIndex:i];
            }
            else
            {
                i++;
            }
        }
    }

    [self.sortedDetours sortUsingComparator:^NSComparisonResult(DetoursForRoute *d1, DetoursForRoute *d2)
    {
        return [d1.route compare:d2.route];
    }];

    
    [self initSearchArray];
}

- (void)fetchDetours:(NSArray*)routes taskController:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh
{    
    [task taskRunAsync:^{
        self.backgroundRefresh = backgroundRefresh;
        
        self.detours = [XMLDetoursAndMessages XmlWithRoutes:routes];
        
        [task taskStartWithItems:1 title:kGettingDetours];
        self.routes = routes;
        self.detours.oneTimeDelegate = task;
        [self.detours fetchDetoursAndMessages];

        [self sort:routes];
        self->_disclaimerSection = self.sortedDetours.count;
        
        [self updateRefreshDate:nil];
        return (UIViewController*)self;
    }];
}

- (void) fetchDetoursAsync:(id<BackgroundTaskController>)task
{
    [self fetchDetours:nil taskController:task backgroundRefresh:NO];
}

- (void)fetchDetoursAsync:(id<BackgroundTaskController>)task routes:(NSArray *)routes backgroundRefresh:(bool)backgroundRefresh
{
    [self fetchDetours:routes taskController:task backgroundRefresh:backgroundRefresh];
}

- (void) fetchDetoursAsync:(id<BackgroundTaskController>)task route:(NSString *)route
{
    [task taskRunAsync:^{
        [task taskStartWithItems:1 title:kGettingDetours];
        self.detours = [XMLDetoursAndMessages XmlWithRoutes:@[route]];
        self.detours.oneTimeDelegate = task;
        [self.detours fetchDetoursAndMessages];
        [self sort:@[route]];
        self->_disclaimerSection = self.sortedDetours.count;
        return (UIViewController*)self;
    }];
}



#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if ([self tableView:tableView disclaimerSection:section])
    {
        return nil;
    }
    
    
    DetoursForRoute *detours = [self filteredData:tableView][section];
    
    if (detours.detours.count > 0 && detours.detours.firstObject.systemWideFlag && [[UserPrefs sharedInstance].hiddenSystemWideDetours containsObject:detours.detours.firstObject.detourId])
    {
         return nil;
    }

    return detours.route.desc;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.accessibilityLabel = header.textLabel.text.phonetic;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if (tableView == self.table)
    {
        return self.sortedDetours.count + 1;
    }
    
    return [self filteredData:tableView].count;
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self tableView:tableView disclaimerSection:section])
    {
        return 1;
    }
    
    return [self filteredData:tableView][section].detours.count;
}

- (void)tableView:(UITableView *)tableView populateCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    DetoursForRoute *detours = [self filteredData:tableView][indexPath.section];
    Detour *detour = detours.detours[indexPath.row];
    
    [detour populateCell:cell font:self.paragraphFont routeDisclosure:YES];
    [self addDetourButtons:detour cell:cell routeDisclosure:YES];
    
    /*
     bool detail = NO;
     
     
     if (detour.hasInfo)
     {
     detail = YES;
     }
     
    if (!detour.systemWideFlag && detail)
    {
        cell.accessoryType  = UITableViewCellAccessoryDetailDisclosureButton;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if (detour.systemWideFlag && detail)
    {
        cell.accessoryType  = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (!detour.systemWideFlag)
    {
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    */
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self tableView:tableView disclaimerSection:indexPath.section])
    {
        return kDisclaimerCellHeight;
    }
    
    // [self populateCell:self.prototypeCellLabel forIndexPath:indexPath];
    
    return UITableViewAutomaticDimension;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
    if ([self tableView:tableView disclaimerSection:indexPath.section])
    {
        UITableViewCell *cell = nil;

        cell = [self disclaimerCell:tableView];
        
        if (self.detours.items == nil)
        {
            [self noNetworkDisclaimerCell:cell];
        } 
        else if (self.detours.count == 0)
        {
            [self addTextToDisclaimerCell:cell text:NSLocalizedString(@"No current detours", @"empty list message")];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;    
        }
        
        [self updateDisclaimerAccessibility:cell];
        return cell;

    }
    else
    {
        Detour *detour = [self filteredData:tableView][indexPath.section].detours[indexPath.row];
        UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:detour.reuseIdentifer font:self.paragraphFont];
        [self tableView:tableView populateCell:cell forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView detourButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath buttonType:(NSInteger)buttonType
{
    Detour *det = [self filteredData:tableView][indexPath.section].detours[indexPath.row];
    [self detourAction:det buttonType:buttonType indexPath:indexPath reloadSection:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self tableView:tableView disclaimerSection:indexPath.section])
    {
        DetoursForRoute *detours = [self filteredData:tableView][indexPath.section];
        Detour *detour = detours.detours[indexPath.row];
        
        if (!detour.systemWideFlag)
        {
            [[DirectionView viewController] fetchDirectionsAsync:self.backgroundTask route:detours.route.route];
        }
        else
        {
            [self detourToggle:detour indexPath:indexPath reloadSection:YES];
        }
    }
    else if (self.detours.items == nil)
    {
        [self networkTips:self.detours.htmlError networkError:self.detours.errorMsg];
        [self clearSelection];
    }

}


#pragma mark View methods

-(void)loadView
{
    [super loadView];
    self.title = NSLocalizedString(@"Alerts & Detours", @"screen title");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self safeScrollToTop];
    
    /*
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                      initWithTitle:NSLocalizedString(@"Refresh", @"")
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(refreshAction:)];
    
    self.navigationItem.rightBarButtonItem = refreshButton;
    
     [refreshButton release];
     */
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

- (void)mapAction:(id)unused
{
     [[MapViewWithDetourStops viewController] fetchLocationsMaybeAsync:self.backgroundTask detours:self.detours.items nav:self.navigationController];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    if (self.detours.gotData && self.detours.items.count > 0)
    {
        [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(mapAction:)]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.detours appendQueryAndData:buffer];
}


-(void)refreshAction:(id)unused
{
    if (!self.backgroundRefresh)
    {
        [self fetchDetoursAsync:self.backgroundTask routes:self.routes backgroundRefresh:YES];
    }
}


@end


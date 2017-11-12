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
#include "DetourData+iOSUI.h"
#import "StringHelper.h"
#import "TriMetRouteColors.h"
#import "UITableViewCell+MultiLineCell.h"

#define kGettingDetours NSLocalizedString(@"getting detours", @"progress message")

@implementation DetoursView

@synthesize detours = _detours;


- (void)dealloc {
	self.detours = nil;
    self.sortedDetours = nil;
	[super dealloc];
}

#pragma mark Data fetchers

- (void)sort:(NSArray *)routes
{
    // Sort the detours
    self.sortedDetours = [NSMutableArray array];
    
    for (Detour *d in self.detours)
    {
        bool found = NO;
        for (NSMutableArray<Detour *>*routes in self.sortedDetours)
        {
            if (routes.count > 0)
            {
                if ([d.route isEqualToString:routes.firstObject.route])
                {
                    [routes addObject:d];
                    found = YES;
                    break;
                }
            }
        }
        
        if (!found)
        {
            [self.sortedDetours addObject:[NSMutableArray arrayWithObject:d]];
        }
    }
    
    // Remove any not in our route list
    if (routes)
    {
        NSSet<NSString*> *routeSet = [NSSet setWithArray:routes];
        
        NSInteger i;
        
        for (i=0; i<self.sortedDetours.count; )
        {
            Detour *d = self.sortedDetours[i].firstObject;
            
            if (![routeSet containsObject:d.route])
            {
                [self.sortedDetours removeObjectAtIndex:i];
            }
            else
            {
                i++;
            }
        }
    }
    
    [self.sortedDetours sortUsingComparator:^NSComparisonResult(NSMutableArray *obj1, NSMutableArray * obj2) {
        Detour *d1 = obj1.firstObject;
        Detour *d2 = obj2.firstObject;
        
        const ROUTE_COL *c1 = [TriMetRouteColors rawColorForRoute:d1.route];
        const ROUTE_COL *c2 = [TriMetRouteColors rawColorForRoute:d2.route];
        
        if (c1 == nil && c2 == nil)
        {
            return d1.route.integerValue - d2.route.integerValue;
        }
        else if (c1 == nil && c2 != nil)
        {
            return NSOrderedDescending;
        }
        else if (c1 !=nil && c2 == nil)
        {
            return NSOrderedAscending;
        }
        
        return c1->order - c2->order;
    }];
}

- (void)fetchDetours:(NSArray*)routes
{	
    [self runAsyncOnBackgroundThread:^{
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingDetours];
        
        self.detours = [XMLDetours xml];
        
        if (routes == nil)
        {
            [self.detours getDetours];
        }
        else
        {
            [self.detours getDetoursForRoutes:routes];
        }
        
        [self sort:routes];
        _disclaimerSection = self.sortedDetours.count;
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
        
    }];
}


- (void) fetchDetoursAsync:(id<BackgroundTaskProgress>) callback
{
	self.backgroundTask.callbackWhenFetching = callback;
    
    [self fetchDetours:nil];
}

- (void)fetchDetoursAsync:(id<BackgroundTaskProgress>) callback routes:(NSArray *)routes
{
	self.backgroundTask.callbackWhenFetching = callback;
    
    [self fetchDetours:routes];
}

- (void) fetchDetoursAsync:(id<BackgroundTaskProgress>)callback route:(NSString *)route
{
	self.backgroundTask.callbackWhenFetching = callback;
	
    [self runAsyncOnBackgroundThread:^{
        [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingDetours];
        
        self.detours = [XMLDetours xml];
        [self.detours getDetoursForRoute:route];
        
        [self sort:@[route]];
        _disclaimerSection = self.sortedDetours.count;
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    }];
}



#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	
	if (section == _disclaimerSection)
	{
		return nil;
	}
	Detour *detour = self.sortedDetours[section].firstObject;
	return detour.routeDesc;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return self.sortedDetours.count + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == _disclaimerSection)
    {
        return 1;
       
    }
     return self.sortedDetours[section].count;
}

- (void)populateCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Detour *detour = self.sortedDetours[indexPath.section][indexPath.row];
    cell.textLabel.text = detour.detourDesc;

    // cell.view.attributedText = [detour.detourDesc formatAttributedStringWithFont:self.paragraphFont];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessibilityLabel = detour.detourDesc;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _disclaimerSection)
    {
        return kDisclaimerCellHeight;
    }
    
    // [self populateCell:self.prototypeCellLabel forIndexPath:indexPath];
    
    return UITableViewAutomaticDimension;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
	if (indexPath.section == _disclaimerSection)
	{
		UITableViewCell *cell = nil;

		cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
		if (cell == nil) {
			cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
		}
		
		if (self.detours.itemArray == nil)
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
		
		return cell;

	}
	else
	{
		NSString *MyIdentifier = [NSString stringWithFormat:@"DetourLabel"];
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
            cell = [UITableViewCell cellWithMultipleLines:MyIdentifier font:self.paragraphFont];
		}
        [self populateCell:cell forIndexPath:indexPath];
        return cell;
	}
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section != _disclaimerSection)
	{
        Detour *detour = self.sortedDetours[indexPath.section][indexPath.row];
		[[DirectionView viewController] fetchDirectionsAsync:self.backgroundTask route:detour.route];
	}
	else if (self.detours.itemArray == nil)
	{
		[self networkTips:self.detours.htmlError networkError:self.detours.errorMsg];
        [self clearSelection];
	}

}


#pragma mark View methods

-(void)loadView
{
	[super loadView];
	self.title = NSLocalizedString(@"Detours", @"screen title");
}

- (void)viewDidLoad {
	[super viewDidLoad];
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


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self updateToolbarItemsWithXml:toolbarItems];

}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.detours appendQueryAndData:buffer];
}

@end


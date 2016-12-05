//
//  DetoursView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetoursView.h"
#import "Detour.h"
#import "CellLabel.h"
#import "DirectionView.h"
#import "DebugLogging.h"
#include "DetourData+iOSUI.h"

#define kGettingDetours NSLocalizedString(@"getting detours", @"progress message")

@implementation DetoursView

@synthesize detours = _detours;

- (void)dealloc {
	self.detours = nil;
	[super dealloc];
}

#pragma mark Data fetchers

- (void)workerToFetchDetours:(NSArray*)routes
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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

	_disclaimerSection = self.detours.count;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}


- (void) fetchDetoursAsync:(id<BackgroundTaskProgress>) callback
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(workerToFetchDetours:) toTarget:self withObject:nil];
}

- (void)fetchDetoursAsync:(id<BackgroundTaskProgress>) callback routes:(NSArray *)routes
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(workerToFetchDetours:) toTarget:self withObject:routes];
}

- (void)workerToFetchDetoursForRoute:(NSString *)route
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingDetours];
	
    self.detours = [XMLDetours xml];
	[self.detours getDetoursForRoute:route];
 
	_disclaimerSection = self.detours.count;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void) fetchDetoursAsync:(id<BackgroundTaskProgress>)callback route:(NSString *)route
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(workerToFetchDetoursForRoute:) toTarget:self withObject:route];
}



#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	
	if (section == _disclaimerSection)
	{
		return nil;
	}
	Detour *detour = self.detours[section];
	return detour.routeDesc;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return self.detours.count + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == _disclaimerSection)
	{
		return kDisclaimerCellHeight;
	}
	
	Detour *detour = self.detours[indexPath.section];
	
	
	return [self getTextHeight:detour.detourDesc font:self.paragraphFont];
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
		
		Detour *detour = self.detours[indexPath.section];
		
		NSString *MyIdentifier = [NSString stringWithFormat:@"DetourLabel%f", [self getTextHeight:detour.detourDesc font:self.paragraphFont]];
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
			cell.view = [Detour create_UITextView:self.paragraphFont];
		}
		
		cell.view.text = detour.detourDesc;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		
		cell.accessibilityLabel = detour.detourDesc;

		return cell;
	}
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section != _disclaimerSection)
	{
		Detour *detour = self.detours[indexPath.section];
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


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

#define kGettingDetours NSLocalizedString(@"getting detours", @"progress message")

@implementation DetoursView

@synthesize detourData = _detourData;

- (void)dealloc {
	self.detourData = nil;
	[super dealloc];
}

#pragma mark Data fetchers

- (void)fetchDetours:(id) arg
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingDetours];
	
    self.detourData = [[[XMLDetour alloc] init] autorelease];
	
	if (arg == nil)
	{
		[self.detourData getDetours];
	}
	else 
	{
		[self.detourData getDetourForRoutes:(NSArray*)arg];
 	}

	disclaimerSection = [self.detourData safeItemCount];
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}


- (void) fetchDetoursInBackground:(id<BackgroundTaskProgress>) callback
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(fetchDetours:) toTarget:self withObject:nil];
}

- (void)fetchDetoursInBackground:(id<BackgroundTaskProgress>) callback routes:(NSArray *)routes
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(fetchDetours:) toTarget:self withObject:routes];
}

- (void)fetchDetoursForRoute:(NSString *)route
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:kGettingDetours];
	
    self.detourData = [[[XMLDetour alloc] init] autorelease];
	[self.detourData getDetourForRoute:route];
 
	disclaimerSection = [self.detourData safeItemCount];
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	[pool release];
}

- (void) fetchDetoursInBackground:(id<BackgroundTaskProgress>)callback route:(NSString *)route
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(fetchDetoursForRoute:) toTarget:self withObject:route];
}



#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	
	if (section == disclaimerSection)
	{
		return nil;
	}
	Detour *detour = [self.detourData itemAtIndex:section];
	return detour.routeDesc;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return [self.detourData safeItemCount] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == disclaimerSection)
	{
		return kDisclaimerCellHeight;
	}
	
	Detour *detour = [self.detourData itemAtIndex:indexPath.section];
	
	
	return [self getTextHeight:detour.detourDesc font:[self getParagraphFont]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
	if (indexPath.section == disclaimerSection)
	{
		UITableViewCell *cell = nil;

		cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
		if (cell == nil) {
			cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
		}
		
		if (self.detourData.itemArray == nil)
		{
			[self noNetworkDisclaimerCell:cell];
		} 
		else if ([self.detourData safeItemCount] == 0)
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
		
		Detour *detour = [self.detourData itemAtIndex:indexPath.section];
		
		NSString *MyIdentifier = [NSString stringWithFormat:@"DetourLabel%f", [self getTextHeight:detour.detourDesc font:[self getParagraphFont]]];
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
			cell.view = [Detour create_UITextView:[self getParagraphFont]];
		}
		
		cell.view.text = detour.detourDesc;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		
		[cell setAccessibilityLabel:[detour detourDesc]];

		return cell;
	}
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section != disclaimerSection)
	{
		Detour *detour = [self.detourData itemAtIndex:indexPath.section];
		DirectionView *directionViewController = [[DirectionView alloc] init];
		
		// directionViewController.route = [detour route];
		[directionViewController fetchDirectionsInBackground:self.backgroundTask route:[detour route]];
		[directionViewController release];	
		
	}
	else if (self.detourData.itemArray == nil)
	{
		[self networkTips:self.detourData.htmlError networkError:self.detourData.errorMsg];
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
    [self.detourData appendQueryAndData:buffer];
}

@end


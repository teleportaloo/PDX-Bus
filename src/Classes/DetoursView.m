//
//  DetoursView.m
//  PDX Bus
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

#import "DetoursView.h"
#import "Detour.h"
#import "CellLabel.h"
#import "DirectionView.h"

#define kGettingDetours @"getting detours"

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
	[self.backgroundTask.callbackWhenFetching BackgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching BackgroundStart:1 title:kGettingDetours];
	
	NSError *parseError = nil;
    self.detourData = [[[XMLDetour alloc] init] autorelease];
	
	if (arg == nil)
	{
		[self.detourData getDetours:&parseError];
	}
	else 
	{
		[self.detourData getDetourForRoutes:(NSArray*)arg parseError:&parseError];
	}

	disclaimerSection = [self.detourData safeItemCount];
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
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
	[self.backgroundTask.callbackWhenFetching BackgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching BackgroundStart:1 title:kGettingDetours];
	
	NSError *parseError = nil;
    self.detourData = [[[XMLDetour alloc] init] autorelease];
	[self.detourData getDetourForRoute:route parseError:&parseError];

	disclaimerSection = [self.detourData safeItemCount];
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
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
			[self addTextToDisclaimerCell:cell text:@"No current detours"];
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
	}

}


#pragma mark View methods

-(void)loadView
{
	[super loadView];
	self.title = @"Detours";
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

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


- (void)createToolbarItems
{
    [self createToolbarItemsWithXml];

}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.detourData appendQueryAndData:buffer];
}

@end


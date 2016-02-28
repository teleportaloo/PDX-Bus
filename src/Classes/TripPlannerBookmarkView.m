//
//  TripPlannerBookmarkView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/3/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerBookmarkView.h"
#import "XMLDepartures.h"
#import "StopNameCacheManager.h"
#import "StringHelper.h"

@implementation TripPlannerBookmarkView
@synthesize locList = _locList;
@synthesize from = _from;


- (void)dealloc {
	self.locList = nil;
    [super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Data fetchers

- (void)fetchNamesForLocations:(NSString*) loc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *aLoc;
	
    self.locList = [[[NSMutableArray alloc] init] autorelease];
    
    NSArray *idList  = [StringHelper arrayFromCommaSeparatedString:loc];
	
    int items = (int)idList.count;
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:items title:@"getting stop names"];
	
	
	items = 0;
    
    StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];
	
    for (int i=0; i<idList.count; i++)
	{
        aLoc = [idList objectAtIndex:i];
        NSArray *stopName = [stopNameCache getStopNameAndCache:aLoc];
		[self.locList addObject:stopName];
		
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
		
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];

	
	[pool release];
	
}

- (void)fetchNamesForLocationsInBackground:(id<BackgroundTaskProgress>)callback loc:(NSString*) loc
{
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(fetchNamesForLocations:) toTarget:self withObject:loc];
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (self.title == nil)
	{
		self.title = @"Bookmarked stops";
	}

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.from)
	{
		return @"Choose a starting stop:";
	}
	return @"Choose a destination stop:";
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.locList.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"tripbookmark";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	NSArray *stopName = [self.locList objectAtIndex:indexPath.row];
	
	// cell.textLabel.text = dep.locDesc;
    cell.textLabel.text = [stopName objectAtIndex:kStopNameCacheLongDescription];
	
	cell.textLabel.adjustsFontSizeToFitWidth = true;
	cell.textLabel.font = [self getBasicFont];
	
	if (cell.textLabel.text != nil)
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	NSArray *stopName = [self.locList objectAtIndex:indexPath.row];
	
/*	if ([self.callback getController] != nil)
	{
		[[self navigationController] popToViewController:[self.callback getController] animated:YES];
	} */
	
	if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
	{
		
		// cell.textLabel.text = dep.locDesc;
		[self.callback selectedStop:[stopName objectAtIndex:kStopNameCacheLocation] desc:[stopName objectAtIndex:kStopNameCacheLongDescription]];
	}
	else 
	{
		[self.callback selectedStop:[stopName objectAtIndex:kStopNameCacheLocation]];
	}
	
}


@end


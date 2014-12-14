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
	NSError *parseError = nil;	
	
	NSScanner *scanner = [NSScanner scannerWithString:loc];
	NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
	NSString *aLoc;
	
	self.locList = [[[NSMutableArray alloc] init] autorelease];
	
	int items = 0;
	
	while ([scanner scanUpToCharactersFromSet:comma intoString:&aLoc])
	{	
		items++;
		
		if (![scanner isAtEnd])
		{
			scanner.scanLocation++;
		}
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:items title:@"getting stop names"];
	
	[scanner setScanLocation:0];
	
	items = 0;
	
	while ([scanner scanUpToCharactersFromSet:comma intoString:&aLoc])
	{	
		XMLDepartures *deps = [[ XMLDepartures alloc ] init];
		[self.locList addObject:deps];
		[deps getDeparturesForLocation:aLoc parseError:&parseError];
		
		if (![scanner isAtEnd])
		{
			scanner.scanLocation++;
		}
		[deps release];
		items++;
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
	XMLDepartures *dep = [self.locList objectAtIndex:indexPath.row];
	
	// cell.textLabel.text = dep.locDesc;
	if (dep.locDesc !=nil)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", dep.locDesc, dep.locDir];
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:@"Stop ID - %@", dep.locid];
	}

	cell.textLabel.adjustsFontSizeToFitWidth = true;
	cell.textLabel.font = [self getBasicFont];
	
	if (cell.textLabel.text != nil)
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		if (dep.itemArray != nil)
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.text = @"Unknown location";
		}
		else
		{
			cell.textLabel.text = dep.locid;
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
	}
		
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	XMLDepartures *dep = [self.locList objectAtIndex:indexPath.row];
	
/*	if ([self.callback getController] != nil)
	{
		[[self navigationController] popToViewController:[self.callback getController] animated:YES];
	} */
	
	if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
	{
		
		// cell.textLabel.text = dep.locDesc;
		if (dep.locDesc !=nil)
		{
			
			[self.callback selectedStop:dep.locid desc:[NSString stringWithFormat:@"%@ - %@", dep.locDesc, dep.locDir]];
		}
		else
		{
			[self.callback selectedStop:dep.locid desc:nil];
		}
	}
	else 
	{
		[self.callback selectedStop:dep.locid];
	}
	
}


@end


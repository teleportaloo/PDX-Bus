//
//  TripPlannerCacheView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TripPlannerCacheView.h"
#import "TripPlannerResultsView.h"
#import "UserFaves.h"
#import "CellLabel.h"
#import "Detour.h"

@implementation TripPlannerCacheView

- (void)dealloc {
    [super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Recent trips";
	// self.table.editing = YES;
	self.table.allowsSelectionDuringEditing = YES;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark  Table View methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (_userData.recentTrips.count == 0)
	{
		return @"No items in history";
	}
	
	return @"These previously planned trip results are cached and use saved locations, so they require no network access to review."; 
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_userData.recentTrips count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *trip = [_userData.recentTrips objectAtIndex:indexPath.row];
	return [self getTextHeight:[trip valueForKey:kUserFavesChosenName] font:[self getParagraphFont]];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSDictionary *trip = [_userData.recentTrips objectAtIndex:indexPath.row];
	NSString *text = [trip valueForKey:kUserFavesChosenName];
	
	NSString *MyIdentifier = [NSString stringWithFormat:@"DetourLabel%f", [self getTextHeight:text font:[self getParagraphFont]]];
	
	CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
		cell.view = [Detour create_UITextView:[self getParagraphFont]];
	}
	
	cell.view.text = text;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.backgroundColor = [UIColor whiteColor];
	
	[cell setAccessibilityLabel:text];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	// [self chosenEndpoint:[self.locList objectAtIndex:indexPath.row] ];
	TripPlannerResultsView *tripResults = [[TripPlannerResultsView alloc] initWithHistoryItem:(int)indexPath.row];
	
	// Push the detail view controller
	[[self navigationController] pushViewController:tripResults animated:YES];
	[tripResults release];
	
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	@synchronized (_userData)
	{
		if (editingStyle == UITableViewCellEditingStyleDelete) {
			[_userData.recentTrips removeObjectAtIndex:indexPath.section];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
			
			_userData.favesChanged = YES;
			[_userData cacheAppData];
		}	
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[self.table setEditing:editing animated:animated];
	// self.table.editing = editing;
	[super setEditing:editing animated:animated];
}

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	//	[self dumpPath:@"moveRowAtIndexPath from" path:fromIndexPath];
	//	[self dumpPath:@"moveRowAtIndexPath to  " path:toIndexPath];
	@synchronized (_userData)
	{
		NSDictionary *move = [[_userData.recentTrips objectAtIndex:fromIndexPath.row] retain];
		if (fromIndexPath.row < toIndexPath.row)
		{
			[_userData.recentTrips insertObject:move atIndex:toIndexPath.row+1];
			[_userData.recentTrips removeObjectAtIndex:fromIndexPath.row];
		}
		else
		{
			[_userData.recentTrips removeObjectAtIndex:fromIndexPath.row];
			[_userData.recentTrips insertObject:move atIndex:toIndexPath.row];
		}
		[move release];
		_userData.favesChanged = YES;
		[_userData cacheAppData];
	}
}




// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the item to be re-orderable.
	return YES;
}



@end


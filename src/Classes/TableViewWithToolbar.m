//
//  TableViewWithToolbar.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewWithToolbar.h"
#import "WebViewController.h"
#import "FlashViewController.h"
#import "NetworkTestView.h"
#import "FindByLocationView.h"
#import "SearchFilter.h"
#import <UIKit/UISearchDisplayController.h>


@implementation TableViewWithToolbar

@synthesize table				= _tableView;
@synthesize backgroundRefresh	= _backgroundRefresh;


@synthesize enableSearch = _enableSearch;
@synthesize searchBar = _searchBar;
@synthesize searchableItems = _searchableItems;
@synthesize filtered = _filtered;
@synthesize searchController = _searchController;

#define DISCLAIMER_TAG 1
#define UPDATE_TAG	   2
#define STREETCAR_TAG  3


- (void)dealloc {
    self.table.tableHeaderView  = nil;
	self.table                  = nil;
	self.callback               = nil;
    
    if (self.searchController)
    {
        self.searchController.delegate = nil;
		self.searchController.searchResultsDataSource = nil;
		self.searchController.searchResultsDelegate = nil;
    }
	self.searchController = nil;
    if (self.searchBar)
    {
        [self.searchBar removeFromSuperview];
        self.searchBar.delegate = nil;
    }
	self.searchBar		= nil;
	self.searchableItems= nil;
   
	[_basicFont release];
	[_smallFont release];
	[_paragraphFont release];
	[_filteredItems release];
	
	[super dealloc];
}

#pragma mark View overridden methods

- (id)init {
	if ((self = [super init]))
	{
		
	}
	return self;
}

-(void)recreateNewTable
{
	if (self.table !=nil)
	{
		[self.table removeFromSuperview];
		self.table = nil;
	}
	
	// Set the size for the table view
	CGRect tableViewRect = [self getMiddleWindowRect];
	
	
	// Create a table view
	self.table = [[[UITableView alloc] initWithFrame:tableViewRect	style:self.getStyle] autorelease];
	// set the autoresizing mask so that the table will always fill the view
	self.table.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	
	
	// set the tableview delegate to this object
	self.table.delegate = self;	
	
	// Set the table view datasource to the data source
	self.table.dataSource = self;
	
	if (self.enableSearch)
	{
		CGRect rect;
		
		rect = CGRectMake(0.0, 0.0, 320.0, [self searchRowHeight]);
		
		self.searchBar = [[[UISearchBar alloc] initWithFrame:rect] autorelease];
		
		self.searchBar.delegate = self;
		self.searchBar.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
		
		self.searchController = [[[UISearchDisplayController alloc]
								 initWithSearchBar:self.searchBar contentsController:self] autorelease];
		
		self.searchController.delegate = self;
		self.searchController.searchResultsDataSource = self;
		self.searchController.searchResultsDelegate = self;

		
		self.table.tableHeaderView = self.searchController.searchBar;
		// self.tableHeaderHeight = [self searchRowHeight];
	}
    
    if (self.getStyle == UITableViewStylePlain)
    {
        self.table.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
	
	[self.view addSubview:self.table];
    
    // Hide all the cell lines at the end
    self.table.tableFooterView = [[[UIView alloc] init] autorelease];
	
}

- (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)greyBackground
{
    return [UIColor colorWithWhite:0.99 alpha:1.0];
}

-(void)filterItems
{
	if (_enableSearch)
	{
		NSString *searchText = nil;
		
		if (self.searchBar != nil)
		{
			searchText = self.searchBar.text;
		}
		
		if (searchText == nil || searchText.length == 0)
		{	
			[_filteredItems release];
			_filteredItems = [self.searchableItems retain];
		}
		else 
		{
			NSMutableArray *filtered = [[NSMutableArray alloc] init];
			for (id<SearchFilter> i in self.searchableItems)
			{			
				NSRange range = [[i stringToFilter] rangeOfString:searchText options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound)
				{
					[filtered addObject:i];
				}
			}
			_filteredItems = filtered;
		}	
	}	
}

- (void)reloadData
{
	[self filterItems];
		
	if (self.searchController !=nil && self.searchController.isActive)
	{
		[self.searchController.searchResultsTableView reloadData];
	}
	
	[self.table reloadData];
}

- (void)loadView
{
	[super loadView];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// self.view = [[[CustomLayoutView alloc] init] autorelease];
	
	[self recreateNewTable];
	
	
	[pool release];
	
}



- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	
	NSIndexPath *ip = [self.table indexPathForSelectedRow];
	if (ip!=nil)
	{
		[self.table deselectRowAtIndexPath:ip animated:YES];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}

#pragma mark Style

- (UITableViewStyle) getStyle
{
	return UITableViewStylePlain;
}

#pragma mark Table View methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if ([cell.reuseIdentifier isEqualToString:kDisclaimerCellId])
	{
		cell.backgroundColor =  [self greyBackground];
	}
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark Table view call helper methods

- (void)clearSelection
{
    NSIndexPath *ip = [self.table indexPathForSelectedRow];
    if (ip!=nil)
    {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}

- (CGFloat)getTextHeight:(NSString *)text font:(UIFont *)font;
{
	CGFloat width = 0.0;
	
	if ([self getStyle] == UITableViewStylePlain || [self iOS7style])
	{
        width = [self screenWidth] - 20 - font.pointSize;
	}
	else 
    {
        width = [self screenWidth] - 100 - font.pointSize;
	}
    DEBUG_LOG(@"Width for text %f\n", width);
	CGSize rect = CGSizeMake(width, MAXFLOAT);
	CGSize sz = [text sizeWithFont:font constrainedToSize:rect lineBreakMode:UILineBreakModeWordWrap];
	return sz.height + font.pointSize + (self.iOS7style ? font.pointSize : 0);
}

- (void)updateAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath text:(NSString *)str alwaysSaySection:(BOOL)alwaysSaySection
{
	[cell setAccessibilityLabel:str];
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:alwaysSaySection];
}

- (void)maybeAddSectionToAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath alwaysSaySection:(BOOL)alwaysSaySection
{
	// iPhone 3.1 made this not required, but keeping just in case!
	/*
	if ((alwaysSaySection || indexPath.row == 0 || indexPath.row == ([self.table numberOfRowsInSection:indexPath.section]) -1) &&
		[cell accessibilityLabel]!=nil)
	{
		NSString *title =[self tableView:self.table titleForHeaderInSection:indexPath.section];
		
		if (title != nil)
		{
			NSString *newVoiceOver = [NSString stringWithFormat:@"%@, %@", title, [cell accessibilityLabel]];
			[cell setAccessibilityLabel:newVoiceOver];
		}
	}
	*/
}

static NSString *trimetDisclaimerText = @"Route and arrival data provided by permission of TriMet";

- (UITableViewCell *)disclaimerCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
		
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 260
	
#define MAIN_FONT_SIZE 16.0
#define SMALL_FONT_SIZE 10.0
#define LABEL_HEIGHT 22.0
#define DISCLAIMER_HEIGHT 14.0
#define LABEL_SPACING 0 // ((kDisclaimerCellHeight - LABEL_HEIGHT - 2.0 * DISCLAIMER_HEIGHT) / 5.0)
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, LABEL_SPACING, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = UPDATE_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor grayColor];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[cell.contentView addSubview:label];
	[label release];
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, 2 * LABEL_SPACING + LABEL_HEIGHT, LEFT_COLUMN_WIDTH, DISCLAIMER_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = STREETCAR_TAG;
	label.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor grayColor];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[cell.contentView addSubview:label];
	[label release];
	
	label =  ((UILabel*)[cell.contentView viewWithTag:STREETCAR_TAG]);
	label.text = @"";
	rect = CGRectMake(LEFT_COLUMN_OFFSET, 3 * LABEL_SPACING + LABEL_HEIGHT + DISCLAIMER_HEIGHT, LEFT_COLUMN_WIDTH, DISCLAIMER_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = DISCLAIMER_TAG;
	label.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor grayColor];
	label.backgroundColor = [UIColor clearColor];
	[cell.contentView addSubview:label];
	[cell.contentView addSubview:label];
	[label release];
	
	label =  ((UILabel*)[cell.contentView viewWithTag:DISCLAIMER_TAG]);
	label.text = trimetDisclaimerText;
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	[cell setAccessibilityLabel:label.text];
	
	return cell;
}

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text trimetDisclaimer:(bool)trimetDisclaimer
{
	if (trimetDisclaimer)
	{
		UILabel *label = ((UILabel*)[cell.contentView viewWithTag:STREETCAR_TAG]);
	
		if (text !=nil)
		{
			label.text = [NSString stringWithFormat:@"Streetcar: %@", text];
		}
		else {
			label.text = @"";
		}
		
		label = ((UILabel*)[cell.contentView viewWithTag:DISCLAIMER_TAG]);
		label.text = trimetDisclaimerText;
	}
	else 
	{
		UILabel *label = ((UILabel*)[cell.contentView viewWithTag:STREETCAR_TAG]);
		
		label.text = @"";
		
		
		label = ((UILabel*)[cell.contentView viewWithTag:DISCLAIMER_TAG]);
		
		if (text !=nil)
		{
			label.text = [NSString stringWithFormat:@"Streetcar: %@", text];
		}
		else {
			label.text = @"";
		} 
	}

	
}


- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text
{
	UILabel *label = ((UILabel*)[cell.contentView viewWithTag:UPDATE_TAG]);
	
	if (text !=nil)
	{
		label.text = text;
	}
	else {
		label.text = @"";
	}

	[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@", text, [cell accessibilityLabel]]];
	
}

- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell
{
	[self addTextToDisclaimerCell:cell text:kNetworkMsg];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}



- (void)notRailAwareButton:(NSInteger)button
{
	[super notRailAwareButton:button];
	
	if (button != kRailAwareReloadButton)
	{
		NSIndexPath *ip = [self.table indexPathForSelectedRow];
		if (ip!=nil)
		{
			[self.table deselectRowAtIndexPath:ip animated:YES];
		}
	}
	
}

- (UIFont *)systemFontBold:(bool)bold size:(CGFloat)size
{
    if (bold)
    {
        return [UIFont boldSystemFontOfSize:size];
    }
    
    return [UIFont systemFontOfSize:size];

}

- (UIFont*)getBasicFont
{
	if (_basicFont == nil)
	{
        bool bold = TRUE;
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
        {
            bold = FALSE;
        }
        
        
        
		if (SmallScreenStyle(self.screenWidth))
		{
            if (self.screenWidth >= WidthiPhone6)
            {
                _basicFont =[[self systemFontBold:bold size:20.0] retain];
            }
            else
            {
                _basicFont =[[self systemFontBold:bold size:18.0] retain];
            }

		}
		else 
		{
            _basicFont = [[self systemFontBold:bold size:22.0] retain];
		}
	}
	return _basicFont;
}

- (UIFont*)getSmallFont
{
	if (_smallFont == nil)
	{
        bool bold = TRUE;
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
        {
            bold = FALSE;
        }
        
		if  (SmallScreenStyle(self.screenWidth))
		{
            if (self.screenWidth >= WidthiPhone6)
            {
                _smallFont =[[self systemFontBold:bold size:16.0] retain];
            }
            else
            {
                _smallFont =[[self systemFontBold:bold size:14.0] retain];
            }
		}
		else 
		{
			_smallFont = [[self systemFontBold:bold size:22.0] retain];
		}		
	}
	return _smallFont;
}

- (UIFont*)getParagraphFont
{
	if (_paragraphFont == nil)
	{
		if (SmallScreenStyle(self.screenWidth))
		{
            if (self.screenWidth >= WidthiPhone6)
            {
                _paragraphFont =[[UIFont systemFontOfSize:16.0] retain];
            }
            else
            {
                _paragraphFont =[[UIFont systemFontOfSize:14.0] retain];
            }
		}
		else {
			_paragraphFont = [[UIFont systemFontOfSize:22.0] retain];
		}		
	}
	return _paragraphFont;
}



- (CGFloat)basicRowHeight
{
	if (SmallScreenStyle(self.screenWidth))
	{
		return 40.0;
	}
	return 45.0;
}

- (CGFloat)narrowRowHeight
{
	if (SmallScreenStyle(self.screenWidth) !=0)
	{
		return 35.0;
	}
	return 40.0;
}





#pragma mark Background task impleementaion

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
	if (self.backgroundRefresh)
	{
		self.backgroundRefresh = false;
		
		if (!cancelled)
		{
			[self reloadData];
			// [[(MainTableViewController *)[self.navigationController topViewController] tableView] reloadData];
		}
		else {
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
	else {
		if (!cancelled)
		{
			[self.navigationController pushViewController:viewController animated:YES];
		}
		else {
			NSIndexPath *ip = [self.table indexPathForSelectedRow];
			if (ip!=nil)
			{
				[self.table deselectRowAtIndexPath:ip animated:YES];
			}
		}

	}	
}

-(void)backgroundTaskStarted
{
	if (self.searchBar)
	{
		[self.searchBar resignFirstResponder];
	}
}

- (bool)backgroundTaskWait
{
	return self.backgroundRefresh && self.table.decelerating;
}

#pragma mark Search filter


- (bool)isSearchRow:(int)section
{
	return section == 0;
}
- (CGFloat)searchRowHeight
{
	return 45.0;
}
- (UITableViewCell *)searchRowCell
{
	static NSString *cellId = @"search cell";
	
	UITableViewCell *cell = nil;
	
	
	cell = [self.table dequeueReusableCellWithIdentifier:cellId];
	
	if (cell != nil)
	{
		return cell;
	}
		
	CGRect rect;
		
	rect = CGRectMake(0.0, 0.0, 320.0, [self searchRowHeight]);
		
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
		
	self.searchBar = [[[UISearchBar alloc] initWithFrame:rect] autorelease];
	
	self.searchBar.delegate = self;
	// self.searchBar.showsCancelButton = YES;
	[cell addSubview:self.searchBar];
	
	return cell;
}

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
//	[self.searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
	[self reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText   // called when text changes (including clear)
{}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	if (!self.searchController.isActive)
	{
	
		
		[self.searchController setActive:YES animated:YES];

	}
	// [self reloadData];
	
			
	return YES;
}

/*
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;                       // called when text ends editing
{
	[self.searchController setActive:NO animated:YES];
	
}
*/

- (NSMutableArray *)topViewData
{
	NSMutableArray *items = nil;
	if (self.searchController !=nil && self.searchController.isActive)
	{
		items = [self filteredData:self.searchController.searchResultsTableView];
	}
	else
	{
		items = [self filteredData:self.table];
	}
	return items;
}


- (NSMutableArray *)filteredData:(UITableView *)table
{
	if (table == self.table)
	{
		return self.searchableItems;
	}
	return _filteredItems;
}

#pragma mark -
#pragma mark UISearchDisplayDelegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[self filterItems];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterItems];    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
	
	[self reloadData];
}

- (void)iOS7workaroundPromptGap
{
    // This is a workaround for the prompt leaving a gap. Not sure why I need it here especially and not in other windows.
    // Based on this answer:  http://stackoverflow.com/questions/19372024/navigation-bar-with-prompt-appears-over-the-view-with-new-ios7-sdk
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        CGRect nbFrame = self.navigationController.navigationBar.frame;
        __block CGRect vFrame = self.view.frame;
        __block CGFloat diff = nbFrame.size.height + nbFrame.origin.y - vFrame.origin.y;
        if (diff != 0.0) {
            __block CGSize size = self.table.contentSize;
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                                  delay:0.0
                                options: UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 vFrame.origin.y += diff;
                                 vFrame.size.height -= diff;
                                 self.view.frame = vFrame;
                                 
                                 size.height -= diff;
                                 self.table.contentSize = size;
                             }
                             completion:^(BOOL finished){
                                 DEBUG_LOG(@"Animation!");
                             }];
        }
    }
}

- (void)deselectItemCallback
{
    NSIndexPath *ip = [self.table indexPathForSelectedRow];
    if (ip!=nil)
    {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}


@end

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
#import <MapKit/MapKit.h>
#include "iOSCompat.h"


@implementation TableViewWithToolbar

@synthesize table				= _tableView;
@synthesize backgroundRefresh	= _backgroundRefresh;


@synthesize enableSearch = _enableSearch;
@synthesize searchableItems = _searchableItems;
@synthesize filtered = _filtered;
@synthesize searchController = _searchController;
@synthesize sectionTypes = _sectionTypes;
@synthesize perSectionRowTypes = _perSectionRowTypes;
@synthesize mapView = _mapView;
@dynamic paragraphFont;
@dynamic basicFont;
@dynamic smallFont;


#define DISCLAIMER_TAG 1
#define UPDATE_TAG	   2
#define STREETCAR_TAG  3
#define MAP_TAG        4

-(void)finishWithMapView
{
    if (self.mapView)
    {
        self.mapView.delegate = nil;
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.showsUserLocation=FALSE;
        [self.mapView removeFromSuperview];
        
        // only cleans up properly if animations are complete
        MKMapView *finalOne = self.mapView.retain;
        [finalOne performSelector:@selector(release) withObject:nil afterDelay:(NSTimeInterval)4.0];
        
        self.mapView = nil;
    }
}


- (void)dealloc {
    self.table.tableHeaderView  = nil;
	self.table                  = nil;
	self.callback               = nil;
    
    if (self.searchController)
    {
        self.searchController.delegate = nil;
        self.searchController.searchBar.delegate = nil;
    }
	self.searchController = nil;
    
	self.searchableItems= nil;
   
	[_basicFont release];
	[_smallFont release];
	[_paragraphFont release];
	[_filteredItems release];
    
    self.sectionTypes = nil;
    self.perSectionRowTypes = nil;
    
    [self finishWithMapView];
	
	[super dealloc];
}

#pragma mark View overridden methods

- (instancetype)init {
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
    
    compatSetIfExists(self.table, setCellLayoutMarginsFollowReadableWidth:, NO);  // iOS9

	// set the tableview delegate to this object
	self.table.delegate = self;	
	
	// Set the table view datasource to the data source
	self.table.dataSource = self;
	
	if (self.enableSearch)
	{
        // The TableViewController used to display the results of a search
        UITableViewController *searchResultsController = [[[UITableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        // searchResultsController.automaticallyAdjustsScrollViewInsets = NO; // Remove table view insets
        searchResultsController.tableView.dataSource = self;
        searchResultsController.tableView.delegate = self;
        
        self.searchController = [[[UISearchController alloc] initWithSearchResultsController:searchResultsController] autorelease];
        self.searchController.searchBar.scopeButtonTitles = [NSArray array];
        self.searchController.searchResultsUpdater = self;
        self.searchController.dimsBackgroundDuringPresentation = YES;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        // self.searchController.searchBar.delegate = self;

		self.table.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
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
		
		if (self.searchController != nil)
		{
			searchText = self.searchController.searchBar.text;
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
        UITableViewController *searchView = (UITableViewController *)self.searchController.searchResultsController;
		[searchView.tableView reloadData];
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

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.mapView)
    {
        self.mapView.showsUserLocation = NO;
    }
    
    [super viewWillDisappear:animated];
}



- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (self.mapView)
    {
        self.mapView.showsUserLocation = _mapShowsUserLocation;
    }
    
    
	NSIndexPath *ip = self.table.indexPathForSelectedRow;
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
    static NSString *defaultId = @"default";
    
    ERROR_LOG(@"Unexpected default cell used.");
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:defaultId];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:defaultId] autorelease];
    }
	return cell;
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
    NSIndexPath *ip = self.table.indexPathForSelectedRow;
    if (ip!=nil)
    {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}

- (CGFloat)getAtrributedTextHeight:(NSAttributedString *)text
{
    CGFloat width = 0.0;
    
    width = self.screenInfo.appWinWidth - 20;
    DEBUG_LOG(@"Width for text %f\n", width);

    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     context:nil];
    
    return rect.size.height;
}

- (CGFloat)getTextHeight:(NSString *)text font:(UIFont *)font;
{
	CGFloat width = 0.0;
    width = self.screenInfo.appWinWidth - 20 - font.pointSize;
	DEBUG_LOG(@"Width for text %f\n", width);
	
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
        NSStringDrawingUsesLineFragmentOrigin;
    
    NSDictionary *attr = @{NSFontAttributeName: font};
    CGRect bounds = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                              options:options
                                           attributes:attr
                                              context:nil];
    
	return bounds.size.height + font.pointSize + font.pointSize;
}

- (void)updateAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath text:(NSString *)str alwaysSaySection:(BOOL)alwaysSaySection
{
	cell.accessibilityLabel = str;
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
	cell.accessibilityLabel = label.text;
	
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

	cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", text, cell.accessibilityLabel];
	
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
		NSIndexPath *ip = self.table.indexPathForSelectedRow;
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

- (UIFont*)basicFont
{
	if (_basicFont == nil)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		{
            if (self.screenInfo.screenWidth >= WidthiPhone6)
            {
                _basicFont =[[self systemFontBold:NO size:20.0] retain];
            }
            else
            {
                _basicFont =[[self systemFontBold:NO size:18.0] retain];
            }

		}
		else 
		{
            _basicFont = [[self systemFontBold:NO size:22.0] retain];
		}
	}
	return _basicFont;
}

- (UIFont*)smallFont
{
	if (_smallFont == nil)
	{
		if  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		{
            if (self.screenInfo.screenWidth >= WidthiPhone6)
            {
                _smallFont =[[self systemFontBold:NO size:16.0] retain];
            }
            else
            {
                _smallFont =[[self systemFontBold:NO size:14.0] retain];
            }
		}
		else 
		{
			_smallFont = [[self systemFontBold:NO size:22.0] retain];
		}		
	}
	return _smallFont;
}

- (UIFont*)paragraphFont
{
	if (_paragraphFont == nil)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		{
            if (self.screenInfo.screenWidth >= WidthiPhone6)
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		return 40.0;
	}
	return 45.0;
}

- (CGFloat)narrowRowHeight
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
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
			NSIndexPath *ip = self.table.indexPathForSelectedRow;
			if (ip!=nil)
			{
				[self.table deselectRowAtIndexPath:ip animated:YES];
			}
		}

	}	
}

-(void)backgroundTaskStarted
{
	if (self.searchController)
	{
		[self.searchController.searchBar resignFirstResponder];
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
		
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
		
#if 0
	self.searchBar = [[[UISearchBar alloc] initWithFrame:rect] autorelease];
	
	self.searchBar.delegate = self;
	// self.searchBar.showsCancelButton = YES;
	[cell addSubview:self.searchBar];
#endif
	return cell;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self reloadData];
}

#if 0

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
//	[self.searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.searchController.searchBar resignFirstResponder];
	[self reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText   // called when text changes (including clear)
{
    [self reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	if (!self.searchController.isActive)
	{
	
		[self.searchController.searchBar sizeToFit];
        [self.searchController setActive:YES];
        // [self.searchController.searchBar becomeFirstResponder];
		// [self.searchController setActive:YES animated:YES];

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

#endif

- (NSMutableArray *)topViewData
{
	NSMutableArray *items = nil;
	if (self.searchController !=nil && self.searchController.isActive)
	{
        UITableViewController *searchView = (UITableViewController *)self.searchController.searchResultsController;
		items = [self filteredData:searchView.tableView];
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

#if 0

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

#endif



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
    NSIndexPath *ip = self.table.indexPathForSelectedRow;
    if (ip!=nil)
    {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}


- (void)clearSectionMaps
{
    self.sectionTypes       = [NSMutableArray array];
    self.perSectionRowTypes = [NSMutableArray array];
}


- (NSInteger)firstSectionOfType:(NSInteger)type
{
    if (self.sectionTypes)
    {
        for (int section = 0; section < self.sectionTypes.count; section ++)
        {
            NSNumber *t = self.sectionTypes[section];
            
            if (t.integerValue == type)
            {
                return section;
            }
        }
    }
    
    return  kNoRowSectionTypeFound;
}

- (NSInteger)firstRowOfType:(NSInteger)type inSection:(NSInteger)section
{
    if (section == kNoRowSectionTypeFound)
    {
        return kNoRowSectionTypeFound;
    }
    
    if (self.perSectionRowTypes)
    {
        if (section < self.perSectionRowTypes.count)
        {
            NSArray *types = self.perSectionRowTypes[section];
            
            int row = 0;
            
            for (row = 0; row < types.count; row ++)
            {
                NSNumber *t = types[row];
                
                if (t.integerValue == type)
                {
                    return row;
                }
            }
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (NSIndexPath*)firstIndexPathOfSectionType:(NSInteger)sectionType rowType:(NSInteger)rowType
{
    NSInteger section = [self firstSectionOfType:sectionType];
    
    NSInteger row = [self firstRowOfType:rowType inSection:section];
        
    if (row!=kNoRowSectionTypeFound)
    {
        return [NSIndexPath indexPathForRow:row inSection:section];
    }

    return nil;
}


- (NSInteger)sectionType:(NSInteger)section
{
    if (self.sectionTypes)
    {
        NSNumber *type = self.sectionTypes[section];
        
        if (type)
        {
            return type.integerValue;
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (void)clearSection:(NSInteger)section
{
    [self.perSectionRowTypes setObject:[NSMutableArray array] atIndexedSubscript:section];
}
- (NSInteger)addRowType:(NSInteger)type forSectionType:(NSInteger)sectionType
{
    NSInteger section = [self firstSectionOfType:sectionType];
    
    NSMutableArray *types = self.perSectionRowTypes[section];
    
    [types addObject:@(type)];
    
    return types.count - 1;
}

- (NSInteger)rowType:(NSIndexPath*)index
{
    if (self.perSectionRowTypes)
    {
        if (index.section < self.perSectionRowTypes.count)
        {
            NSArray *types = self.perSectionRowTypes[index.section];
            
            if (index.row < types.count)
            {
                NSNumber *val = types[index.row];
                
                if (val)
                {
                    return val.integerValue;
                }
            }
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (NSInteger)addSectionType:(NSInteger)type
{
    [self.sectionTypes       addObject:@(type)];
    [self.perSectionRowTypes addObject:[NSMutableArray<NSNumber*> array]];
    
    return self.sectionTypes.count - 1;
}

- (NSInteger)addRowType:(NSInteger)type
{
    NSMutableArray *types = self.perSectionRowTypes.lastObject;
    
    [types addObject:@(type)];
    
    return types.count - 1;
}

- (NSInteger)rowsInSection:(NSInteger)section
{
    if (section < self.perSectionRowTypes.count)
    {
        return self.perSectionRowTypes[section].count;
    }
    return 0;
}



- (NSInteger)sections
{
     if (self.sectionTypes == nil)
     {
         return 0;
     }
    
    return self.sectionTypes.count;
}

- (CGFloat)mapCellHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return 150.0;
    }
    
    return 250.0;
}

- (UITableViewCell*)getMapCell:(NSString*)id withUserLocation:(bool)userLocation
{
    CGRect middleRect = [self getMiddleWindowRect];
    
    CGRect mapRect = CGRectMake(0,0, middleRect.size.width, [self mapCellHeight]);
    
    
    
    UITableViewCell *cell  = [self.table dequeueReusableCellWithIdentifier:MakeCellId(kRowMap)];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kRowMap)] autorelease];
    }
    
    MKMapView *map = (MKMapView*)[cell viewWithTag:MAP_TAG];
    
    if (map == nil)
    {
        [self finishWithMapView];
        
        map = [[[MKMapView alloc] initWithFrame:mapRect] autorelease];
        map.tag = MAP_TAG;
        _mapShowsUserLocation = userLocation;
        map.showsUserLocation = userLocation;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell addSubview:map];
        
        self.mapView = map;
        
        map.userInteractionEnabled = YES;
        map.scrollEnabled = FALSE;
        map.zoomEnabled = FALSE;
        map.pitchEnabled = FALSE;
        map.rotateEnabled = FALSE;
        
        UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(didTapMap:)];
        [map addGestureRecognizer:tapRec];
        [tapRec release];
        
    }
    else
    {
        map.frame = mapRect;
        [map removeAnnotations:map.annotations];
    }
    
    self.mapView = map;

    return cell;
    
}

- (void)didTapMap:(id)sender
{
    
}




@end

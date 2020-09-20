//
//  TableViewWithToolbar.m
//  PDXBus
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
#import "iOSCompat.h"
#import "BearingAnnotationView.h"
#import "NSString+Helper.h"
#import "TripPlannerSummaryView.h"
#import "Detour+iOSUI.h"
#import "MapViewWithDetourStops.h"
#import "MainQueueSync.h"
#import "TintedImageCache.h"
#import "DetourTableViewCell.h"
#import "DepartureTimesView.h"
#import "UIApplication+Compat.h"

@interface TableViewWithToolbar<FilteredItemType>() {
    NSMutableArray<FilteredItemType> *_filteredItems;
    bool _mapShowsUserLocation;
    UIFont *_smallFont;
}

@property (nonatomic, strong) NSMutableArray<NSNumber *> *sectionTypes;
@property (nonatomic, strong) NSMutableArray<NSMutableArray <NSNumber *> *> *perSectionRowTypes;

@end

@implementation TableViewWithToolbar

static NSString *callString = @"tel:1-503-238-RIDE";

- (bool)canCallTriMet {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:callString]];
}

- (void)callTriMet {
    [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:callString]];
};

#define MAP_TAG 4

static CGFloat leftInset;

- (void)finishWithMapView {
    if (self.mapView) {
        self.mapView.delegate = nil;
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.showsUserLocation = FALSE;
        [self.mapView removeFromSuperview];
        
        // only cleans up properly if animations are complete
        MKMapView *finalOne = self.mapView;
        [finalOne performSelector:@selector(self) withObject:nil afterDelay:(NSTimeInterval)4.0];
        
        self.mapView = nil;
    }
}

- (void)dealloc {
    self.table.tableHeaderView = nil;
    self.stopIdCallback = nil;
    
    if (self.searchController) {
        self.searchController.delegate = nil;
        self.searchController.searchBar.delegate = nil;
    }
    
    [self finishWithMapView];
}

#pragma mark View overridden methods

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.table.backgroundColor = [UIColor modeAwareAppBackground];
}

- (void)recreateNewTable {
    if (self.table != nil) {
        [self.table removeFromSuperview];
        self.table = nil;
    }
    
    // Set the size for the table view
    CGRect tableViewRect = self.middleWindowRect;
    
    
    // Create a table view
    self.table = [[UITableView alloc] initWithFrame:tableViewRect style:self.style];
    // set the autoresizing mask so that the table will always fill the view
    self.table.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    compatSetIfExists(self.table, setCellLayoutMarginsFollowReadableWidth:, NO);  // iOS9
    
    // set the tableview delegate to this object
    self.table.delegate = self;
    
    // Set the table view datasource to the data source
    self.table.dataSource = self;
    
    if (self.enableSearch) {
        // The TableViewController used to display the results of a search
        UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        // searchResultsController.automaticallyAdjustsScrollViewInsets = NO; // Remove table view insets
        searchResultsController.tableView.dataSource = self;
        searchResultsController.tableView.delegate = self;
        
        searchResultsController.extendedLayoutIncludesOpaqueBars = YES;
        
        if (@available(iOS 13.0, *)) {
            // searchResultsController.extendedLayoutIncludesOpaqueBars = TRUE;
            // searchResultsController.edgesForExtendedLayout = UIRectEdgeAll;
            
            searchResultsController.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        } else if (@available(iOS 11.0, *)) {
            searchResultsController.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.definesPresentationContext = YES;
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
        self.searchController.searchBar.scopeButtonTitles = [NSArray array];
        self.searchController.searchResultsUpdater = self;
#ifdef TARGET_OS_MACCATALYST
        self.searchController.obscuresBackgroundDuringPresentation  = YES;
#else
        self.searchController.dimsBackgroundDuringPresentation = YES;
#endif
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.backgroundImage = [[UIImage alloc] init];
        self.searchController.searchBar.backgroundColor = UIColor.modeAwareAppBackground;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        
        self.table.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
        // self.tableHeaderHeight = [self searchRowHeight];
        
        UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, -200, self.table.bounds.size.width, 200)];
        [topView setBackgroundColor:[UIColor modeAwareAppBackground]];
        [self.table addSubview:topView];
    }
    
    if (@available(iOS 11.0, *)) {
        self.table.contentInsetAdjustmentBehavior = self.neverAdjustContentInset ? UIScrollViewContentInsetAdjustmentNever : UIScrollViewContentInsetAdjustmentAutomatic;
    }
    
    [self.view addSubview:self.table];
    
    // Hide all the cell lines at the end
    self.table.tableFooterView = [[UIView alloc] init];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    if (bar == self.searchController.searchBar) {
        return UIBarPositionTopAttached;
    } else { // Handle other cases
        return UIBarPositionAny;
    }
}

- (bool)neverAdjustContentInset {
    return NO;
}

- (UIColor *)lighterColorForColor:(UIColor *)c {
    CGFloat r, g, b, a;
    
    if ([c getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    }
    
    return nil;
}

- (NSString *)stringToFilter:(NSObject *)i {
    return ((id<SearchFilter>)i).stringToFilter;
}

- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index {
    NSRange range = [[self stringToFilter:i] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        return i;
    }
    
    return nil;
}

- (void)filterItems {
    if (_enableSearch) {
        NSString *searchText = nil;
        
        if (self.searchController != nil) {
            searchText = self.searchController.searchBar.text;
        }
        
        if (searchText == nil || searchText.length == 0) {
            _filteredItems = self.searchableItems;
        } else {
            NSMutableArray *filtered = [[NSMutableArray alloc] init];
            NSInteger index = 0;
            
            for (id i in self.searchableItems) {
                id obj = [self filteredObject:i searchString:searchText index:index];
                
                if (obj) {
                    [filtered addObject:obj];
                }
                
                index++;
            }
            
            _filteredItems = filtered;
        }
    }
}

- (void)reloadData {
    [super reloadData];
    [self filterItems];
    
    if (self.searchController != nil && self.searchController.isActive) {
        UITableViewController *searchView = (UITableViewController *)self.searchController.searchResultsController;
        [searchView.tableView reloadData];
    } else {
        [self.table reloadData];
    }
}

- (void)loadView {
    [super loadView];
    
    @autoreleasepool {
        [self recreateNewTable];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.mapView) {
        self.mapView.delegate = nil;
        self.mapView.showsUserLocation = NO;
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_reloadOnAppear) {
        _reloadOnAppear = NO;
        [self reloadData];
    }
    
    if (self.mapView) {
        self.mapView.showsUserLocation = _mapShowsUserLocation;
        self.mapView.delegate = self;
    }
    
    NSIndexPath *ip = self.table.indexPathForSelectedRow;
    
    if (ip != nil) {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
    
    if (self.enableSearch && self.searchController && self.searchController.isActive) {
        UITableViewController *searchView = (UITableViewController *)self.searchController.searchResultsController;
        
        if (searchView.tableView && !searchView.tableView.isHidden) {
            NSIndexPath *ip = searchView.tableView.indexPathForSelectedRow;
            
            if (ip != nil) {
                [searchView.tableView deselectRowAtIndexPath:ip animated:YES];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
}

#pragma mark Style

- (UITableViewStyle)style {
    return UITableViewStylePlain;
}

#pragma mark Table View methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ERROR_LOG(@"Unexpected default cell used.");
    
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"default"];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)leftInset {
    return leftInset;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell.reuseIdentifier isEqualToString:kDisclaimerCellId]) {
        cell.backgroundColor = [UIColor modeAwareDisclaimerBackground];
    } else if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
        cell.backgroundColor = [UIColor modeAwareSystemWideAlertBackground];
    } else {
        cell.backgroundColor = [UIColor modeAwareCellBackground];
    }
    
    if (cell.layoutMargins.left > leftInset) {
        leftInset = cell.layoutMargins.left;
    }
}

#pragma mark Table view call helper methods

- (void)clearSelection {
    NSIndexPath *ip = self.table.indexPathForSelectedRow;
    
    if (ip != nil) {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}

- (void)updateAccessibility:(UITableViewCell *)cell {
    if (cell.textLabel.attributedText != nil) {
        cell.textLabel.accessibilityLabel = cell.textLabel.attributedText.string.phonetic;
    } else if (cell.textLabel.text != nil) {
        cell.textLabel.accessibilityLabel = cell.textLabel.text.phonetic;
    }
}

- (UITableViewCell *)disclaimerCell:(UITableView *)tableView {
    /*
     Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
     */
    
#define MAIN_FONT_SIZE  16.0
#define SMALL_FONT_SIZE 12.0
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kDisclaimerCellId];
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.detailTextLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.text = kTriMetDisclaimerText;
        cell.backgroundColor = [UIColor modeAwareDisclaimerBackground];
    }
    
    return cell;
}

- (void)updateDisclaimerAccessibility:(UITableViewCell *)cell {
    NSMutableString *str = [NSMutableString string];
    
    if (cell.textLabel.attributedText) {
        [str appendString:cell.textLabel.attributedText.string];
    } else if (cell.textLabel.text) {
        [str appendString:cell.textLabel.text];
    }
    
    [str appendString:@" "];
    
    if (cell.detailTextLabel.attributedText) {
        [str appendString:cell.detailTextLabel.attributedText.string];
    } else if (cell.detailTextLabel.text) {
        [str appendString:cell.detailTextLabel.text];
    }
    
    cell.accessibilityLabel = str.phonetic;
}

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text trimetDisclaimer:(bool)trimetDisclaimer {
    if (trimetDisclaimer) {
        if (text != nil) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Streetcar: %@\n%@", text, kTriMetDisclaimerText];
            cell.detailTextLabel.numberOfLines = 2;
        } else {
            cell.detailTextLabel.text = kTriMetDisclaimerText;
            cell.detailTextLabel.numberOfLines = 1;
        }
    } else {
        if (text != nil) {
            cell.detailTextLabel.text = @"";
            cell.detailTextLabel.numberOfLines = 1;
        } else {
            cell.detailTextLabel.text = text;
            cell.detailTextLabel.numberOfLines = 1;
        }
    }
}

- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text {
    [self addTextToDisclaimerCell:cell text:text lines:1];
}

- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text lines:(NSInteger)numberOfLines {
    if (text != nil) {
        cell.textLabel.text = text;
        cell.textLabel.numberOfLines = numberOfLines;
    } else {
        cell.textLabel.text = @"";
        cell.textLabel.numberOfLines = 1;
    }
}

- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell {
    [self addTextToDisclaimerCell:cell text:kNetworkMsg];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (UIFont *)systemFontBold:(bool)bold size:(CGFloat)size {
    if (bold) {
        return [UIFont boldSystemFontOfSize:size];
    }
    
    return [UIFont systemFontOfSize:size];
}

- (CGFloat)heightOffset {
    return -[UIApplication sharedApplication].compatStatusBarFrame.size.height;
}

- (CGFloat)basicRowHeight {
    if (SMALL_SCREEN) {
        return 40.0;
    }
    
    return 45.0;
}

- (CGFloat)narrowRowHeight {
    if (SMALL_SCREEN) {
        return 35.0;
    }
    
    return 40.0;
}

#pragma mark Background task implementaion

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled {
    if (self.backgroundRefresh) {
        self.backgroundRefresh = false;
        
        if (!cancelled) {
            [self reloadData];
            // [[(MainTableViewController *)[self.navigationController topViewController] tableView] reloadData];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        if (!cancelled) {
            [self.navigationController pushViewController:viewController animated:YES];
        } else {
            NSIndexPath *ip = self.table.indexPathForSelectedRow;
            
            if (ip != nil) {
                [self.table deselectRowAtIndexPath:ip animated:YES];
            }
        }
    }
}

- (void)backgroundTaskStarted {
    if (self.searchController) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (bool)backgroundTaskWait {
    __block BOOL decelerating = NO;
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        decelerating = self.table.decelerating;
    }];
    
    return self.backgroundRefresh && decelerating;
}

#pragma mark Search filter
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.isActive) {
        [self reloadData];
    }
}

- (NSMutableArray *)topViewData {
    NSMutableArray *items = nil;
    
    if (self.searchController != nil && self.searchController.isActive) {
        UITableViewController *searchView = (UITableViewController *)self.searchController.searchResultsController;
        items = [self filteredData:searchView.tableView];
    } else {
        items = [self filteredData:self.table];
    }
    
    return items;
}

- (NSMutableArray *)filteredData:(UITableView *)table {
    if (table == self.table) {
        return self.searchableItems;
    }
    
    return _filteredItems;
}

- (void)iOS7workaroundPromptGap {
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
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                vFrame.origin.y += diff;
                vFrame.size.height -= diff;
                self.view.frame = vFrame;
                
                size.height -= diff;
                self.table.contentSize = size;
            }
                             completion:^(BOOL finished) {
                DEBUG_LOG(@"Animation!");
            }];
        }
    }
}

- (void)deselectItemCallback {
    NSIndexPath *ip = self.table.indexPathForSelectedRow;
    
    if (ip != nil) {
        [self.table deselectRowAtIndexPath:ip animated:YES];
    }
}

- (void)clearSectionMaps {
    self.sectionTypes = [NSMutableArray array];
    self.perSectionRowTypes = [NSMutableArray array];
}

- (NSInteger)firstSectionOfType:(NSInteger)type {
    if (self.sectionTypes) {
        for (int section = 0; section < self.sectionTypes.count; section++) {
            NSNumber *t = self.sectionTypes[section];
            
            if (t.integerValue == type) {
                return section;
            }
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (NSInteger)firstRowOfType:(NSInteger)type inSection:(NSInteger)section {
    if (section == kNoRowSectionTypeFound) {
        return kNoRowSectionTypeFound;
    }
    
    if (self.perSectionRowTypes) {
        if (section < self.perSectionRowTypes.count) {
            NSArray *types = self.perSectionRowTypes[section];
            
            int row = 0;
            
            for (row = 0; row < types.count; row++) {
                NSNumber *t = types[row];
                
                if (t.integerValue == type) {
                    return row;
                }
            }
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (NSIndexPath *)firstIndexPathOfSectionType:(NSInteger)sectionType rowType:(NSInteger)rowType {
    if (self.sectionTypes) {
        for (int section = 0; section < self.sectionTypes.count; section++) {
            NSNumber *t = self.sectionTypes[section];
            
            if (t.integerValue == sectionType) {
                NSInteger row = [self firstRowOfType:rowType inSection:section];
                
                if (row != kNoRowSectionTypeFound) {
                    return [NSIndexPath indexPathForRow:row inSection:section];
                }
            }
        }
    }
    
    return nil;
}

- (NSInteger)sectionType:(NSInteger)section {
    if (self.sectionTypes) {
        NSNumber *type = self.sectionTypes[section];
        
        if (type) {
            return type.integerValue;
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (void)clearSection:(NSInteger)section {
    [self.perSectionRowTypes setObject:[NSMutableArray array] atIndexedSubscript:section];
}

- (NSInteger)addRowType:(NSInteger)type forSectionType:(NSInteger)sectionType {
    NSInteger section = [self firstSectionOfType:sectionType];
    
    NSMutableArray *types = self.perSectionRowTypes[section];
    
    [types addObject:@(type)];
    
    return types.count - 1;
}

- (NSInteger)rowType:(NSIndexPath *)index {
    if (self.perSectionRowTypes) {
        if (index.section < self.perSectionRowTypes.count) {
            NSArray *types = self.perSectionRowTypes[index.section];
            
            if (index.row < types.count) {
                NSNumber *val = types[index.row];
                
                if (val) {
                    return val.integerValue;
                }
            }
        }
    }
    
    return kNoRowSectionTypeFound;
}

- (NSInteger)addSectionType:(NSInteger)type {
    [self.sectionTypes addObject:@(type)];
    [self.perSectionRowTypes addObject:[NSMutableArray<NSNumber *> array]];
    
    return self.sectionTypes.count - 1;
}

- (NSInteger)addRowType:(NSInteger)type {
    NSMutableArray *types = self.perSectionRowTypes.lastObject;
    
    [self.perSectionRowTypes.lastObject addObject:@(type)];
    
    return types.count - 1;
}

- (NSInteger)addRowType:(NSInteger)type count:(NSInteger)count {
    NSMutableArray *types = self.perSectionRowTypes.lastObject;
    
    NSNumber *typeNume = @(type);
    
    for (int i = 0; i < count; i++) {
        [types addObject:typeNume];
    }
    
    return types.count - 1;
}

- (NSInteger)rowsInLastSection {
    return self.perSectionRowTypes.lastObject.count;
}

- (NSInteger)rowsInSection:(NSInteger)section {
    if (section < self.perSectionRowTypes.count) {
        return self.perSectionRowTypes[section].count;
    }
    
    return 0;
}

- (NSInteger)sections {
    if (self.sectionTypes == nil) {
        return 0;
    }
    
    return self.sectionTypes.count;
}

- (CGFloat)mapCellHeight {
    if (SMALL_SCREEN) {
        return 150.0;
    }
    
    return 250.0;
}

- (UITableViewCell *)getMapCell:(NSString *)id withUserLocation:(bool)userLocation {
    CGRect middleRect = self.middleWindowRect;
    
    CGRect mapRect = CGRectMake(0, 0, middleRect.size.width, [self mapCellHeight]);
    
    UITableViewCell *cell = [self tableView:self.table cellWithReuseIdentifier:MakeCellId(kRowMap)];
    
    MKMapView *map = (MKMapView *)[cell viewWithTag:MAP_TAG];
    
    if (map == nil) {
        [self finishWithMapView];
        
        map = [[MKMapView alloc] initWithFrame:mapRect];
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
        map.delegate = self;
        
        UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(didTapMap:)];
        [map addGestureRecognizer:tapRec];
    } else {
        map.frame = mapRect;
        [map removeAnnotations:map.annotations];
    }
    
    self.mapView = map;
    
    return cell;
}

- (void)didTapMap:(id)sender {
}

//Without this the page bounces when reloading the location time.

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.table.rowHeight;
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *retView = nil;
    
    if (annotation == mv.userLocation) {
        return nil;
    } else if ([annotation conformsToProtocol:@protocol(MapPinColor)]) {
        retView = [BearingAnnotationView viewForPin:(id<MapPinColor>)annotation mapView:mv];
        
        retView.canShowCallout = YES;
    }
    
    return retView;
}

- (void)updateAnnotations:(MKMapView *)map {
    if (map) {
        for (id <MKAnnotation> annotation in map.annotations) {
            MKAnnotationView *av = [map viewForAnnotation:annotation];
            
            if (av && [av isKindOfClass:[BearingAnnotationView class]]) {
                BearingAnnotationView *bv = (BearingAnnotationView *)av;
                
                [bv updateDirectionalAnnotationView:map];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)resuseIdentifier {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:resuseIdentifier];
    }
    
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:resuseIdentifier];
        cell.textLabel.numberOfLines = 0;
    }
    
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier font:(UIFont *)font {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:resuseIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = font;
    }
    
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableViewCell:(UITableView *)tableView
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"1"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor modeAwareText];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = nil;
    
    return cell;
}

- (UITableViewCell *)tableViewMultiLineCell:(UITableView *)tableView font:(UIFont*)font
{
    UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"0"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.font = font;
    cell.textLabel.adjustsFontSizeToFitWidth = NO;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.textColor = [UIColor modeAwareText];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = nil;
    return cell;
}

- (UITableViewCell *)tableViewMultiLineBasicCell:(UITableView *)tableView
{
    return  [self tableViewMultiLineCell:tableView font:self.basicFont];
}

- (UITableViewCell *)tableViewMultiLineParaCell:(UITableView *)tableView
{
    return  [self tableViewMultiLineCell:tableView font:self.paragraphFont];
}


- (void)detourToggle:(Detour *)detour indexPath:(NSIndexPath *)ip reloadSection:(bool)reloadSection {
    if (detour.systemWide) {
        [self detourAction:detour buttonType:DETOUR_BUTTON_COLLAPSE indexPath:ip reloadSection:reloadSection];
    }
}

- (void)safeScrollToTop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self tableView:self.table numberOfRowsInSection:0] > 0) {
            [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
        }
    });
}

- (void)detourAction:(Detour *)detour buttonType:(NSInteger)buttonType indexPath:(NSIndexPath *)ip reloadSection:(bool)reloadSection {
    if (buttonType == DETOUR_BUTTON_MAP) {
        [[MapViewWithDetourStops viewController] fetchLocationsMaybeAsync:self.backgroundTask detours:[NSArray arrayWithObject:detour] nav:self.navigationController];
        return;
    }
    
    if (buttonType == DETOUR_BUTTON_COLLAPSE) {
        UITableView *table = self.table;
        
        if (self.enableSearch && self.searchController && self.searchController.isActive) {
            table = ((UITableViewController *)(self.searchController.searchResultsController)).tableView;
        }
        
        [Settings toggleHiddenSystemWideDetour:detour.detourId];
        
        // UITableViewRowAnimation direction = [UserPrefs sharedInstance].hideSystemWideDetours ? UITableViewRowAnimationRight : UITableViewRowAnimationLeft;
        
        [table beginUpdates];
        
        if (reloadSection) {
            NSArray *visibleCells = self.table.visibleCells;
            
            NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
            
            for (UITableViewCell *cell in visibleCells) {
                if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
                    [indices addIndex:[table indexPathForCell:cell].section];
                }
            }
            
            [table reloadSections:indices withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            NSArray *visibleCells = self.table.visibleCells;
            
            NSMutableArray *indices = [NSMutableArray array];
            
            for (UITableViewCell *cell in visibleCells) {
                if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
                    [indices addObject:[table indexPathForCell:cell]];
                }
            }
            
            [table reloadRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [table endUpdates];
    }
}



- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
            // Clear the image cache as half of it is not needed
            [[TintedImageCache sharedInstance] userInterfaceStyleChanged:self.traitCollection.userInterfaceStyle];
            
            if (self.enableSearch && self.searchController) {
                self.searchController.searchBar.backgroundColor = UIColor.modeAwareAppBackground;
            }
            
            [self reloadData];
        }
        
        self.table.backgroundColor = [UIColor modeAwareAppBackground];
    }
}

@end

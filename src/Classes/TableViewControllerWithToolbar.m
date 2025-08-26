//
//  TableViewWithToolbar.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "TableViewControllerWithToolbar.h"
#import "AlertsForRouteIntent.h"
#import "BearingAnnotationView.h"
#import "DepartureTimesViewController.h"
#import "Detour+iOSUI.h"
#import "DetourTableViewCell.h"
#import "FindByLocationViewController.h"
#import "FlashViewController.h"
#import "Icons.h"
#import "MainQueueSync.h"
#import "MapViewControllerWithDetourStops.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "NetworkTestViewController.h"
#import "PDXBusAppDelegate+Methods.h"
#import "SearchFilter.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerSummaryViewController.h"
#import "UIApplication+Compat.h"
#import "UIFont+Utility.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "ViewControllerBase+MapPinAction.h"
#import "WebViewController.h"
#import "iOSCompat.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <MapKit/MapKit.h>
#import <UIKit/UISearchDisplayController.h>

@interface TableViewControllerWithToolbar <FilteredItemType>() {
    NSMutableArray<FilteredItemType> *_filteredItems;
    bool _mapShowsUserLocation;
    UIFont *_smallFont;
}

@property(nonatomic, strong) NSMutableArray<NSNumber *> *sectionTypes;
@property(nonatomic, strong)
    NSMutableArray<NSMutableArray<NSNumber *> *> *perSectionRowTypes;
@property(nonatomic, strong) NSArray *savedOverlays;

@end

@implementation TableViewControllerWithToolbar

static NSString *callString = @"tel:1-503-238-RIDE";

- (bool)canCallTriMet {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier =
        networkInfo.serviceSubscriberCellularProviders.allValues.firstObject;

    // Device has a carrier, and allows VOICE
    return (carrier.carrierName.length > 0);
}

- (void)callTriMet {
    [[UIApplication sharedApplication]
        compatOpenURL:[NSURL URLWithString:callString]];
};

#define MAP_TAG 4

static CGFloat leftInset;

- (instancetype)init {
    if ((self = [super init])) {
    }

    return self;
}

- (void)dealloc {
    _tableView.tableHeaderView = nil;
    self.stopIdStringCallback = nil;

    if (_searchController) {
        _searchController.delegate = nil;
        _searchController.searchBar.delegate = nil;
    }

    [self finishWithMapView];
}

- (void)finishWithMapView {
    if (self.mapView) {
        self.mapView.delegate = nil;
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.showsUserLocation = FALSE;
        [self.mapView removeFromSuperview];

        // only cleans up properly if animations are complete
        MKMapView *finalOne = self.mapView;
        [finalOne performSelector:@selector(self)
                       withObject:nil
                       afterDelay:(NSTimeInterval)4.0];

        self.mapView = nil;
    }
}

#pragma mark View overridden methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.tableView.backgroundColor = [UIColor modeAwareAppBackground];

    self.tableView.sectionHeaderTopPadding = 0;
}

- (void)recreateNewTable {
    if (self.tableView != nil) {
        [self.tableView removeFromSuperview];
        self.tableView = nil;
    }

    // Set the size for the table view
    CGRect tableViewRect = self.middleWindowRect;

    // Create a table view
    self.tableView = [[UITableView alloc] initWithFrame:tableViewRect
                                                  style:self.style];
    // set the autoresizing mask so that the table will always fill the view
    self.tableView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    compatSetIfExists(self.tableView, setCellLayoutMarginsFollowReadableWidth:,
                      NO); // iOS9

    // set the tableview delegate to this object
    self.tableView.delegate = self;

    // Set the table view datasource to the data source
    self.tableView.dataSource = self;

    if (self.enableSearch) {
        // The TableViewController used to display the results of a search
        UITableViewController *searchResultsController =
            [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        // searchResultsController.automaticallyAdjustsScrollViewInsets = NO; //
        // Remove table view insets
        searchResultsController.tableView.dataSource = self;
        searchResultsController.tableView.delegate = self;

        searchResultsController.extendedLayoutIncludesOpaqueBars = YES;

        searchResultsController.tableView.contentInsetAdjustmentBehavior =
            UIScrollViewContentInsetAdjustmentAutomatic;

        self.extendedLayoutIncludesOpaqueBars = YES;
        self.definesPresentationContext = YES;

        self.searchController = [[UISearchController alloc]
            initWithSearchResultsController:searchResultsController];
        self.searchController.searchBar.scopeButtonTitles = [NSArray array];
        self.searchController.searchResultsUpdater = self;
#ifdef TARGET_OS_MACCATALYST
        self.searchController.obscuresBackgroundDuringPresentation = YES;
#else
        self.searchController.dimsBackgroundDuringPresentation = YES;
#endif
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.backgroundImage =
            [[UIImage alloc] init];
        self.searchController.searchBar.backgroundColor =
            UIColor.modeAwareAppBackground;
        self.searchController.searchBar.searchBarStyle =
            UISearchBarStyleMinimal;

        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
        // self.tableHeaderHeight = [self searchRowHeight];

        UIView *topView = [[UIView alloc]
            initWithFrame:CGRectMake(0, -200, self.tableView.bounds.size.width,
                                     200)];
        [topView setBackgroundColor:[UIColor modeAwareAppBackground]];
        [self.tableView addSubview:topView];
    }

    self.tableView.contentInsetAdjustmentBehavior =
        self.neverAdjustContentInset
            ? UIScrollViewContentInsetAdjustmentNever
            : UIScrollViewContentInsetAdjustmentAutomatic;

    [self.view addSubview:self.tableView];

    // Hide all the cell lines at the end
    self.tableView.tableFooterView = [[UIView alloc] init];
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

- (id)filteredObject:(id)i
        searchString:(NSString *)searchText
               index:(NSInteger)index {
    NSRange range =
        [[self stringToFilter:i] rangeOfString:searchText
                                       options:NSCaseInsensitiveSearch];

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
                id obj = [self filteredObject:i
                                 searchString:searchText
                                        index:index];

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
        UITableViewController *searchView =
            (UITableViewController *)
                self.searchController.searchResultsController;
        [searchView.tableView reloadData];
    } else {
        [self.tableView reloadData];
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

    NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

    if (ip != nil) {
        [self.tableView deselectRowAtIndexPath:ip animated:YES];
    }

    if (self.enableSearch && self.searchController &&
        self.searchController.isActive) {
        UITableViewController *searchView =
            (UITableViewController *)
                self.searchController.searchResultsController;

        if (searchView.tableView && !searchView.tableView.isHidden) {
            NSIndexPath *ip = searchView.tableView.indexPathForSelectedRow;

            if (ip != nil) {
                [searchView.tableView deselectRowAtIndexPath:ip animated:YES];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a
                                     // superview Release anything that's not
                                     // essential, such as cached data
}

#pragma mark Style

- (UITableViewStyle)style {
    return UITableViewStylePlain;
}

#pragma mark Table View methods

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ERROR_LOG(@"Unexpected default cell used.");

    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"default"];

    return cell;
}

- (CGFloat)leftInset {
    return leftInset;
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell.reuseIdentifier isEqualToString:kDisclaimerCellId]) {
        cell.backgroundColor = [UIColor modeAwareDisclaimerBackground];
    } else if ([cell.reuseIdentifier
                   isEqualToString:kSystemDetourResuseIdentifier]) {
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
    NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

    if (ip != nil) {
        [self.tableView deselectRowAtIndexPath:ip animated:YES];
    }
}

- (void)updateAccessibility:(UITableViewCell *)cell {
    if (cell.textLabel.attributedText != nil) {
        cell.textLabel.accessibilityLabel =
            cell.textLabel.attributedText.string.phonetic;
    } else if (cell.textLabel.text != nil) {
        cell.textLabel.accessibilityLabel = cell.textLabel.text.phonetic;
    }
}

- (UITableViewCell *)disclaimerCell:(UITableView *)tableView {
    /*
     Create an instance of UITableViewCell and add tagged subviews for the name,
     local time, and quarter image of the time zone.
     */

#define MAIN_FONT_SIZE 16.0
#define SMALL_FONT_SIZE 12.0

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];

    if (cell == nil) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:kDisclaimerCellId];

        cell.textLabel.font =
            [UIFont monospacedDigitSystemFontOfSize:MAIN_FONT_SIZE
                                             weight:UIFontWeightBold];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.detailTextLabel.font =
            [UIFont monospacedDigitSystemFontOfSize:SMALL_FONT_SIZE];
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.baselineAdjustment =
            UIBaselineAdjustmentAlignCenters;
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor modeAwareGrayText];
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

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell
                                    text:(NSString *)text
                        trimetDisclaimer:(bool)trimetDisclaimer {
    if (trimetDisclaimer) {
        if (text != nil) {
            cell.detailTextLabel.text =
                [NSString stringWithFormat:@"Streetcar: %@\n%@", text,
                                           kTriMetDisclaimerText];
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
    [self addTextToDisclaimerCell:cell text:text lines:0];
}

- (void)addTextToDisclaimerCell:(UITableViewCell *)cell
                           text:(NSString *)text
                          lines:(NSInteger)numberOfLines {
    if (text != nil) {
        cell.textLabel.attributedText =
            [text attributedStringFromMarkUpWithFont:cell.textLabel.font];
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

- (CGFloat)heightOffset {
    if (@available(iOS 15.0, *)) {

        // In ios13 we added this on, and here we take it off again. C'est la
        // vie.
        return -[UIApplication firstKeyWindow]
                    .windowScene.statusBarManager.statusBarFrame.size.height;
    }

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

- (void)backgroundTaskDone:(UIViewController *)viewController
                 cancelled:(bool)cancelled {
    if (self.backgroundRefresh) {
        self.backgroundRefresh = false;

        if (!cancelled) {
            [self reloadData];
            // [[(MainTableViewController *)[self.navigationController
            // topViewController] tableView] reloadData];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        if (!cancelled) {
            [self.navigationController pushViewController:viewController
                                                 animated:YES];
        } else {
            NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

            if (ip != nil) {
                [self.tableView deselectRowAtIndexPath:ip animated:YES];
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
      decelerating = self.tableView.decelerating;
    }];

    return self.backgroundRefresh && decelerating;
}

#pragma mark Search filter
- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController {
    if (searchController.isActive) {
        [self reloadData];
    }
}

- (NSMutableArray *)topViewData {
    NSMutableArray *items = nil;

    if (self.searchController != nil && self.searchController.isActive) {
        UITableViewController *searchView =
            (UITableViewController *)
                self.searchController.searchResultsController;
        items = [self filteredData:searchView.tableView];
    } else {
        items = [self filteredData:self.tableView];
    }

    return items;
}

- (NSMutableArray *)filteredData:(UITableView *)table {
    if (table == self.tableView) {
        return self.searchableItems;
    }

    return _filteredItems;
}

- (void)iOS7workaroundPromptGap {
    // This is a workaround for the prompt leaving a gap. Not sure why I need it
    // here especially and not in other windows. Based on this answer:
    // http://stackoverflow.com/questions/19372024/navigation-bar-with-prompt-appears-over-the-view-with-new-ios7-sdk
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        CGRect nbFrame = self.navigationController.navigationBar.frame;
        __block CGRect vFrame = self.view.frame;
        __block CGFloat diff =
            nbFrame.size.height + nbFrame.origin.y - vFrame.origin.y;

        if (diff != 0.0) {
            __block CGSize size = self.tableView.contentSize;
            [UIView
                animateWithDuration:UINavigationControllerHideShowBarDuration
                delay:0.0
                options:UIViewAnimationOptionCurveEaseOut
                animations:^{
                  vFrame.origin.y += diff;
                  vFrame.size.height -= diff;
                  self.view.frame = vFrame;

                  size.height -= diff;
                  self.tableView.contentSize = size;
                }
                completion:^(BOOL finished) {
                  DEBUG_LOG(@"Animation!");
                }];
        }
    }
}

- (void)deselectItemCallback {
    NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

    if (ip != nil) {
        [self.tableView deselectRowAtIndexPath:ip animated:YES];
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

- (NSIndexPath *)firstIndexPathOfSectionType:(NSInteger)sectionType
                                     rowType:(NSInteger)rowType {
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
    [self.perSectionRowTypes setObject:[NSMutableArray array]
                    atIndexedSubscript:section];
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

- (NSInteger)addSectionTypeWithRow:(NSInteger)type {
    [self addSectionType:type];
    [self addRowType:type];

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
    if (self.perSectionRowTypes != nil) {
        return self.perSectionRowTypes.lastObject.count;
    }

    return 0;
}

- (NSInteger)rowsInSection:(NSInteger)section {
    if (self.perSectionRowTypes != nil &&
        section < self.perSectionRowTypes.count) {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (void)removeRowAtIndexPath:(NSIndexPath *)index {
    if (self.perSectionRowTypes) {
        if (index.section < self.perSectionRowTypes.count) {
            NSMutableArray *types = self.perSectionRowTypes[index.section];

            if (index.row < types.count) {
                [types removeObjectAtIndex:index.row];
            }
        }
    }
}

- (CGFloat)mapCellHeight {
    if (SMALL_SCREEN) {
        return 150.0;
    }

    return 250.0;
}

- (UITableViewCell *)getMapCell:(NSString *)id
               withUserLocation:(bool)userLocation
                     completion:(void (^_Nullable)(MKMapView *))completion {
    CGRect middleRect = self.middleWindowRect;

    CGRect mapRect =
        CGRectMake(0, 0, middleRect.size.width, [self mapCellHeight]);

    UITableViewCell *cell = [self tableView:self.tableView
                    cellWithReuseIdentifier:MakeCellId(kRowMap)];

    __block MKMapView *map =
        (MKMapView *)[cell.contentView viewWithTag:MAP_TAG];

    if (map == nil) {

        MainTask(^{
          [self finishWithMapView];

          map = [[MKMapView alloc] initWithFrame:mapRect];

          map.tag = MAP_TAG;
          self->_mapShowsUserLocation = userLocation;
          map.showsUserLocation = userLocation;
          cell.selectionStyle = UITableViewCellSelectionStyleNone;
          [cell.contentView addSubview:map];

          self.mapView = map;

          map.userInteractionEnabled = YES;
          map.scrollEnabled = FALSE;
          map.zoomEnabled = FALSE;
          map.pitchEnabled = FALSE;
          map.rotateEnabled = FALSE;
          map.delegate = self;

          UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc]
              initWithTarget:self
                      action:@selector(didTapMap:)];

          [map addGestureRecognizer:tapRec];

          self.mapView = map;

          completion(map);
        });

    } else {
        map.frame = mapRect;
        [map removeAnnotations:map.annotations];
        completion(map);
    }

    return cell;
}

- (void)didTapMap:(id)sender {
}

// Without this the page bounces when reloading the location time.
- (CGFloat)tableView:(UITableView *)tableView
    estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView.rowHeight;
}

- (MKAnnotationView *)mapView:(MKMapView *)mv
            viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *retView = nil;

    if (annotation == mv.userLocation) {
        return nil;
    } else if ([annotation conformsToProtocol:@protocol(MapPin)]) {
        retView = [BearingAnnotationView viewForPin:(id<MapPin>)annotation
                                            mapView:mv
                                          urlAction:self.linkActionForPin];

        retView.canShowCallout = YES;
    }

    return retView;
}

- (void)updateAnnotations:(MKMapView *)map {
    if (map) {
        for (id<MKAnnotation> annotation in map.annotations) {
            MKAnnotationView *av = [map viewForAnnotation:annotation];

            if (av && [av isKindOfClass:[BearingAnnotationView class]]) {
                BearingAnnotationView *bv = (BearingAnnotationView *)av;

                [bv updateDirectionalAnnotationView:map];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
       cellWithReuseIdentifier:(NSString *)resuseIdentifier {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];

    if (cell == nil) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:resuseIdentifier];
    }

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];

    if (cell == nil) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:resuseIdentifier];
        cell.textLabel.numberOfLines = 0;
    }

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier
                                font:(UIFont *)font {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];

    if (cell == nil) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:resuseIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = font;
    }

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

- (UITableViewCell *)tableViewCell:(UITableView *)tableView {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"1"];
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

- (UITableViewCell *)tableViewMultiLineCell:(UITableView *)tableView
                                       font:(UIFont *)font {
    UITableViewCell *cell = [self tableView:tableView
           multiLineCellWithReuseIdentifier:@"0"];
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

- (UITableViewCell *)tableView:(UITableView *)tableView
                    imageNamed:(NSString *)image
                   systemImage:(bool)systemImage
                simpleLinkCell:(NSString *)text
                          link:(NSString *)link {
    static NSString *cellId = @"link";
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:cellId];

    if (cell == nil) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:cellId];
    }

    if (link == nil) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    UIListContentConfiguration *config =
        [UIListContentConfiguration cellConfiguration];
    config.text = text;
    config.secondaryText = link;
    if (image) {
        if (image.firstUnichar == '!') {
            systemImage = true;
            image = [image substringFromIndex:1];
        }

        if (systemImage) {
            config.image = [UIImage systemImageNamed:image];
            cell.contentConfiguration = config;
        } else {
            [Icons getDelayedIcon:image
                       completion:^(UIImage *_Nonnull image) {
                         config.image = image;
                         cell.contentConfiguration = config;
                       }];
        }
    } else {
        cell.contentConfiguration = config;
    }

    cell.accessibilityLabel =
        [NSString stringWithFormat:@"Link to %@", cell.textLabel.text.phonetic];
    return cell;
}

- (UITableViewCell *)tableViewMultiLineBasicCell:(UITableView *)tableView {
    return [self tableViewMultiLineCell:tableView font:self.basicFont];
}

- (UITableViewCell *)tableViewMultiLineParaCell:(UITableView *)tableView {
    return [self tableViewMultiLineCell:tableView font:self.smallFont];
}

- (void)detourToggle:(Detour *)detour
           indexPath:(NSIndexPath *)ip
       reloadSection:(bool)reloadSection {
    if (detour.systemWide) {
        [self detourAction:detour
                buttonType:DETOUR_BUTTON_COLLAPSE
                 indexPath:ip
             reloadSection:reloadSection];
    }
}

- (void)safeScrollToTop {
    MainTask(^{
      if ([self tableView:self.tableView numberOfRowsInSection:0] > 0) {
          [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                    inSection:0]
                                atScrollPosition:UITableViewScrollPositionTop
                                        animated:NO];
      }
    });
}

- (DetourTableViewCell *)detourCell:(Detour *)det
                          indexPath:(NSIndexPath *)indexPath {
    DetourTableViewCell *dcell =
        [self.tableView dequeueReusableCellWithIdentifier:det.reuseIdentifer];

    [dcell populateCell:det route:nil];

    __weak __typeof__(self) weakSelf = self;

    dcell.buttonCallback = ^(DetourTableViewCell *cell, NSInteger tag) {
      [weakSelf detourAction:cell.detour
                  buttonType:tag
                   indexPath:indexPath
               reloadSection:NO];
    };

    dcell.urlCallback = self.detourActionCalback;

    return dcell;
}



- (void)detourAction:(Detour *)detour
          buttonType:(NSInteger)buttonType
           indexPath:(NSIndexPath *)ip
       reloadSection:(bool)reloadSection {
    if (!self.tableView.window) {
        return;
    }

    if (buttonType == DETOUR_BUTTON_MAP) {
        [[MapViewControllerWithDetourStops viewController]
            fetchLocationsMaybeAsync:self.backgroundTask
                             detours:[NSArray arrayWithObject:detour]
                                 nav:self.navigationController];
        return;
    }

    if (buttonType == DETOUR_BUTTON_COLLAPSE) {
        UITableView *table = self.tableView;

        if (self.enableSearch && self.searchController &&
            self.searchController.isActive) {
            table = ((UITableViewController *)(self.searchController
                                                   .searchResultsController))
                        .tableView;
        }

        [Settings toggleHiddenSystemWideDetour:detour.detourId];

        [table beginUpdates];

        if (reloadSection) {
            NSArray<NSIndexPath *> *visiblePaths =
                table.indexPathsForVisibleRows;

            NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];

            for (NSIndexPath *ip in visiblePaths) {
                UITableViewCell *cell = [table cellForRowAtIndexPath:ip];
                if (cell) {
                    if ([cell.reuseIdentifier
                            isEqualToString:kSystemDetourResuseIdentifier]) {
                        [indices addIndex:ip.section];
                    }
                }
            }

            if (indices.count > 0) {
                [table reloadSections:indices
                     withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else {
            NSArray<NSIndexPath *> *visiblePaths =
                table.indexPathsForVisibleRows;

            NSMutableArray *indices = [NSMutableArray array];

            for (NSIndexPath *ip in visiblePaths) {
                UITableViewCell *cell = [table cellForRowAtIndexPath:ip];

                if (cell) {
                    if ([cell.reuseIdentifier
                            isEqualToString:kSystemDetourResuseIdentifier]) {
                        [indices addObject:ip];
                    }
                }
            }

            if (indices.count > 0) {
                [table reloadRowsAtIndexPaths:indices
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }

        [table endUpdates];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (previousTraitCollection.userInterfaceStyle !=
        self.traitCollection.userInterfaceStyle) {
        // Clear the image cache as half of it is not needed
        if (self.enableSearch && self.searchController) {
            self.searchController.searchBar.backgroundColor =
                UIColor.modeAwareAppBackground;
        }

        [self reloadData];
    }

    self.tableView.backgroundColor = [UIColor modeAwareAppBackground];
}

- (void)tableView:(UITableView *)table
    siriAlertsForRoute:(NSString *)routeName
           routeNumner:(NSString *)routeNumber {
    AlertsForRouteIntent *intent = [[AlertsForRouteIntent alloc] init];

    intent.suggestedInvocationPhrase =
        [NSString stringWithFormat:@"TriMet alerts for %@", routeName];
    intent.routeNumber = routeNumber;
    intent.includeSystemWideAlerts = @(NO);

    INShortcut *shortCut = [[INShortcut alloc] initWithIntent:intent];

    INUIAddVoiceShortcutViewController *viewController =
        [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;

    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)addVoiceShortcutViewController:
            (INUIAddVoiceShortcutViewController *)controller
            didFinishWithVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut
                                 error:(nullable NSError *)error
    API_AVAILABLE(ios(12.0)) {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)addVoiceShortcutViewControllerDidCancel:
    (INUIAddVoiceShortcutViewController *)controller API_AVAILABLE(ios(12.0)) {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)didEnterBackground {
    if (self.mapView && self.mapView.overlays) {
        self.savedOverlays =
            [[NSArray alloc] initWithArray:self.mapView.overlays copyItems:NO];
        [self.mapView removeOverlays:self.savedOverlays];
    }

    [super didEnterBackground];
}

- (void)didBecomeActive {
    [super didBecomeActive];
    if (self.mapView && self.savedOverlays) {
        [self.mapView addOverlays:self.savedOverlays];
        self.savedOverlays = nil;
    }
}

@end

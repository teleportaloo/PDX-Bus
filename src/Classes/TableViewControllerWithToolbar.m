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
#import "CellTextField.h"
#import "DatePickerCell.h"
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
#import "PDXBus-Swift.h"
#import "PDXBusAppDelegate+Methods.h"
#import "PickerCell.h"
#import "SearchFilter.h"
#import "SegmentCell.h"
#import "TaskDispatch.h"
#import "TextViewLinkCell.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerSummaryViewController.h"
#import "UIApplication+Compat.h"
#import "UIFont+Utility.h"
#import "UITableViewCell+Icons.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "ViewControllerBase+LinkCell.h"
#import "ViewControllerBase+MapPinAction.h"
#import "WebViewController.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <MapKit/MapKit.h>
#import <UIKit/UISearchDisplayController.h>

#define VTABLE(T) (((T) < _vTableMapSize) ? *(_vTableMap + (T)) : nil)

NSString *kSimpleId = @"simple";
NSString *kActionCellId = @"action";
NSString *kLinkCellWithIconId = @"linkicon";

@interface TableViewControllerWithToolbar <FilteredItemType>() {
    NSMutableArray<FilteredItemType> *_filteredItems;
    bool _mapShowsUserLocation;
    UIFont *_smallFont;

    const RowVTable *const *_vTableMap;
    size_t _vTableMapSize;
}

@property (nonatomic, strong) NSMutableArray<NSNumber *> *sectionTypes;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *perSectionRowTypes;
@property (nonatomic, strong) NSArray *savedOverlays;
@property (nonatomic, strong) TriMetXML *disclaimerXml;

@end

@implementation TableViewControllerWithToolbar

static NSString *callString = @"tel:1-503-238-RIDE";

// Tune this if you want a tiny gap above the toolbar when scrolled to the end.
static const CGFloat kToolbarClearance = 10.0;

- (bool)canCallTriMet {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = networkInfo.serviceSubscriberCellularProviders.allValues.firstObject;

    // Device has a carrier, and allows VOICE
    return (carrier.carrierName.length > 0);
}

- (void)callTriMet {
    [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:callString]];
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
        [finalOne performSelector:@selector(self) withObject:nil afterDelay:(NSTimeInterval)4.0];

        self.mapView = nil;
    }
}

#pragma mark - Underlap core

- (CGFloat)toolbarHeight {
    UINavigationController *nc = self.navigationController;
    UIToolbar *tb = nc.toolbar;
    if (!nc || nc.isToolbarHidden || !tb || tb.isHidden || tb.alpha <= 0.001)
        return 0.0;
    // Accurate on all devices/sizes
    return [tb sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds), CGFLOAT_MAX)].height;
}

- (NSDictionary<NSNumber *, NSValue *> *)makeVTable {
    return [NSDictionary dictionary];
}

#pragma mark View overridden methods

- (RowVTableTable)getvTable {
    return nil;
}
- (size_t)getvTableSize {
    return 0;
}

- (void)loadView {
    _vTableMap = [self getvTable];
    _vTableMapSize = [self getvTableSize];

    DEBUG_BLOCK(^{
      [self debugCheckCells];
    });
    [super loadView];
    [self recreateNewTable];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)recreateNewTable {
    if (self.tableView != nil) {
        [self.tableView removeFromSuperview];
    }

    // 1) Bars policy (works whether toolbar is opaque or translucent)
    self.navigationController.toolbarHidden = NO;

    // 2) Create table & pin to VIEW EDGES (not safe area)
    UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:self.style];
    tv.translatesAutoresizingMaskIntoConstraints = NO;

    // Let the view extend behind the toolbar
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    self.extendedLayoutIncludesOpaqueBars = YES;

    // Let UIKit manage content insets for sizing
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    self.tableView.automaticallyAdjustsScrollIndicatorInsets = YES;

    tv.contentInset = UIEdgeInsetsZero;
    tv.verticalScrollIndicatorInsets = UIEdgeInsetsZero;
    tv.horizontalScrollIndicatorInsets = UIEdgeInsetsZero;
    tv.delegate = self;
    tv.dataSource = self;
    [self.view addSubview:tv];
    self.tableView = tv;

    [NSLayoutConstraint activateConstraints:@[
        [tv.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [tv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    // Trim grouped padding that can look like a phantom gap
    if (self.style == UITableViewStyleGrouped || self.style == UITableViewStyleInsetGrouped) {
        self.tableView.sectionHeaderTopPadding = 0.0;
        self.tableView.sectionFooterHeight = 0.0;
        self.tableView.estimatedSectionFooterHeight = 0.0;
    }

    if (self.enableSearch) {
        UITableViewController *resultsVC =
            [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        resultsVC.tableView.dataSource = self;
        resultsVC.tableView.delegate = self;

        UISearchController *sc =
            [[UISearchController alloc] initWithSearchResultsController:resultsVC];
        sc.searchResultsUpdater = self;
        sc.obscuresBackgroundDuringPresentation = YES;
        sc.hidesNavigationBarDuringPresentation = NO;
        sc.searchBar.delegate = self;
        sc.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        sc.searchBar.backgroundImage = [UIImage new];
        sc.searchBar.backgroundColor = UIColor.modeAwareAppBackground;
        sc.searchBar.tintColor = UIColor.modeAwareText;

        self.searchController = sc;
        self.definesPresentationContext = YES;

        // Put search in the nav bar so it “pulls down to reveal”
        self.navigationItem.searchController = sc;
        self.navigationItem.hidesSearchBarWhenScrolling = YES; // pull to reveal
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }

    // In viewDidLoad (or right after creating the search controller)
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeNever; // iOS 11+
    self.navigationItem.title = self.title;

    for (size_t i = 0; i < _vTableMapSize; i++) {
        const RowVTable *vt = (_vTableMap[i]);

        if (vt && vt->selRegister) {
            CELL_REG_IMP imp = (CELL_REG_IMP)[self methodForSelector:vt->selRegister];
            imp(self, vt->selRegister, self.tableView, vt, i);
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Keep indicators readable above the toolbar/home indicator
    CGFloat desiredBottom =
        MAX([self toolbarHeight], self.view.safeAreaInsets.bottom) + kToolbarClearance;
    UIEdgeInsets v = self.tableView.verticalScrollIndicatorInsets;
    if (fabs(v.bottom - desiredBottom) > 0.5) {
        v.bottom = desiredBottom;
        self.tableView.verticalScrollIndicatorInsets = v;
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    if (bar == self.searchController.searchBar) {
        return UIBarPositionTopAttached;
    } else { // Handle other cases
        return UIBarPositionAny;
    }
}

// Call this as well after you change toolbar items or show/hide the toolbar.
- (void)setToolbarItems:(NSArray<UIBarButtonItem *> *)toolbarItems animated:(BOOL)animated {
    [super setToolbarItems:toolbarItems animated:animated];
    [self.view setNeedsLayout];
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
    NSRange range = [[self stringToFilter:i] rangeOfString:searchText
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
        UITableViewController *searchView =
            (UITableViewController *)self.searchController.searchResultsController;
        [searchView.tableView reloadData];
    } else {
        [self.tableView reloadData];
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

    if (self.enableSearch && self.searchController && self.searchController.isActive) {
        UITableViewController *searchView =
            (UITableViewController *)self.searchController.searchResultsController;

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

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    UITableViewCell *cell = nil;

    if (vt && vt->selConfigure) {
        CELL_CONFIG_IMP imp = (CELL_CONFIG_IMP)[self methodForSelector:vt->selConfigure];
        cell = imp(self, vt->selConfigure, tableView, indexPath, extra, vt, offset);
    } else if (vt && vt->selUpdate) {
        CELL_UPDATE_IMP imp = (CELL_UPDATE_IMP)[self methodForSelector:vt->selUpdate];
        cell = [self tableView:tableView cellWithReuseIdentifier:vt->reuseId];
        imp(self, vt->selUpdate, tableView, cell, indexPath, extra, vt, offset);
    }

    if (cell == nil) {
        SEL sel = CELL_CONFIG_SEL(default);
        CELL_CONFIG_IMP imp = (CELL_CONFIG_IMP)[self methodForSelector:sel];
        cell = imp(self, sel, tableView, indexPath, extra, vt, offset);
    }

    return cell;
}

CELL_CONFIG_METHOD(default) {
    ERROR_LOG(@"Unexpected default cell used.");
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"default"];

    NSString *cls = NSStringFromClass(self.class);

#ifdef DEBUGLOGGING
    NSDictionary *offsets = TableViewControllerWithToolbar.debugCellTypeStore[cls];

    if (offsets) {
        cell.textLabel.text = [NSString
            stringWithFormat:@"Missing cell %@ %@ %ld", cls, offsets[@(offset)], (long)offset];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
#else
    cell.textLabel.text = [NSString stringWithFormat:@"Missing cell %@ %ld", cls, (long)offset];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
#endif // DEBUGLOGGING
    return cell;
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_ACCESSORY_SEL(default);

    if (vt && vt->selAccessoryTapped) {
        sel = vt->selAccessoryTapped;
    }

    CELL_ACCESSORY_IMP imp = (CELL_ACCESSORY_IMP)[self methodForSelector:sel];
    imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_ACCESSORY_METHOD(default) {}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_CAN_MOVE_SEL(default);

    if (vt && vt->selCanMove) {
        sel = vt->selCanMove;
    }
    CELL_CAN_MOVE_IMP imp = (CELL_CAN_MOVE_IMP)[self methodForSelector:sel];
    return imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_CAN_MOVE_METHOD(default) { return NO; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_SELECT_SEL(default);

    if (vt && vt->selSelect) {
        sel = vt->selSelect;
    }
    CELL_SELECT_IMP imp = (CELL_SELECT_IMP)[self methodForSelector:sel];
    imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_SELECT_METHOD(default) {}

- (CGFloat)leftInset {
    return leftInset;
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_WILL_DISPLAY_SEL(default);

    if (vt && vt->selWillDisplayCell) {
        sel = vt->selWillDisplayCell;
    }

    CELL_WILL_DISPLAY_IMP imp = (CELL_WILL_DISPLAY_IMP)[self methodForSelector:sel];
    imp(self, sel, tableView, cell, indexPath, extra, vt, offset);

    if (cell.layoutMargins.left > leftInset) {
        leftInset = cell.layoutMargins.left;
    }
}

CELL_WILL_DISPLAY_METHOD(default) {
    if ([cell.reuseIdentifier isEqualToString:kDisclaimerCellId]) {
        cell.backgroundColor = [UIColor modeAwareDisclaimerBackground];
    } else if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
        cell.backgroundColor = [UIColor modeAwareSystemWideAlertBackground];
    } else {
        cell.backgroundColor = [UIColor modeAwareCellBackground];
    }
}

- (bool)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_CAN_EDIT_SEL(default);

    if (vt && vt->selCanEditRow) {
        sel = vt->selCanEditRow;
    }

    CELL_CAN_EDIT_IMP imp = (CELL_CAN_EDIT_IMP)[self methodForSelector:sel];
    return imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_CAN_EDIT_METHOD(default) { return NO; }

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];

    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_EDITING_STYLE_SEL(default);

    if (vt && vt->selEditingStyle) {
        sel = vt->selEditingStyle;
    }
    CELL_EDITING_STYLE_IMP imp = (CELL_EDITING_STYLE_IMP)[self methodForSelector:sel];
    return imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_EDITING_STYLE_METHOD(default) { return UITableViewCellEditingStyleNone; }

CELL_EDITING_STYLE_METHOD(insert) { return UITableViewCellEditingStyleInsert; }

#pragma mark Table view call helper methods

- (void)clearSelection {
    NSIndexPath *ip = self.tableView.indexPathForSelectedRow;

    if (ip != nil) {
        [self.tableView deselectRowAtIndexPath:ip animated:YES];
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
     Create an instance of UITableViewCell and add tagged subviews for the name,
     local time, and quarter image of the time zone.
     */

#define MAIN_FONT_SIZE 16.0
#define SMALL_FONT_SIZE 12.0

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kDisclaimerCellId];

        cell.textLabel.font = [UIFont monospacedDigitSystemFontOfSize:MAIN_FONT_SIZE
                                                               weight:UIFontWeightBold];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.detailTextLabel.font = [UIFont monospacedDigitSystemFontOfSize:SMALL_FONT_SIZE];
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor modeAwareGrayText];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.text = kTriMetDisclaimerText;
        cell.backgroundColor = [UIColor modeAwareDisclaimerBackground];
    }

    return cell;
}

- (UITableViewCell *)disclaimerCell:(TriMetXML *)xml noResults:(NSString *)noResults {
    UITableViewCell *cell = [self disclaimerCell:self.tableView];

    self.disclaimerXml = xml;

    if (xml.items == nil) {
        [self noNetworkDisclaimerCell:cell];
    } else if (xml.count == 0) {
        [self addTextToDisclaimerCell:cell text:noResults];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [self addTextToDisclaimerCell:cell
                                 text:[NSString
                                          stringWithFormat:@"%@", [xml displayDate:xml.cacheTime]]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    [self updateDisclaimerAccessibility:cell];
    return cell;
}

CELL_SELECT_METHOD(disclaimer) {
    if (self.disclaimerXml.items == nil) {
        [self networkTips:self.disclaimerXml.htmlError
             networkError:self.disclaimerXml.networkErrorMsg];
        [self clearSelection];
    }
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
                [NSString stringWithFormat:@"Streetcar: %@\n%@", text, kTriMetDisclaimerText];
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
            // [[(MainTableViewController *)[self.navigationController
            // topViewController] tableView] reloadData];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        if (!cancelled) {
            [self.navigationController pushViewController:viewController animated:YES];
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
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.isActive) {
        [self reloadData];
    }
}

- (NSMutableArray *)topViewData {
    NSMutableArray *items = nil;

    if (self.searchController != nil && self.searchController.isActive) {
        UITableViewController *searchView =
            (UITableViewController *)self.searchController.searchResultsController;
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
        __block CGFloat diff = nbFrame.size.height + nbFrame.origin.y - vFrame.origin.y;

        if (diff != 0.0) {
            __block CGSize size = self.tableView.contentSize;
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
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

- (NSInteger)addRowTypes:(NSArray *)array {
    NSMutableArray *types = self.perSectionRowTypes.lastObject;

    [self.perSectionRowTypes.lastObject addObjectsFromArray:array];

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
    if (self.perSectionRowTypes != nil && section < self.perSectionRowTypes.count) {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

    CGFloat width = self.navigationController.view.frame.size.width;

    CGRect mapRect = CGRectMake(0, 0, width, [self mapCellHeight]);

    UITableViewCell *cell = [self tableView:self.tableView
                    cellWithReuseIdentifier:MakeCellId(kRowMap)];

    __block MKMapView *map = (MKMapView *)[cell.contentView viewWithTag:MAP_TAG];

    if (map == nil) {

        MAIN_TASK(^{
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

          UITapGestureRecognizer *tapRec =
              [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMap:)];

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

- (NSInteger)tableView:(UITableView *)tableView
          vTableOffset:(NSIndexPath *)indexPath
              extraOut:(id __autoreleasing *)extra {
    return [self rowType:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id extra = nil;
    NSInteger offset = [self tableView:tableView vTableOffset:indexPath extraOut:&extra];
    RowVTablePtrConst vt = VTABLE(offset);

    SEL sel = CELL_HEIGHT_SEL(default);
    if (vt && vt->selHeight) {
        sel = vt->selHeight;
    }

    CELL_HEIGHT_IMP imp = (CELL_HEIGHT_IMP)[self methodForSelector:sel];
    return imp(self, sel, tableView, indexPath, extra, vt, offset);
}

CELL_HEIGHT_METHOD(default) { return self.tableView.rowHeight; }

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:resuseIdentifier];
    }

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    return cell;
}

CELL_REG_METHOD(linkCell) {
    [tableView registerClass:LabelLinkCellWithIcon.class
        forCellReuseIdentifier:kLinkCellWithIconId];
}

CELL_CREATION_METHOD(actionCell) {
    [cell prepareForReuse];

    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor modeAwareGrayText];

    cell.icon = icon;

    cell.textLabel.text = text;
    cell.accessoryType = accType;
    cell.selectionStyle = selStyle;

    [self updateAccessibility:cell];

    return cell;
}

CELL_CREATION_METHOD(markupCell) {
    [cell prepareForReuse];
    [self baseCell:cell accessory:accType selection:selStyle];
    cell.textLabel.attributedText = text.attributedStringFromMarkUp;

    cell.icon = icon;

    [self updateAccessibility:cell];
    return cell;
}

CELL_CREATION_METHOD(multiLine) {
    [cell prepareForReuse];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.attributedText = text.attributedStringFromMarkUp;
    cell.accessoryType = accType;
    cell.selectionStyle = selStyle;

    cell.icon = icon;

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    [self updateAccessibility:cell];

    return cell;
}

CELL_CREATION_METHOD(paraLine) {
    [cell prepareForReuse];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = self.smallFont;
    cell.textLabel.attributedText = text.smallAttributedStringFromMarkUp;
    cell.accessoryType = accType;
    cell.selectionStyle = selStyle;

    cell.icon = icon;

    cell.backgroundColor = [UIColor modeAwareCellBackground];
    [self updateAccessibility:cell];

    return cell;
}

CELL_CREATION_METHOD(simpleCell) {
    [cell prepareForReuse];
    [self baseCell:cell accessory:accType selection:selStyle];

    cell.textLabel.textColor = [UIColor modeAwareText];
    cell.textLabel.text = text;

    cell.icon = icon;

    [self updateAccessibility:cell];

    return cell;
}

CELL_CREATION_METHOD(textCell) {
    [cell prepareForReuse];

    TextViewLinkCell *textCell = (TextViewLinkCell *)cell;
    textCell.textView.attributedText = text.smallAttributedStringFromMarkUp;
    textCell.selectionStyle = selStyle;
    textCell.accessoryType = accType;
    textCell.urlCallback = self.urlActionCalback;

    return textCell;
}

CELL_REG_METHOD(TextViewLinkCell) {
    [self.tableView registerNib:TextViewLinkCell.nib
         forCellReuseIdentifier:TextViewLinkCell.identifier];
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
    MAIN_TASK(^{
      if ([self tableView:self.tableView numberOfRowsInSection:0] > 0) {
          [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                atScrollPosition:UITableViewScrollPositionTop
                                        animated:NO];
      }
    });
}

- (DetourTableViewCell *)detourCell:(Detour *)det
                              route:(Route *)route
                          indexPath:(NSIndexPath *)indexPath {
    return [self detourCell:det route:route indexPath:indexPath showHeader:NO showRoute:NO];
}

- (DetourTableViewCell *)detourCell:(Detour *)det
                              route:(Route *)route
                          indexPath:(NSIndexPath *)indexPath
                         showHeader:(bool)includeHeader
                          showRoute:(bool)showRoute {
    DetourTableViewCell *dcell = nil;
    if (det) {
        dcell = [self.tableView dequeueReusableCellWithIdentifier:det.reuseIdentifer];

        [dcell populateCell:det route:route.routeId showHeader:includeHeader showRoute:showRoute];

        __weak __typeof__(self) weakSelf = self;

        dcell.buttonCallback = ^(DetourTableViewCell *cell, NSInteger tag) {
          [weakSelf detourAction:cell.detour buttonType:tag indexPath:indexPath reloadSection:NO];
        };

        dcell.urlCallback = self.detourActionCalback;
    } else {
        dcell = [self.tableView dequeueReusableCellWithIdentifier:kDetourResuseIdentifier];
        dcell.textView.text = NSLocalizedString(@"Detour information not known.", @"error message");
        dcell.accessoryType = UITableViewCellAccessoryNone;
        dcell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

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

        if (self.enableSearch && self.searchController && self.searchController.isActive) {
            table = ((UITableViewController *)(self.searchController.searchResultsController))
                        .tableView;
        }

        [Settings toggleHiddenSystemWideDetour:detour.detourId];

        [table beginUpdates];

        if (reloadSection) {
            NSArray<NSIndexPath *> *visiblePaths = table.indexPathsForVisibleRows;

            NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];

            for (NSIndexPath *ip in visiblePaths) {
                UITableViewCell *cell = [table cellForRowAtIndexPath:ip];
                if (cell) {
                    if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
                        [indices addIndex:ip.section];
                    }
                }
            }

            if (indices.count > 0) {
                [table reloadSections:indices withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else {
            NSArray<NSIndexPath *> *visiblePaths = table.indexPathsForVisibleRows;

            NSMutableArray *indices = [NSMutableArray array];

            for (NSIndexPath *ip in visiblePaths) {
                UITableViewCell *cell = [table cellForRowAtIndexPath:ip];

                if (cell) {
                    if ([cell.reuseIdentifier isEqualToString:kSystemDetourResuseIdentifier]) {
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

    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        // Clear the image cache as half of it is not needed
        if (self.enableSearch && self.searchController) {
            self.searchController.searchBar.backgroundColor = UIColor.modeAwareAppBackground;
        }

        [self reloadData];
    }

    self.tableView.backgroundColor = [UIColor modeAwareAppBackground];

    [self.view setNeedsLayout];
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

- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller
            didFinishWithVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut
                                 error:(nullable NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)didEnterBackground {
    if (self.mapView && self.mapView.overlays) {
        self.savedOverlays = [[NSArray alloc] initWithArray:self.mapView.overlays copyItems:NO];
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

- (UITableViewCell *)baseCell:(UITableViewCell *)cell
                    accessory:(UITableViewCellAccessoryType)accType
                    selection:(UITableViewCellSelectionStyle)selStyle {

    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.numberOfLines = 1;
    cell.accessoryType = accType;
    cell.backgroundColor = [UIColor modeAwareCellBackground];
    cell.textLabel.adjustsFontForContentSizeCategory = NO;
    cell.selectionStyle = selStyle;

    return cell;
}

+ (NSMutableDictionary *)debugCellTypeStore {
    static NSMutableDictionary *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
      s = [NSMutableDictionary new];
    });
    return s;
}

+ (void)debugCheckSelMissing:(Class)cls sel:(SEL)selector vtable:(RowVTablePtrConst)vTable {
    if ([cls instancesRespondToSelector:selector]) {
        ERROR_LOG(@"class %@ should not respond to %@",
                  NSStringFromClass(cls),
                  NSStringFromSelector(selector));
    }

    //    ASSERT(![cls instancesRespondToSelector:selector]);
}

+ (void)debugRegisterCellType:(NSInteger)type
            standardSelectors:(RowVTablePtrConst)sels
                      inClass:(Class)cls {
    @synchronized(self) {
        NSString *key = NSStringFromClass(cls);
        NSMutableDictionary *byEnum = self.debugCellTypeStore[key];

        if (byEnum == nil) {
            byEnum = [NSMutableDictionary new];
            self.debugCellTypeStore[key] = byEnum;
        }

        [byEnum setObject:[NSValue valueWithBytes:sels objCType:@encode(RowVTable)] forKey:@(type)];
    }
}

- (void)debugCheckCells {
    NSString *key = NSStringFromClass(self.class);
    NSMutableDictionary *cells = TableViewControllerWithToolbar.debugCellTypeStore[key];

    DEBUG_LOG(@"Checking %@", key);

    for (NSNumber *number in cells) {
        ASSERT(number.integerValue < _vTableMapSize);
        if (number.integerValue < _vTableMapSize) {
            if (_vTableMap[number.integerValue] == nil) {
                NSValue *value = cells[number];
                RowVTable vTable;
                [value getValue:&vTable];
                ERROR_LOG(
                    @"%@ is missing row map entry for %@ %d", key, vTable.reuseId, number.intValue);
            }
            ASSERT(_vTableMap[number.integerValue] != nil);
        }
    }
}

CELL_HEIGHT_METHOD(basic) { return [self basicRowHeight]; }
CELL_HEIGHT_METHOD(narrow) { return [self narrowRowHeight]; }
CELL_HEIGHT_METHOD(auto) { return UITableViewAutomaticDimension; }
CELL_HEIGHT_METHOD(SegmentCell) { return SegmentCell.rowHeight; }
CELL_HEIGHT_METHOD(mapCell) { return [self mapCellHeight]; }
CELL_HEIGHT_METHOD(CellTextField) { return [CellTextField cellHeight]; }
CELL_CAN_EDIT_METHOD(yes) { return YES; }
CELL_EDITING_STYLE_METHOD(delete) { return UITableViewCellEditingStyleDelete; }
CELL_SELECT_METHOD(LabelLinkCellWithIcon) {
    LabelLinkCellWithIcon *cell =
        (LabelLinkCellWithIcon *)[tableView cellForRowAtIndexPath:indexPath];

    [WebViewController displayPage:cell.link
                              full:cell.link
                         navigator:self.navigationController
                    itemToDeselect:self
                          whenDone:self.callbackWhenDone];
}
CELL_REG_METHOD(DetourTableViewCell) {
    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kSystemDetourResuseIdentifier];
    [self.tableView registerNib:[DetourTableViewCell nib]
         forCellReuseIdentifier:kDetourResuseIdentifier];
}
CELL_REG_METHOD(PickerCell) {
    [self.tableView registerNib:[PickerCell nib] forCellReuseIdentifier:MakeCellId(PickerCell)];
}
CELL_REG_METHOD(DatePickerCell) {
    [self.tableView registerNib:[DatePickerCell nib]
         forCellReuseIdentifier:MakeCellId(DatePickerCell)];
}
CELL_CAN_MOVE_METHOD(yes) { return YES; }

CELL_CONFIG_METHOD(tipJar) {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kSimpleId];

    [self baseCell:cell
         accessory:UITableViewCellAccessoryDisclosureIndicator
         selection:UITableViewCellSelectionStyleBlue];

    cell.textLabel.text = TipJarManager.shared.hasTipped
                              ? NSLocalizedString(@"Thanks for Supporting Us!", @"main menu item")
                              : NSLocalizedString(@"Support Us!", @"main menu item");
    cell.textLabel.textColor = [UIColor modeAwareText];

    cell.icon = TipJarManager.shared.hasTipped ? kIconHeartFull : kIconHeart;

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [self updateAccessibility:cell];

    return cell;
}

- (void)showTipJar {
    [TipJarManager.shared showTipJar:self
                             message:@"PDX Bus is developed by volunteers, using public data "
                                     @"provided by TriMet.\n\nLeave a tip to support the app "
                                     @"❤️.\n\nThere are no extra features to buy - the app is "
                                     @"free and fully featured."];
}

CELL_SELECT_METHOD(tipJar) {
    [self showTipJar];
    [self clearSelection];
}

@end

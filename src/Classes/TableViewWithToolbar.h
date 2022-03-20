//
//  TableViewWithToolbar.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "UIToolbar+Auto.h"
#import "TaskController.h"
#import "ProgressModalView.h"
#import "BackgroundTaskContainer.h"
#import "MapKit/MapKit.h"
#import "DeselectItemDelegate.h"
#import <IntentsUI/IntentsUI.h>

#define kDisclaimerCellHeight     UITableViewAutomaticDimension
#define kSectionRowDisclaimerType 0xFFFFFF
#define kDisclaimerCellId         MakeCellId(kSectionRowDisclaimerType)
#define kExceptionCellId          @"Exception"

#define kNoNetwork                NSLocalizedString(@"%@: touch here for info", @"Stop ID and message")
#define kNoNetworkErrorID         NSLocalizedString(@"(ID %@) %@: touch here for info", @"Stop ID and message")
#define kNoNetworkID              NSLocalizedString(@"(ID %@) No Network: touch here for info", @"Stop ID and error message")
#define kNetworkMsg               NSLocalizedString(@"Network error: touch here for info", @"Network error message")

#define ACCESSORY_BUTTON_SIZE     35


#define MakeCellId(X)                            @#X
#define MakeCellIdW(X, W)                        [NSString stringWithFormat:@"%@+%f", @#X, (float)W]

#define MakeMapRectWithPointAtCenter(X, Y, W, H) MKMapRectMake((X)-(W) / 2, (Y)-(H) / 2, W, H)

// #define kBasicTextViewFontSize    14.0

#define kNoRowSectionTypeFound (-1)

@class MKMapView;
@class Detour;


@interface TableViewWithToolbar<FilteredItemType> : ViewControllerBase <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate,
DeselectItemDelegate, MKMapViewDelegate, UISearchBarDelegate, INUIAddVoiceShortcutViewControllerDelegate> {
    bool _reloadOnAppear;
}

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, readonly) UITableViewStyle style;
@property (nonatomic, readonly) CGFloat basicRowHeight;
@property (nonatomic, readonly) CGFloat narrowRowHeight;
@property (nonatomic, readonly, copy) NSMutableArray *topViewData;
@property (nonatomic, readonly) CGFloat mapCellHeight;
@property (nonatomic, strong) NSMutableArray<FilteredItemType> *searchableItems;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) MKMapView *mapView;
@property bool backgroundRefresh;
@property bool enableSearch;

// Methods for storing an integer type for each row and section
// These can be used by tables to simplify the calculation of the structure of
// the table.   Not all tables need to use this but refactoring will make it
// simpler.
- (void)clearSectionMaps;
- (NSInteger)sectionType:(NSInteger)section;
- (NSInteger)rowType:(NSIndexPath *)index;
- (NSInteger)addSectionType:(NSInteger)type;
- (NSInteger)addSectionTypeWithRow:(NSInteger)type;
- (NSInteger)addRowType:(NSInteger)type;
- (NSInteger)addRowType:(NSInteger)type count:(NSInteger)count;
- (NSInteger)sections;
- (void)clearSection:(NSInteger)section;
- (NSInteger)addRowType:(NSInteger)type forSectionType:(NSInteger)sectionType;
- (NSInteger)rowsInSection:(NSInteger)section;
- (NSInteger)rowsInLastSection;
- (NSInteger)firstSectionOfType:(NSInteger)type;
- (NSInteger)firstRowOfType:(NSInteger)type inSection:(NSInteger)section;
- (NSIndexPath *)firstIndexPathOfSectionType:(NSInteger)sectionType rowType:(NSInteger)rowType;
- (void)removeRowAtIndexPath:(NSIndexPath *)index;

// Other methods
- (CGFloat)leftInset;
- (void)finishWithMapView;
- (UITableViewCell *)getMapCell:(NSString *)id withUserLocation:(bool)userLocation;
- (void)updateAnnotations:(MKMapView *)map;
- (UITableViewCell *)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)resuseIdentifier;
- (UITableViewCell *)tableView:(UITableView *)tableView multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier;
- (UITableViewCell *)tableView:(UITableView *)tableView multiLineCellWithReuseIdentifier:(NSString *)resuseIdentifier font:(UIFont *)font;

- (UITableViewCell *)tableViewCell:(UITableView *)tableView;
- (UITableViewCell *)tableViewMultiLineBasicCell:(UITableView *)tableView;
- (UITableViewCell *)tableViewMultiLineParaCell:(UITableView *)tableView;


- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text trimetDisclaimer:(bool)trimetDisclaimer;
- (void)updateDisclaimerAccessibility:(UITableViewCell *)cell;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text lines:(NSInteger)numberOfLines;
- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell;
- (UITableViewCell *)disclaimerCell:(UITableView *)tableView;
- (void)recreateNewTable;
- (bool)neverAdjustContentInset;
- (void)updateAccessibility:(UITableViewCell *)cell;
- (bool)canCallTriMet;
- (void)callTriMet;
- (NSMutableArray<FilteredItemType> *)filteredData:(UITableView *)table;
- (NSString *)stringToFilter:(NSObject *)i;
- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index;
- (void)iOS7workaroundPromptGap;
- (void)clearSelection;

- (void)detourAction:(Detour *)detour buttonType:(NSInteger)buttonType indexPath:(NSIndexPath *)ip reloadSection:(bool)reloadSection;
- (void)detourToggle:(Detour *)detour indexPath:(NSIndexPath *)ip reloadSection:(bool)reloadSection;
- (void)safeScrollToTop;

- (void)tableView:(UITableView *)table siriAlertsForRoute:(NSString *)routeName routeNumner:(NSString*)routeNumber;


@end

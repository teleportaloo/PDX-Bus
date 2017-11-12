//
//  TableViewWithToolbar.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "ReturnStopId.h"
#import "UIToolbar+Auto.h"
#import "BackgroundTaskProgress.h"
#import "ProgressModalView.h"
#import "BackgroundTaskContainer.h"
#import "MapKit/MapKit.h"

#define kDisclaimerCellHeight       UITableViewAutomaticDimension
#define kSectionRowDisclaimerType   0xFFFFFF
#define kDisclaimerCellId           MakeCellId(kSectionRowDisclaimerType)
#define kExceptionCellId            @"Exception"

#define kNoNetwork				NSLocalizedString(@"%@: touch here for info", @"Stop ID and message")
#define kNoNetworkErrorID		NSLocalizedString(@"(ID %@) %@: touch here for info", @"Stop ID and message")
#define kNoNetworkID			NSLocalizedString(@"(ID %@) No Network: touch here for info", @"Stop ID and error message")
#define kNetworkMsg				NSLocalizedString(@"Network error: touch here for info", @"Network error message")


#define MakeCellId(X) @#X
#define MakeCellIdW(X,W) [NSString stringWithFormat:@"%@+%f", @#X, (float)W]

#define MakeMapRectWithPointAtCenter(X,Y,W,H) MKMapRectMake((X)-(W)/2, (Y)-(H)/2, W, H)

// #define kBasicTextViewFontSize	14.0

#define kNoRowSectionTypeFound  (-1)

@protocol UIAlertViewDelegate;
@class MKMapView;

@interface TableViewWithToolbar : ViewControllerBase <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate,
            DeselectItemDelegate, MKMapViewDelegate> {
	UITableView *       _tableView;
	bool                _backgroundRefresh;
	UIFont *            _basicFont;
	UIFont *            _smallFont;
	UIFont *            _paragraphFont;
	bool                _enableSearch;
	NSMutableArray *    _filteredItems;
	NSMutableArray *    _searchableItems;
	UISearchController *_searchController;
    NSMutableArray<NSNumber*> *                     _sectionTypes;
    NSMutableArray<NSMutableArray <NSNumber *> *> * _perSectionRowTypes;
    MKMapView   *       _mapView;
    bool                _mapShowsUserLocation;
}

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text trimetDisclaimer:(bool)trimetDisclaimer;

- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text lines:(NSInteger)numberOfLines;
- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell;
- (UITableViewCell *)disclaimerCellWithReuseIdentifier:(NSString *)identifier;
- (void)recreateNewTable;
- (bool)neverAdjustContentInset;
- (void)updateAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath text:(NSString *)str alwaysSaySection:(BOOL)alwaysSaySection;
@property (nonatomic, getter=getStyle, readonly) UITableViewStyle style;

@property (nonatomic, readonly, copy) UIFont *basicFont;
@property (nonatomic, readonly, copy) UIFont *smallFont;
@property (nonatomic, readonly, copy) UIFont *paragraphFont;
@property (nonatomic, readonly) CGFloat basicRowHeight;
@property (nonatomic, readonly) CGFloat narrowRowHeight;
- (bool)isSearchRow:(int)section;
@property (nonatomic, readonly) CGFloat searchRowHeight;
@property (nonatomic, readonly, strong) UITableViewCell *searchRowCell;
- (NSMutableArray *)filteredData:(UITableView *)table;
@property (nonatomic, readonly, copy) NSMutableArray *topViewData;
- (void)clearSelection;
@property (nonatomic, readonly, copy) UIColor *greyBackground;
- (void)iOS7workaroundPromptGap;


// Methods for storing an integer type for each row and section
// These can be used by tables to simplify the calculation of the structure of
// the table.   Not all tables need to use this but refactoring will make it
// simpler.

- (CGFloat)leftInset;
- (void)clearSectionMaps;
- (NSInteger)sectionType:(NSInteger)section;
- (NSInteger)rowType:(NSIndexPath*)index;
- (NSInteger)addSectionType:(NSInteger)type;
- (NSInteger)addRowType:(NSInteger)type;
@property (nonatomic, readonly) NSInteger sections;
- (void)clearSection:(NSInteger)section;
- (NSInteger)addRowType:(NSInteger)type forSectionType:(NSInteger)sectionType;

- (NSInteger)rowsInSection:(NSInteger)section;
- (NSInteger)firstSectionOfType:(NSInteger)type;
- (NSInteger)firstRowOfType:(NSInteger)type inSection:(NSInteger)section;
- (NSIndexPath*)firstIndexPathOfSectionType:(NSInteger)sectionType rowType:(NSInteger)rowType;

@property (nonatomic, readonly) CGFloat mapCellHeight;
- (void)finishWithMapView;
- (UITableViewCell*)getMapCell:(NSString*)id withUserLocation:(bool)userLocation;
- (void)updateAnnotations:(MKMapView *)map;


@property (nonatomic, retain) UITableView *table;
@property bool backgroundRefresh;
@property bool enableSearch;
@property (nonatomic, retain) NSMutableArray *searchableItems;
@property (readonly) bool filtered;
@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) NSMutableArray<NSNumber*> * sectionTypes;
@property (nonatomic, retain) NSMutableArray<NSMutableArray <NSNumber *> *> *perSectionRowTypes;
@property (nonatomic, retain) MKMapView *mapView;



@end

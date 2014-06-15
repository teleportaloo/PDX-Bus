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
#import "CustomToolbar.h"
#import "BackgroundTaskProgress.h"
#import "ProgressModalView.h"
#import "BackgroundTaskContainer.h"

#define kDisclaimerCellHeight	55.0
#define kDisclaimerCellId		@"Disclaimer"
#define kExceptionCellId		@"Exception"

#define kNoNetwork				@"%@: touch here for info"
#define kNoNetworkErrorID		@"(ID %@) %@: touch here for info"
#define kNoNetworkID			@"(ID %@) No Network: touch here for info"
#define kNetworkMsg				@"Network error: touch here for info"
// #define kBasicTextViewFontSize	14.0

@protocol UIAlertViewDelegate;

@interface TableViewWithToolbar : ViewControllerBase <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate, DeselectItemDelegate> {
	UITableView *_tableView;
	bool _backgroundRefresh;
	UIFont *_basicFont;
	UIFont *_smallFont;
	UIFont *_paragraphFont;
	UISearchBar *_searchBar;
	bool _enableSearch;
	NSMutableArray *_filteredItems;
	NSMutableArray *_searchableItems;
	UISearchDisplayController *_searchController;
}

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text trimetDisclaimer:(bool)trimetDisclaimer;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text;
- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell;
- (UITableViewCell *)disclaimerCellWithReuseIdentifier:(NSString *)identifier;
- (void)recreateNewTable;


- (void)maybeAddSectionToAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath alwaysSaySection:(BOOL)alwaysSaySection;
- (void)updateAccessibility:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath text:(NSString *)str alwaysSaySection:(BOOL)alwaysSaySection;
- (UITableViewStyle) getStyle;
- (CGFloat)getTextHeight:(NSString *)text font:(UIFont *)font;
- (UIFont*)getBasicFont;
- (UIFont*)getSmallFont;
- (UIFont*)getParagraphFont;
- (CGFloat)basicRowHeight;
- (CGFloat)narrowRowHeight;
- (bool)isSearchRow:(int)section;
- (CGFloat)searchRowHeight;
- (UITableViewCell *)searchRowCell;
- (NSMutableArray *)filteredData:(UITableView *)table;
- (NSMutableArray *)topViewData;
- (void)clearSelection;
- (UIColor*)greyBackground;
- (void)iOS7workaroundPromptGap;

@property (nonatomic, retain) UITableView *table;
@property bool backgroundRefresh;
@property bool enableSearch;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSMutableArray *searchableItems;
@property (readonly) bool filtered;
@property (nonatomic, retain) UISearchDisplayController *searchController;


@end

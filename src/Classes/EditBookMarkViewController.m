//
//  EditBookMarkViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "EditBookMarkViewController.h"
#import "AddNewStopToBookMarkViewController.h"
#import "AllRailStationViewController.h"
#import "CellTextField.h"
#import "DayOfTheWeekViewController.h"
#import "DepartureTimesViewController.h"
#import "Icons.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "RailMapViewController.h"
#import "RouteView.h"
#import "SegmentCell.h"
#import "TextViewLinkCell.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerDateViewController.h"
#import "TripPlannerEndPointViewController.h"
#import "TripPlannerOptionsViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UITableViewCell+Icons.h"
#import "UserParams.h"
#import "UserState.h"
#import <Intents/Intents.h>

enum SECTIONS_AND_ROWS {
    kTableMessage,
    kTableName,
    kTableStops,
    kTableSectionTrip,
    kTableSiri,
    kTableDelete,
    kTableSave,
    kTableRun,
    kTableCommute,
    kTableCommuteInfo,
    kTableRowStopId,
    kTableRowStopBrowse,
    kTableRowRailMap,
    kTableRowRailStations,
    kTableTripRowFrom,
    kTableTripRowTo,
    kTableTripRowOptions,
    kTableRowTime
};

#define kTakeMeHomeText                                                        \
    NSLocalizedString(@"This page enables you to create a bookmark that will " \
                      @"search for a route from your #icurrent location#i to " \
                      @"a destination, leaving immediately.\n\nFor example, "  \
                      @"use it to create a #BTake Me Home Now#D trip.",        \
                      @"take me home text")

#define kMarkedUpIncompleteStopMsg                                             \
    NSLocalizedString(@"#RThe bookmark was incomplete. Please add a stop.",    \
                      @"error text")
#define kMarkedUpIncompleteTripMsg                                             \
    NSLocalizedString(                                                         \
        @"#RThe bookmark was incomplete. Please check locations.",             \
        @"error text")

#define kUIEditHeight 55.0
#define kUIRowHeight 40.0

@interface EditBookMarkViewController () {
    bool _reloadTrip;
    bool _reloadArrival;
    NSInteger _stopSection;
    bool _updateNameFromDestination;
}

@property(nonatomic, copy) NSString *markedUpMsg;

@property(nonatomic, strong) NSMutableArray<NSString *> *stopIdArray;
@property(nonatomic, strong) MutableUserParams *originalFave;
@property(nonatomic, strong) UITextField *editWindow;
@property(nonatomic) NSInteger item;
@property(nonatomic, strong) CellTextField *editCell;
@property(nonatomic, strong) TripUserRequest *userRequest;
@property(nonatomic) bool newBookmark;
@property(nonatomic, readonly) bool autoCommuteEnabled;
@property(nonatomic, readonly, copy) NSString *daysString;

@end

@implementation EditBookMarkViewController

- (instancetype)init {
    if ((self = [super init])) {
        // clear the last run so the commute bookmark can be tested
        _userState.lastRun = nil;
        self.invalidItem = NO;
        _updateNameFromDestination = NO;
        _newBookmark = NO;
    }

    return self;
}

- (void)setupArrivalSections {
    [self clearSectionMaps];

    if (self.invalidItem) {
        [self addSectionType:kTableMessage];
        [self addRowType:kTableMessage];
        self.markedUpMsg = kMarkedUpIncompleteStopMsg;
    }

    [self addSectionType:kTableName];
    [self addRowType:kTableName];

    _stopSection = [self addSectionType:kTableStops];

    [self addRowType:kTableStops count:self.stopIdArray.count];

    [self addRowType:kTableRowStopId];
    [self addRowType:kTableRowStopBrowse];
    [self addRowType:kTableRowRailMap];
    [self addRowType:kTableRowRailStations];

    [self addSectionType:kTableCommute];
    [self addRowType:kTableCommuteInfo];
    [self addRowType:kTableCommute];

#if !TARGET_OS_MACCATALYST
    [self addSectionType:kTableSiri];
    [self addRowType:kTableSiri];
#endif

    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];

    [self addSectionType:kTableSave];
    [self addRowType:kTableSave];
}

- (void)setupTripSections {
    [self clearSectionMaps];

    if (self.invalidItem) {
        [self addSectionType:kTableMessage];
        [self addRowType:kTableMessage];
        self.markedUpMsg = kMarkedUpIncompleteTripMsg;
    }

    [self addSectionType:kTableName];
    [self addRowType:kTableName];

    [self addSectionType:kTableSectionTrip];
    [self addRowType:kTableTripRowFrom];
    [self addRowType:kTableTripRowTo];
    [self addRowType:kTableTripRowOptions];
    [self addRowType:kTableRowTime];

    [self addSectionType:kTableRun];
    [self addRowType:kTableRun];

    [self addSectionType:kTableSiri];
    [self addRowType:kTableSiri];

    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];

    [self addSectionType:kTableSave];
    [self addRowType:kTableSave];

    _stopSection = kNoRowSectionTypeFound;
}

- (void)setupTakeMeHomeSections {
    [self clearSectionMaps];

    [self addSectionType:kTableMessage];
    [self addRowType:kTableMessage];
    self.markedUpMsg = kTakeMeHomeText;

    [self addSectionType:kTableName];
    [self addRowType:kTableName];

    [self addSectionType:kTableSectionTrip];
    [self addRowType:kTableTripRowTo];
    [self addRowType:kTableTripRowOptions];

    [self addSectionType:kTableRun];
    [self addRowType:kTableRun];

    [self addSectionType:kTableSiri];
    [self addRowType:kTableSiri];

    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];

    _stopSection = kNoRowSectionTypeFound;
}

#pragma mark Commuter Helper functions

- (bool)autoCommuteEnabled {
    bool autoCommute = NO;

    if (self.originalFave != nil) {
        if (self.originalFave.valDayOfWeek != kDayNever) {
            autoCommute = YES;
        }
    }

    return autoCommute;
}

- (bool)autoCommuteMorning {
    return self.originalFave.valMorning;
}

- (NSString *)daysPostfix {
    int days = self.originalFave.valDayOfWeek;

    if (days == kDayNever) {
        return @"";
    }

    if ([self autoCommuteMorning]) {
        return NSLocalizedString(@" mornings",
                                 @"text concatonated after a list of weekdays");
    }

    return NSLocalizedString(@" afternoons",
                             @"text concatonated after a list of weekdays");
}

- (NSString *)dayPrefix {
    int days = self.originalFave.valDayOfWeek;

    switch (days) {
    case kDayNever:
        return @"";

    case kDayAllWeek:
        return NSLocalizedString(
            @"Show ", @"before text 'every day in the <morning or evening>'");

    default:
        return NSLocalizedString(@"Show on ",
                                 @"followed by a list of the days of the week");
    }
}

- (NSString *)daysString {
    int days = self.originalFave.valDayOfWeek;
    return [EditBookMarkViewController daysString:days];
}

+ (NSString *)daysString:(int)days {
    switch (days) {
    case kDayNever:
        return NSLocalizedString(@"No days selected", @"error message");

    case kDayWeekend:
        return NSLocalizedString(@"weekend", @"short for Saturday and Sunday");

    case kDayWeekday:
        return NSLocalizedString(@"weekday", @"short for Monday - Friday");

    case kDayAllWeek:
        return NSLocalizedString(@"everyday in the",
                                 @"followed by <morning/afternoon>");

    case kDayMon:
        return NSLocalizedString(@"Monday", @"full name for day of the week");

    case kDayTue:
        return NSLocalizedString(@"Tuesday", @"full name for day of the week");

    case kDayWed:
        return NSLocalizedString(@"Wednesday",
                                 @"full name for day of the week");

    case kDayThu:
        return NSLocalizedString(@"Thursday", @"full name for day of the week");

    case kDayFri:
        return NSLocalizedString(@"Friday", @"full name for day of the week");

    case kDaySat:
        return NSLocalizedString(@"Saturday", @"full name for day of the week");

    case kDaySun:
        return NSLocalizedString(@"Sunday", @"full name for day of the week");

    default: {
        NSMutableString *dayStr = [NSMutableString string];
        NSString *spacing = @"";
        static NSString *space = @" ";

#define ADD_DAY(X, STR)                                                        \
    if ((days & X) != 0) {                                                     \
        [dayStr appendString:spacing];                                         \
        [dayStr appendString:STR];                                             \
        spacing = space;                                                       \
    }

        ADD_DAY(kDayMon,
                NSLocalizedString(@"Mon", @"short name for day of the week"))
        ADD_DAY(kDayTue,
                NSLocalizedString(@"Tue", @"short name for day of the week"))
        ADD_DAY(kDayWed,
                NSLocalizedString(@"Wed", @"short name for day of the week"))
        ADD_DAY(kDayThu,
                NSLocalizedString(@"Thu", @"short name for day of the week"))
        ADD_DAY(kDayFri,
                NSLocalizedString(@"Fri", @"short name for day of the week"))
        ADD_DAY(kDaySat,
                NSLocalizedString(@"Sat", @"short name for day of the week"))
        ADD_DAY(kDaySun,
                NSLocalizedString(@"Sun", @"short name for day of the week"))

        return dayStr;
    }
    }
}

#pragma mark Segmented controls

- (void)timeSegmentChanged:(UISegmentedControl *)sender {
    self.userRequest.timeChoice = (TripTimeChoice)sender.selectedSegmentIndex;
    self.originalFave.valTrip = self.userRequest.toDictionary;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Helper functions

- (void)makeNewFave {
    @synchronized(_userState) {
        self.originalFave = MutableUserParams.new;
        [_userState.faves addObject:self.originalFave.mutableDictionary];
        self.item = _userState.faves.count - 1;
    }
}

- (void)addBookMark {
    [self makeNewFave];
    self.originalFave.valChosenName = kNewBookMark;
    self.stopIdArray = [NSMutableArray array];
    self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
    self.newBookmark = YES;
    [self setupArrivalSections];
}

- (void)addTripBookMark {
    [self makeNewFave];
    self.originalFave.valChosenName = kNewTripBookMark;

    NSDictionary *lastTrip = _userState.lastTrip;

    if (lastTrip != nil) {
        self.userRequest = [TripUserRequest fromDictionary:lastTrip];
        self.userRequest.dateAndTime = nil;
        self.userRequest.arrivalTime = NO;
    } else {
        self.userRequest = [TripUserRequest new];
    }

    self.userRequest.timeChoice = TripDepartAfterTime;
    self.originalFave.valTrip = self.userRequest.toDictionary;
    self.title = NSLocalizedString(@"Add Trip Bookmark", @"screen title");
    self.newBookmark = YES;
    [self setupTripSections];
}

- (void)addTakeMeHomeBookMark {
    [self makeNewFave];

    _updateNameFromDestination = YES;
    self.originalFave.valChosenName = kNewTakeMeSomewhereBookMark;
    self.userRequest = [TripUserRequest new];
    self.userRequest.timeChoice = TripDepartAfterTime;
    self.userRequest.fromPoint.useCurrentLocation = YES;
    [self.userRequest clearGpsNames];
    self.originalFave.valTrip = self.userRequest.toDictionary;
    self.title =
        NSLocalizedString(@"Add a Take Me Somewhere Trip", @"screen title");
    self.newBookmark = YES;
    [self setupTakeMeHomeSections];
}

- (void)processStops:(NSString *)stopIds {
    self.stopIdArray = stopIds.mutableArrayFromCommaSeparatedString;
}

- (void)addBookMarkFromStop:(NSString *)desc stopId:(NSString *)stopId {
    [self makeNewFave];
    self.originalFave.valChosenName = desc;
    [self processStops:stopId];
    self.userRequest = nil;
    [self setupArrivalSections];
    self.originalFave.valLocation = stopId;
    self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
}

- (void)addBookMarkFromUserRequest:(XMLTrips *)tripQuery;
{
    [self makeNewFave];
    NSString *title = [tripQuery shortName];

    if (title == nil) {
        title = NSLocalizedString(@"New Trip", @"screen title");
    }

    self.originalFave.valChosenName = title;
    self.stopIdArray = nil;
    [self setupTripSections];
    self.userRequest = tripQuery.userRequest;
    self.originalFave.valTrip = tripQuery.userRequest.toDictionary;
    self.title = NSLocalizedString(@"Add bookmark", @"screen title");
}

- (void)editBookMark:(NSMutableDictionary *)fave item:(uint)i {
    self.item = i;
    self.originalFave = fave.mutableUserParams;

    if (self.originalFave.valTrip == nil) {
        [self processStops:self.originalFave.valLocation];
        [self setupArrivalSections];
    } else { // if (fave.valTrip !=nil)
        self.userRequest =
            [TripUserRequest fromDictionary:self.originalFave.valTrip];
        [self setupTripSections];
    }

    self.title = NSLocalizedString(@"Edit bookmark", @"screen title");
}

- (UITextField *)createTextField_Rounded {
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, [CellTextField editHeight]);
    UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];

    returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor modeAwareText];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"";
    returnTextField.backgroundColor = [UIColor modeAwareGrayBackground];
    returnTextField.autocorrectionType =
        UITextAutocorrectionTypeNo; // no auto correction support

    returnTextField.keyboardType = UIKeyboardTypeDefault;
    returnTextField.returnKeyType = UIReturnKeyDone;

    returnTextField.clearButtonMode =
        UITextFieldViewModeWhileEditing; // has a clear 'x' button to the right
    self.editWindow = returnTextField;

    return returnTextField;
}

- (void)selectFromRailMap {
    RailMapViewController *rmView = [RailMapViewController viewController];

    rmView.stopIdStringCallback = self;

    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];

    _reloadArrival = YES;
}

- (void)selectFromRailStations {
    AllRailStationViewController *rmView =
        [AllRailStationViewController viewController];

    rmView.stopIdStringCallback = self;

    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];
    _reloadArrival = YES;
}

- (void)browseForStop {
    RouteView *routeViewController = [RouteView viewController];

    routeViewController.stopIdStringCallback = self;

    [routeViewController fetchRoutesAsync:self.backgroundTask
                        backgroundRefresh:NO];
    _reloadArrival = YES;
}

- (void)enterStopId {
    AddNewStopToBookMarkViewController *add =
        [AddNewStopToBookMarkViewController viewController];

    add.stopIdStringCallback = self;
    // Push the detail view controller
    [self.navigationController pushViewController:add animated:YES];
    _reloadArrival = YES;
}

- (BOOL)updateStopsInFave {
    if (self.originalFave != nil) {
        self.originalFave.valLocation = [NSString
            commaSeparatedStringFromStringEnumerator:self.stopIdArray];
        return YES;
    }

    return NO;
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kTableName:
        return NSLocalizedString(@"Bookmark name:", @"section header");

    case kTableStops:
        return NSLocalizedString(@"Add stop ids in the desired order:",
                                 @"section header");

    case kTableSectionTrip:
        return NSLocalizedString(@"Trip:", @"section header");

    case kTableCommute:
        return NSLocalizedString(@"Commuter bookmark", @"section header");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = 0.0;

    switch ([self rowType:indexPath]) {
    case kTableMessage:
        result = UITableViewAutomaticDimension;
        break;

    case kTableName:
        result = [CellTextField cellHeight];
        break;

    case kTableTripRowOptions:
        result = UITableViewAutomaticDimension;
        break;

    case kTableTripRowTo:
        result = UITableViewAutomaticDimension;
        break;

    case kTableTripRowFrom:
        result = UITableViewAutomaticDimension;
        break;

    case kTableRowTime:
        result = [SegmentCell rowHeight];
        break;

    case kTableRun:
    case kTableStops:
    case kTableDelete:
    case kTableSave:
    case kTableSiri:
    case kTableRowStopId:
    case kTableRowStopBrowse:
    case kTableRowRailMap:
    case kTableRowRailStations:
        result = [self basicRowHeight];
        break;

    case kTableCommute:
        return [self basicRowHeight] * 1.4;
    case kTableCommuteInfo:
        return UITableViewAutomaticDimension;
    }

    return result;
}

- (UITableViewCell *)plainCell:(UITableView *)tableView
                          text:(NSString *)text
                     indexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:MakeCellId(plainCell)];

    // Set up the cell
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = text;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    return cell;
}

- (void)populateOptionsCell:(TripItemCell *)cell {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    [cell populateMarkedUpBody:[self.userRequest optionsDisplayText]
                          mode:NSLocalizedString(@"Options", @"trip options")
                          time:nil
                     leftColor:nil
                         route:nil];
}

- (void)populateEndCell:(TripItemCell *)cell from:(bool)from {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    NSString *text;
    NSString *dir;

    if (from) {
        text = [self.userRequest.fromPoint markedUpUserInputDisplayText];
        dir = NSLocalizedString(@"From", @"trip starting from");
    } else {
        text = [self.userRequest.toPoint markedUpUserInputDisplayText];
        dir = NSLocalizedString(@"To", @"trip ending at");
    }

    [cell populateMarkedUpBody:text mode:dir time:nil leftColor:nil route:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];

    switch (rowType) {
    case kTableMessage: {
        NSString *cellId =
            MakeCellIdW(kTableMessage, self.screenInfo.appWinWidth);

        NSAttributedString *text =
            self.markedUpMsg.smallAttributedStringFromMarkUp;

        UITableViewCell *cell = [self tableView:tableView
               multiLineCellWithReuseIdentifier:cellId];
        cell.textLabel.attributedText = text;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self updateAccessibility:cell];
        return cell;

        break;
    }

    case kTableName: {
        if (self.editCell == nil) {
            self.editCell =
                [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:MakeCellId(kTableName)];
            self.editCell.view = [self createTextField_Rounded];
            self.editCell.delegate = self;
        }

        self.editCell.view.text = self.originalFave.valChosenName;
        return self.editCell;
    }

    case kTableStops:
        return [self plainCell:tableView
                          text:self.stopIdArray[indexPath.row]
                     indexPath:indexPath];

    case kTableRowStopId:
        return [self
            plainCell:tableView
                 text:NSLocalizedString(@"Add new stop ID", @"button text")
            indexPath:indexPath];

    case kTableRowStopBrowse:
        return [self plainCell:tableView
                          text:NSLocalizedString(@"Browse routes for stop",
                                                 @"button text)")
                     indexPath:indexPath];

    case kTableRowRailMap:
        return [self plainCell:tableView
                          text:NSLocalizedString(@"Select stop from rail maps",
                                                 @"button text")
                     indexPath:indexPath];

    case kTableRowRailStations:
        return [self
            plainCell:tableView
                 text:NSLocalizedString(@"Search rail stations (A-Z) for stop",
                                        @"button text")
            indexPath:indexPath];

    case kTableRun: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kTableRun)];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Show trip", @"button text");
        cell.systemIcon = kSFIconTripPlanner;
        return cell;
    }

    case kTableTripRowFrom:
    case kTableTripRowTo: {
        TripItemCell *cell =
            [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
        [self populateEndCell:cell
                         from:[self rowType:indexPath] == kTableTripRowFrom];
        return cell;
    }

    case kTableTripRowOptions: {
        TripItemCell *cell =
            [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
        [self populateOptionsCell:cell];
        return cell;
    }

    case kTableRowTime: {
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kTableRowTime)
            cellWithContent:@[
                NSLocalizedString(@"Ask for Time", @"trip time in bookmark"),
                NSLocalizedString(@"Depart Now", @"trip time in bookmark")
            ]
                     target:self
                     action:@selector(timeSegmentChanged:)
              selectedIndex:self.userRequest.timeChoice];
    }

    case kTableDelete: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kTableDelete)];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.font = self.basicFont;

        if (self.newBookmark) {
            cell.textLabel.text =
                NSLocalizedString(@"Cancel new bookmark", @"button text");
        } else {
            cell.textLabel.text =
                NSLocalizedString(@"Delete bookmark", @"button text");
        }

        [cell systemIcon:kSFIconDelete tint:kSFIconDeleteTint];
        return cell;
    }

    case kTableSave: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kTableSave)];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor greenColor];
        cell.textLabel.font = self.basicFont;
        cell.textLabel.text =
            NSLocalizedString(@"Save bookmark", @"button text");

        [cell systemIcon:kSFIconTick tint:kSFIconTickTint];
        return cell;
    }

    case kTableSiri: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kTableSiri)];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.font = self.basicFont;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = kAddBookmarkToSiri;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.namedIcon = kIconSiri;
        return cell;
    }

    case kTableCommute: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kTableCommute)];

        // Set up the cell
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

        cell.textLabel.numberOfLines = 2;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;

        cell.textLabel.text =
            [NSString stringWithFormat:@"%@%@%@", [self dayPrefix],
                                       [self daysString], [self daysPostfix]];

        if ([self autoCommuteEnabled]) {
            if ([self autoCommuteMorning]) {
                [cell systemIcon:kSFIconMorning tint:kSFIconMorningTint];
            } else {
                [cell systemIcon:kSFIconEvening tint:kSFIconEveningTint];
            }
        } else {
            cell.systemIcon = kSFIconArrivals;
        }

        return cell;
    }
    case kTableCommuteInfo: {
        TextViewLinkCell *cell = [self.tableView
            dequeueReusableCellWithIdentifier:MakeCellId(kTableCommuteInfo)];

        cell.textView.attributedText =
            NSLocalizedString(
                @"For commuters, PDX Bus can automatically show this bookmark "
                @"the first time the app starts in the morning or afternoon. "
                @"\n\nYou can also touch the #)#S" kSFIconCommute
                @" #( toolbar icon to show the commuter bookmark.",
                @"section header")
                .smallAttributedStringFromMarkUp;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (bool)tripIsGood {
    return ((self.userRequest.toPoint.useCurrentLocation ||
             self.userRequest.toPoint.locationDesc != nil) &&
            (self.userRequest.fromPoint.useCurrentLocation ||
             self.userRequest.fromPoint.locationDesc != nil));
}

- (void)badTrip {
    UIAlertController *alert = [UIAlertController
        simpleOkWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
                  message:NSLocalizedString(
                              @"Select a start and destination to plan a trip.",
                              @"alert message")];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addToSiri {
    NSUserActivity *activity = [[NSUserActivity alloc]
        initWithActivityType:kHandoffUserActivityBookmark];

    if (self.userRequest == nil) {
        activity.title =
            [NSString stringWithFormat:kUserFavesDescription,
                                       self.originalFave.valChosenName];
        activity.userInfo = self.originalFave.dictionary;
    } else {
        activity = [self.userRequest
            userActivityWithTitle:self.originalFave.valChosenName];
    }

    INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:activity];

    INUIAddVoiceShortcutViewController *viewController =
        [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;

    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
    case kTableStops: {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];
        departureViewController.stopIdStringCallback = self;
        [departureViewController
            fetchTimesForLocationAsync:self.backgroundTask
                                stopId:self.stopIdArray[indexPath.row]
                                 title:self.originalFave.valChosenName];
        break;
    }

    case kTableRowStopBrowse:
        [self browseForStop];
        break;

    case kTableRowRailMap:
        [self selectFromRailMap];
        break;

    case kTableRowRailStations:
        [self selectFromRailStations];
        break;

    case kTableRowStopId:
        [self enterStopId];
        break;

    case kTableTripRowFrom:
    case kTableTripRowTo: {
        TripPlannerEndPointViewController *tripEnd =
            [TripPlannerEndPointViewController viewController];

        tripEnd.from = ([self rowType:indexPath] == kTableTripRowFrom);
        tripEnd.tripQuery = [XMLTrips xml];
        tripEnd.tripQuery.userRequest = self.userRequest;
        @synchronized(_userState) {
            [tripEnd.tripQuery addStopsFromUserFaves:_userState.faves];
        }
        tripEnd.popBackTo = self;

        // Push the detail view controller
        [self.navigationController pushViewController:tripEnd animated:YES];
        _reloadTrip = YES;

        break;
    }

    case kTableTripRowOptions: {
        TripPlannerOptionsViewController *options =
            [TripPlannerOptionsViewController viewController];

        options.tripQuery = [XMLTrips xml];
        options.tripQuery.userRequest = self.userRequest;

        [self.navigationController pushViewController:options animated:YES];
        _reloadTrip = YES;
        break;
    }

    case kTableRun: {
        if (self.tripIsGood) {
            TripPlannerDateViewController *tripDate =
                [TripPlannerDateViewController viewController];

            [tripDate initializeFromBookmark:self.userRequest];

            @synchronized(_userState) {
                [tripDate.tripQuery addStopsFromUserFaves:_userState.faves];
            }

            // Push the detail view controller
            [tripDate nextScreen:self.navigationController
                   taskContainer:self.backgroundTask];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

            [self badTrip];
        }

        break;
    }

    case kTableDelete: {
        @synchronized(_userState) {
            [_userState.faves removeObjectAtIndex:self.item];

            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }

    case kTableSave: {
        [self.navigationController popViewControllerAnimated:YES];
        break;
    }

    case kTableSiri: {
        // Validate that the stop makes sense
        if (self.userRequest != nil) {
            if (self.tripIsGood) {
                [self addToSiri];
            } else {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                [self badTrip];
            }
        } else {
            if (self.stopIdArray == nil || self.stopIdArray.count == 0) {
                UIAlertController *alert = [UIAlertController
                    simpleOkWithTitle:NSLocalizedString(@"Cannot continue",
                                                        @"alert title")
                              message:NSLocalizedString(
                                          @"Please add a stop the bookmark.",
                                          @"alert message")];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                [self addToSiri];
            }
        }

        break;
    }

    case kTableCommute: {
        _reloadArrival = YES;
        DayOfTheWeekViewController *dow =
            [DayOfTheWeekViewController viewController];
        dow.originalFave = self.originalFave;
        [self.navigationController pushViewController:dow animated:YES];
        break;
    }
    }
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        [self.stopIdArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:YES];
        [self updateStopsInFave];
        [self setupArrivalSections];
        [self favesChanged];
        [tableView endUpdates];
    }

    if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

// The editing style for a row is the kind of button displayed to the left of
// the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self sectionType:indexPath.section] == kTableStops) {
        if (indexPath.row < self.stopIdArray.count) {
            return UITableViewCellEditingStyleDelete;
        }

        return UITableViewCellEditingStyleInsert;
    }

    return UITableViewCellEditingStyleNone;
}

// Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.

    switch ([self sectionType:indexPath.section]) {
    case kTableStops:
        return YES;

    case kTableSectionTrip:
    case kTableName:
    case kTableDelete:
    case kTableSave:
    case kTableRun:
    case kTableCommute:
    case kTableMessage:
    case kTableSiri:
        return NO;
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
                         toProposedIndexPath:
                             (NSIndexPath *)proposedDestinationIndexPath {
    if ([self sectionType:proposedDestinationIndexPath.section] !=
        kTableStops) {
        return [NSIndexPath indexPathForRow:0 inSection:_stopSection];
    }

    if (proposedDestinationIndexPath.row >= self.stopIdArray.count) {
        return [NSIndexPath indexPathForRow:self.stopIdArray.count - 1
                                  inSection:_stopSection];
    }

    return proposedDestinationIndexPath;
}

/*
 // Have an accessory view for the second section only
 - (UITableViewCellAccessoryType)tableView:(UITableView *)tableView
 accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath { return
 (indexPath.section == kTableSectionStops) ?
 UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
 }
 */

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath {
    if ([self sectionType:fromIndexPath.section] == kTableStops &&
        [self sectionType:toIndexPath.section] == kTableStops) {
        NSString *move = self.stopIdArray[fromIndexPath.row];

        if (fromIndexPath.row < toIndexPath.row) {
            [self.stopIdArray insertObject:move atIndex:toIndexPath.row + 1];
            [self.stopIdArray removeObjectAtIndex:fromIndexPath.row];
        } else {
            [self.stopIdArray removeObjectAtIndex:fromIndexPath.row];
            [self.stopIdArray insertObject:move atIndex:toIndexPath.row];
        }

        [self updateStopsInFave];
    }
}

// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView
    canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if ([self rowType:indexPath] == kTableStops) {
        return YES;
    }

    return NO;
}

#pragma mark View methods

- (void)viewDidLoad {
    // Add the following line if you want the list to be editable
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.editing = YES;
    [self favesChanged];

    [self.tableView registerNib:[TextViewLinkCell nib]
         forCellReuseIdentifier:MakeCellId(kTableCommuteInfo)];
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] ==
        NSNotFound) {
        [self favesChanged];
        [_userState cacheState];
    }

    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_reloadTrip) {
        self.originalFave.valTrip = self.userRequest.toDictionary;

        if (_updateNameFromDestination) {
            NSString *place = self.userRequest.toPoint.additionalInfo;

            if (place == nil) {
                place = self.userRequest.toPoint.displayText;
            }

            if (place == nil) {
                place = self.userRequest.toPoint.locationDesc;
            }

            self.originalFave.valChosenName =
                [NSString stringWithFormat:@"Take me to %@", place];
        }

        [self reloadData];
        _reloadTrip = FALSE;
    }

    if (_reloadArrival) {
        [self favesChanged];
        [self setupArrivalSections];
        [self reloadData];
        _reloadArrival = FALSE;
    }
}

- (void)loadView {
    [super loadView];
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.tableView registerNib:[TripItemCell nib]
         forCellReuseIdentifier:kTripItemCellId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a
                                     // superview Release anything that's not
                                     // essential, such as cached data
}

#pragma mark Text Editing Methods
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell {
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(cancelAction:)];

    self.navigationItem.rightBarButtonItem = cancelButton;

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                              inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];

    return YES;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell {
    UITextView *textView = (UITextView *)((CellTextField *)cell).view;

    if (textView.text.length != 0 &&
        self.navigationItem.rightBarButtonItem != nil) {
        self.originalFave.valChosenName = textView.text;
    } else {
        textView.text = self.originalFave.valChosenName;
    }
}

- (void)cancelAction:(id)sender {
    self.navigationItem.rightBarButtonItem = nil;
    [self.editWindow resignFirstResponder];
}

#pragma mark ReturnStopIdString methods

- (NSString *)returnStopIdStringActionText {
    return NSLocalizedString(@"Add stop to bookmark", @"Button text");
}

- (void)returnStopIdString:(NSString *)stopId desc:(NSString *)stopDesc {
    if (stopDesc != nil) {
        if ([self.editCell.view.text isEqualToString:kNewBookMark]) {
            self.originalFave.valChosenName = stopDesc;
            self.editCell.view.text = stopDesc;
        }
    }

    [self.navigationController popToViewController:self animated:YES];
    [self.stopIdArray addObject:stopId];
    [self updateStopsInFave];
    [self reloadData];
}

- (UIViewController *)returnStopIdStringController {
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle !=
        self.traitCollection.userInterfaceStyle) {
        self.editCell = nil;
    }

    [super traitCollectionDidChange:previousTraitCollection];
}

@end

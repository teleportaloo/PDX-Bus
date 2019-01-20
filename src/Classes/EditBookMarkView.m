//
//  EditBookMarkView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "EditBookMarkView.h"
#import "UserFaves.h"
#import "CellTextField.h"
#import "CellTextView.h"
#import "DepartureTimesView.h"
#import "RouteView.h"
#import "AddNewStopToBookMark.h"
#import "RailMapView.h"
#import "TripPlannerEndPointView.h"
#import "TripPlannerDateView.h"
#import "TripPlannerOptions.h"
#import "AllRailStationView.h"
#import "DayOfTheWeekView.h"
#import "SegmentCell.h"
#import "StringHelper.h"
#import <Intents/Intents.h>


enum SECTIONS_AND_ROWS
{
    kTableMessage,
    kTableName,
    kTableStops,
    kTableSectionTrip,
    kTableSiri,
    kTableDelete,
    kTableRun,
    kTableCommute,
    kTableRowStopId,
    kTableRowStopBrowse,
    kTableRowRailMap,
    kTableRowRailStations,
    kTableTripRowFrom,
    kTableTripRowTo,
    kTableTripRowOptions,
    kTableRowTime
} ;


#define kTakeMeHomeText NSLocalizedString(@"This page enables you to create a bookmark that will search for a route from your #icurrent location#i to a destination, leaving immediately.\n\nFor example, use it to create a #BTake Me Home Now#0 trip.", \
                                          @"take me home text")


#define kIncompleteStopMsg NSLocalizedString(@"#RThe bookmark was incomplete. Please add a stop.", @"error text")
#define kIncompleteTripMsg NSLocalizedString(@"#RThe bookmark was incomplete. Please check locations.", @"error text")

#define kUIEditHeight            55.0
#define kUIRowHeight            40.0

@implementation EditBookMarkView



- (instancetype)init {
    if ((self = [super init]))
    {
        // clear the last run so the commute bookmark can be tested
        [SafeUserData sharedInstance].lastRun = nil;
        self.invalidItem = NO;
        _updateNameFromDestination = NO;
        _newBookmark = NO;
    }
    return self;
}

-(void) setupArrivalSections
{
    [self clearSectionMaps];

    if (self.invalidItem)
    {
        [self addSectionType:kTableMessage];
        [self addRowType:kTableMessage];
        self.msg = kIncompleteStopMsg;
    }
    
    [self addSectionType:kTableName];
    [self addRowType:kTableName];
    
    _stopSection = [self addSectionType:kTableStops];
    
    [self addRowType:kTableStops count:self.stops.count];
    
    [self addRowType:kTableRowStopId];
    [self addRowType:kTableRowStopBrowse];
    [self addRowType:kTableRowRailMap];
    [self addRowType:kTableRowRailStations];
    
    [self addSectionType:kTableCommute];
    [self addRowType:kTableCommute];
    
    if (@available(iOS 12.0, *))
    {
        [self addSectionType:kTableSiri];
        [self addRowType:kTableSiri];
    }
    
    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];
}

-(void) setupTripSections
{
    [self clearSectionMaps];
    
    if (self.invalidItem)
    {
        [self addSectionType:kTableMessage];
        [self addRowType:kTableMessage];
        self.msg = kIncompleteTripMsg;
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
    
    if (@available(iOS 12.0, *))
    {
        [self addSectionType:kTableSiri];
        [self addRowType:kTableSiri];
    }
    
    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];
    
    _stopSection   = kNoRowSectionTypeFound;
}


-(void) setupTakeMeHomeSections
{
    [self clearSectionMaps];
    
    [self addSectionType:kTableMessage];
    [self addRowType:kTableMessage];
    self.msg = kTakeMeHomeText;
    
    [self addSectionType:kTableName];
    [self addRowType:kTableName];
    
    [self addSectionType:kTableSectionTrip];
    [self addRowType:kTableTripRowTo];
    [self addRowType:kTableTripRowOptions];
    
    [self addSectionType:kTableRun];
    [self addRowType:kTableRun];
    
    if (@available(iOS 12.0, *))
    {
        [self addSectionType:kTableSiri];
        [self addRowType:kTableSiri];
    }
    
    [self addSectionType:kTableDelete];
    [self addRowType:kTableDelete];
    
    _stopSection   = kNoRowSectionTypeFound;
}


#pragma mark Commuter Helper functions

- (bool)autoCommuteEnabled
{
    bool autoCommute = NO;
    if (self.originalFave!=nil)
    {
        NSNumber *days = self.originalFave[kUserFavesDayOfWeek];
        
        if (days.intValue!=kDayNever)
        {
            autoCommute = YES;
        }
    }
    return autoCommute;    
}

- (bool)autoCommuteMorning
{
    NSNumber *num = self.originalFave[kUserFavesMorning];
    bool morning = TRUE;
    
    if (num)
    {
        morning = num.boolValue;
    }
    
    return morning;
}

- (NSString *)daysPostfix
{
    NSNumber *num = self.originalFave[kUserFavesDayOfWeek];
    int days = kDayNever;
    
    if (num)
    {
        days = num.intValue;
    }
    
    if (days == kDayNever)
    {
        return @"";
    }
    
    if ([self autoCommuteMorning])
    {
        return NSLocalizedString(@" mornings", @"text concatonated after a list of weekdays");
    }
    return NSLocalizedString(@" afternoons", @"text concatonated after a list of weekdays");
}

- (NSString *)dayPrefix
{
    NSNumber *num = self.originalFave[kUserFavesDayOfWeek];
    int days = kDayNever;
    
    if (num)
    {
        days = num.intValue;
    }
    
    switch (days)
    {
        case kDayNever:
            return @"";
        case kDayAllWeek:
            return NSLocalizedString(@"Show ", @"before text 'every day in the <morning or evening>'");
        default:
            return NSLocalizedString(@"Show on ", @"followed by a list of the days of the week");
    }
}

- (NSString*)daysString
{
    NSNumber *num = self.originalFave[kUserFavesDayOfWeek];
    int days = kDayNever;
    
    if (num)
    {
        days = num.intValue;
    }
    
    return [EditBookMarkView daysString:days];
}

+ (NSString *)daysString:(int)days
{
    switch (days)
    {
        case kDayNever:
            return NSLocalizedString(@"No days selected", @"error message");
        case kDayWeekend:
            return NSLocalizedString(@"weekend", @"short for Saturday and Sunday");
        case kDayWeekday:
            return NSLocalizedString(@"weekday", @"short for Monday - Friday");
        case kDayAllWeek:
            return NSLocalizedString(@"everyday in the", @"followed by <morning/afternoon>");
        case kDayMon:
            return NSLocalizedString(@"Monday",   @"full name for day of the week");
        case kDayTue:
            return NSLocalizedString(@"Tuesday",  @"full name for day of the week");
        case kDayWed:
            return NSLocalizedString(@"Wednesday",@"full name for day of the week");
        case kDayThu:
            return NSLocalizedString(@"Thursday", @"full name for day of the week");
        case kDayFri:
            return NSLocalizedString(@"Friday",   @"full name for day of the week");
        case kDaySat:
            return NSLocalizedString(@"Saturday", @"full name for day of the week");
        case kDaySun:
            return NSLocalizedString(@"Sunday",   @"full name for day of the week");
        default:
        {
            NSMutableString *dayStr = [NSMutableString string];
            NSString *spacing = @"";
            static NSString *space = @" ";
            
#define ADD_DAY(X, STR)                                    \
            if ((days & X) !=0)                            \
            {                                            \
                [dayStr appendString:spacing];            \
                [dayStr appendString:STR];                \
                spacing = space;                        \
            }                                            
            
            ADD_DAY(kDayMon, NSLocalizedString(@"Mon", @"short name for day of the week"))
            ADD_DAY(kDayTue, NSLocalizedString(@"Tue", @"short name for day of the week"))
            ADD_DAY(kDayWed, NSLocalizedString(@"Wed", @"short name for day of the week"))
            ADD_DAY(kDayThu, NSLocalizedString(@"Thu", @"short name for day of the week"))
            ADD_DAY(kDayFri, NSLocalizedString(@"Fri", @"short name for day of the week"))
            ADD_DAY(kDaySat, NSLocalizedString(@"Sat", @"short name for day of the week"))
            ADD_DAY(kDaySun, NSLocalizedString(@"Sun", @"short name for day of the week"))
            
            return dayStr;
        }
    }
}

#pragma mark Segmented controls

- (void)timeSegmentChanged:(id)sender
{
    UISegmentedControl *seg = (UISegmentedControl*)sender;
    self.userRequest.timeChoice = (TripTimeChoice)seg.selectedSegmentIndex;
    self.originalFave[kUserFavesTrip] = self.userRequest.toDictionary;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) style
{
    return UITableViewStyleGrouped;
}

#pragma mark Helper functions

-(void)makeNewFave
{
    @synchronized (_userData)
    {    
        self.originalFave = [NSMutableDictionary dictionary];
        [_userData.faves addObject:self.originalFave];
        self.item = _userData.faves.count-1;
    }
}

-(void)addBookMark
{
    [self makeNewFave];
    self.originalFave[kUserFavesChosenName] = kNewBookMark;
    self.stops = [NSMutableArray array];
    self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
    self.newBookmark = YES;
    [self setupArrivalSections];
}

-(void)addTripBookMark
{
    [self makeNewFave];
    self.originalFave[kUserFavesChosenName] = kNewTripBookMark;
    
    NSDictionary *lastTrip = _userData.lastTrip;
    
    if (lastTrip !=nil)
    {
        self.userRequest = [TripUserRequest fromDictionary:lastTrip];
        self.userRequest.dateAndTime = nil;
        self.userRequest.arrivalTime = NO;
    }
    else
    {
        self.userRequest = [TripUserRequest data];
    }
    
    
    self.userRequest.timeChoice = TripDepartAfterTime;
    self.originalFave[kUserFavesTrip] = self.userRequest.toDictionary;
    self.title = NSLocalizedString(@"Add Trip Bookmark", @"screen title");
    self.newBookmark = YES;
    [self setupTripSections];
}


-(void)addTakeMeHomeBookMark
{
    [self makeNewFave];
    
    _updateNameFromDestination = YES;
    self.originalFave[kUserFavesChosenName] = kNewTakeMeSomewhereBookMark;
    self.userRequest = [TripUserRequest data];
    self.userRequest.timeChoice = TripDepartAfterTime;
    self.userRequest.fromPoint.useCurrentLocation = YES;
    [self.userRequest clearGpsNames];
    self.originalFave[kUserFavesTrip] = self.userRequest.toDictionary;
    self.title = NSLocalizedString(@"Add a Take Me Somewhere Trip", @"screen title");
    self.newBookmark = YES;
    [self setupTakeMeHomeSections];
}


-(void)processStops:(NSString *)locs
{
    self.stops = locs.arrayFromCommaSeparatedString;
}

-(void) addBookMarkFromStop:(NSString *)desc location:(NSString *)locid
{
    [self makeNewFave];
    self.originalFave[kUserFavesChosenName] = desc;
    [self processStops:locid];
    self.userRequest = nil;
    [self setupArrivalSections];
    self.originalFave[kUserFavesLocation] = locid;
    self.title = NSLocalizedString(@"Add Bookmark", @"screen title");
}

-(void) addBookMarkFromUserRequest:(XMLTrips*)tripQuery;
{
    [self makeNewFave];
    NSString *title = [tripQuery shortName];
    
    if (title == nil) 
    {
        title = NSLocalizedString(@"New Trip", @"screen title");
    }

    self.originalFave[kUserFavesChosenName] = title;
    self.stops = nil;
    [self setupTripSections];
    self.userRequest = tripQuery.userRequest;
    self.originalFave[kUserFavesTrip] = tripQuery.userRequest.toDictionary;
    self.title = NSLocalizedString(@"Add bookmark", @"screen title");
}



-(void) editBookMark:(NSMutableDictionary *)fave item:(uint)i
{
    self.item = i;
    self.originalFave = fave;
    
    if (fave[kUserFavesTrip] == nil )
    {    
        [self processStops:fave[kUserFavesLocation]];
        [self setupArrivalSections];
    }
    else // if (fave[kUserFavesTrip] !=nil)
    {
        self.userRequest = [TripUserRequest fromDictionary:fave[kUserFavesTrip]];
        [self setupTripSections];
    }
        
    self.title = NSLocalizedString(@"Edit bookmark", @"screen title");
}

- (UITextField *)createTextField_Rounded
{
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, [CellTextField editHeight]);
    UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];
    
    returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"";
    returnTextField.backgroundColor = [UIColor whiteColor];
    returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;    // no auto correction support
    
    returnTextField.keyboardType = UIKeyboardTypeDefault;
    returnTextField.returnKeyType = UIReturnKeyDone;
    
    returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;    // has a clear 'x' button to the right
    self.editWindow = returnTextField;
    
    return returnTextField;
}

- (void) selectFromRailMap
{
    RailMapView *rmView = [RailMapView viewController];
    
    rmView.callback = self;
    
    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];
    
    _reloadArrival = YES;
}

- (void) selectFromRailStations
{
    AllRailStationView *rmView = [AllRailStationView viewController];
    
    rmView.callback = self;
    
    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];
    _reloadArrival = YES;
}

- (void) browseForStop
{
    RouteView *routeViewController = [RouteView viewController];
    
    routeViewController.callback = self;
    
    [routeViewController fetchRoutesAsync:self.backgroundTask backgroundRefresh:NO];
    _reloadArrival = YES;
}

- (void) enterStopId
{
    AddNewStopToBookMark *add = [AddNewStopToBookMark viewController];
    add.callback = self;
    // Push the detail view controller
    [self.navigationController pushViewController:add animated:YES];
    _reloadArrival = YES;
}

- (BOOL) updateStopsInFave
{
    if (self.originalFave !=nil)    {
        NSMutableString *locations = [[NSMutableString alloc] init];
        
        if (self.stops.count > 0)
        {
            for (NSString *stop in self.stops)
            {
                if (locations.length>0)
                {
                    [locations appendString:@","];
                }
                [locations appendFormat:@"%@",stop];
            }
        }
        
        self.originalFave[kUserFavesLocation] = locations;
        return YES;
    }
    return NO;
    
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self sections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section])
    {
        case kTableName:
            return NSLocalizedString(@"Bookmark name:", @"section header");
        case kTableStops:
            return NSLocalizedString(@"Add stop ids in the desired order:", @"section header");
        case kTableSectionTrip:
            return NSLocalizedString(@"Trip:", @"section header");
        case kTableCommute:
            return NSLocalizedString(@"For commuters, PDX Bus can automatically show this bookmark the first time the app starts in the morning or afternoon:", @"section header");
    }
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = 0.0;
    
    switch ([self rowType:indexPath])
    {
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
            result = [SegmentCell segmentCellHeight];
            break;
        case kTableRun:
        case kTableStops:
        case kTableDelete:
        case kTableSiri:
        case kTableRowStopId:
        case kTableRowStopBrowse:
        case kTableRowRailMap:
        case kTableRowRailStations:
            result = [self basicRowHeight];
            break;
        case kTableCommute:
            return [self basicRowHeight] * 1.4;
            break;
    }
    
    return result;
}

- (UITableViewCell *)plainCell:(UITableView *)tableView text:(NSString *)text indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell  = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(plainCell)];
    
    // Set up the cell
    cell.accessoryType = UITableViewCellAccessoryNone ;
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
    cell.textLabel.text = text;
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    return cell;

}

- (void)populateOptionsCell:(TripItemCell *)cell
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    
    [cell populateBody:[self.userRequest optionsDisplayText] mode:NSLocalizedString(@"Options", @"trip options") time:nil leftColor:nil route:nil];
}

- (void)populateEndCell:(TripItemCell *)cell from:(bool)from
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    
    NSString *text;
    NSString *dir;
    
    if (from)
    {
        text = [self.userRequest.fromPoint userInputDisplayText];
        dir = NSLocalizedString(@"From", @"trip starting from");
        
    }
    else {
        text = [self.userRequest.toPoint userInputDisplayText];
        dir = NSLocalizedString(@"To", @"trip ending at");
    }
    
    [cell populateBody:text mode:dir time:nil leftColor:nil route:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger rowType = [self rowType:indexPath];
    
    switch(rowType)
    {
        case kTableMessage:
        {
            NSString *cellId = MakeCellIdW(kTableMessage,self.screenInfo.appWinWidth);
            
            NSAttributedString *text = [self.msg formatAttributedStringWithFont:self.paragraphFont];
            
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:cellId];
            cell.textLabel.attributedText =  text;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self updateAccessibility:cell];
            return cell;
            break;
        }
        case kTableName:
        {
            if (self.editCell == nil)
            {
                self.editCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kTableName)];
                self.editCell.view = [self createTextField_Rounded];
                self.editCell.delegate = self;
            }
            self.editCell.view.text = self.originalFave[kUserFavesChosenName];
            return self.editCell;
        }
        case kTableStops:
            return [self plainCell:tableView text:self.stops[indexPath.row] indexPath:indexPath];
        case kTableRowStopId:
            return [self plainCell:tableView text: NSLocalizedString(@"Add new stop ID", @"button text") indexPath:indexPath];
        case kTableRowStopBrowse:
            return [self plainCell:tableView text: NSLocalizedString(@"Browse routes for stop", @"button text)") indexPath:indexPath];
        case kTableRowRailMap:
            return [self plainCell:tableView text: NSLocalizedString(@"Select stop from rail maps", @"button text") indexPath:indexPath];
        case kTableRowRailStations:
            return [self plainCell:tableView text: NSLocalizedString(@"Search rail stations (A-Z) for stop", @"button text") indexPath:indexPath];
            
        case kTableRun:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTableRun)];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            cell.textLabel.text = NSLocalizedString(@"Show trip", @"button text");
            cell.imageView.image = [self getIcon:kIconTripPlanner];
            return cell;
        }
            
        case kTableTripRowFrom:
        case kTableTripRowTo:
        {
            TripItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
            [self populateEndCell:cell from:[self rowType:indexPath] == kTableTripRowFrom];
            return cell;
        }
        case kTableTripRowOptions:
        {
            TripItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
            [self populateOptionsCell:cell];
            return cell;
        }
            
        case kTableRowTime:
        {
            SegmentCell *cell = (SegmentCell*)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kTableRowTime)];
            if (cell == nil) {
                cell = [[SegmentCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:MakeCellId(kTableRowTime)];
                
                [cell createSegmentWithContent:@[
                                                NSLocalizedString(@"Ask for Time",@"trip time in bookmark"),
                                                NSLocalizedString(@"Depart Now",@"trip time in bookmark")]
                                        target:self
                                        action:@selector(timeSegmentChanged:)];
                cell.isAccessibilityElement = NO;
            }
            cell.segment.selectedSegmentIndex = self.userRequest.timeChoice;
            return cell;
        }
        case kTableDelete:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTableDelete)];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.font = self.basicFont;
            
            if (self.newBookmark)
            {
                cell.textLabel.text = NSLocalizedString(@"Cancel new bookmark", @"button text");
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Delete bookmark", @"button text");
            }
            cell.imageView.image = [self getIcon:kIconDelete];
            return cell;
        }
        case kTableSiri:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTableSiri)];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = kAddBookmarkToSiri;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.imageView.image = [self getIcon:kIconSiri];
            return cell;
        }
        case kTableCommute:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kTableCommute)];
    
            // Set up the cell
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator ;
            
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", 
                                   [self dayPrefix], 
                                   [self daysString],
                                   [self daysPostfix] ];
            
            if ([self autoCommuteEnabled])
            {
                if ([self autoCommuteMorning])
                {
                    cell.imageView.image = [self getFaveIcon:kIconMorning]; 
                }
                else 
                {
                    cell.imageView.image = [self getFaveIcon:kIconEvening]; 
                }
            }
            else 
            {
                cell.imageView.image = [self getFaveIcon:kIconArrivals];
            }
            
            
            return cell;    
        }
            
            
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (bool)tripIsGood
{
    return ((self.userRequest.toPoint.useCurrentLocation || self.userRequest.toPoint.locationDesc!=nil)
            && (self.userRequest.fromPoint.useCurrentLocation || self.userRequest.fromPoint.locationDesc!=nil));
}

- (void)badTrip
{
    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
                                                      message:NSLocalizedString(@"Select a start and destination to plan a trip.", @"alert message")
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                            otherButtonTitles:nil ];
    [alert show];
}

- (void)addToSiri
{
    if (@available(iOS 12.0, *))
    {
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:kHandoffUserActivityBookmark];
        
        if (self.userRequest==nil)
        {
            
            activity.title = [NSString stringWithFormat:kUserFavesDescription,  self.originalFave[kUserFavesChosenName]];
            activity.userInfo = self.originalFave;
        }
        else
        {
            activity = [self.userRequest userActivityWithTitle:self.originalFave[kUserFavesChosenName]];
        }
        
        
        INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:activity];
        
        INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.delegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller didFinishWithVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut error:(nullable NSError *)error
API_AVAILABLE(ios(12.0))
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)addVoiceShortcutViewControllerDidCancel:(nonnull INUIAddVoiceShortcutViewController *)controller
API_AVAILABLE(ios(12.0))
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch([self rowType:indexPath])
    {
            
        case kTableStops:
        {
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
            departureViewController.callback = self;
            [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                            loc:self.stops[indexPath.row]
                                                          title:self.originalFave[kUserFavesChosenName]];
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
        case kTableTripRowTo:
        {
            TripPlannerEndPointView *tripEnd = [TripPlannerEndPointView viewController];
            
            
            tripEnd.from = ([self rowType:indexPath]== kTableTripRowFrom) ;
            tripEnd.tripQuery = [XMLTrips xml];
            tripEnd.tripQuery.userRequest = self.userRequest;
            @synchronized (_userData)
            {
                [tripEnd.tripQuery addStopsFromUserFaves:_userData.faves];
            }
            tripEnd.popBackTo = self;
            
            // Push the detail view controller
            [self.navigationController pushViewController:tripEnd animated:YES];
            _reloadTrip = YES;
            
            break;
        }
        case kTableTripRowOptions:
        {
            TripPlannerOptions * options = [TripPlannerOptions viewController];
            
            options.tripQuery = [XMLTrips xml];
            options.tripQuery.userRequest = self.userRequest;
            
            [self.navigationController pushViewController:options animated:YES];
            _reloadTrip = YES;
            break;
            
        }
        case kTableRun:
        {
            if (self.tripIsGood)
            {
                TripPlannerDateView *tripDate = [TripPlannerDateView viewController];
                
                [tripDate initializeFromBookmark:self.userRequest];
                
                @synchronized (_userData)
                {
                    [tripDate.tripQuery addStopsFromUserFaves:_userData.faves];
                }
                
                
                // Push the detail view controller
                [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
                
            }
            else {
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
                
                [self badTrip];
            }
            
            break;
        }
        case kTableDelete:
        {
            @synchronized (_userData)
            {
                [_userData.faves removeObjectAtIndex:self.item];
                
                [self.navigationController popViewControllerAnimated:YES];
                break;
            }
        }
        case kTableSiri:
        {
            // Validate that the stop makes sense
            if (self.userRequest!=nil)
            {
                if (self.tripIsGood)
                {
                    [self addToSiri];
                }
                else
                {
                    [self.table deselectRowAtIndexPath:indexPath animated:YES];
                    
                    [self badTrip];
                }
            }
            else
            {
                if (self.stops==nil || self.stops.count == 0)
                {
                    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Cannot continue", @"alert title")
                                                                      message:NSLocalizedString(@"Please add a stop the bookmark.", @"alert message")
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                            otherButtonTitles:nil ];
                    [alert show];
                }
                else
                {
                    [self addToSiri];
                }
            }
            
            
            break;
        }
        case kTableCommute:
        {
            _reloadArrival = YES;
            DayOfTheWeekView *dow = [DayOfTheWeekView viewController];
            dow.originalFave = self.originalFave;
            [self.navigationController pushViewController:dow animated:YES];
            break;
        }
    }
}



// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        [self.stops removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        [self updateStopsInFave];
        [self setupArrivalSections];
        [self favesChanged];
        [tableView endUpdates];
    }
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self sectionType:indexPath.section] == kTableStops)
    {
        if ( indexPath.row < self.stops.count)
        {
            return UITableViewCellEditingStyleDelete;
        }
        return UITableViewCellEditingStyleInsert;
        
    }
    return UITableViewCellEditingStyleNone;
}

// Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    
    switch([self sectionType:indexPath.section])
    {
        case kTableStops:
            return YES;
        case kTableSectionTrip:
        case kTableName:
        case kTableDelete:
        case kTableRun:
        case kTableCommute:
        case kTableMessage:
        case kTableSiri:
            return NO;
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if ([self sectionType:proposedDestinationIndexPath.section] != kTableStops)
    {
        return [NSIndexPath
                indexPathForRow:0
                inSection:_stopSection];
    }
    
    if (proposedDestinationIndexPath.row >= self.stops.count)
    {
        return [NSIndexPath
                indexPathForRow:self.stops.count-1
                inSection:_stopSection];
    }
    
    return proposedDestinationIndexPath;
    
}

/*
 // Have an accessory view for the second section only
 - (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
 return (indexPath.section == kTableSectionStops) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
 }
 */

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    if ([self sectionType:fromIndexPath.section] == kTableStops && [self sectionType:toIndexPath.section] == kTableStops)
    {
        NSString *move = self.stops[fromIndexPath.row];
        
        if (fromIndexPath.row < toIndexPath.row)
        {
            [self.stops insertObject:move atIndex:toIndexPath.row+1];
            [self.stops removeObjectAtIndex:fromIndexPath.row];
        }
        else
        {
            [self.stops removeObjectAtIndex:fromIndexPath.row];
            [self.stops insertObject:move atIndex:toIndexPath.row];
        }
        [self updateStopsInFave];
    }
}

// Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if ([self rowType:indexPath] == kTableStops)
    {
        return YES;
    }
    return NO;
}

#pragma mark View methods

- (void)viewDidLoad {
    // Add the following line if you want the list to be editable
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.table.editing = YES;
    [self favesChanged];
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_reloadTrip)
    {
        self.originalFave[kUserFavesTrip] = self.userRequest.toDictionary;
        
        if (_updateNameFromDestination)
        {
            NSString *place = self.userRequest.toPoint.additionalInfo;
            if (place == nil)
            {
                place = self.userRequest.toPoint.displayText;
            }
            
            if (place == nil)
            {
                place = self.userRequest.toPoint.locationDesc;
            }
            self.originalFave[kUserFavesChosenName] = [NSString stringWithFormat:@"Take me to %@", place];
        }
        
        [self reloadData];
        _reloadTrip = FALSE;
    }
    
    if (_reloadArrival)
    {
        [self favesChanged];
        [self setupArrivalSections];
        [self reloadData];
        _reloadArrival = FALSE;
    }
}

- (void)loadView
{
    [super loadView];
    self.table.allowsSelectionDuringEditing = YES;
    [self.table registerNib:[TripItemCell nib] forCellReuseIdentifier:kTripItemCellId];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


#pragma mark Text Editing Methods
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                     target:self
                                     action:@selector(cancelAction:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [self.table scrollToRowAtIndexPath:[NSIndexPath
                                        indexPathForRow:0
                                        inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    
    
    
    return YES;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
    UITextView *textView = (UITextView*)((CellTextField*)cell).view;
    if (textView.text.length !=0 && self.navigationItem.rightBarButtonItem != nil )
    {
        self.originalFave[kUserFavesChosenName] = textView.text;
    }
    else
    {
        textView.text = self.originalFave[kUserFavesChosenName];
    }
}

- (void)cancelAction:(id)sender
{
    self.navigationItem.rightBarButtonItem = nil;
    [self.editWindow resignFirstResponder];
}

#pragma mark ReturnStopId methods

- (NSString *)actionText
{
    return NSLocalizedString(@"Add stop to bookmark", @"Button text");
}

-(void) selectedStop:(NSString *)stopId
{
    [self.navigationController popToViewController:self animated:YES];
    [self.stops addObject:stopId];
    [self updateStopsInFave];
    [self reloadData];
}

-(void) selectedStop:(NSString *)stopId desc:(NSString*)stopDesc
{
    if ([self.editCell.view.text isEqualToString:kNewBookMark])
    {
        self.originalFave[kUserFavesChosenName] = stopDesc;
        self.editCell.view.text = stopDesc;
    }
    
    [self.navigationController popToViewController:self animated:YES];
    [self.stops addObject:stopId];
    [self updateStopsInFave];
    [self reloadData];
}

-(UIViewController*) controller
{
    return self;
}

#pragma mark TripReturnUserRequest methods

-(void)userRequest:(TripUserRequest *)userRequest
{
    self.userRequest = userRequest;
    
    if ([self.editCell.view.text isEqualToString:kNewTripBookMark])
    {
        self.originalFave[kUserFavesChosenName] = userRequest.shortName;
        self.editCell.view.text = [userRequest shortName];
    }
    
    
    self.originalFave[kUserFavesTrip] = userRequest.toDictionary;
    
    [self reloadData];
}


@end

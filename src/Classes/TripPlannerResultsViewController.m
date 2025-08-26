//
//  TripPlannerResultsView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "TripPlannerResultsViewController.h"
#import "AlarmAccurateStopProximity.h"
#import "AlarmTaskList.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "CLLocation+Helper.h"
#import "DepartureTimesViewController.h"
#import "DetoursViewController.h"
#import "EditBookMarkViewController.h"
#import "Icons.h"
#import "MainQueueSync.h"
#import "MapViewController.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "NetworkTestViewController.h"
#import "PDXBus-Swift.h"
#import "SimpleAnnotation.h"
#import "TriMetInfo+UI.h"
#import "TriMetInfo.h"
#import "TripPlannerDateViewController.h"
#import "TripPlannerEndPointViewController.h"
#import "TripPlannerMapController.h"
#import "TripPlannerSummaryViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIBarButtonItem+Icons.h"
#import "UITableViewCell+Icons.h"
#import "UIViewController+LocationAuthorization.h"
#import "UserParams.h"
#import "UserState.h"
#import "WebViewController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <Intents/Intents.h>
#import <IntentsUI/IntentsUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MessageUI.h>

enum {
    kRowTypeLeg = 0,
    kRowTypeDuration,
    kRowTypeTransfers,
    kRowTypeDistance,
    kRowTypeFare,
    kRowTypeMap,
    kRowTypeEmail,
    kRowTypeSMS,
    kRowTypeCal,
    kRowTypeClipboard,
    kRowTypeTag,
    kRowTypeAlarms,
    kRowTypeArrivals,
    kRowTypeDetours,
    kRowTypeError,
    kRowTypeReverse,
    kRowTypeFrom,
    kRowTypeTo,
    kRowTypeOptions,
    kRowTypeDateAndTime
};

enum {
    kSectionTypeEndPoints = 0,
    kSectionTypeOptions,
    kRowsInDisclaimerSection
};

#define kDisclosure UITableViewCellAccessoryDisclosureIndicator
#define kScheduledText                                                         \
    @"The trip planner shows scheduled service only. Check below to see how "  \
    @"detours may affect your trip."

@interface TripPlannerResultsViewController () {
    int _itinerarySectionOffset;
    bool _sms;
    bool _cal;
    int _recentTripItem;
}

@property(nonatomic, strong) TripItemCell *prototypeTripCell;
@property(nonatomic, strong) EKEvent *event;
@property(nonatomic, strong) EKEventStore *eventStore;
@property(nonatomic, readonly, copy) NSString *fromText;
@property(nonatomic, readonly, copy) NSString *toText;

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath;
- (NSInteger)legRows:(TripItinerary *)it;
- (TripItinerary *)getSafeItinerary:(NSInteger)section;
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error;
- (void)messageComposeViewController:
            (MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result;

- (void)setItemFromHistory:(int)item;
- (void)setItemFromArchive:(NSDictionary *)archive;

@end

@implementation TripPlannerResultsViewController

- (instancetype)init {
    if ((self = [super init])) {
        _recentTripItem = -1;
    }

    return self;
}

- (instancetype)initWithHistoryItem:(int)item {
    if ((self = [super init])) {
        [self setItemFromHistory:item];
    }

    return self;
}

- (void)dealloc {
    if (_userActivity) {
        [_userActivity invalidate];
    }
}

- (void)setItemFromArchive:(NSDictionary *)archive {
    self.tripQuery = [XMLTrips xml];
    UserParams *params = archive.userParams;

    self.tripQuery.userRequest =
        [TripUserRequest fromDictionary:params.immutableTrip];
    // trips.rawData     = trip[kUserFavesTripResults];

    [self.tripQuery addStopsFromUserFaves:_userState.faves];
    [self.tripQuery fetchItineraries:params.valTripResults];

    [self setupRows];
}

- (void)setItemFromHistory:(int)item {
    NSDictionary *trip = nil;

    @synchronized(_userState) {
        trip = _userState.recentTrips[item];

        _recentTripItem = item;

        [self setItemFromArchive:trip];
    }
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    // match each of the toolbar item's style match the selection in the
    // "UIBarButtonItemStyle" segmented control
    UIBarButtonItemStyle style = UIBarButtonItemStylePlain;

    // create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                             target:self
                             action:@selector(bookmarkButton:)];

    bookmark.style = style;

    // create the system-defined "OK or Done" button
    UIBarButtonItem *edit = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Redo", @"button text")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(showCopy:)];

    // create the system-defined "OK or Done" button
    [toolbarItems addObject:bookmark];
    [toolbarItems addObject:[UIToolbar flexSpace]];
    [toolbarItems addObject:edit];
    [toolbarItems addObject:[UIToolbar flexSpace]];

    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }

    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

- (void)appendXmlData:(NSMutableData *)buffer {
    [self.tripQuery appendQueryAndData:buffer];
}

#pragma mark View methods

- (void)enableArrows:(UISegmentedControl *)seg {
    [seg setEnabled:(_recentTripItem > 0) forSegmentAtIndex:0];

    [seg setEnabled:(_recentTripItem < (_userState.recentTrips.count - 1))
        forSegmentAtIndex:1];
}

- (void)upDown:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case 0: // UIPickerView
    {
        // Up
        if (_recentTripItem > 0) {
            [self setItemFromHistory:_recentTripItem - 1];
            [self reloadData];
        }

        break;
    }

    case 1: // UIPickerView
    {
        if (_recentTripItem < (_userState.recentTrips.count - 1)) {
            [self setItemFromHistory:_recentTripItem + 1];
            [self reloadData];
        }

        break;
    }
    }
    [self enableArrows:sender];
}

- (void)loadView {
    [super loadView];

    [self.tableView registerNib:[TripItemCell nib]
         forCellReuseIdentifier:kTripItemCellId];
}

- (void)setupRows {
    [self clearSectionMaps];

    if (self.tripQuery.resultFrom != nil && self.tripQuery.resultTo != nil) {
        [self addSectionType:kSectionTypeEndPoints];
        [self addRowType:kRowTypeFrom];
        [self addRowType:kRowTypeTo];
        [self addRowType:kRowTypeOptions];
        [self addRowType:kRowTypeDateAndTime];

        _itinerarySectionOffset = 1;
    } else {
        _itinerarySectionOffset = 0;
    }

    for (TripItinerary *it in self.tripQuery) {
        [self addSectionType:kSectionTypeOptions];

        NSInteger legs = [self legRows:it];

        if (legs == 0) {
            [self addRowType:kRowTypeError];
        } else {
            [self addRowType:kRowTypeLeg count:legs];
        }

        if (legs > 0) {
            [self addRowType:kRowTypeDuration];

            if (it.numberOfTransfers > 0) {
                [self addRowType:kRowTypeTransfers];
            }

            if (it.distanceMiles > 0) {
                [self addRowType:kRowTypeDistance];
            }

            if (it.hasFare) {
                [self addRowType:kRowTypeFare];
            }

            [self addRowType:kRowTypeMap];
            [self addRowType:kRowTypeEmail];
            [self addRowType:kRowTypeClipboard];

            if (_sms) {
                [self addRowType:kRowTypeSMS];
            }

            if (_cal) {
                [self addRowType:kRowTypeCal];
            }

            if (it.hasBlocks) {
                [self addRowType:kRowTypeTag];

                if ([AlarmTaskList proximitySupported]) {
                    [self addRowType:kRowTypeAlarms];
                }
                [self addRowType:kRowTypeArrivals];
                [self addRowType:kRowTypeDetours];
            }
        }
    }

    [self addSectionType:kSectionRowDisclaimerType];

    if (!self.tripQuery.reversed) {
        [self addRowType:kRowTypeReverse];
    }

    [self addRowType:kSectionRowDisclaimerType];
}

- (void)createUpDownSegUp:(UIImage *)up down:(UIImage *)down {
    if (up == nil || down == nil ||
        self.navigationItem.rightBarButtonItem != nil) {
        return;
    }

    self.navigationItem.rightBarButtonItem =
        [self segBarButtonWithItems:@[ up, down ]
                             action:@selector(upDown:)
                      selectedIndex:kSegNoSelectedIndex];

    UISegmentedControl *seg = self.navigationItem.rightBarButtonItem.customView;
    seg.frame = CGRectMake(0, 0, 60, 30.0);
    seg.momentary = YES;

    [self enableArrows:seg];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Trip", @"page title");

    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));

    if (messageClass != nil) {
        // Check whether the current device is configured for sending SMS
        // messages
        _sms = [messageClass canSendText];
    }

    Class eventClass = (NSClassFromString(@"EKEventEditViewController"));

    _cal = (eventClass != nil);

    [self setupRows];

    if (_recentTripItem >= 0) {
        [self createUpDownSegUp:[UIImage systemImageNamed:kSFIconChevronUp]
                           down:[UIImage systemImageNamed:kSFIconChevronDown]];
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark UI helpers

- (TripItinerary *)getSafeItinerary:(NSInteger)section {
    if ([self sectionType:section] == kSectionTypeOptions) {
        return self.tripQuery[section - _itinerarySectionOffset];
    }

    return nil;
}

- (NSInteger)legRows:(TripItinerary *)it {
    return it.displayEndPoints.count;
}

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath {
    TripItinerary *it = [self getSafeItinerary:indexPath.section];

    if (indexPath.row < [self legRows:it]) {
        return it.displayEndPoints[indexPath.row].displayText;
    }

    return nil;
}

- (void)showCopy:(id)sender {
    TripPlannerSummaryViewController *trip =
        [TripPlannerSummaryViewController viewController];

    trip.tripQuery = [self.tripQuery createAuto];
    [trip.tripQuery resetCurrentLocation];

    [trip makeSummaryRows];

    [self.navigationController pushViewController:trip animated:YES];
}

- (NSString *)fromText {
    //    if (self.tripQuery.fromPoint.useCurrentPosition)
    //    {
    //        return [NSString stringWithFormat:@"From: %@, %@",
    //        self.tripQuery.fromPoint.lat, self.tripQuery.fromPoint.lng];
    //    }
    return self.tripQuery.resultFrom.desc.safeEscapeForMarkUp;
}

- (NSString *)toText {
    //    if (self.tripQuery.toPoint.useCurrentPosition)
    //    {
    //        return [NSString stringWithFormat:@"To: %@, %@",
    //        self.tripQuery.toPoint.lat, self.tripQuery.toPoint.lng];
    //    }
    return self.tripQuery.resultTo.desc.safeEscapeForMarkUp;
}

- (void)selectLeg:(TripLegEndPoint *)leg {
    NSString *stopId = [leg stopId];

    if (stopId != nil) {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];

        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                     stopId:stopId];
    } else if (leg.loc != nil) {
        MapViewController *mapPage = [MapViewController viewController];
        SimpleAnnotation *pin = [SimpleAnnotation annotation];
        mapPage.stopIdStringCallback = self.stopIdStringCallback;
        pin.coordinate = leg.coordinate;
        pin.pinTitle = leg.desc;
        pin.pinColor = MAP_PIN_COLOR_PURPLE;

        [mapPage addPin:pin];
        mapPage.title = leg.desc;
        [self.navigationController pushViewController:mapPage animated:YES];
    }
}

#pragma mark UI Callback methods

- (void)bookmarkButton:(UIBarButtonItem *)sender {
    NSString *desc = nil;
    int bookmarkItem = kNoBookmark;

    @synchronized(_userState) {
        int i;

        TripUserRequest *req = [[TripUserRequest alloc] init];

        for (i = 0; _userState.faves != nil && i < _userState.faves.count;
             i++) {
            UserParams *bm = _userState.faves[i].userParams;
            NSDictionary *faveTrip = bm.valTrip;

            if (bm != nil && faveTrip != nil) {
                [req readDictionary:faveTrip];

                if ([req equalsTripUserRequest:self.tripQuery.userRequest]) {
                    bookmarkItem = i;
                    desc = bm.valChosenName;
                    break;
                }
            }
        }
    }

    if (bookmarkItem == kNoBookmark) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:NSLocalizedString(@"Bookmark Trip",
                                                       @"alert title")
                             message:nil
                      preferredStyle:UIAlertControllerStyleActionSheet];

        [alert
            addAction:
                [UIAlertAction
                    actionWithTitle:NSLocalizedString(@"Add new bookmark",
                                                      @"button text")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                              EditBookMarkViewController *edit =
                                  [EditBookMarkViewController viewController];
                              // [edit addBookMarkFromStop:self.bookmarkDesc
                              // location:self.bookmarkLoc];
                              [edit addBookMarkFromUserRequest:self.tripQuery];
                              // Push the detail view controller
                              [self.navigationController
                                  pushViewController:edit
                                            animated:YES];
                            }]];

#if !TARGET_OS_MACCATALYST
        [alert
            addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                               [self addBookmarkToSiri];
                                             }]];
#endif

        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",
                                                               @"button text")
                                       style:UIAlertActionStyleCancel
                                     handler:nil]];

        alert.popoverPresentationController.barButtonItem = sender;

        [self presentViewController:alert
                           animated:YES
                         completion:^{
                           [self clearSelection];
                         }];
    } else {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:desc
                             message:nil
                      preferredStyle:UIAlertControllerStyleActionSheet];

        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(
                                                 @"Delete this bookmark",
                                                 @"button text")
                                       style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction *action) {
                                       [self->_userState.faves
                                           removeObjectAtIndex:bookmarkItem];
                                       [self favesChanged];
                                       [self->_userState cacheState];
                                     }]];

#if !TARGET_OS_MACCATALYST
        [alert
            addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                               [self addBookmarkToSiri];
                                             }]];
#endif
        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(
                                                 @"Edit this bookmark",
                                                 @"button text")
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action) {
                                       EditBookMarkViewController *edit =
                                           [EditBookMarkViewController
                                               viewController];
                                       [edit
                                           editBookMark:self->_userState
                                                            .faves[bookmarkItem]
                                                   item:bookmarkItem];
                                       // Push the detail view controller
                                       [self.navigationController
                                           pushViewController:edit
                                                     animated:YES];
                                     }]];

        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",
                                                               @"button text")
                                       style:UIAlertActionStyleCancel
                                     handler:nil]];

        alert.popoverPresentationController.barButtonItem = sender;

        [self presentViewController:alert
                           animated:YES
                         completion:^{
                           [self clearSelection];
                         }];
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tripQuery.count + 1 + _itinerarySectionOffset;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionTypeEndPoints:
        return NSLocalizedString(
            @"The trip planner shows scheduled service only. Check below to "
            @"see how detours may affect your trip.\n\nYour trip:",
            @"section header");

        break;

    case kSectionTypeOptions: {
        TripItinerary *it = [self getSafeItinerary:section];

        NSInteger legs = [self legRows:it];

        if (legs > 0) {
            return [NSString
                stringWithFormat:NSLocalizedString(@"Option %ld - %@",
                                                   @"section header"),
                                 (long)(section + 1 - _itinerarySectionOffset),
                                 it.shortTravelTime];
        } else {
            return NSLocalizedString(@"No route was found:", @"section header");
        }
    }

    case kSectionRowDisclaimerType:
        // return @"Other options";
        break;
    }
    return nil;
}

- (void)populateTripCell:(TripItemCell *)cell
               itinerary:(TripItinerary *)it
                 rowType:(NSInteger)rowType
               indexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (rowType) {
    case kRowTypeError:
        [cell populateMarkedUpBody:it.message.safeEscapeForMarkUp
                              mode:@"No"
                              time:@"Route"
                         leftColor:nil
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (!self.tripQuery.gotData) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        // [cell populateBody:it.xmessage mode:nil time:nil];
        // cell.view.text = it.xmessage;
        break;

    case kRowTypeLeg: {
        TripLegEndPoint *ep = it.displayEndPoints[indexPath.row];
        [cell populateMarkedUpBody:ep.displayText
                              mode:ep.displayModeText
                              time:ep.displayTimeText
                         leftColor:ep.leftColor
                             route:ep.displayRouteNumber];

        //[cell populateBody:@"l l l l l l l l l l l l l l l l l l l l l l l l l
        // l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l
        // l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l
        // l l l l l l l l l l l l l l l l l l l l l"
        //                 mode:ep.displayModeText time:ep.displayTimeText
        //                 leftColor:ep.leftColor
        //                route:ep.xnumber];

        if (ep.strStopId != nil || ep.loc != nil) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = kDisclosure;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    // cell.view.text = [self getTextForLeg:indexPath];

    // printf("width: %f\n", cell.view.frame.size.width);
    break;

    case kRowTypeDuration:
        [cell populateMarkedUpBody:it.travelTime
                              mode:@"Travel"
                              time:@"time"
                         leftColor:nil
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        // justText = [it getTravelTime];
        break;

    case kRowTypeTransfers:
        [cell populateMarkedUpBody:it.strNumberOfTransfers.safeEscapeForMarkUp
                              mode:@"Transfers"
                              time:nil
                         leftColor:nil
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        // justText = [it getTravelTime];
        break;

    case kRowTypeDistance:
        [cell populateMarkedUpBody:it.formattedDistance
                              mode:@"Distance"
                              time:nil
                         leftColor:nil
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        // justText = [it getTravelTime];
        break;

    case kRowTypeFare:
        [cell populateMarkedUpBody:it.fare.stringByTrimmingWhitespace
                              mode:@"Fare"
                              time:nil
                         leftColor:nil
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        // justText = it.fare;
        break;

    case kRowTypeFrom:
        [cell populateMarkedUpBody:self.fromText
                              mode:@"From"
                              time:nil
                         leftColor:[UIColor modeAwareBlue]
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;

    case kRowTypeOptions:
        [cell
            populateMarkedUpBody:[self.tripQuery.userRequest optionsDisplayText]
                            mode:@"Options"
                            time:nil
                       leftColor:[UIColor modeAwareBlue]
                           route:nil];

        cell.accessibilityLabel =
            [self.tripQuery.userRequest optionsAccessability];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        break;

    case kRowTypeTo:
        [cell populateMarkedUpBody:self.toText
                              mode:@"To"
                              time:nil
                         leftColor:[UIColor modeAwareBlue]
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;

    case kRowTypeDateAndTime:
        [cell populateMarkedUpBody:[self.tripQuery.userRequest getDateAndTime]
                              mode:[self.tripQuery.userRequest timeType]
                              time:nil
                         leftColor:[UIColor modeAwareBlue]
                             route:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
                    actionCell:(NSIndexPath *)indexPath
                          text:(NSString *)text
                    imageNamed:(NSString *)image
                          type:(UITableViewCellAccessoryType)type {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"TripAction"];

    cell.textLabel.text = text;
    cell.namedIcon = image;
    cell.accessoryType = type;

    cell.textLabel.textColor = [UIColor modeAwareGrayText];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = self.basicFont;
    [self updateAccessibility:cell];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
                    actionCell:(NSIndexPath *)indexPath
                          text:(NSString *)text
                   systemImage:(NSString *)image
                          type:(UITableViewCellAccessoryType)type {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"TripAction"];

    cell.textLabel.text = text;
    cell.imageView.image = [UIImage systemImageNamed:image];
    cell.accessoryType = type;

    cell.textLabel.textColor = [UIColor modeAwareGrayText];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = self.basicFont;
    [self updateAccessibility:cell];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
                    actionCell:(NSIndexPath *)indexPath
                          text:(NSString *)text
                         image:(UIImage *)image
                          type:(UITableViewCellAccessoryType)type {
    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:@"TripAction"];

    cell.textLabel.text = text;
    cell.imageView.image = image;
    cell.accessoryType = type;

    cell.textLabel.textColor = [UIColor modeAwareGrayText];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = self.basicFont;
    [self updateAccessibility:cell];

    return cell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];

    switch (rowType) {
    case kRowTypeError:
    case kRowTypeLeg:
    case kRowTypeDuration:
    case kRowTypeTransfers:
    case kRowTypeDistance:
    case kRowTypeFare:
    case kRowTypeFrom:
    case kRowTypeTo:
    case kRowTypeDateAndTime:
    case kRowTypeOptions: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];
        TripItemCell *cell =
            [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
        [self populateTripCell:cell
                     itinerary:it
                       rowType:rowType
                     indexPath:indexPath];
        return cell;
    }

    case kSectionRowDisclaimerType: {
        UITableViewCell *cell = [self disclaimerCell:tableView];

        if (self.tripQuery.queryDateFormatted != nil &&
            self.tripQuery.queryTimeFormatted != nil) {
            [self
                addTextToDisclaimerCell:cell
                                   text:[NSString stringWithFormat:
                                                      @"Updated %@ %@",
                                                      self.tripQuery
                                                          .queryDateFormatted,
                                                      self.tripQuery
                                                          .queryTimeFormatted]];
        }

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self updateDisclaimerAccessibility:cell];
        return cell;
    }

    case kRowTypeDetours:
        return [self
              tableView:tableView
             actionCell:indexPath
                   text:NSLocalizedString(@"Check detours", @"main menu item")
            systemImage:kSFIconDetour
                   type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeMap:
        return
            [self tableView:tableView
                 actionCell:indexPath
                       text:NSLocalizedString(@"Show on map", @"main menu item")
                systemImage:kSFIconMap
                       type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeEmail:
        return [self
              tableView:tableView
             actionCell:indexPath
                   text:NSLocalizedString(@"Send by email", @"main menu item")
            systemImage:kSFIconEmail
                   type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeSMS:
        return [self tableView:tableView
                    actionCell:indexPath
                          text:NSLocalizedString(@"Send by text message",
                                                 @"main menu item")
                   systemImage:kSFIconSMS
                          type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeCal:
        return [self
              tableView:tableView
             actionCell:indexPath
                   text:NSLocalizedString(@"Add to calendar", @"main menu item")
            systemImage:kSFIconCal
                   type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeTag: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        UIColor *color = nil;
        UIColor *newColor = nil;

        for (TripLeg *leg in it.legs) {
            if (leg.block) {

                newColor =
                    [[BlockColorDb sharedInstance] colorForBlock:leg.block];

                DEBUG_LOG_description(newColor);

                if (newColor == nil) {
                    newColor = [UIColor grayColor];
                }

                if (color == nil) {
                    color = newColor;
                } else {
                    if (![color isEqual:newColor]) {
                        color = [UIColor grayColor];
                    }
                }
            }
        }

        if (color == nil) {
            color = [UIColor grayColor];
        }

        return [self tableView:tableView
                    actionCell:indexPath
                          text:NSLocalizedString(@"Tag all " kBlockNames
                                                  " with a color",
                                                 @"main menu item")
                         image:[BlockColorDb imageWithColor:color]
                          type:UITableViewCellAccessoryDetailDisclosureButton];
    }

    case kRowTypeClipboard:
        return [self tableView:tableView
                    actionCell:indexPath
                          text:NSLocalizedString(@"Copy to clipboard",
                                                 @"main menu item")
                   systemImage:kSFIconCopy
                          type:UITableViewCellAccessoryNone];

    case kRowTypeReverse:
        return [self
              tableView:tableView
             actionCell:indexPath
                   text:NSLocalizedString(@"Reverse trip", @"main menu item")
            systemImage:kSFIconReverse
                   type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeArrivals:
        return [self tableView:tableView
                    actionCell:indexPath
                          text:NSLocalizedString(@"Departures for all stops",
                                                 @"main menu item")
                   systemImage:kSFIconArrivals
                          type:UITableViewCellAccessoryDisclosureIndicator];

    case kRowTypeAlarms:
        return [self tableView:tableView
                    actionCell:indexPath
                          text:NSLocalizedString(@"Set deboard alarms",
                                                 @"main menu item")
                   systemImage:kSFIconAlarm
                          type:UITableViewCellAccessoryDisclosureIndicator];
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kRowTypeTag) {
        _reloadOnAppear = YES;
        [self.navigationController
            pushViewController:[BlockColorViewController viewController]
                      animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];

    switch (rowType) {
    case kRowTypeError:
    case kRowTypeLeg:
    case kRowTypeDuration:
    case kRowTypeTransfers:
    case kRowTypeDistance:
    case kRowTypeFare:
    case kRowTypeFrom:
    case kRowTypeTo:
    case kRowTypeDateAndTime:
    case kRowTypeOptions:
        return UITableViewAutomaticDimension;

    case kRowTypeEmail:
    case kRowTypeClipboard:
    case kRowTypeAlarms:
    case kRowTypeMap:
    case kRowTypeReverse:
    case kRowTypeArrivals:
    case kRowTypeSMS:
    case kRowTypeCal:
    case kRowTypeDetours:
        return [self basicRowHeight];
    }
    return kDisclaimerCellHeight;
}

- (NSString *)plainText:(TripItinerary *)it {
    NSMutableString *trip = [NSMutableString string];

    //    TripItinerary *it = [self getSafeItinerary:indexPath.section];

    if (self.tripQuery.resultFrom != nil) {
        [trip appendFormat:@"From: %@\n", self.tripQuery.resultFrom.desc];
    }

    if (self.tripQuery.resultTo != nil) {
        [trip appendFormat:@"To: %@\n", self.tripQuery.resultTo.desc];
    }

    [trip appendFormat:@"%@: %@\n\n", [self.tripQuery.userRequest timeType],
                       [self.tripQuery.userRequest getDateAndTime]];

    NSString *htmlText = [it startPointText:TripTextTypeClip];

    [trip appendString:htmlText];

    int i;

    for (i = 0; i < [it legCount]; i++) {
        TripLeg *leg = [it getLeg:i];
        htmlText = [leg createFromText:(i == 0) textType:TripTextTypeClip];
        [trip appendString:htmlText];
        htmlText = [leg createToText:(i == [it legCount] - 1)
                            textType:TripTextTypeClip];
        [trip appendString:htmlText];
    }

    [trip appendFormat:@"Scheduled travel time: %@\n\n", it.travelTime];

    if (it.numberOfTransfers > 0) {
        [trip appendFormat:@"Transfers: %@\n\n", it.strNumberOfTransfers];
    }

    if (it.distanceMiles > 0) {
        [trip appendFormat:@"Distance: %@\n\n", it.formattedDistance];
    }

    if (it.fare != nil) {
        [trip appendFormat:@"Fare: %@", it.fare];
    }

    return trip;
}

- (void)addCalendarItem:(TripItinerary *)it {
    self.event = [EKEvent eventWithEventStore:self.eventStore];
    self.event.title = [NSString
        stringWithFormat:@"TriMet Trip\n%@", [self.tripQuery mediumName]];
    self.event.notes = [NSString
        stringWithFormat:
            @"Note: ensure you leave early enough to arrive in time for the "
            @"first connection.\n\n%@"
             "\nRoute and departure data provided by permission of TriMet.",
            [self plainText:it]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];

    dateFormatter.locale = enUS;

    // Yikes - may have AM or PM or be 12 hour. :-(
    NSString *formatted = it.startTimeFormatted;
    unichar last = 0;

    // Sometimes it crashes here - so let;s not assume the formatted date exists

    if (formatted && formatted.length > 0) {
        last = [it.startTimeFormatted
            characterAtIndex:(it.startTimeFormatted.length - 1)];
    }

    if (last == 'M' || last == 'm') {
        dateFormatter.dateFormat = @"M/d/yy hh:mm a";
    } else {
        dateFormatter.dateFormat = @"M/d/yy HH:mm:ss";
    }

    dateFormatter.timeZone = [NSTimeZone localTimeZone];

    NSString *fullDateStr =
        [NSString stringWithFormat:@"%@ %@", it.startDateFormatted,
                                   it.startTimeFormatted];
    NSDate *start = [dateFormatter dateFromString:fullDateStr];

    // The start time does not include the inital walk so take it off...
    for (int i = 0; i < [it legCount]; i++) {
        TripLeg *leg = [it getLeg:i];

        if (leg.mode == nil) {
            continue;
        }

        if ([leg.mode isEqualToString:kModeWalk]) {
            start = [start dateByAddingTimeInterval:-(leg.durationMins * 60)];
            ;
        } else {
            break;
        }
    }

    NSDate *end = [start dateByAddingTimeInterval:it.durationMins * 60];

    self.event.startDate = start;
    self.event.endDate = end;

    EKCalendar *cal = self.eventStore.defaultCalendarForNewEvents;

    self.event.calendar = cal;
    NSError *err;

    if (cal != nil && [self.eventStore saveEvent:self.event
                                            span:EKSpanThisEvent
                                           error:&err]) {
        // Upon selecting an event, create an EKEventViewController to display
        // the event.
        EKEventViewController *eventController =
            [[EKEventViewController alloc] init];
        eventController.event = self.event;
        eventController.title =
            NSLocalizedString(@"Calendar Event", @"page title");
        eventController.delegate = self;
        eventController.allowsCalendarPreview = YES;
        eventController.allowsEditing = YES;

        [self.navigationController pushViewController:eventController
                                             animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController
    // alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    switch ([self rowType:indexPath]) {
    case kRowTypeError:

        if (!self.tripQuery.gotData) {
            [self networkTips:self.tripQuery.htmlError
                 networkError:self.tripQuery.networkErrorMsg];
            [self clearSelection];
        }

        break;

    case kRowTypeTo:
    case kRowTypeFrom: {
        TripLegEndPoint *ep = nil;

        if ([self rowType:indexPath] == kRowTypeTo) {
            ep = self.tripQuery.resultTo;
        } else {
            ep = self.tripQuery.resultFrom;
        }

        [self selectLeg:ep];
        break;
    }

    case kRowTypeLeg: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];
        TripLegEndPoint *leg = it.displayEndPoints[indexPath.row];
        [self selectLeg:leg];
    }

    break;

    case kRowTypeDuration:
    case kRowTypeTransfers:
    case kRowTypeDistance:
    case kSectionRowDisclaimerType:
    case kRowTypeFare:
        break;

    case kRowTypeClipboard: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [self plainText:it];
        break;
    }

    case kRowTypeAlarms: {
        AlarmTaskList *taskList = [AlarmTaskList sharedInstance];

        if ([UIViewController
                locationAuthorizedOrNotDeterminedWithBackground:YES]) {
            [taskList
                userAlertForProximity:self
                               source:[tableView
                                          cellForRowAtIndexPath:indexPath]
                           completion:^(bool cancelled, bool accurate) {
                             if (!cancelled) {
                                 TripItinerary *it =
                                     [self getSafeItinerary:indexPath.section];

                                 for (TripLegEndPoint *leg in it
                                          .displayEndPoints) {
                                     if (leg.deboard) {
                                         if (![taskList
                                                 hasTaskForStopIdProximity:
                                                     leg.stopId]) {
                                             [taskList
                                                 addTaskForStopIdProximity:
                                                     leg.stopId
                                                                       loc:leg.loc
                                                                      desc:
                                                                          leg.desc
                                                                  accurate:
                                                                      accurate];
                                         }
                                     }
                                 }
                             }

                             [self.tableView deselectRowAtIndexPath:indexPath
                                                           animated:YES];
                           }];
        } else {
            [self locationAuthorizedOrNotDeterminedAlertWithBackground:YES];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }

        break;
    }

    case kRowTypeSMS: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];
        MFMessageComposeViewController *picker =
            [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;

        picker.body = [self plainText:it];

        [self presentViewController:picker
                           animated:YES
                         completion:^{
                           [self clearSelection];
                         }];
        break;
    }

    case kRowTypeCal: {
        if (self.eventStore == nil) {
            self.eventStore = [[EKEventStore alloc] init];
        }

        // maybe check for access
        [self
                .eventStore requestAccessToEntityType:EKEntityTypeEvent
                                           completion:
                                               ^(BOOL granted, NSError *error) {
                                                 [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:
                                                                    ^{
                                                                      if (granted) {
                                                                          UIAlertController *alert = [UIAlertController
                                                                              alertControllerWithTitle:
                                                                                  NSLocalizedString(
                                                                                      @"Calendar",
                                                                                      @"alert title")
                                                                                               message:
                                                                                                   NSLocalizedString(
                                                                                                       @"Are you sure "
                                                                                                       @"you want to "
                                                                                                       @"add this to "
                                                                                                       @"your default "
                                                                                                       @"calendar?",
                                                                                                       @"alert "
                                                                                                       @"message")
                                                                                        preferredStyle:
                                                                                            UIAlertControllerStyleActionSheet];

                                                                          [alert
                                                                              addAction:
                                                                                  [UIAlertAction
                                                                                      actionWithTitle:
                                                                                          NSLocalizedString(
                                                                                              @"Yes",
                                                                                              @"button text")
                                                                                                style:
                                                                                                    UIAlertActionStyleDefault
                                                                                              handler:^(
                                                                                                  UIAlertAction
                                                                                                      *action) {
                                                                                                [self
                                                                                                    addCalendarItem:
                                                                                                        [self
                                                                                                            getSafeItinerary:
                                                                                                                indexPath
                                                                                                                    .section]];
                                                                                              }]];

                                                                          [alert
                                                                              addAction:
                                                                                  [UIAlertAction
                                                                                      actionWithTitle:
                                                                                          NSLocalizedString(
                                                                                              @"Cancel",
                                                                                              @"button text")
                                                                                                style:
                                                                                                    UIAlertActionStyleCancel
                                                                                              handler:
                                                                                                  nil]];

                                                                          alert
                                                                              .popoverPresentationController
                                                                              .sourceView =
                                                                              [tableView
                                                                                  cellForRowAtIndexPath:
                                                                                      indexPath];

                                                                          // Make
                                                                          // a
                                                                          // small
                                                                          // rect
                                                                          // in
                                                                          // the
                                                                          // center,
                                                                          // just
                                                                          // 10,10
                                                                          const CGFloat
                                                                              side =
                                                                                  10;
                                                                          CGRect frame =
                                                                              alert
                                                                                  .popoverPresentationController
                                                                                  .sourceView
                                                                                  .frame;
                                                                          CGRect sourceRect = CGRectMake(
                                                                              (frame
                                                                                   .size
                                                                                   .width -
                                                                               side) /
                                                                                  2.0,
                                                                              (frame
                                                                                   .size
                                                                                   .height -
                                                                               side) /
                                                                                  2.0,
                                                                              side,
                                                                              side);

                                                                          alert
                                                                              .popoverPresentationController
                                                                              .sourceRect =
                                                                              sourceRect;

                                                                          [self
                                                                              presentViewController:
                                                                                  alert
                                                                                           animated:
                                                                                               YES
                                                                                         completion:^{
                                                                                           [self
                                                                                               clearSelection];
                                                                                         }];
                                                                      } else {
                                                                          UIAlertController *alert = [UIAlertController
                                                                              simpleOkWithTitle:
                                                                                  NSLocalizedString(
                                                                                      @"Calendar",
                                                                                      @"alert title")
                                                                                        message:
                                                                                            NSLocalizedString(
                                                                                                @"Calendar access has "
                                                                                                @"been denied. Please "
                                                                                                @"check the app "
                                                                                                @"settings to allow "
                                                                                                @"access to the "
                                                                                                @"calendar.",
                                                                                                @"alert message")];
                                                                          [self
                                                                              presentViewController:
                                                                                  alert
                                                                                           animated:
                                                                                               YES
                                                                                         completion:
                                                                                             nil];
                                                                      }
                                                                    }];
                                               }];

        break;
    }

    case kRowTypeTag: {
        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        __weak __typeof(self) weakSelf = self;

        UIViewController *picker = [SimpleColorPickerCoordinator
            createWithInitialColor:UIColor.randomColor
                             title:NSLocalizedString(@"Pick tag color",
                                                     @"window title")
                          onPicked:^(UIColor *selectedColor) {
                            __strong __typeof(self) strongSelf = weakSelf;

                            if (!strongSelf)
                                return;
                            if (selectedColor) {
                                for (TripLeg *leg in it.legs) {
                                    if (leg.block) {
                                        [[BlockColorDb sharedInstance]
                                               addColor:selectedColor
                                               forBlock:leg.block
                                            description:leg.routeName];
                                    }
                                }

                                [strongSelf favesChanged];
                            }
                            [strongSelf reloadData];
                          }];

        [self presentViewController:picker
                           animated:YES
                         completion:^{
                         }];

    } break;

    case kRowTypeEmail: {
        NSMutableString *trip = [[NSMutableString alloc] init];

        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        if (self.tripQuery.resultFrom != nil) {
            if (self.tripQuery.resultFrom.loc != nil) {
                [trip appendFormat:@"From: <a "
                                   @"href=\"http://map.google.com/"
                                   @"?q=location@%@\">%@<br></a>",
                                   COORD_TO_LAT_LNG_STR(
                                       self.tripQuery.resultFrom.coordinate),
                                   self.tripQuery.resultFrom.desc];
            } else {
                [trip appendFormat:@"%@<br>", self.fromText];
            }
        }

        if (self.tripQuery.resultTo != nil) {
            if (self.tripQuery.resultTo.loc) {
                [trip appendFormat:@"To: <a "
                                   @"href=\"http://map.google.com/"
                                   @"?q=location@%@\">%@<br></a>",
                                   COORD_TO_LAT_LNG_STR(
                                       self.tripQuery.resultTo.coordinate),
                                   self.tripQuery.resultTo.desc];
            } else {
                [trip appendFormat:@"%@<br>", self.toText];
            }
        }

        [trip appendFormat:@"%@:%@<br><br>",
                           [self.tripQuery.userRequest timeType],
                           [self.tripQuery.userRequest getDateAndTime]];

        NSString *htmlText = [it startPointText:TripTextTypeHTML];
        [trip appendString:htmlText];

        int i;

        for (i = 0; i < [it legCount]; i++) {
            TripLeg *leg = [it getLeg:i];
            htmlText = [leg createFromText:(i == 0) textType:TripTextTypeHTML];
            [trip appendString:htmlText];
            htmlText = [leg createToText:(i == [it legCount] - 1)
                                textType:TripTextTypeHTML];
            [trip appendString:htmlText];
        }

        [trip appendFormat:@"Travel time: %@<br><br>", it.travelTime];

        if (it.numberOfTransfers > 0) {
            [trip
                appendFormat:@"Transfers: %@<br><br>", it.strNumberOfTransfers];
        }

        if (it.distanceMiles > 0) {
            [trip appendFormat:@"Distance: %@<br><br>", it.formattedDistance];
        }

        if (it.fare != nil) {
            [trip appendFormat:@"Fare: %@<br><br>", it.fare];
        }

        MFMailComposeViewController *email =
            [[MFMailComposeViewController alloc] init];

        email.mailComposeDelegate = self;

        if (![MFMailComposeViewController canSendMail]) {
            UIAlertController *alert = [UIAlertController
                simpleOkWithTitle:NSLocalizedString(@"email", @"alert title")
                          message:NSLocalizedString(
                                      @"Cannot send email on this device",
                                      @"alert message")];
            [self presentViewController:alert animated:YES completion:nil];

            break;
        }

        [email setSubject:@"TriMet Trip"];

        [email setMessageBody:trip isHTML:YES];

        [self presentViewController:email
                           animated:YES
                         completion:^{
                           [self clearSelection];
                         }];

        break;
    }

    case kRowTypeMap: {
        TripPlannerMapController *mapPage =
            [TripPlannerMapController viewController];
        mapPage.stopIdStringCallback = self.stopIdStringCallback;
        mapPage.lineOptions = MapViewFitLines;
        mapPage.nextPrevButtons = YES;
        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        int i, j = 0;

        for (i = 0; i < [it legCount]; i++) {
            TripLeg *leg = [it getLeg:i];
            [leg createFromText:(i == 0) textType:TripTextTypeMap];

            if (leg.from.mapText != nil) {
                j++;
                leg.from.index = j;

                [mapPage addPin:leg.from];
            }

            [leg createToText:(i == ([it legCount] - 1))
                     textType:TripTextTypeMap];

            if (leg.to.mapText != nil) {
                j++;
                leg.to.index = j;

                [mapPage addPin:leg.to];
            }
        }

        mapPage.it = it;

        [mapPage fetchShapesAsync:self.backgroundTask];
    } break;

    case kRowTypeReverse: {
        XMLTrips *reverse = [self.tripQuery createReverse];

        TripPlannerDateViewController *tripDate =
            [TripPlannerDateViewController viewController];

        tripDate.userFaves = reverse.userFaves;
        tripDate.tripQuery = reverse;

        // Push the detail view controller
        [tripDate nextScreen:self.navigationController
               taskContainer:self.backgroundTask];
        /*
         TripPlannerEndPointView *tripStart = [[TripPlannerEndPointView alloc]
         init];

         // Push the detail view controller
         [self.navigationController pushViewController:tripStart animated:YES];
         [tripStart release];
         */
        break;
    }

    case kRowTypeDetours: {
        NSMutableArray *allRoutes = [NSMutableArray array];
        NSString *route = nil;
        NSMutableSet *allRoutesSet = [NSMutableSet set];

        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        int i = 0;

        for (i = 0; i < [it legCount]; i++) {
            TripLeg *leg = [it getLeg:i];

            route = leg.internalRouteNumber;

            if (route && ![allRoutesSet containsObject:route]) {
                [allRoutesSet addObject:route];

                [allRoutes addObject:route];
            }
        }

        if (allRoutes.count > 0) {
            [[DetoursViewController viewController]
                fetchDetoursAsync:self.backgroundTask
                           routes:allRoutes
                backgroundRefresh:NO];
        }

        break;
    }

    case kRowTypeArrivals: {
        NSMutableString *allstops = [NSMutableString string];
        NSString *lastStop = nil;
        NSString *nextStop = nil;

        TripItinerary *it = [self getSafeItinerary:indexPath.section];

        int i = 0;
        int j = 0;

        for (i = 0; i < [it legCount]; i++) {
            TripLeg *leg = [it getLeg:i];

            nextStop = [leg.from stopId];

            for (j = 0; j < 2; j++) {
                if (nextStop != nil &&
                    (lastStop == nil || ![nextStop isEqualToString:lastStop])) {
                    if (allstops.length > 0) {
                        [allstops appendFormat:@","];
                    }

                    [allstops appendFormat:@"%@", nextStop];
                    lastStop = nextStop;
                }

                nextStop = [leg.to stopId];
            }
        }

        if (allstops.length > 0) {
            [[DepartureTimesViewController viewController]
                fetchTimesForLocationAsync:self.backgroundTask
                                    stopId:allstops];
        }

        break;
    }
    }
}

#pragma mark Mail composer delegate

// Dismisses the email composition interface when users tap Cancel or Send.
// Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SMS composer delegate

- (void)messageComposeViewController:
            (MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to
// user actions.

- (void)eventViewController:(EKEventViewController *)controller
      didCompleteWithAction:(EKEventViewAction)action {
    DEBUG_LOG_long(action);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.userActivity != nil) {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }

    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    Class userActivityClass = (NSClassFromString(@"NSUserActivity"));

    if (userActivityClass != nil) {
        if (self.userActivity != nil) {
            [self.userActivity invalidate];
            self.userActivity = nil;
        }

        self.userActivity = [self.tripQuery.userRequest
            userActivityWithTitle:self.tripQuery.shortName];

        [self.userActivity becomeCurrent];
    }
}

- (void)addBookmarkToSiri {
    INShortcut *shortCut =
        [[INShortcut alloc] initWithUserActivity:self.userActivity];

    INUIAddVoiceShortcutViewController *viewController =
        [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;

    [self presentViewController:viewController animated:YES completion:nil];
}

@end

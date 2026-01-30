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
    kRowTypeDateAndTime,
    kSectionRowDisclaimerType
};

enum { kSectionTypeEndPoints = 0, kSectionTypeOptions, kRowsInDisclaimerSection };

#define kDisclosure UITableViewCellAccessoryDisclosureIndicator
#define kScheduledText                                                                             \
    @"The trip planner shows scheduled service only. Check below to see how "                      \
    @"detours may affect your trip."

@interface TripPlannerResultsViewController () {
    int _itinerarySectionOffset;
    bool _sms;
    bool _cal;
    int _recentTripItem;
}

@property (nonatomic, strong) TripItemCell *prototypeTripCell;
@property (nonatomic, strong) EKEvent *event;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, readonly, copy) NSString *fromText;
@property (nonatomic, readonly, copy) NSString *toText;

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath;
- (NSInteger)legRows:(TripItinerary *)it;
- (TripItinerary *)getSafeItinerary:(NSInteger)section;
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error;
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
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

    self.tripQuery.userRequest = [TripUserRequest fromDictionary:params.immutableTrip];
    self.tripQuery.userFaves = _userState.stopsFromFaves;
    [self.tripQuery fetchItineraries:params.valTripResults];

    [self setupRows];
}

- (void)setItemFromHistory:(int)item {
    __block NSDictionary *trip = nil;

    [_userState accessArray:_userState.recentTrips
                      block:^(NSMutableArray *safeArray) {
                        trip = safeArray[item];
                        self->_recentTripItem = item;
                      }];
    [self setItemFromArchive:trip];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    // match each of the toolbar item's style match the selection in the
    // "UIBarButtonItemStyle" segmented control
    UIBarButtonItemStyle style = UIBarButtonItemStylePlain;

    // create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                      target:self
                                                      action:@selector(bookmarkButton:)];

    bookmark.style = style;

    // create the system-defined "OK or Done" button
    UIBarButtonItem *edit = [UIBarButtonItem textButton:NSLocalizedString(@"Redo", @"button text")
                                                 target:self
                                                 action:@selector(showCopy:)];

    // create the system-defined "OK or Done" button
    [toolbarItems addObject:bookmark];
    [toolbarItems addObject:[UIBarButtonItem flexSpace]];
    [toolbarItems addObject:edit];
    [toolbarItems addObject:[UIBarButtonItem flexSpace]];

    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
        [toolbarItems addObject:[UIBarButtonItem flexSpace]];
    }

    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

- (void)appendDebugXmlData:(NSMutableData *)buffer {
    [self.tripQuery appendQueryAndData:buffer];
}

#pragma mark View methods

- (void)enableArrows:(UISegmentedControl *)seg {
    [seg setEnabled:(_recentTripItem > 0) forSegmentAtIndex:0];

    [seg setEnabled:(_recentTripItem < (_userState.recentTrips.count - 1)) forSegmentAtIndex:1];
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

    [self.tableView registerNib:[TripItemCell nib] forCellReuseIdentifier:kTripItemCellId];
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
    if (up == nil || down == nil || self.navigationItem.rightBarButtonItem != nil) {
        return;
    }

    self.navigationItem.rightBarButtonItem = [self segBarButtonWithItems:@[ up, down ]
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
        [self createUpDownSegUp:kIconChevronUp.image down:kIconChevronDown.image];
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
    TripPlannerSummaryViewController *trip = [TripPlannerSummaryViewController viewController];

    trip.tripQuery = [self.tripQuery createAuto];
    [trip.tripQuery resetCurrentLocation];

    [trip makeSummaryRows];

    [self.navigationController pushViewController:trip animated:YES];
}

- (NSString *)fromText {
    return self.tripQuery.resultFrom.desc.safeEscapeForMarkUp;
}

- (NSString *)toText {
    return self.tripQuery.resultTo.desc.safeEscapeForMarkUp;
}

- (void)selectLeg:(TripLegEndPoint *)leg {
    NSString *stopId = [leg stopId];

    if (stopId != nil) {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];

        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask stopId:stopId];
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
    __block NSString *desc = nil;
    __block int bookmarkItem = kNoBookmark;

    [_userState accessArray:_userState.faves
                      block:^(NSMutableArray<NSMutableDictionary *> *safeArray) {
                        TripUserRequest *req = [[TripUserRequest alloc] init];

                        for (int i = 0; safeArray != nil && i < safeArray.count; i++) {
                            UserParams *bm = safeArray[i].userParams;
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
                      }];

    if (bookmarkItem == kNoBookmark) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:NSLocalizedString(@"Bookmark Trip", @"alert title")
                             message:nil
                      preferredStyle:UIAlertControllerStyleActionSheet];

        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Add new bookmark", @"button text")
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action) {
                                       EditBookMarkViewController *edit =
                                           [EditBookMarkViewController viewController];
                                       // [edit addBookMarkFromStop:self.bookmarkDesc
                                       // location:self.bookmarkLoc];
                                       [edit addBookMarkFromUserRequest:self.tripQuery];
                                       // Push the detail view controller
                                       [self.navigationController pushViewController:edit
                                                                            animated:YES];
                                     }]];

#if !TARGET_OS_MACCATALYST
        [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                  [self addBookmarkToSiri];
                                                }]];
#endif // !TARGET_OS_MACCATALYST

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];

        [self displayPopover:alert
            fromBarButtonItem:sender
                   completion:^{
                     [self clearSelection];
                   }];
    } else {
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:desc
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];

        [alert
            addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Delete this bookmark", @"button text")
                                    style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction *action) {
                                    [self->_userState.faves removeObjectAtIndex:bookmarkItem];
                                    [self userStateChanged];
                                    [self->_userState cacheState];
                                  }]];

#if !TARGET_OS_MACCATALYST
        [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                  [self addBookmarkToSiri];
                                                }]];
#endif // !TARGET_OS_MACCATALYST
        [alert
            addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Edit this bookmark", @"button text")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                    EditBookMarkViewController *edit =
                                        [EditBookMarkViewController viewController];
                                    [edit editBookMark:self->_userState.faves[bookmarkItem]
                                                  item:bookmarkItem];
                                    // Push the detail view controller
                                    [self.navigationController pushViewController:edit
                                                                         animated:YES];
                                  }]];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];

        [self displayPopover:alert
                  completion:^{
                    [self clearSelection];
                  }];
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tripQuery.count + 1 + _itinerarySectionOffset;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionTypeEndPoints:
        return NSLocalizedString(@"The trip planner shows scheduled service only. Check below to "
                                 @"see how detours may affect your trip.\n\nYour trip:",
                                 @"section header");

        break;

    case kSectionTypeOptions: {
        TripItinerary *it = [self getSafeItinerary:section];

        NSInteger legs = [self legRows:it];

        if (legs > 0) {
            return
                [NSString stringWithFormat:NSLocalizedString(@"Option %ld - %@", @"section header"),
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

- (NSString *)plainText:(TripItinerary *)it {
    NSMutableString *trip = [NSMutableString string];
    if (self.tripQuery.resultFrom != nil) {
        [trip appendFormat:@"From: %@\n", self.tripQuery.resultFrom.desc];
    }

    if (self.tripQuery.resultTo != nil) {
        [trip appendFormat:@"To: %@\n", self.tripQuery.resultTo.desc];
    }

    [trip appendFormat:@"%@: %@\n\n",
                       [self.tripQuery.userRequest timeType],
                       [self.tripQuery.userRequest getDateAndTime]];

    NSString *htmlText = [it startPointText:TripTextTypeClip];

    [trip appendString:htmlText];

    int i;

    for (i = 0; i < [it legCount]; i++) {
        TripLeg *leg = [it getLeg:i];
        htmlText = [leg createFromText:(i == 0) textType:TripTextTypeClip];
        [trip appendString:htmlText];
        htmlText = [leg createToText:(i == [it legCount] - 1) textType:TripTextTypeClip];
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
    self.event.title = [NSString stringWithFormat:@"TriMet Trip\n%@", [self.tripQuery mediumName]];
    self.event.notes =
        [NSString stringWithFormat:@"Note: ensure you leave early enough to arrive in time for the "
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
        last = [it.startTimeFormatted characterAtIndex:(it.startTimeFormatted.length - 1)];
    }

    if (last == 'M' || last == 'm') {
        dateFormatter.dateFormat = @"M/d/yy hh:mm a";
    } else {
        dateFormatter.dateFormat = @"M/d/yy HH:mm:ss";
    }

    dateFormatter.timeZone = [NSTimeZone localTimeZone];

    NSString *fullDateStr =
        [NSString stringWithFormat:@"%@ %@", it.startDateFormatted, it.startTimeFormatted];
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

    if (cal != nil && [self.eventStore saveEvent:self.event span:EKSpanThisEvent error:&err]) {
        // Upon selecting an event, create an EKEventViewController to display
        // the event.
        EKEventViewController *eventController = [[EKEventViewController alloc] init];
        eventController.event = self.event;
        eventController.title = NSLocalizedString(@"Calendar Event", @"page title");
        eventController.delegate = self;
        eventController.allowsCalendarPreview = YES;
        eventController.allowsEditing = YES;

        [self.navigationController pushViewController:eventController animated:YES];
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

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
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

        self.userActivity =
            [self.tripQuery.userRequest userActivityWithTitle:self.tripQuery.shortName];

        [self.userActivity becomeCurrent];
    }
}

- (void)addBookmarkToSiri {
    INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:self.userActivity];

    INUIAddVoiceShortcutViewController *viewController =
        [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;

    [self presentViewController:viewController animated:YES completion:nil];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS TripPlannerResultsViewController
//--------------------------------------------------------------------------------------------------

#define TRIP_CELL_MAIN(TOK, EP, BODY, MODE, TIME, COLOR, ROUTE, ACCLABEL, DISCLOSURE, BLUE)        \
    CELL_UPDATE_METHOD(TOK) {                                                                      \
        TripItinerary *it = [self getSafeItinerary:indexPath.section];                             \
        TripItemCell *tripCell = (TripItemCell *)cell;                                             \
        TripLegEndPoint *ep = (EP);                                                                \
        [tripCell populateMarkedUpBody:BODY                                                        \
                                  mode:MODE                                                        \
                                  time:TIME                                                        \
                             leftColor:COLOR                                                       \
                                 route:ROUTE                                                       \
                           accessLabel:ACCLABEL];                                                  \
        tripCell.accessoryType = (DISCLOSURE) ? UITableViewCellAccessoryDisclosureIndicator        \
                                              : UITableViewCellAccessoryNone;                      \
        tripCell.selectionStyle =                                                                  \
            (BLUE) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;        \
        (void)ep;                                                                                  \
        (void)it;                                                                                  \
    }

//--------------------------------------------------------------------------------------------------
#define TRIP_CELL_SELECT(TOK, EP, BODY, MODE, TIME, COLOR, ROUTE, ACCLABEL, DISCLOSURE, BLUE)      \
    TRIP_CELL_MAIN(TOK, EP, BODY, MODE, TIME, COLOR, ROUTE, ACCLABEL, DISCLOSURE, BLUE)            \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_UPDATE_SEL(TOK),                                                                  \
        SET_CELL_SELECT_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(auto),                                                                 \
        .reuseId = (kTripItemCellId),                                                              \
    };                                                                                             \
    CELL_POP_SEL_WARNING;                                                                          \
    CELL_SELECT_METHOD(TOK)

//--------------------------------------------------------------------------------------------------
#define TRIP_CELL(TOK, EP, BODY, MODE, TIME, COLOR, ROUTE, ACCLABEL, DISCLOSURE, BLUE)             \
    TRIP_CELL_MAIN(TOK, EP, BODY, MODE, TIME, COLOR, ROUTE, ACCLABEL, DISCLOSURE, BLUE)            \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_UPDATE_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(auto),                                                                 \
        .reuseId = (kTripItemCellId),                                                              \
    };

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeError

TRIP_CELL_SELECT(kRowTypeError,
                 nil,
                 it.message.safeEscapeForMarkUp,
                 NSLocalizedString(@"No", @"Trip info"),
                 NSLocalizedString(@"Route", @"Trip info"),
                 nil,
                 nil,
                 nil,
                 !self.tripQuery.gotData,
                 NO) {
    if (!self.tripQuery.gotData) {
        [self networkTips:self.tripQuery.htmlError networkError:self.tripQuery.networkErrorMsg];
        [self clearSelection];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeLeg

TRIP_CELL_SELECT(kRowTypeLeg,
                 it.displayEndPoints[indexPath.row],
                 ep.displayText,
                 ep.displayModeText,
                 ep.displayTimeText,
                 ep.leftColor,
                 ep.displayRouteNumber,
                 nil,
                 ep.strStopId != nil || ep.loc != nil,
                 ep.strStopId != nil || ep.loc != nil) {
    TripItinerary *it = [self getSafeItinerary:indexPath.section];
    TripLegEndPoint *leg = it.displayEndPoints[indexPath.row];
    [self selectLeg:leg];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeDuration

TRIP_CELL(kRowTypeDuration,
          nil,
          it.travelTime,
          NSLocalizedString(@"Travel", @"Trip info"),
          NSLocalizedString(@"time", @"Trip info"),
          nil,
          nil,
          nil,
          NO,
          NO);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeTransfers

TRIP_CELL(kRowTypeTransfers,
          nil,
          it.strNumberOfTransfers.safeEscapeForMarkUp,
          NSLocalizedString(@"Transfers", @"Trip info"),
          nil,
          nil,
          nil,
          nil,
          NO,
          NO);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeDistance

TRIP_CELL(kRowTypeDistance,
          nil,
          it.formattedDistance,
          NSLocalizedString(@"Distance", @"Trip info"),
          nil,
          nil,
          nil,
          nil,
          NO,
          NO);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeFare

TRIP_CELL(kRowTypeFare,
          nil,
          it.fare.stringByTrimmingWhitespace,
          NSLocalizedString(@"Fare", @"Trip info"),
          nil,
          nil,
          nil,
          nil,
          NO,
          NO);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeFrom

TRIP_CELL_SELECT(kRowTypeFrom,
                 nil,
                 self.fromText,
                 NSLocalizedString(@"From", @"Trip info"),
                 nil,
                 [UIColor modeAwareBlue],
                 nil,
                 nil,
                 YES,
                 YES) {
    [self selectLeg:self.tripQuery.resultFrom];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeTo

TRIP_CELL_SELECT(kRowTypeTo,
                 nil,
                 self.toText,
                 NSLocalizedString(@"To", @"Trip info"),
                 nil,
                 [UIColor modeAwareBlue],
                 nil,
                 nil,
                 YES,
                 YES) {
    [self selectLeg:self.tripQuery.resultTo];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeDateAndTime

TRIP_CELL(kRowTypeDateAndTime,
          nil,
          [self.tripQuery.userRequest getDateAndTime],
          [self.tripQuery.userRequest timeType],
          nil,
          [UIColor modeAwareBlue],
          nil,
          nil,
          NO,
          NO);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowOptions

TRIP_CELL(kRowTypeOptions,
          nil,
          [self.tripQuery.userRequest optionsDisplayText],
          NSLocalizedString(@"Options", @"Trip info"),
          nil,
          [UIColor modeAwareBlue],
          nil,
          [self.tripQuery.userRequest optionsAccessability],
          NO,
          NO);
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowDisclaimerType

CELL_CONFIG_METHOD(kSectionRowDisclaimerType) {
    UITableViewCell *cell = [self disclaimerCell:tableView];

    if (self.tripQuery.queryDateFormatted != nil && self.tripQuery.queryTimeFormatted != nil) {
        [self
            addTextToDisclaimerCell:cell
                               text:[NSString stringWithFormat:NSLocalizedString(@"Updated %@ %@",
                                                                                 @"Trip info"),
                                                               self.tripQuery.queryDateFormatted,
                                                               self.tripQuery.queryTimeFormatted]];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self updateDisclaimerAccessibility:cell];
    return cell;
}

STATIC_VTABLE_VC_H(kSectionRowDisclaimerType, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeDetours

ACTION_CELL_SELECT(kRowTypeDetours,
                   NSLocalizedString(@"Check detours", @"main menu item"),
                   kIconDetour,
                   UITableViewCellAccessoryDisclosureIndicator) {
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
        [[DetoursViewController viewController] fetchDetoursAsync:self.backgroundTask
                                                           routes:allRoutes
                                                backgroundRefresh:NO];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeMap

ACTION_CELL_SELECT(kRowTypeMap,
                   NSLocalizedString(@"Show on map", @"main menu item"),
                   kIconMap,
                   UITableViewCellAccessoryDisclosureIndicator) {
    TripPlannerMapController *mapPage = [TripPlannerMapController viewController];
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

        [leg createToText:(i == ([it legCount] - 1)) textType:TripTextTypeMap];

        if (leg.to.mapText != nil) {
            j++;
            leg.to.index = j;

            [mapPage addPin:leg.to];
        }
    }

    mapPage.it = it;

    [mapPage fetchShapesAsync:self.backgroundTask];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeTag

CELL_CONFIG_METHOD(kRowTypeTag) {
    TripItinerary *it = [self getSafeItinerary:indexPath.section];

    UIColor *color = nil;
    UIColor *newColor = nil;

    for (TripLeg *leg in it.legs) {
        if (leg.block) {

            newColor = [[BlockColorDb sharedInstance] colorForBlock:leg.block];

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

    UITableViewCell *cell = [self tableView:tableView
                    cellWithReuseIdentifier:MakeCellId(kRowTypeTag)];

    [self actionCell:cell
                  text:NSLocalizedString(@"Tag all " kBlockNames " with a color", @"main menu item")
                  icon:[[BoxedImageIcon alloc] initWithImage:[BlockColorDb imageWithColor:color]]
         accessoryType:UITableViewCellAccessoryDetailDisclosureButton
        selectionStyle:UITableViewCellSelectionStyleBlue];

    return cell;
}

CELL_ACCESSORY_METHOD(kRowTypeTag) {
    _reloadOnAppear = YES;
    [self.navigationController pushViewController:[BlockColorViewController viewController]
                                         animated:YES];
}

CELL_SELECT_METHOD(kRowTypeTag) {
    TripItinerary *it = [self getSafeItinerary:indexPath.section];

    __weak __typeof(self) weakSelf = self;

    UIViewController *picker = [SimpleColorPickerCoordinator
        createWithInitialColor:UIColor.randomColor
                         title:NSLocalizedString(@"Pick tag color", @"window title")
                      onPicked:^(UIColor *selectedColor) {
                        __strong __typeof(self) strongSelf = weakSelf;

                        if (!strongSelf)
                            return;
                        if (selectedColor) {
                            for (TripLeg *leg in it.legs) {
                                if (leg.block) {
                                    [[BlockColorDb sharedInstance] addColor:selectedColor
                                                                   forBlock:leg.block
                                                                description:leg.routeName];
                                }
                            }

                            [strongSelf userStateChanged];
                        }
                        [strongSelf reloadData];
                      }];

    [self presentViewController:picker
                       animated:YES
                     completion:^{
                     }];
}

CELL_STATIC_VTABLE(kRowTypeTag){
    SET_CELL_CONFIG_SEL(kRowTypeTag),
    SET_CELL_SELECT_SEL(kRowTypeTag),
    SET_CELL_ACCESSORY_SEL(kRowTypeTag),
    SET_CELL_HEIGHT_SEL(narrow),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeEmail

ACTION_CELL_SELECT(kRowTypeEmail,
                   NSLocalizedString(@"Send by email", @"main menu item"),
                   kIconEmail,
                   UITableViewCellAccessoryDisclosureIndicator) {
    NSMutableString *trip = [[NSMutableString alloc] init];

    TripItinerary *it = [self getSafeItinerary:indexPath.section];

    if (self.tripQuery.resultFrom != nil) {
        if (self.tripQuery.resultFrom.loc != nil) {
            [trip appendFormat:@"From: <a "
                               @"href=\"http://map.google.com/"
                               @"?q=location@%@\">%@<br></a>",
                               COORD_TO_LAT_LNG_STR(self.tripQuery.resultFrom.coordinate),
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
                               COORD_TO_LAT_LNG_STR(self.tripQuery.resultTo.coordinate),
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
        htmlText = [leg createToText:(i == [it legCount] - 1) textType:TripTextTypeHTML];
        [trip appendString:htmlText];
    }

    [trip appendFormat:NSLocalizedString(@"Travel time: %@<br><br>", @"Trip Info"), it.travelTime];

    if (it.numberOfTransfers > 0) {
        [trip appendFormat:NSLocalizedString(@"Transfers: %@<br><br>", @"Trip Info"),
                           it.strNumberOfTransfers];
    }

    if (it.distanceMiles > 0) {
        [trip appendFormat:NSLocalizedString(@"Distance: %@<br><br>", @"Trip Info"),
                           it.formattedDistance];
    }

    if (it.fare != nil) {
        [trip appendFormat:NSLocalizedString(@"Fare: %@<br><br>", @"Trip Info"), it.fare];
    }

    MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];

    email.mailComposeDelegate = self;

    if (![MFMailComposeViewController canSendMail]) {
        [UIAlertController simpleOkWithTitle:NSLocalizedString(@"email", @"alert title")
                                     message:NSLocalizedString(@"Cannot send email on this device",
                                                               @"alert message")
                              viewController:self
                                  completion:nil];
        return;
    }

    [email setSubject:@"TriMet Trip"];

    [email setMessageBody:trip isHTML:YES];

    [self presentViewController:email
                       animated:YES
                     completion:^{
                       [self clearSelection];
                     }];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeSMS

ACTION_CELL_SELECT(kRowTypeSMS,
                   NSLocalizedString(@"Send by text message", @"main menu item"),
                   kIconSMS,
                   UITableViewCellAccessoryDisclosureIndicator) {

    TripItinerary *it = [self getSafeItinerary:indexPath.section];
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;

    picker.body = [self plainText:it];

    [self presentViewController:picker
                       animated:YES
                     completion:^{
                       [self clearSelection];
                     }];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeCal

ACTION_CELL_SELECT(kRowTypeCal,
                   NSLocalizedString(@"Add to calendar", @"main menu item"),
                   kIconCal,
                   UITableViewCellAccessoryDisclosureIndicator) {
    if (self.eventStore == nil) {
        self.eventStore = [[EKEventStore alloc] init];
    }

    [self.eventStore
        requestAccessToEntityType:EKEntityTypeEvent
                       completion:^(BOOL granted, NSError *error) {
                         [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                           if (granted) {
                               UIAlertController *alert = [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Calendar",
                                                                              @"alert title")
                                                    message:NSLocalizedString(@"Are you sure "
                                                                              @"you want to "
                                                                              @"add this to "
                                                                              @"your default "
                                                                              @"calendar?",
                                                                              @"alert "
                                                                              @"message")
                                             preferredStyle:UIAlertControllerStyleActionSheet];

                               [alert
                                   addAction:[UIAlertAction
                                                 actionWithTitle:NSLocalizedString(@"Yes",
                                                                                   @"button text")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                           [self addCalendarItem:
                                                                     [self getSafeItinerary:
                                                                               indexPath.section]];
                                                         }]];

                               [alert addAction:[UIAlertAction
                                                    actionWithTitle:NSLocalizedString(
                                                                        @"Cancel", @"button text")
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];

                               [self displayPopover:alert
                                               view:[tableView cellForRowAtIndexPath:indexPath]
                                         completion:^{
                                           [self clearSelection];
                                         }];

                           } else {
                               [UIAlertController
                                   simpleOkWithTitle:NSLocalizedString(@"Calendar", @"alert title")
                                             message:NSLocalizedString(@"Calendar access has "
                                                                       @"been denied. Please "
                                                                       @"check the app "
                                                                       @"settings to allow "
                                                                       @"access to the "
                                                                       @"calendar.",
                                                                       @"alert message")
                                      viewController:self
                                          completion:nil];
                           }
                         }];
                       }];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeClipboard

ACTION_CELL_SELECT(kRowTypeClipboard,
                   NSLocalizedString(@"Copy to clipboard", @"main menu item"),
                   kIconCopy,
                   UITableViewCellAccessoryNone) {

    TripItinerary *it = [self getSafeItinerary:indexPath.section];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self plainText:it];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeReverse

ACTION_CELL_SELECT(kRowTypeReverse,
                   NSLocalizedString(@"Reverse trip", @"main menu item"),
                   kIconReverse,
                   UITableViewCellAccessoryDisclosureIndicator) {

    XMLTrips *reverse = [self.tripQuery createReverse];

    TripPlannerDateViewController *tripDate = [TripPlannerDateViewController viewController];

    tripDate.userFaves = reverse.userFaves;
    tripDate.tripQuery = reverse;

    // Push the detail view controller
    [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeArrivals

ACTION_CELL_SELECT(kRowTypeArrivals,
                   NSLocalizedString(@"Departures for all stops", @"main menu item"),
                   kIconArrivals,
                   UITableViewCellAccessoryDisclosureIndicator) {

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
            if (nextStop != nil && (lastStop == nil || ![nextStop isEqualToString:lastStop])) {
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
}

//--------------------------------------------------------------------------------------------------
#pragma mark kRowTypeAlarms

ACTION_CELL_SELECT(kRowTypeAlarms,
                   NSLocalizedString(@"Set deboard alarms", @"main menu item"),
                   kIconAlarm,
                   UITableViewCellAccessoryDisclosureIndicator) {
    AlarmTaskList *taskList = [AlarmTaskList sharedInstance];

    if ([UIViewController locationAuthorizedOrNotDeterminedWithBackground:YES]) {
        [taskList userAlertForProximity:self
                                 source:[tableView cellForRowAtIndexPath:indexPath]
                             completion:^(bool cancelled, bool accurate) {
                               if (!cancelled) {
                                   TripItinerary *it = [self getSafeItinerary:indexPath.section];

                                   for (TripLegEndPoint *leg in it.displayEndPoints) {
                                       if (leg.deboard) {
                                           if (![taskList hasTaskForStopIdProximity:leg.stopId]) {
                                               [taskList addTaskForStopIdProximity:leg.stopId
                                                                               loc:leg.loc
                                                                              desc:leg.desc
                                                                          accurate:accurate
                                                                        controller:self];
                                           }
                                       }
                                   }
                               }

                               [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                             }];
    } else {
        [self locationAuthorizedOrNotDeterminedAlertWithBackground:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kRowTypeError),
    CELL_MAP(kRowTypeLeg),
    CELL_MAP(kRowTypeDuration),
    CELL_MAP(kRowTypeTransfers),
    CELL_MAP(kRowTypeDistance),
    CELL_MAP(kRowTypeFare),
    CELL_MAP(kRowTypeFrom),
    CELL_MAP(kRowTypeTo),
    CELL_MAP(kRowTypeDateAndTime),
    CELL_MAP(kRowTypeOptions),
    CELL_MAP(kSectionRowDisclaimerType),
    CELL_MAP(kRowTypeDetours),
    CELL_MAP(kRowTypeMap),
    CELL_MAP(kRowTypeTag),
    CELL_MAP(kRowTypeEmail),
    CELL_MAP(kRowTypeSMS),
    CELL_MAP(kRowTypeCal),
    CELL_MAP(kRowTypeClipboard),
    CELL_MAP(kRowTypeReverse),
    CELL_MAP(kRowTypeArrivals),
    CELL_MAP(kRowTypeAlarms),
};

@end

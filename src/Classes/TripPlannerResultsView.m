//
//  TripPlannerResultsView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerResultsView.h"
#import "DepartureTimesView.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "TripPlannerDateView.h"
#import "DepartureTimesView.h"
#import "NetworkTestView.h"
#import "WebViewController.h"
#import "TripPlannerMap.h"
#include "UserFaves.h"
#include "EditBookMarkView.h"
#import <MessageUI/MessageUI.h>
#include "TripPlannerEndPointView.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "TripPlannerSummaryView.h"
#import "DetoursView.h"
#import "AlarmTaskList.h"
#import "AlarmAccurateStopProximity.h"
#import "LocationAuthorization.h"
#import "StringHelper.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "TriMetInfo.h"
#import <Intents/Intents.h>
#import <IntentsUI/IntentsUI.h>
#import "MainQueueSync.h"

#define kRowTypeLeg            0
#define kRowTypeDuration    1
#define kRowTypeFare        2
#define kRowTypeMap            3
#define kRowTypeEmail        4
#define kRowTypeSMS            5
#define kRowTypeCal         6
#define kRowTypeClipboard    7
#define kRowTypeTag         8
#define kRowTypeAlarms      9
#define kRowTypeArrivals    10
#define kRowTypeDetours        11
#define kRowTypeError        12
#define kRowTypeReverse        13
#define kRowTypeFrom        14
#define kRowTypeTo            15
#define kRowTypeOptions        16
#define kRowTypeDateAndTime 17


#define kSectionTypeEndPoints    0
#define kSectionTypeOptions        1
#define kRowsInDisclaimerSection 2

#define kDefaultRowHeight        40.0


#define KDisclosure UITableViewCellAccessoryDisclosureIndicator
#define kScheduledText @"The trip planner shows scheduled service only. Check below to see how detours may affect your trip."

@implementation TripPlannerResultsView

- (void)dealloc {
    
    if (self.userActivity)
    {
        [self.userActivity invalidate];
    }
    
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _recentTripItem = -1;
    }
    
    return self;
    
}

- (instancetype)initWithHistoryItem:(int)item
{
    if ((self = [super init]))
    {
        [self setItemFromHistory:item];
    }
    
    return self;
}


- (void)setItemFromArchive:(NSDictionary *)archive
{
    self.tripQuery = [XMLTrips xml];
    
    
    self.tripQuery.userRequest = [TripUserRequest fromDictionary:archive[kUserFavesTrip]];
    // trips.rawData     = trip[kUserFavesTripResults];
    
    [self.tripQuery addStopsFromUserFaves:_userData.faves];
    [self.tripQuery fetchItineraries:archive[kUserFavesTripResults]];
    
    [self setupRows];
}

- (void)setItemFromHistory:(int)item
{
    NSDictionary *trip = nil;
    @synchronized (_userData)
    {
        trip = _userData.recentTrips[item];
        
        _recentTripItem = item;
    
        [self setItemFromArchive:trip];
        
    }

}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) style
{
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{    
    // match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
    UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
    
    
    
    
    // create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                 target:self action:@selector(bookmarkButton:)];
    
    bookmark.style = style;
    
    // create the system-defined "OK or Done" button
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Redo", @"button text")
                                                             style:UIBarButtonItemStylePlain 
                                                            target:self 
                                                            action:@selector(showCopy:)];
    
    // create the system-defined "OK or Done" button


    [toolbarItems addObject: bookmark];
    [toolbarItems addObject: [UIToolbar flexSpace]];
    [toolbarItems addObject: edit];
    [toolbarItems addObject: [UIToolbar flexSpace]];
     
    if ([UserPrefs sharedInstance].debugXML)
    {
        [toolbarItems addObject:[self debugXmlButton]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
    
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.tripQuery appendQueryAndData:buffer];
}

#pragma mark View methods


- (void)enableArrows:(UISegmentedControl*)seg
{
    [seg setEnabled:(_recentTripItem > 0) forSegmentAtIndex:0];
    
    [seg setEnabled:(_recentTripItem < (_userData.recentTrips.count-1)) forSegmentAtIndex:1];

}


- (void)upDown:(id)sender
{
    UISegmentedControl *segControl = sender;
    switch (segControl.selectedSegmentIndex)
    {
        case 0:    // UIPickerView
        {
            // Up
            if (_recentTripItem > 0)
            {
                [self setItemFromHistory:_recentTripItem-1];
                [self reloadData];
            }
            break;
        }
        case 1:    // UIPickerView
        {
            if (_recentTripItem < (_userData.recentTrips.count-1) )
            {
                [self setItemFromHistory:_recentTripItem+1];
                [self reloadData];
            }
            break;
        }
    }
    [self enableArrows:segControl];
}

- (void)loadView
{
    [super loadView];
    
    [self.table registerNib:[TripItemCell nib] forCellReuseIdentifier:kTripItemCellId];
}

- (void)setupRows
{
    [self clearSectionMaps];
    
    if (self.tripQuery.resultFrom != nil && self.tripQuery.resultTo != nil)
    {
        [self addSectionType:kSectionTypeEndPoints];
        [self addRowType:kRowTypeFrom];
        [self addRowType:kRowTypeTo];
        [self addRowType:kRowTypeOptions];
        [self addRowType:kRowTypeDateAndTime];
        
        _itinerarySectionOffset = 1;
    }
    else
    {
        _itinerarySectionOffset = 0;
    }
    
    for (TripItinerary *it in self.tripQuery)
    {
        [self addSectionType:kSectionTypeOptions];
        
        NSInteger legs = [self legRows:it];
        
        if (legs == 0)
        {
            [self addRowType:kRowTypeError];
        }
        else
        {
            [self addRowType:kRowTypeLeg count:legs];
        }
        
        if (legs > 0)
        {
            [self addRowType:kRowTypeDuration];
            
            if (it.hasFare)
            {
                [self addRowType:kRowTypeFare];
            }
            
            [self addRowType:kRowTypeMap];
            [self addRowType:kRowTypeEmail];
        
            if (_sms)
            {
                [self addRowType:kRowTypeSMS];
            }
        
            if (_cal)
            {
                [self addRowType:kRowTypeCal];
            }
        
            if (it.hasBlocks)
            {
                [self addRowType:kRowTypeTag];
                [self addRowType:kRowTypeAlarms];
                [self addRowType:kRowTypeArrivals];
                [self addRowType:kRowTypeDetours];
            }
        }
    }

    
    [self addSectionType:kSectionRowDisclaimerType];
    
    if (!self.tripQuery.reversed)
    {
        [self addRowType:kRowTypeReverse];
    }
    [self addRowType:kSectionRowDisclaimerType];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Trip",@"page title");
    
    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    
    if (messageClass != nil) {          
        // Check whether the current device is configured for sending SMS messages
        _sms =  [messageClass canSendText];
    }
    
    Class eventClass = (NSClassFromString(@"EKEventEditViewController"));
    
    _cal = (eventClass != nil);
    
    [self setupRows];
    
    if (_recentTripItem >=0)
    {
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[
                                            [TableViewWithToolbar getToolbarIcon:kIconUp7],
                                            [TableViewWithToolbar getToolbarIcon:kIconDown7]] ];
        seg.frame = CGRectMake(0, 0, 60, 30.0);
        seg.momentary = YES;
        [seg addTarget:self action:@selector(upDown:) forControlEvents:UIControlEventValueChanged];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: seg];
        
        [self enableArrows:seg];
        
    }
    
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark UI helpers



- (TripItinerary *)getSafeItinerary:(NSInteger)section
{
    if ([self sectionType:section] ==  kSectionTypeOptions)
    {
        return self.tripQuery[section - _itinerarySectionOffset]; 
    }
    return nil;
}

- (NSInteger)legRows:(TripItinerary *)it
{
    return it.displayEndPoints.count;
}

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath
{
    TripItinerary *it = [self getSafeItinerary:indexPath.section];
    
    if (indexPath.row < [self legRows:it])
    {
        return it.displayEndPoints[indexPath.row].displayText;
    }
    
    return nil;
    
}

-(void)showCopy:(id)sender
{
    TripPlannerSummaryView *trip = [TripPlannerSummaryView viewController];
    
    trip.tripQuery = [self.tripQuery createAuto];
    [trip.tripQuery resetCurrentLocation];
    
    [self.navigationController pushViewController:trip animated:YES];
}


- (NSString*)fromText
{
    //    if (self.tripQuery.fromPoint.useCurrentPosition)
    //    {
    //        return [NSString stringWithFormat:@"From: %@, %@", self.tripQuery.fromPoint.lat, self.tripQuery.fromPoint.lng];
    //    }    
    return self.tripQuery.resultFrom.xdescription;
}

- (NSString*)toText
{
    //    if (self.tripQuery.toPoint.useCurrentPosition)
    //    {
    //        return [NSString stringWithFormat:@"To: %@, %@", self.tripQuery.toPoint.lat, self.tripQuery.toPoint.lng];
    //    }
    return self.tripQuery.resultTo.xdescription;
}




-(void)selectLeg:(TripLegEndPoint *)leg
{
    NSString *stopId = [leg stopId];
    
    if (stopId != nil)
    {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        
        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:stopId];
    }
    else if (leg.xlat !=0 && leg.xlon !=0)
    {
        MapViewController *mapPage = [MapViewController viewController];
        SimpleAnnotation *pin = [SimpleAnnotation annotation];
        mapPage.callback = self.callback;
        pin.coordinate =  leg.loc.coordinate;
        pin.pinTitle = leg.xdescription;
        pin.pinColor = MAP_PIN_COLOR_PURPLE;
        
        
        [mapPage addPin:pin];
        mapPage.title = leg.xdescription; 
        [self.navigationController pushViewController:mapPage animated:YES];
    }    
    
    
}

#pragma mark UI Callback methods

-(void)bookmarkButton:(UIBarButtonItem*)sender
{
    NSString *desc = nil;
    int  bookmarkItem = kNoBookmark;
    @synchronized (_userData)
    {
        int i;

        TripUserRequest * req = [[TripUserRequest alloc] init];
    
        for (i=0; _userData.faves!=nil &&  i< _userData.faves.count; i++)
        {
            NSDictionary *bm = _userData.faves[i];
            NSDictionary * faveTrip = (NSDictionary *)bm[kUserFavesTrip];
        
            if (bm!=nil && faveTrip != nil)
            {
                [req readDictionary:faveTrip];
                if ([req equalsTripUserRequest:self.tripQuery.userRequest])
                {
                    bookmarkItem = i;
                    desc = bm[kUserFavesChosenName];
                    break;
                }
            }
        
        }
    }
    
    if (bookmarkItem == kNoBookmark)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Bookmark Trip",@"alert title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add new bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    EditBookMarkView *edit = [EditBookMarkView viewController];
                                                    // [edit addBookMarkFromStop:self.bookmarkDesc location:self.bookmarkLoc];
                                                    [edit addBookMarkFromUserRequest:self.tripQuery];
                                                    // Push the detail view controller
                                                    [self.navigationController pushViewController:edit animated:YES];
                                                }]];
        
        if (@available(iOS 12.0, *))
        {
            [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action){
                                                        [self addBookmarkToSiri];
                                                    }]];
        }
        
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
        
        alert.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:alert animated:YES completion:^{
            [self clearSelection];
        }];
    }
    else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:desc
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete this bookmark", @"button text")
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action){
                                                    [self->_userData.faves removeObjectAtIndex:bookmarkItem];
                                                    [self favesChanged];
                                                    [self->_userData cacheAppData];
                                                }]];
        
        
        if (@available(iOS 12.0, *))
        {
            [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action){
                                                        [self addBookmarkToSiri];
                                                    }]];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit this bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    EditBookMarkView *edit = [EditBookMarkView viewController];
                                                    [edit editBookMark:self->_userData.faves[bookmarkItem] item:bookmarkItem];
                                                    // Push the detail view controller
                                                    [self.navigationController pushViewController:edit animated:YES];
                                                }]];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
        
        alert.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:alert animated:YES completion:^{
            [self clearSelection];
        }];
        
    }    
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tripQuery.count+1+_itinerarySectionOffset;
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch ([self sectionType:section])
    {
    case kSectionTypeEndPoints:    
        return NSLocalizedString(@"The trip planner shows scheduled service only. Check below to see how detours may affect your trip.\n\nYour trip:", @"section header");
        break;
    case kSectionTypeOptions:
        {
            TripItinerary *it = [self getSafeItinerary:section];

            NSInteger legs = [self legRows:it];
    
            if (legs > 0)
            {
                return [NSString stringWithFormat:NSLocalizedString(@"Option %ld - %@", @"section header"), (long)(section + 1 - _itinerarySectionOffset), it.shortTravelTime];
            }
            else
            {
                return NSLocalizedString(@"No route was found:", @"section header");
            }
        }
    case kSectionRowDisclaimerType:
        // return @"Other options";
        break;
    }
    return nil;
}

- (void)populateTripCell:(TripItemCell *)cell itinerary:(TripItinerary *)it rowType:(NSInteger)rowType indexPath:(NSIndexPath*)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (rowType)
    {
        case kRowTypeError:
            [cell populateBody:it.xmessage mode:@"No" time:@"Route" leftColor:nil route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (!self.tripQuery.gotData)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            // [cell populateBody:it.xmessage mode:nil time:nil];
            // cell.view.text = it.xmessage;
            break;
        case kRowTypeLeg:
        {
            TripLegEndPoint * ep = it.displayEndPoints[indexPath.row];
            [cell populateBody:ep.displayText mode:ep.displayModeText time:ep.displayTimeText leftColor:ep.leftColor
                         route:ep.xnumber];
            
            //[cell populateBody:@"l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l"
            //                 mode:ep.displayModeText time:ep.displayTimeText leftColor:ep.leftColor
            //                route:ep.xnumber];
            
            
            if (ep.xstopId!=nil || ep.xlat !=nil)
            {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryType = KDisclosure;
            }
            else
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
            // cell.view.text = [self getTextForLeg:indexPath];
            
            //printf("width: %f\n", cell.view.frame.size.width);
            break;
        case kRowTypeDuration:
            [cell populateBody:it.travelTime mode:@"Travel" time:@"time" leftColor:nil route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            // justText = [it getTravelTime];
            break;
        case kRowTypeFare:
            [cell populateBody:it.fare.stringWithTrailingSpacesRemoved
                          mode:@"Fare"
                          time:nil
                     leftColor:nil
                         route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            // justText = it.fare;
            break;
        case kRowTypeFrom:
            [cell populateBody:self.fromText mode:@"From" time:nil leftColor:nil route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case kRowTypeOptions:
            [cell populateBody:[self.tripQuery.userRequest optionsDisplayText] mode:@"Options" time:nil
                     leftColor:nil
                         route:nil];
            
            cell.accessibilityLabel = [self.tripQuery.userRequest optionsAccessability];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case kRowTypeTo:
            [cell populateBody:self.toText mode:@"To" time:nil leftColor:nil route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kRowTypeDateAndTime:
            
            
            [cell populateBody:[self.tripQuery.userRequest getDateAndTime]
                          mode:[self.tripQuery.userRequest timeType]
                          time:nil
                     leftColor:nil
                         route:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView actionCell:(NSIndexPath *)indexPath text:(NSString *)text image:(UIImage *)image type:(UITableViewCellAccessoryType)type
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"TripAction"];
    
    cell.textLabel.text = text;
    cell.imageView.image = image;
    cell.accessoryType = type;
    
    cell.textLabel.textColor = [ UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = self.basicFont;
    [self updateAccessibility:cell];
    
    return cell;
    
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowTypeError:
        case kRowTypeLeg:
        case kRowTypeDuration:
        case kRowTypeFare:
        case kRowTypeFrom:
        case kRowTypeTo:
        case kRowTypeDateAndTime:
        case kRowTypeOptions:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            TripItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripItemCellId];
            [self populateTripCell:cell itinerary:it rowType:rowType indexPath:indexPath];
            return cell;
        }
        case kSectionRowDisclaimerType:
        {
            UITableViewCell *cell  = [self disclaimerCell:tableView];
            
            if (self.tripQuery.xdate != nil && self.tripQuery.xtime!=nil)
            {
                [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"Updated %@ %@", self.tripQuery.xdate, self.tripQuery.xtime]];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self updateDisclaimerAccessibility:cell];
            return cell;
        }
            
        case kRowTypeDetours:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Check detours", @"main menu item")
                             image:[self getIcon:kIconDetour]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeMap:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Show on map", @"main menu item")
                             image:[self getIcon:kIconMapAction7]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeEmail:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Send by email", @"main menu item")
                             image:[self getIcon:kIconEmail]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeSMS:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Send by text message", @"main menu item")
                             image:[self getIcon:kIconCell]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeCal:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Add to calendar", @"main menu item")
                             image:[self getIcon:kIconCal]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeTag:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            UIColor *color = nil;
            UIColor *newColor = nil;
            
            for (TripLeg *leg in it.legs)
            {
                if (leg.xblock)
                {
                    newColor = [[BlockColorDb sharedInstance] colorForBlock:leg.xblock];
                    
                    if (newColor == nil)
                    {
                        newColor = [UIColor grayColor];
                    }
                    
                    if (color == nil)
                    {
                        color = newColor;
                    }
                    else
                    {
                        if (![color isEqual:newColor])
                        {
                            color = [UIColor grayColor];
                        }
                    }
                }
            }
            
            if (color == nil)
            {
                color = [UIColor grayColor];
            }
            
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Tag all " kBlockNames " with a color", @"main menu item")
                             image:[BlockColorDb imageWithColor:color]
                              type:UITableViewCellAccessoryDetailDisclosureButton];
        }
        case kRowTypeClipboard:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Copy to clipboard", @"main menu item")
                             image:[self getIcon:kIconCut]
                              type:UITableViewCellAccessoryNone];
        case kRowTypeReverse:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Reverse trip", @"main menu item")
                             image:[self getIcon:kIconReverse]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeArrivals:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Arrivals for all stops", @"main menu item")
                             image:[self getIcon:kIconArrivals]
                              type:UITableViewCellAccessoryDisclosureIndicator];
        case kRowTypeAlarms:
            return [self tableView:tableView
                        actionCell:indexPath
                              text:NSLocalizedString(@"Set deboard alarms", @"main menu item")
                             image:[self getIcon:kIconAlarm]
                              type:UITableViewCellAccessoryDisclosureIndicator];

    }
    
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if ([self rowType:indexPath] == kRowTypeTag)
    {
        _reloadOnAppear = YES;
        [self.navigationController pushViewController:[BlockColorViewController viewController] animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType)
    {
        case kRowTypeError:
        case kRowTypeLeg:
        case kRowTypeDuration:
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

- (NSString *)plainText:(TripItinerary *)it
{
    NSMutableString *trip = [NSMutableString string];
    
//    TripItinerary *it = [self getSafeItinerary:indexPath.section];
    
    if (self.tripQuery.resultFrom != nil)
    {
        [trip appendFormat:@"From: %@\n",
         self.tripQuery.resultFrom.xdescription
         ];
    }
    
    if (self.tripQuery.resultTo != nil)
    {
        [trip appendFormat:@"To: %@\n",
         self.tripQuery.resultTo.xdescription
         ];
    }
    

    [trip appendFormat:@"%@: %@\n\n", [self.tripQuery.userRequest timeType], [self.tripQuery.userRequest getDateAndTime]];
        
    NSString *htmlText = [it startPointText:TripTextTypeClip];
    [trip appendString:htmlText];
    
    int i;
    for (i=0; i< [it legCount]; i++)
    {
        TripLeg *leg = [it getLeg:i];
        htmlText = [leg createFromText:(i==0) textType:TripTextTypeClip];
        [trip appendString:htmlText];
        htmlText = [leg createToText:(i==[it legCount]-1) textType:TripTextTypeClip];
        [trip appendString:htmlText];
    }
    
    [trip appendFormat:@"Scheduled travel time: %@\n\n",it.travelTime];
    
    if (it.fare != nil)
    {
        [trip appendFormat:@"Fare: %@",it.fare ];
    }
    
    return trip;
}

-(void)addCalendarItem:(TripItinerary *)it
{
    
    self.event      = [EKEvent eventWithEventStore:self.eventStore];
    self.event.title= [NSString stringWithFormat:@"TriMet Trip\n%@", [self.tripQuery mediumName]];
    self.event.notes= [NSString stringWithFormat:@"Note: ensure you leave early enough to arrive in time for the first connection.\n\n%@"
                       "\nRoute and arrival data provided by permission of TriMet.",
                       [self plainText:it]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.locale = enUS;
    
    
    // Yikes - may have AM or PM or be 12 hour. :-(
    unichar last = [it.xstartTime characterAtIndex:(it.xstartTime.length-1)];
    if (last=='M' || last=='m')
    {
        dateFormatter.dateFormat = @"M/d/yy hh:mm a";
    }
    else
    {
        dateFormatter.dateFormat = @"M/d/yy HH:mm:ss";
    }
    
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    
    NSString *fullDateStr = [NSString stringWithFormat:@"%@ %@", it.xdate, it.xstartTime];
    NSDate *start = [dateFormatter dateFromString:fullDateStr];
    
    
    
    // The start time does not include the inital walk so take it off...
    for (int i=0; i< [it legCount]; i++)
    {
        TripLeg *leg = [it getLeg:i];
        
        if (leg.mode == nil)
        {
            continue;
        }
        if ([leg.mode isEqualToString:kModeWalk])
        {
            start = [start dateByAddingTimeInterval: -(leg.xduration.intValue * 60)];;
        }
        else {
            break;
        }
    }

    NSDate *end   = [start dateByAddingTimeInterval: it.xduration.intValue * 60];
    
    self.event.startDate = start;
    self.event.endDate   = end;
    
    EKCalendar *cal = self.eventStore.defaultCalendarForNewEvents;
    
    self.event.calendar = cal;
    NSError *err;
    if (cal !=nil && [self.eventStore saveEvent:self.event span:EKSpanThisEvent error:&err])
    {
        // Upon selecting an event, create an EKEventViewController to display the event.
        EKEventViewController *eventController = [[EKEventViewController alloc] init];
        eventController.event = self.event;
        eventController.title = NSLocalizedString(@"Calendar Event", @"page title");
        eventController.delegate = self;
        eventController.allowsCalendarPreview = YES;
        eventController.allowsEditing = YES;
        
        [self.navigationController pushViewController:eventController animated:YES];
        
        //[event retain];
        //[eventStore retain];
        
    }
}
    




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    switch ([self rowType:indexPath])
    {
        case kRowTypeError:
            if (!self.tripQuery.gotData)
            {
                
                [self networkTips:self.tripQuery.htmlError networkError:self.tripQuery.errorMsg];
                [self clearSelection];
                
            }
            break;
        case kRowTypeTo:
        case kRowTypeFrom:
        {
            TripLegEndPoint *ep = nil;
            
            if ([self rowType:indexPath] == kRowTypeTo)
            {
                ep = self.tripQuery.resultTo;
            }
            else
            {
                ep = self.tripQuery.resultFrom;
            }
            
            [self selectLeg:ep];
            break;
        }
            
        case kRowTypeLeg:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            TripLegEndPoint *leg = it.displayEndPoints[indexPath.row];
            [self selectLeg:leg];
        }
            
            break;
        case kRowTypeDuration:
        case kSectionRowDisclaimerType:
        case kRowTypeFare:
            break;
        case kRowTypeClipboard:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = [self plainText:it];
            break;
        }
        case kRowTypeAlarms:
        {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            
            if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
            {
                [taskList userAlertForProximity:self source:[tableView cellForRowAtIndexPath:indexPath]
                                     completion:^(bool cancelled, bool accurate) {
                                         if (!cancelled)
                                         {
                                             TripItinerary *it = [self getSafeItinerary:indexPath.section];
                                             
                                             for (TripLegEndPoint *leg in it.displayEndPoints)
                                             {
                                                 if (leg.deboard)
                                                 {
                                                     if (![taskList hasTaskForStopIdProximity:leg.stopId])
                                                     {
                                                         [taskList addTaskForStopIdProximity:leg.xstopId loc:leg.loc desc:leg.xdescription accurate:accurate];
                                                         
                                                     }
                                                 }
                                             }
                                         }
                                         [self.table deselectRowAtIndexPath:indexPath animated:YES];
                                     }];
            }
            else
            {
                [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:YES backgroundRequired:YES];
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
            }
            
            break;
            
        }
        case kRowTypeSMS:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
            picker.messageComposeDelegate = self;
            
            picker.body = [self plainText:it];
            
            [self presentViewController:picker animated:YES completion:nil];
            break;
        }
        case kRowTypeCal:
        {
            if (self.eventStore==nil)
            {
                self.eventStore = [[EKEventStore alloc] init];
            }
            
            // maybe check for access
            [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                
                [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                    if (granted)
                    {
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Calendar", @"alert title")
                                                                                       message:NSLocalizedString(@"Are you sure you want to add this to your default calendar?", @"alert message")
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"button text")
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action){
                                                                    [self addCalendarItem:[self getSafeItinerary:indexPath.section]];
                                                                }]];
                        
                        
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
                        
                        alert.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
                        
                        // Make a small rect in the center, just 10,10
                        const CGFloat side = 10;
                        CGRect frame = alert.popoverPresentationController.sourceView.frame;
                        CGRect sourceRect = CGRectMake((frame.size.width - side)/2.0, (frame.size.height-side)/2.0, side, side);
                        
                        alert.popoverPresentationController.sourceRect = sourceRect;
                        
                        
                        [self presentViewController:alert animated:YES completion:^{
                            [self clearSelection];
                        }];
                        
                    }
                    else
                    {
                        UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Calendar", @"alert title")
                                                                           message:NSLocalizedString(@"Calendar access has been denied. Please check the app settings to allow access to the calendar.",  @"alert message")
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"No", @"button text")
                                                                 otherButtonTitles:nil ];
                        [alert show];
                    }
                }];
            }];
            
            break;
        }
            
        case kRowTypeTag:
        {
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            InfColorPickerController* picker = [ InfColorPickerController colorPickerViewController ];
            
            picker.delegate = self;
            
            picker.sourceColor = [self randomColor];
            
            picker.completionBlock = ^(InfColorPickerController *sender) {
                
                for (TripLeg *leg in it.legs)
                {
                    if (leg.xblock)
                    {
                        [[BlockColorDb sharedInstance] addColor:sender.resultColor
                                                       forBlock:leg.xblock
                                                    description:leg.xname];
                    }
                }
                
                [sender dismissViewControllerAnimated:YES completion:nil];
                
                [self favesChanged];
                [self reloadData];
                
            };
            
            
            [ picker presentModallyOverViewController: self ];
        }
            break;
            
        case kRowTypeEmail:
        {
            
            
            NSMutableString *trip = [[NSMutableString alloc] init];
            
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            if (self.tripQuery.resultFrom != nil)
            {
                if (self.tripQuery.resultFrom.xlat!=nil)
                {
                    [trip appendFormat:@"From: <a href=\"http://map.google.com/?q=location@%@,%@\">%@<br></a>",
                     self.tripQuery.resultFrom.xlat, self.tripQuery.resultFrom.xlon,
                     self.tripQuery.resultFrom.xdescription
                     ];
                }
                else
                {
                    [trip appendFormat:@"%@<br>", self.fromText];
                }
            }
            
            if (self.tripQuery.resultTo != nil)
            {
                if (self.tripQuery.resultTo.xlat)
                {
                    [trip appendFormat:@"To: <a href=\"http://map.google.com/?q=location@%@,%@\">%@<br></a>",
                     self.tripQuery.resultTo.xlat, self.tripQuery.resultTo.xlon,
                     self.tripQuery.resultTo.xdescription
                     ];
                }
                else
                {
                    [trip appendFormat:@"%@<br>", self.toText];
                }
            }
            
            [trip appendFormat:@"%@:%@<br><br>", [self.tripQuery.userRequest timeType], [self.tripQuery.userRequest getDateAndTime]];
                        
            NSString *htmlText = [it startPointText:TripTextTypeHTML];
            [trip appendString:htmlText];
            
            int i;
            for (i=0; i< [it legCount]; i++)
            {
                TripLeg *leg = [it getLeg:i];
                htmlText = [leg createFromText:(i==0) textType:TripTextTypeHTML];
                [trip appendString:htmlText];
                htmlText = [leg createToText:(i==[it legCount]-1) textType:TripTextTypeHTML];
                [trip appendString:htmlText];
            }
            
            [trip appendFormat:@"Travel time: %@<br><br>",it.travelTime];
            
            if (it.fare != nil)
            {
                [trip appendFormat:@"Fare: %@<br><br>",it.fare ];
            }
            
            MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
            
            email.mailComposeDelegate = self;
            
            if (![MFMailComposeViewController canSendMail])
            {
                UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"email", @"alert title")
                                                                   message:NSLocalizedString(@"Cannot send email on this device", @"alert message")
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                         otherButtonTitles:nil];
                [alert show];
                break;
            }
            
            [email setSubject:@"TriMet Trip"];
            
            [email setMessageBody:trip isHTML:YES];
            
            [self presentViewController:email animated:YES completion:nil];
            
            
        }
            break;
        case kRowTypeMap:
        {
            TripPlannerMap *mapPage = [TripPlannerMap viewController];
            mapPage.callback = self.callback;
            mapPage.lineOptions = MapViewFitLines;
            mapPage.nextPrevButtons = YES;
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            int i,j = 0;
            for (i=0; i< [it legCount]; i++)
            {
                TripLeg *leg = [it getLeg:i];
                [leg createFromText:(i==0) textType:TripTextTypeMap];
                
                if (leg.from.mapText != nil)
                {
                    j++;
                    leg.from.index = j;
                    
                    [mapPage addPin:leg.from];
                }
                
                [leg createToText:(i==([it legCount]-1)) textType:TripTextTypeMap];
                if (leg.to.mapText != nil)
                {
                    j++;
                    leg.to.index = j;
                    
                    [mapPage addPin:leg.to];
                }
                
            }
            
            mapPage.it = it;
            
            [mapPage fetchShapesAsync:self.backgroundTask];
        }
            break;
        case kRowTypeReverse:
        {
            XMLTrips * reverse = [self.tripQuery createReverse];
            
            TripPlannerDateView *tripDate = [TripPlannerDateView viewController];
            
            tripDate.userFaves = reverse.userFaves;
            tripDate.tripQuery = reverse;
            
            // Push the detail view controller
            [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
            /*
             TripPlannerEndPointView *tripStart = [[TripPlannerEndPointView alloc] init];
             
             // Push the detail view controller
             [self.navigationController pushViewController:tripStart animated:YES];
             [tripStart release];
             */
            break;
            
        }
        case kRowTypeDetours:
        {
            NSMutableArray *allRoutes = [NSMutableArray array];
            NSString *route = nil;
            NSMutableSet *allRoutesSet = [NSMutableSet set];
            
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            
            int i = 0;
            for (i=0; i< [it legCount]; i++)
            {
                TripLeg *leg = [it getLeg:i];
                
                route = leg.xinternalNumber;
                
                if (route && ![allRoutesSet containsObject:route])
                {
                    [allRoutesSet addObject:route];
                    
                    [allRoutes addObject:route];
                }
                
            }
            
            if (allRoutes.count >0 )
            {
                [[DetoursView viewController] fetchDetoursAsync:self.backgroundTask routes:allRoutes backgroundRefresh:NO];
            }
            break;
        }
        case kRowTypeArrivals:
        {
            NSMutableString *allstops = [NSMutableString string];
            NSString *lastStop = nil;
            NSString *nextStop = nil;
            
            TripItinerary *it = [self getSafeItinerary:indexPath.section];
            
            
            int i = 0;
            int j = 0;
            for (i=0; i< [it legCount]; i++)
            {
                TripLeg *leg = [it getLeg:i];
                
                nextStop = [leg.from stopId];
                
                for (j=0; j<2; j++)
                {
                    if (nextStop !=nil && (lastStop==nil || ![nextStop isEqualToString:lastStop]))
                    {
                        if (allstops.length > 0)
                        {
                            [allstops appendFormat:@","];
                        }
                        [allstops appendFormat:@"%@", nextStop];
                        lastStop = nextStop;
                    }
                    nextStop = [leg.to stopId];
                }
            }
            
            if (allstops.length >0 )
            {
                [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask loc:allstops];
            }
            break;
        }
            
    }
}

#pragma mark Mail composer delegate

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SMS composer delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
    DEBUG_LOGL(action);
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) viewWillDisappear:(BOOL)animated
{
    if (self.userActivity!=nil)
    {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    Class userActivityClass = (NSClassFromString(@"NSUserActivity"));
    
    if (userActivityClass !=nil)
    {
        
        if (self.userActivity != nil)
        {
            [self.userActivity invalidate];
            self.userActivity = nil;
        }
        
        NSDictionary *tripItem = [self.tripQuery.userRequest toDictionary];
        
        [tripItem setValue:@"yes" forKey:kDictUserRequestHistorical];
        
        if (tripItem)
        {
            self.userActivity = [self.tripQuery.userRequest userActivityWithTitle:self.tripQuery.shortName];
            
            [self.userActivity becomeCurrent];
        }
        
    }
    
}

- (UIColor*) randomColor
{
    CGFloat red    = (double)(arc4random() % 256 ) / 255.0;
    CGFloat green  = (double)(arc4random() % 256 ) / 255.0;
    CGFloat blue   = (double)(arc4random() % 256 ) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller
{

}

- (void)addBookmarkToSiri
{
    if (@available(iOS 12.0, *))
    {
        INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:self.userActivity];
        
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

- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller
API_AVAILABLE(ios(12.0))
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}



@end


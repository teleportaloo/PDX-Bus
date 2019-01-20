//
//  RootViewController.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RootViewController.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "DepartureTimesView.h"
#import "RouteView.h"
#import "EditableTableViewCell.h"
#import "CellTextField.h"
#import "UserFaves.h"
#import "AboutView.h"
#import "SupportView.h"
#import "WebViewController.h"
#import "DetoursView.h"
#import "FindByLocationView.h"
#import "EditBookMarkView.h"
#import "FlashViewController.h"
#import "TripPlannerDateView.h"
#import "AppDelegateMethods.h"
#import "RailMapView.h"
#import "DebugLogging.h"
#import "XMLTrips.h"
#import "TripPlannerDateView.h"
#import "TripPlannerResultsView.h"
#import "TripPlannerCacheView.h"
#import "DepartureHistoryView.h"
#import "WhatsNewView.h"
#import "TripPlannerSummaryView.h"
#import "AllRailStationView.h"
#import "AlarmViewMinutes.h"
#import "AlarmAccurateStopProximity.h"
#import "LocationServicesDebugView.h"
#import "VehicleLocatingTableView.h"
#import "DirectionView.h"

#import "TripPlannerLocatingView.h"
#import "QrCodeReaderViewController.h"

#import "ProgressModalView.h"
#import "BlockColorDb.h"

#import "AddressBook/AddressBook.h"
#import <AddressBook/ABPerson.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import "RailStationTableView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WatchConnectivity/WatchConnectivity.h"
#import "WatchAppContext.h"
#import "StringHelper.h"
#import "CLLocation+Helper.h"
#import <Intents/Intents.h>
#import "MainQueueSync.h"
#import "KMLRoutes.h"
#import "VehicleIdsView.h"
#import "CLLocation+Helper.h"

enum SECTIONS_AND_ROWS
{
    kTableSectionStopId,
    kTableSectionVehicleId,
    
    kTableSectionFaves,
    kTableSectionAbout,
    kTableSectionPlanner,
    kTableSectionAlarms,
    kTableSectionTriMet,
    
    kTableTriMetDetours,
    kTableTriMetLink,
    kTableTriMetFacebook,
    kTableTriMetCustomerService,
    kTableTriMetCall,
    kTableTriMetTweet,
    kTableTriMetTicketApp,
    kTableStreetcarTweet,
    
    kTableAboutSettings,
    kTableAboutRowAbout,
    kTableAboutSupport,
    kTableAboutFacebook,
    kTableAboutRate,
    
    kTableFindRowId,
    kTableFindRowBrowse,
    kTableFindRowLocate,
    kTableFindRowRailStops,
    kTableFindRowRailMap,
    kTableFindRowQR,
    kTableFindRowHistory,
    kTableFindRowVehicle,
    kTableFindRowVehicleId,
    
    kTableFaveBookmark,
    kTableFaveButtons,
    kTableFaveAddStop,
    kTableFaveAddTrip,
    kTableFaveAddTakeMeHome
    
};


enum TRIP_ROWS
{
    kTableTripRowPlanner,
    kTableTripRowCache,
    kTableTripRows
};

#define kUIEditHeight            50.0
#define kUIRowHeight            40.0

#define kTextFieldId            @"TextField"
#define kAboutId                @"AboutLink"
#define kPlainId                @"Plain"
#define kAlarmCellId            @"Alarm"




#define kSearchItemBookmark @"org.teleportaloo.pdxbus.bookmark"

// #define LOADINGSCREEN


@implementation RootViewController


#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style
{
    return UITableViewStyleGrouped;
}


- (CGFloat)heightOffset
{
    return -[UIApplication sharedApplication].statusBarFrame.size.height;
}


- (bool)neverAdjustContentInset
{
    return YES;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems removeAllObjects];
    bool spaceNeeded = NO;
    
    
    if ([UserPrefs sharedInstance].locateToolbarIcon)
    {
        [toolbarItems addObject:[UIToolbar locateButtonWithTarget:self  action:@selector(autoLocate:)]];
        spaceNeeded = YES;
    }
    
    if ([UserPrefs sharedInstance].commuteButton)
    {
        if (spaceNeeded)
        {
            [toolbarItems addObject:[UIToolbar flexSpace]];
        }
        [toolbarItems addObject:[UIToolbar commuteButtonWithTarget:self action:@selector(commuteAction:)]];
        spaceNeeded = YES;
    }
    
    if (self.videoCaptureSupported && [UserPrefs sharedInstance].qrCodeScannerIcon)
    {
        if (spaceNeeded)
        {
             [toolbarItems addObject:[UIToolbar flexSpace]];
        }
        [toolbarItems addObject:[UIToolbar qrScannerButtonWithTarget:self action:@selector(QRScannerAction:)]];
        spaceNeeded = YES;
    }
    
    if ([UserPrefs sharedInstance].ticketAppIcon)
    {
        if (spaceNeeded)
        {
             [toolbarItems addObject:[UIToolbar flexSpace]];
        }
        [toolbarItems addObject:[self ticketAppButton]];
        spaceNeeded = YES;
    }
    
    [self maybeAddFlashButtonWithSpace:spaceNeeded buttons:toolbarItems big:YES];
    
    
    if (self.goButton==nil)
    {
        self.goButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                       target:self
                                                                       action:@selector(editGoAction:)];
    }
    
    
    if (self.helpButton==nil)
    {
        self.helpButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help", @"button text")
                                                            style:UIBarButtonItemStylePlain
                                                           target:self action:@selector(helpAction:)];
    }
}

#pragma mark UI Helper functions

- (void)delayedQRScanner:(NSObject *)arg
{
    QrCodeReaderViewController* qrView = [[ QrCodeReaderViewController alloc ] init ];
    
    [self presentViewController:qrView animated:YES completion:nil];
}

- (bool)QRCodeScanner
{
    if (self.videoCaptureSupported)
    {
        QrCodeReaderViewController* qrView = [[ QrCodeReaderViewController alloc ] init ];
        
        [self.navigationController pushViewController:qrView animated:YES];
        
    }
    else {
        UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:nil
                                                           message:@"QR Scanning is not supported in this version of iOS. :-("
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil ];
        [alert show]; 
        return NO;
    }
    return YES;
}

- (NSString *)addressFromMapItem:(MKMapItem *)mapItem
{
    if (mapItem.name != nil)
    {
        return mapItem.name;
    }
    
    NSMutableString *address = [NSMutableString string];
    
    if (mapItem.placemark.addressDictionary != nil)
    {
        // NSDictionary *dict = mapItem.placemark.addressDictionary;
       
        CFDictionaryRef dict =  (__bridge CFDictionaryRef)mapItem.placemark.addressDictionary;

        NSString* item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
    
        if (item && item.length > 0)
        {
            [address appendString:item];
        }
    
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCityKey);
    
        if (item && item.length > 0)
        {
            if (address.length > 0)
            {
                [address appendString:@", "];
            }
            [address appendString:item];
        }
    
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStateKey);
        
        if (item && item.length > 0)
        {
            if (address.length > 0)
            {
                [address appendString:@","];
            }
            [address appendString:item];
    
    
        }
        return address;
    }
    
    return nil;

}

- (void)launchTripPlannerFromAppleURL
{
    MKDirectionsRequest* directionsInfo = [[MKDirectionsRequest alloc] initWithContentsOfURL:self.routingURL];
    
    self.routingURL = nil;
    
    TripPlannerLocatingView * locView = [TripPlannerLocatingView viewController];
    
    XMLTrips *query = [XMLTrips xml];
    
    if (directionsInfo.source.isCurrentLocation)
    {
        query.userRequest.fromPoint.useCurrentLocation = YES;
    }
    else
    {
        query.userRequest.fromPoint.locationDesc = [self addressFromMapItem:directionsInfo.source];
        query.userRequest.fromPoint.coordinates = directionsInfo.source.placemark.location;
        DEBUG_LOG(@"From desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }
    
    if (directionsInfo.destination.isCurrentLocation)
    {
        query.userRequest.toPoint.useCurrentLocation = YES;
    }
    else
    {
        query.userRequest.toPoint.locationDesc = [self addressFromMapItem:directionsInfo.destination];
        query.userRequest.toPoint.coordinates = directionsInfo.destination.placemark.location;
        DEBUG_LOG(@"To desc: %@\n", query.userRequest.fromPoint.locationDesc);
    }
    
    
    query.userRequest.timeChoice = TripDepartAfterTime;
    query.userRequest.dateAndTime = [NSDate date];
    
    locView.tripQuery = query;
    
    [locView nextScreen:self.navigationController forceResults:NO postQuery:NO
            orientation:[UIApplication sharedApplication].statusBarOrientation
          taskContainer:self.backgroundTask];
}

- (void)launchTripPlannerFromRouteURL
{
    NSString *strUrl = self.routingURL.absoluteString;
    
    
    self.routingURL = nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:strUrl];
    NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
    NSCharacterSet *ampersand = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSCharacterSet *equalsOrAmpersand = [NSCharacterSet characterSetWithCharactersInString:@"=&"];
    
    
    NSString *section;
    NSString *protocol;
    NSString *value;
    
    NSString *from_lon = nil;
    NSString *from_lat = nil;
    NSString *from_name = nil;
    NSString *to_lon = nil;
    NSString *to_lat = nil;
    NSString *to_name = nil;
    bool from_here = NO;
    bool to_here   = NO;
    
    
    
    
    // skip up to first colon
    [scanner scanUpToCharactersFromSet:colon intoString:&protocol];
    
    if (scanner.atEnd)
    {
        DEBUG_LOG(@"Badly formed route URL %@ - no :\n",strUrl);
        return;
    }
    
    scanner.scanLocation++;
       
    // Skip slashes
    while (!scanner.atEnd && [strUrl characterAtIndex:scanner.scanLocation] == '/')
    {
        scanner.scanLocation++;
    }
    
    if (scanner.atEnd)
    {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after :\n",strUrl);
        return;
    }
    
    [scanner scanUpToCharactersFromSet:query intoString:&section];
    
    if ([section caseInsensitiveCompare:@"route"] != NSOrderedSame)
    {
        DEBUG_LOG(@"Badly formed route URL %@ - route command missing\n",strUrl);
        return;
    }
    
    scanner.scanLocation++;
    
    if (scanner.atEnd)
    {
        DEBUG_LOG(@"Badly formed route URL %@ - nothing after route?\n",strUrl);
        return;
    }
    
    while (!scanner.atEnd)
    {
        value = nil;
        
        [scanner scanUpToCharactersFromSet:equalsOrAmpersand intoString:&section];
        
        if (!scanner.atEnd)
        {
            if ([strUrl characterAtIndex:scanner.scanLocation] == '=')
            {
                scanner.scanLocation++;
                
                if (scanner.atEnd)
                {
                    DEBUG_LOG(@"Badly formed route URL %@ - nothing after =\n",strUrl);
                    return;
                }
                
                [scanner scanUpToCharactersFromSet:ampersand intoString:&value];
                
                
                if (!scanner.atEnd)
                {
                    scanner.scanLocation++;
                }

            }
            else
            {
                scanner.scanLocation++;
            }
        }
        
        
        if ([section caseInsensitiveCompare:@"from_lon"] == NSOrderedSame && value!=nil)
        {
            from_lon = value.stringByRemovingPercentEncoding;;
        }
        else if ([section caseInsensitiveCompare:@"to_lon"] == NSOrderedSame && value!=nil)
        {
            to_lon = value.stringByRemovingPercentEncoding;;
        }
        else if ([section caseInsensitiveCompare:@"from_lat"] == NSOrderedSame && value!=nil)
        {
            from_lat = value.stringByRemovingPercentEncoding;;
        }
        else if ([section caseInsensitiveCompare:@"to_lat"] == NSOrderedSame && value!=nil)
        {
            to_lat = value.stringByRemovingPercentEncoding;;
        }
        else if ([section caseInsensitiveCompare:@"from_name"] == NSOrderedSame && value!=nil)
        {
            from_name = value.stringByRemovingPercentEncoding;
        }
        else if ([section caseInsensitiveCompare:@"to_name"] == NSOrderedSame && value!=nil)
        {
            to_name = value.stringByRemovingPercentEncoding;
        }
        else if ([section caseInsensitiveCompare:@"from_here"] == NSOrderedSame)
        {
            from_here = YES;
        }
        else if ([section caseInsensitiveCompare:@"to_here"] == NSOrderedSame)
        {
            to_here = YES;
        }
    }
    
    bool error = false;
    if (from_name == nil && (from_lat == nil || from_lon == nil) && !from_here)
    {
        error = true;
    }
    
    if (to_name == nil && (to_lat == nil || to_lon == nil) && !to_here)
    {
        error = true;
    }

    if (from_here && (from_lat != nil || from_lon !=nil || from_name != nil))
    {
        error = true;
    }
    
    if (to_here && (to_lat != nil || to_lon !=nil || to_name != nil))
    {
        error = true;
    }
    
    if (to_here && from_here)
    {
        error = true;
    }
    
    if (error)
    {
        DEBUG_LOG(@"Badly formed route URL %@ - bad value from_name %@ from_lat %@ from_lon %@ to_name %@ to_lat %@ to_lon %@ from_here %d to_here %d\n",
                  strUrl,
                  from_name, from_lat, from_lon,
                  to_name, to_lat, to_lon,
                  (int)from_here, (int)to_here
                  );
        return;
    }
    
    DEBUG_LOG(@"Route URL %@ - from_name %@ from_lat %@ from_lon %@ to_name %@ to_lat %@ to_lon %@ from_here %d to_here %d\n",
              strUrl,
              from_name, from_lat, from_lon,
              to_name, to_lat, to_lon,
              (int)from_here,
              (int)to_here
              );
    
    TripPlannerLocatingView * locView = [TripPlannerLocatingView viewController];
    
    XMLTrips *tripQuery = [XMLTrips xml];
    
    tripQuery.userRequest.fromPoint.locationDesc = from_name;
    
    if (from_lat!=nil && from_lon!=nil)
    {
        tripQuery.userRequest.fromPoint.coordinates = [CLLocation fromStringsLat:from_lat lng:from_lon];
    }
    tripQuery.userRequest.toPoint.locationDesc = to_name;
    
    if (to_lat!=nil && to_lon!=nil)
    {
        tripQuery.userRequest.toPoint.coordinates = [CLLocation fromStringsLat:to_lat lng:to_lon];
    }
    
    if (from_here)
    {
        tripQuery.userRequest.fromPoint.useCurrentLocation = YES;
    }
    
    if (to_here)
    {
        tripQuery.userRequest.toPoint.useCurrentLocation = YES;
    }
    
    tripQuery.userRequest.timeChoice = TripDepartAfterTime;
    tripQuery.userRequest.dateAndTime = [NSDate date];
    
    locView.tripQuery = tripQuery;
    
    [locView nextScreen:self.navigationController forceResults:NO postQuery:NO
            orientation:[UIApplication sharedApplication].statusBarOrientation
          taskContainer:self.backgroundTask];
}

- (void)launchTripPlannerFromURL
{
    Class dirClass = (NSClassFromString(@"MKDirectionsRequest"));
    
    if (dirClass && [MKDirectionsRequest isDirectionsRequestURL:self.routingURL]) {
        [self launchTripPlannerFromAppleURL];
    }
    else
    {
        [self launchTripPlannerFromRouteURL];
    }
    

}

- (void)launchFromURL
{
    [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                loc:self.launchStops
                                                              title:@"Launching..."];
    self.launchStops = nil;
}


- (void)QRScannerAction:(id)sender
{
    [self QRCodeScanner];
}

- (void)autoLocate:(id)sender
{
    if (self.initialActionArgs)
    {
        FindByLocationView *findView = [[FindByLocationView alloc] init];
        
        [findView actionArgs:self.initialActionArgs];
        self.initialActionArgs = nil;
        
        [self.navigationController pushViewController:findView animated:YES];
    }
    else if ([UserPrefs sharedInstance].autoLocateShowOptions)
    {
        // Push the detail view controller
        [self.navigationController pushViewController:[FindByLocationView viewController] animated:YES];
    }
    else
    {
        FindByLocationView *findView = [[FindByLocationView alloc] init];
        
        [findView actionArgs:@{}];
        
        // Push the detail view controller
        [self.navigationController pushViewController:findView animated:YES];
    }

    
}

- (void)commuteAction:(id)sender
{
    
    NSDictionary *commuteBookmark = [[SafeUserData sharedInstance] checkForCommuterBookmarkShowOnlyOnce:NO];
    
    if (commuteBookmark!=nil)
    {
        [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                          loc:commuteBookmark[kUserFavesLocation]
                                                                        title:commuteBookmark[kUserFavesChosenName]
         ];
    }
    else {
        UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Commute", @"alert title")
                                                           message:NSLocalizedString(@"No commuter bookmark was found for the current day of the week and time. To create a commuter bookmark, edit a bookmark to set which days to use it for the morning or evening commute.", @"alert text")
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                 otherButtonTitles:nil ];
        [alert show];
    }
}

- (void)helpAction:(id)sender
{
    // Push the detail view controller
    [self.navigationController pushViewController:[SupportView viewController] animated:YES];
}

- (void)executeInitialAction
{
    // DEBUG_PRINTF("Last arrivals: %s", [self.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding]);
    DEBUG_LOGB(self.commuterBookmark);
    
    if (!self.viewLoaded)
    {
        self.delayedInitialAction = YES;
        return;
    }

    NSDateComponents *nowDateComponents =  [[NSCalendar currentCalendar] components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYear)
                                                                           fromDate:[NSDate date]];
    
    
    bool showHelp     = [self newVersion:@"lastRun.plist"  version:kAboutVersion];
    bool showWhatsNew = [self newVersion:@"whatsNew.plist" version:[WhatsNewView version]];
    
    // The stations need to be re-indexed every so often or they will exipire
    // I'm making it so we do it every week
    bool reIndexStations = [self newVersion:@"stationIndex.plist" version:
                            [NSString stringWithFormat:@"%@ %d %d %d",
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                             (int)[UserPrefs sharedInstance].searchStations,
                             (int)nowDateComponents.weekOfYear,
                             (int)nowDateComponents.year]];
    
    if (reIndexStations)
    {
        [[AllRailStationView viewController] indexStations];
    }
    
    if (showHelp)
    {
        [self.navigationController pushViewController:[SupportView viewController] animated:NO];
    }
    else  if (showWhatsNew)
    {
        [TriMetXML deleteCacheFile];
        [KMLRoutes deleteCacheFile];
        [self.navigationController pushViewController:[WhatsNewView viewController] animated:NO];
    }
    else if (self.routingURL)
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        [self launchTripPlannerFromURL];
    }
    else if (self.launchStops)
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        [self launchFromURL];
    }
    else if (self.commuterBookmark)
    {
        [_userData clearLastArrivals];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        DEBUG_LOG(@"popToRootViewControllerAnimated");
        
        
        [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                          loc:self.commuterBookmark[kUserFavesLocation]
                                                                        title:self.commuterBookmark[kUserFavesChosenName]];
        _showingLast = true;
        self.commuterBookmark = nil;
    }
    else if (self.initialAction == InitialAction_TripPlanner)
    {
        [self tripPlanner:YES];
    }
    else if (self.initialAction == InitialAction_Commute)
    {
        [self commuteAction:nil];
    }
    else if (self.initialAction == InitialAction_Locate)
    {
        [self autoLocate:nil];
    }
    else if (self.initialAction == InitialAction_QRCode)
    {
        [self QRCodeScanner];
    }
    else if (self.initialAction == InitialAction_BookmarkIndex)
    {
        [self openFave:self.initialBookmarkIndex allowEdit:NO];
    }
    else if (self.initialAction == InitialAction_UserActivityBookmark)
    {
        [self openUserActivityBookmark:self.initialActionArgs];
        self.initialActionArgs = nil;
    }
    else if (self.initialAction == InitialAction_UserActivitySearch)
    {
        [self openSearchItem:self.initialActionArgs];
        self.initialActionArgs = nil;
    }
    
    else if (self.initialBookmarkName != nil)
    {
        bool found = NO;
        int foundItem = 0;
        @synchronized (_userData)
        {
            for (int i=0; i< _userData.faves.count; i++)
            {
                NSMutableDictionary *item = (NSMutableDictionary *)(_userData.faves[i]);
                NSString *name = item[kUserFavesChosenName];
                if (name!=nil && [self.initialBookmarkName isEqualToString:name])
                {
                    found = YES;
                    foundItem = i;
                    break;
                }
            }
        }
        if (found)
        {
            [self openFave:foundItem allowEdit:NO];
        }
    }
    else
    {
        // Reload just in case the user changed the settings outside the app
        [self reloadData];
        [self updateToolbar];
    }
    
    self.delayedInitialAction = NO;
    self.initialAction = InitialAction_None;
    self.initialBookmarkName = nil;
}

- (UITextField *)createTextField_Rounded
{
    CGRect frame = CGRectMake(30.0, 0.0, 50.0, [CellTextField editHeight]);
    UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];
    
    returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = NSLocalizedString(@"<enter stop ID>", @"default text");
    returnTextField.backgroundColor = [UIColor whiteColor];
    returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;    // no auto correction support
    
    returnTextField.keyboardType = UIKeyboardTypeNumberPad;
    returnTextField.returnKeyType = UIReturnKeyGo;
    
    returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;    // has a clear 'x' button to the right
    self.editWindow = returnTextField;
    
    return returnTextField;
}

-(void)tripPlanner:(bool)animated
{    
    
    TripPlannerSummaryView *tripStart = [TripPlannerSummaryView viewController];
//    tripStart.from = true;
    // tripStart.tripQuery = self.tripQuery;
    
    // tripStart.tripQuery.userFaves = self.userFaves;
    @synchronized (_userData)
    {
        [tripStart.tripQuery addStopsFromUserFaves:_userData.faves];
    }
    
    // Push the detail view controller
    [self.navigationController pushViewController:tripStart animated:YES];
}

- (void)updatePlaceholderRows:(bool)add
{
    NSArray *indexPaths = @[
                           [NSIndexPath indexPathForRow:_userData.faves.count inSection:_faveSection],
                           [NSIndexPath indexPathForRow:_userData.faves.count+1 inSection:_faveSection],
                           [NSIndexPath indexPathForRow:_userData.faves.count+2 inSection:_faveSection]
                           ];
    
//    NSInteger rows = [self.table numberOfRowsInSection:faveSection];
    
    NSInteger addRow = [self firstRowOfType:kTableFaveAddStop inSection:_faveSection];
    
    if (add && addRow == kNoRowSectionTypeFound) {
        // Show the placeholder rows
        
        [self clearSection:_faveSection];
        
        [self addRowType:kTableFaveAddStop  forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTrip  forSectionType:kTableSectionFaves];
        [self addRowType:kTableFaveAddTakeMeHome  forSectionType:kTableSectionFaves];
        
        [self addRowType:kTableFaveButtons  forSectionType:kTableSectionFaves];
        
        
        [self.table insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        
    } else if (!add) { // && (_userData.faves).count!=0) {
        
        [self clearSection:_faveSection];
        [self addRowType:kTableFaveButtons forSectionType:kTableSectionFaves];
        
        [self.table deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    
    [self setEditBookmarksButtonTitle];
}


- (void)editGoAction:(id)sender
{
    [self.editWindow resignFirstResponder];
}


// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
    _keyboardUp = YES;
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                      target:self
                                      action:@selector(cancelAction:)];
    
    
    
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = self.goButton;
    
    
    [self.table scrollToRowAtIndexPath:[NSIndexPath 
                                        indexPathForRow:[self firstRowOfType:kTableFindRowId inSection:_editSection]
                                        inSection:_editSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    
    return YES;
}

#pragma mark View methods


- (void)addStopIdRows
{
    [self addRowType:kTableFindRowId];
    [self addRowType:kTableFindRowLocate];
    [self addRowType:kTableFindRowBrowse];
    [self addRowType:kTableFindRowRailMap];
    

    
    if (self.videoCaptureSupported)
    {
        [self addRowType:kTableFindRowQR];
    }
    
    if ([UserPrefs sharedInstance].maxRecentStops != 0)
    {
        [self addRowType:kTableFindRowHistory];
    }
}


- (NSInteger)rowType:(NSIndexPath *)indexPath
{
    NSInteger sectionType = [self sectionType:indexPath.section];
    
    if (sectionType == kTableSectionFaves)
    {
        if (indexPath.row < _userData.faves.count)
        {
            return kTableFaveBookmark;
        }
        return [super rowType:[NSIndexPath indexPathForRow:(indexPath.row - _userData.faves.count) inSection:indexPath.section]];
    }
    
    return [super rowType:indexPath];
    
}

- (void)mapSections
{
    [self clearSectionMaps];
    
    if (_taskList)
    {
        self.alarmKeys = _taskList.taskKeys;
    }
    
    if ([UserPrefs sharedInstance].bookmarksAtTheTop)
    {
        
        if (self.alarmKeys!=nil && self.alarmKeys.count>0)
        {
            [self addSectionType:kTableSectionAlarms];
        }
        
        _faveSection = [self addSectionType:kTableSectionFaves];
        if (self.editing)
        {
            [self addRowType:kTableFaveAddStop];
            [self addRowType:kTableFaveAddTrip];
            [self addRowType:kTableFaveAddTakeMeHome];
        }
        
        [self addRowType:kTableFaveButtons];
        _editSection = [self addSectionType:kTableSectionStopId];
        [self addStopIdRows];
        [self addSectionType:kTableSectionPlanner];
        
    }
    else
    {
        if (_taskList!=nil && _taskList.taskCount>0)
        {
            [self addSectionType:kTableSectionAlarms];
        }
        _editSection = [self addSectionType:kTableSectionStopId];
        [self addStopIdRows];
        [self addSectionType:kTableSectionPlanner];
        _faveSection = [self addSectionType:kTableSectionFaves];
        if (self.editing)
        {
            [self addRowType:kTableFaveAddStop];
            [self addRowType:kTableFaveAddTrip];
            [self addRowType:kTableFaveAddTakeMeHome];
        }
        [self addRowType:kTableFaveButtons];
    }
    
    if ([UserPrefs sharedInstance].vehicleLocations)
    {
        [self addSectionType:kTableSectionVehicleId];

        [self addRowType:kTableFindRowVehicle];
        [self addRowType:kTableFindRowVehicleId];
    }
    
    [self addSectionType:kTableSectionTriMet];
    [self addRowType:kTableTriMetDetours];
    [self addRowType:kTableTriMetTweet];
    [self addRowType:kTableStreetcarTweet];
    [self addRowType:kTableTriMetFacebook];
    
    if ([UserPrefs sharedInstance].ticketAppIcon)
    {
        [self addRowType:kTableTriMetTicketApp];
    }
    [self addRowType:kTableTriMetLink];
    
    if ([self canCallTriMet])
    {
        [self addRowType:kTableTriMetCall];
    }
    [self addRowType:kTableTriMetCustomerService];
    
    
    [self addSectionType:kTableSectionAbout];
    [self addRowType:kTableAboutSettings];
    [self addRowType:kTableAboutRowAbout];
    [self addRowType:kTableAboutSupport];
    [self addRowType:kTableAboutFacebook];
    [self addRowType:kTableAboutRate];
}


- (bool)initMembers
{
    bool result = [super initMembers];
    
    if ([AlarmTaskList supported])
    {
        _taskList = [AlarmTaskList sharedInstance];
    }
    
    if (self.session == nil)
    {
        Class wcClass = (NSClassFromString(@"WCSession"));
        
        if (wcClass)
        {
            
            if ([WCSession isSupported]) {
                self.session  = [WCSession defaultSession];
                self.session .delegate = self;
                [self.session  activateSession];
            }
        }
    }
    
    return result;
}

- (void)indexBookmarks
{
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));
    
    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable])
    {
        return;
    }
    
    CSSearchableIndex * searchableIndex = [CSSearchableIndex defaultSearchableIndex];
    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[@"bookmark"] completionHandler:^(NSError * __nullable error) {
        if (error != nil)
        {
            ERROR_LOG(@"Failed to delete bookmark index %@\n", error.description);
        }
        
        if ([UserPrefs sharedInstance].searchBookmarks)
        {
            NSDictionary *bookmark = nil;
            NSMutableArray *index = [NSMutableArray array];
            int i;
            for (i=0; i< self->_userData.faves.count; i++)
            {
                bookmark = self->_userData.faves[i];
                
                CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeText];
                attributeSet.title = bookmark[kUserFavesChosenName];
                
                
                
                if (bookmark[kUserFavesLocation] != nil)
                {
                    
                    attributeSet.contentDescription = @"Arrival bookmark";
                }
                else
                {
                    
                    attributeSet.contentDescription = @"Trip Planner bookmark";
                    
                }
                
                NSString *uniqueId = [NSString stringWithFormat:@"%@:%d", kSearchItemBookmark, i];
                
                CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId domainIdentifier:@"bookmark" attributeSet:attributeSet];
                
                [index addObject:item];
                
            }
            
            [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:index completionHandler: ^(NSError * __nullable error) {
                if (error != nil)
                {
                    ERROR_LOG(@"Failed to create bookmark index %@\n", error.description);
                }
            }];
        }
        
    }];
    
    
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([app respondsToSelector:@selector(setShortcutItems:)])
    {
        
        NSMutableArray *shortCutItems = [NSMutableArray array];
        NSDictionary *bookmark = nil;
        
        int i;
        for (i=0; i< _userData.faves.count && i < 4; i++)
        {
            bookmark = _userData.faves[i];
            UIMutableApplicationShortcutItem *aMutableShortcutItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"bookmark" localizedTitle:bookmark[kUserFavesChosenName]];
            
            if (bookmark[kUserFavesLocation] != nil)
            {
                
                aMutableShortcutItem.localizedSubtitle = NSLocalizedString(@"Arrival bookmark",@"button text");
            }
            else
            {
                
                aMutableShortcutItem.localizedSubtitle = NSLocalizedString(@"Trip Planner bookmark",@"button text");

                
            }
            
            aMutableShortcutItem.userInfo = bookmark;
            
            
            [shortCutItems addObject:aMutableShortcutItem];
            
            
        }
        
        [UIApplication sharedApplication].shortcutItems = shortCutItems;
        
    }
}

- (void)reloadData
{
    [self mapSections];
    [self setTheme];
    [super reloadData];
    [self indexBookmarks];
    [self setEditBookmarksButtonTitle];
}

- (void)loadView
{
    [self initMembers];
    [self mapSections];
    [super loadView];
    self.table.allowsSelectionDuringEditing = YES;
}

-(void)writeLastRun:(NSDictionary *)dict file:(NSString*)lastRun
{
    bool written = false;
    
    @try {
        written = [dict writeToFile:lastRun atomically:YES];
    }
    @catch (NSException *exception)
    {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason );
    }
    
    if (!written)
    {
        ERROR_LOG(@"Failed to write to %@\n", lastRun);
    }
}

- (bool)newVersion:(NSString *)file version:(NSString *)version
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    
    DEBUG_LOGS(documentsDirectory);
    
    NSString *lastRun = [documentsDirectory stringByAppendingPathComponent:file];
    NSMutableDictionary *dict = nil;
    bool newVersion = NO;
    
    if ([fileManager fileExistsAtPath:lastRun] == NO) {
        dict = [NSMutableDictionary dictionary];
        dict[kVersion] = version;
        
        [self writeLastRun:dict file:lastRun];
        
        newVersion = YES;
    }
    else {
        dict = [[NSMutableDictionary alloc] initWithContentsOfFile:lastRun];
        NSString *lastVerRun = dict[kVersion];
        if (![lastVerRun isEqualToString:version])
        {
            newVersion = YES;    
            dict[kVersion] = version;
            [self writeLastRun:dict file:lastRun];
        }
    }
    
    return newVersion;
    
}


- (void)viewDidLoad {
#ifndef LOADINGSCREEN
    self.navigationItem.leftBarButtonItem = self.editButtonItem;    
    self.title = NSLocalizedString(@"PDX Bus", @"Main Screen title");
#else
    self.title = @"Loading PDX Bus";
#endif
    
    [super viewDidLoad];
    
    if (self.delayedInitialAction)
    {
        [self executeInitialAction];
        self.delayedInitialAction = NO;
    }
    
    if (@available(ios 12.0, *))
    {
        [INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
        
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    DEBUG_LOGL(self.table.contentOffset.y);
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    DEBUG_LOGL(self.table.contentOffset.y);
    [super viewWillAppear:animated];
    
    DEBUG_FUNC();

}

- (void) handleChangeInUserSettings:(id)obj
{
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        [self reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    DEBUG_LOGL(self.table.contentOffset.y);
    [super viewDidAppear:animated];
    
    DEBUG_FUNC();
    
    if (_taskList)
    {
        _taskList.observer = self;
    }
    
    if (_userData.favesChanged || !_updatedWatch)
    {
        [_userData cacheAppData];
        
        if (!_updatedWatch)
        {
            [WatchAppContext updateWatch:self.session];
        }
        _userData.favesChanged = NO;
        _updatedWatch = YES;
    }    
    
    if (!_showingLast)
    {
        [_userData clearLastArrivals];
        //[[(RootViewController *)[self.navigationController topViewController] table] reloadData];    

    }
    
#ifndef LOADINGSCREEN
    self.navigationItem.rightBarButtonItem = self.helpButton;
#endif
    
    [self reloadData];
    [self updateToolbar];
    _showingLast = false;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeInUserSettings:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
    
    
    [self iOS7workaroundPromptGap];
    
    DEBUG_FUNCEX();
}

- (void)viewWillLayoutSubviews
{
    DEBUG_LOGL(self.table.contentOffset.y);
}

- (void)viewDidDisappear:(BOOL)animated {
    if (_taskList)
    {
        _taskList.observer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    DEBUG_LOGL(self.table.contentOffset.y);
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Editing callbacks
// Set the editing state of the view controller. We pass this down to the table view and also modify the content
// of the table to insert a placeholder row for adding content when in editing mode.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.table setEditing:editing animated:animated];
    [self.table beginUpdates];
    [self updatePlaceholderRows:editing];
    [self setEditBookmarksButtonTitle];
    
    [self.table endUpdates];
    
}



- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
    UITextView *textView = (UITextView*)((CellTextField*)cell).view;
    [self postEditingAction:textView];
}


- (void)cancelAction:(id)sender
{
    self.navigationItem.rightBarButtonItem = self.helpButton;
    [self.editWindow resignFirstResponder];
}

-(void)postEditingAction:(UITextView *)textView;
{
    NSString *editText = [textView.text justNumbers];
    
    if (editText.length !=0 && (!_keyboardUp || self.navigationItem.rightBarButtonItem != self.helpButton ))
    {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        departureViewController.displayName = @"";
        [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:editText];
    }
    else if (_keyboardUp)
    {
        [self.editWindow resignFirstResponder];    
    }
    self.navigationItem.rightBarButtonItem = self.helpButton;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    _keyboardUp = NO;
}

#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self sections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    switch ([self sectionType:section])
    {
    case kTableSectionStopId:
    case kTableSectionVehicleId:
        rows = [self rowsInSection:section];
        break;
        
    case kTableSectionFaves:
        {
            NSInteger cnt = _userData.faves.count;
            // DEBUG_LOG(@"Cnt %ld Editing self %d tableview %d\n", (long)cnt, self.editing, tableView.editing);
            rows = cnt + [self rowsInSection:section];
            // DEBUG_LOG(@"Rows %ld\n", (long)rows);

            break;
        }
    case kTableSectionAlarms:
        {
            if (_taskList)
            {
                rows = self.alarmKeys.count;
            }
            break;
        }
    case kTableSectionAbout:
        rows = [self rowsInSection:section];
        break;
    case kTableSectionTriMet:
        rows = [self rowsInSection:section];
        break;
    case kTableSectionPlanner:
            
            rows = kTableTripRows;
            if ([UserPrefs sharedInstance].maxRecentTrips == 0)
            {
                rows--;
            }
            break;
    }
    // printf("Section %d rows %d\n", section, rows);
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section])
    {
        case kTableSectionStopId:
            return NSLocalizedString(@"Show arrivals for stop:",@"section header");
        case kTableSectionVehicleId:
            return NSLocalizedString(@"Locate vehicle you are on (not Streetcar)",@"section header");
        case kTableSectionAlarms:
            return NSLocalizedString(@"Alarms:",@"section header");
        case kTableSectionFaves:
            return NSLocalizedString(@"Bookmarks:",@"section header");
        case kTableSectionTriMet:
            return NSLocalizedString(@"More info from TriMet:",@"section header");
        case kTableSectionAbout:
            return NSLocalizedString(@"More app info:",@"section header");
        case kTableSectionPlanner:
            return NSLocalizedString(@"Trips:",@"section header");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = 0.0;
    
    switch ([self sectionType:indexPath.section])
    {
        case kTableSectionStopId:
        case kTableSectionVehicleId:
        {
            NSInteger rowType = [self rowType:indexPath];
            if (rowType == kTableFindRowId)
            {
                result = [CellTextField cellHeight];
            }
            else
            {
                result = [self basicRowHeight];
            }
            break;
        }
        case kTableSectionAbout:
        case kTableSectionTriMet:
            result = [self basicRowHeight];
            break;
            
        case kTableSectionFaves:
        case kTableSectionPlanner:
            result = [self basicRowHeight];
            break;

        case kTableSectionAlarms:
            result = [AlarmCell rowHeight];

            break;
    }
    return result;
}

- (void)tableView: (UITableView*)tableView willDisplayCell: (UITableViewCell*)cell forRowAtIndexPath: (NSIndexPath*)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    switch([self sectionType:indexPath.section])
    {
        case kTableSectionAlarms:
            if (indexPath.row < self.alarmKeys.count)
            {
               
                AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
                
                if (task!=nil & task.alarmState == AlarmFired)
                {
                    cell.backgroundColor =  [UIColor yellowColor];
                }
                else
                {
                    cell.backgroundColor =  [UIColor whiteColor]; 
                }
            }
            break;
            default:
            break;
    }
    
}

- (void)setEditBookmarksButtonTitle
{
    if (self.editing)
    {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Done editing", @"button text") forState:UIControlStateNormal];
    }
    else if (_userData.faves.count > 0)
    {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Edit bookmarks", @"button text") forState:UIControlStateNormal];
    }
    else
    {
        [self.editBookmarksButton setTitle:NSLocalizedString(@"Add bookmarks", @"button text") forState:UIControlStateNormal];
    }
    

    if (_userData.faves.count > 0)
    {
        [self.emailBookmarksButton setTitle:NSLocalizedString(@"Email bookmarks", @"button text") forState:UIControlStateNormal];
        self.emailBookmarksButton.enabled = YES;
    }
    else
    {
        [self.emailBookmarksButton setTitle:@"" forState:UIControlStateNormal];
        self.emailBookmarksButton.enabled = NO;
    }
    
    
}

- (void)editBookmarks:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

- (void)emailBookmarks:(id)sender
{
    {
        @synchronized (_userData)
        {
            if (_userData.faves.count > 0)
            {
                
                
                if (![MFMailComposeViewController canSendMail])
                {
                    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"email", @"alert title")
                                                                       message:NSLocalizedString(@"Cannot send email on this device", @"error message")
                                                                      delegate:nil
                                                             cancelButtonTitle:NSLocalizedString(@"OK", "button text")
                                                             otherButtonTitles:nil];
                    [alert show];
                    return;
                }
                
                
                MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
                
                email.mailComposeDelegate = self;
                
                [email setSubject:NSLocalizedString(@"PDX Bus Bookmarks", @"email subject")];
                
                NSMutableString *body = [[NSMutableString alloc] init];
                NSDictionary *item;
                
                [body appendFormat:NSLocalizedString(@"Click on a link to add a bookmark to PDXBus running on a another device.<br><br>", @"email body")];
                
                int i;
                for (i=0; i< _userData.faves.count; i++)
                {
                    
                    item = _userData.faves[i];
                    if (item[kUserFavesLocation] != nil)
                    {
                        [body appendFormat:@"<a href=\"pdxbus2://?d%@/\">%@</a> - %@<br>",
                         [self propertyListToHex:item],
                         item[kUserFavesChosenName],
                         item[kUserFavesLocation]];
                    }
                    else
                    {
                        [body appendFormat:NSLocalizedString(@"<a href=\"pdxbus2://?d%@/\">%@</a> - Trip Planner Bookmark<br>", @"email body"),
                         [self propertyListToHex:item],item[kUserFavesChosenName]];
                    }
                }
                
                [body appendFormat:@"<br><br>"];
                
                
                [body appendFormat:@"<a href = \"pdxbus2://"];
                for (i=0; i< _userData.faves.count; i++)
                {
                    item = _userData.faves[i];
                    [body appendFormat:@"?d%@/",
                     [self propertyListToHex:item]];
                }
                [body appendFormat:NSLocalizedString(@"\">Add all bookmarks</a>", @"email body")];
                
                [email setMessageBody:body isHTML:YES];
                
                [self presentViewController:email animated:YES completion:nil];
                
                DEBUG_LOG(@"BODY\n%@\n", body);
                
            }
            
        }
    }
}

#define kEditButtonTag 1
#define kEmailButtonTag 2



- (UITableViewCell *)buttonCell:(NSString*)cellId
                        buttons:(NSArray*)items
                         height:(CGFloat)height
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    static const CGFloat xgap    = 10;
    static const CGFloat ymargin = 2;
    
    CGRect tableRect = self.middleWindowRect;
    
    CGFloat width = ((tableRect.size.width - xgap*2) / items.count) - ((items.count-1) * xgap);
    
    int i = 0;
    
    for (UIButton *button in items)
    {
        CGRect buttonRect = CGRectMake(xgap +(xgap+width)*i, ymargin, width, height-(ymargin *2));
        
        button.frame = buttonRect;
        
        [cell.contentView addSubview:button];
        i++;
    }
    
    [cell layoutSubviews];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.isAccessibilityElement = NO;
    cell.backgroundView = [self clearView];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (UITableViewCell *)plainCell:(UITableView *)tableView
                         image:(UIImage*)image
                          text:(NSString*)text
                     accessory:(UITableViewCellAccessoryType)accType
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainId];
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.imageView.image = image;
    cell.textLabel.text = text;
    cell.accessoryType = accType;
    [self updateAccessibility:cell];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // DEBUG_LOG(@"cellForRowAtIndexPath %d %d\n", indexPath.section, indexPath.row);
    // [self dumpPath:@"cellForRowAtIndexPath" path:indexPath];
    
    switch([self sectionType:indexPath.section])
    {
        case kTableSectionStopId:
        case kTableSectionVehicleId:
        {
            NSInteger rowType = [self rowType:indexPath];
            switch (rowType)
            {
                case kTableFindRowId:
                {
                    if (self.editCell == nil)
                    {
                        self.editCell =  [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTextFieldId];
                        self.editCell.view = [self createTextField_Rounded];
                        self.editCell.delegate = self;
                        self.editCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        self.editCell.imageView.image = [self getIcon:kIconEnterStopID];
                        self.editCell.cellLeftOffset = 50.0;
                    }
                    // printf("kTableFindRowId %p\n", sourceCell);
                    return self.editCell;
                }
                case kTableFindRowBrowse:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconBrowse]
                                      text:NSLocalizedString(@"Lookup stop by route", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                case kTableFindRowRailMap:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconMaxMap]
                                      text:NSLocalizedString(@"Lookup rail stop from map or A-Z", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                    
                case kTableFindRowRailStops:
                {
                    
                    return [self plainCell:tableView
                                     image:[self getIcon:KIconRailStations]
                                      text:NSLocalizedString(@"Search all rail stations (A-Z)", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                case kTableFindRowVehicle:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconLocate7]
                                      text:NSLocalizedString(@"Locate the vehicle you're on", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                case kTableFindRowVehicleId:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconLocate7]
                                      text:NSLocalizedString(@"Locate the vehicle by ID", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                case kTableFindRowLocate:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconLocate7]
                                      text:NSLocalizedString(@"Locate nearby stops", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                case kTableFindRowHistory:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconArrivals]
                                      text:NSLocalizedString(@"Recent stops", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
                    
                case kTableFindRowQR:
                {
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconCameraAction7]
                                      text:NSLocalizedString(@"Scan TriMet QR Code", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                }
            }
        }
        case kTableSectionFaves:
        {
            // printf("fave row: %d count %d\n", indexPath.row, [self.userFaves count]);
            UITableViewCell *cell = nil;
            NSInteger rowType = [self rowType:indexPath];
            
            switch (rowType)
            {
                default:
                    cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
                    break;
                case kTableFaveBookmark:
                {
                    // Set up the cell
                    @synchronized (_userData)
                    {
                        NSDictionary *item = _userData.faves[indexPath.row];
                        // printf("item %p\n", item);
                        
                        cell = [self plainCell:tableView
                                         image:nil
                                          text:item[kUserFavesChosenName]
                                     accessory:UITableViewCellAccessoryDisclosureIndicator];
                        
                        
                        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        
                        if (![self validBookmark:item])
                        {
                            cell.textLabel.textColor = [UIColor redColor];
                        }

                        if (item[kUserFavesTrip] != nil)
                        {
                            cell.imageView.image = [self getFaveIcon:kIconTripPlanner];
                        }
                        else // if ([item valueForKey:kUserFavesLocation] != nil)
                        {
                            NSNumber *morning = item[kUserFavesMorning];
                            NSNumber *day     = item[kUserFavesDayOfWeek];
                            if (day && day.intValue!=kDayNever)
                            {
                                if (morning == nil || morning.boolValue)
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
                                cell.imageView.image = [self getFaveIcon:kIconFave];
                            }
                        }
                    }
                    break;
                }
                case kTableFaveAddStop:
                case kTableFaveAddTrip:
                case kTableFaveAddTakeMeHome:
                {
                    
                    cell = [self tableView:tableView cellWithReuseIdentifier:kNewBookMark];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.font = self.basicFont;
                    cell.textLabel.adjustsFontSizeToFitWidth = YES;
                    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
                    cell.editingAccessoryType = cell.accessoryType;
                    switch (rowType)
                    {
                        case kTableFaveAddStop:
                            cell.textLabel.text = NSLocalizedString(@"Add new stop", @"main menu item");
                            cell.imageView.image = [self getFaveIcon:kIconFave];
                            break;
                        case kTableFaveAddTrip:
                            cell.textLabel.text = NSLocalizedString(@"Add new trip", @"main menu item");
                            cell.imageView.image = [self getFaveIcon:kIconTripPlanner];
                            break;
                        case kTableFaveAddTakeMeHome:
                            cell.textLabel.text = NSLocalizedString(@"Add 'Take me somewhere' trip", @"main menu item");
                            cell.imageView.image = [self getFaveIcon:kIconTripPlanner];
                            break;
                    }
                    [self updateAccessibility:cell];
                    break;
                }
                case kTableFaveButtons:
                {
                    NSString *cellIdentifier = [NSString stringWithFormat:@"%@%f", kBookMarkUtil,self.screenInfo.appWinWidth];
                    
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        self.emailBookmarksButton = [UIButton buttonWithType:UIButtonTypeSystem];
                        [self.emailBookmarksButton setTitle:NSLocalizedString(@"Email bookmarks", @"button text") forState:UIControlStateNormal];
                        [self.emailBookmarksButton addTarget:self action:@selector(emailBookmarks:) forControlEvents:UIControlEventTouchUpInside];
                        self.emailBookmarksButton.tag = kEmailButtonTag;
                        
                        
                        self.editBookmarksButton = [UIButton buttonWithType:UIButtonTypeSystem];
                        
                        [self.editBookmarksButton addTarget:self action:@selector(editBookmarks:) forControlEvents:UIControlEventTouchUpInside];
                        self.editBookmarksButton.tag = kEditButtonTag;
                        
                        [self setEditBookmarksButtonTitle];
                        
                        cell = [self buttonCell:cellIdentifier
                                        buttons:@[self.editBookmarksButton, self.emailBookmarksButton]
                                         height:[self basicRowHeight]];
                    }
                    else
                    {
                        self.editBookmarksButton = (UIButton*)[cell.contentView viewWithTag:kEditButtonTag];
                        self.emailBookmarksButton = (UIButton*)[cell.contentView viewWithTag:kEmailButtonTag];
                    }
                    break;
                }
            }
            
            [self updateAccessibility:cell];
            return cell;
        }
        case kTableSectionTriMet:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kAboutId];
            NSInteger rowType = [self rowType:indexPath];
            
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
            
#define ATTR(X) [X formatAttributedStringWithFont:self.basicFont]
            
            switch (rowType)
            {
                case kTableTriMetCustomerService:
                    cell.textLabel.text = NSLocalizedString(@"TriMet Customer Service", @"main menu item");
                    cell.imageView.image =  [self getIcon:kIconTriMetLink];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableTriMetCall:
                    cell.textLabel.text = NSLocalizedString(@"Call TriMet on 503-238-RIDE", @"main menu item");
                    cell.imageView.image =  [self getIcon:kIconPhone];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                case kTableTriMetLink:
                    cell.textLabel.text = NSLocalizedString(@"Visit TriMet online", @"main menu item");
                    cell.imageView.image = [self getIcon:kIconTriMetLink];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableTriMetTweet:
                    cell.textLabel.text = NSLocalizedString(@"@TriMet on Twitter", @"main menu item");
                    
                    cell.imageView.image = [self getIcon:kIconTwitter];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableStreetcarTweet:
                    cell.textLabel.text = NSLocalizedString(@"@PDXStreetcar on Twitter",@"main menu item");
                    cell.imageView.image = [self getIcon:kIconTwitter];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableTriMetTicketApp:
                    cell.textLabel.text = NSLocalizedString(@"TriMet Tickets app",@"main menu item");
                    cell.imageView.image = [self getIcon:kIconTicket];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableTriMetDetours:
                    cell.textLabel.attributedText = ATTR(NSLocalizedString(@"#RDetours, delays and closures",@"main menu item"));
                    cell.imageView.image = [self getIcon:kIconDetour];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.adjustsFontSizeToFitWidth = YES;
                    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
                    break;
                case kTableTriMetFacebook:
                    cell.textLabel.text = NSLocalizedString(@"TriMet's Facebook Page",@"main menu item");
                    cell.imageView.image = [self getIcon:kIconFacebook];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
            }
            cell.textLabel.font = self.basicFont;
            [self updateAccessibility:cell];
            return cell;
        }
        case kTableSectionAbout:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kAboutId];
            
            NSInteger rowType = [self rowType:indexPath];
            
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
            
            switch (rowType)
            {
                case kTableAboutSettings:
                    cell.textLabel.text = NSLocalizedString(@"Settings",@"main menu item");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.imageView.image = [self getIcon:kIconSettings];
                    break;
                case kTableAboutRowAbout:
                    cell.textLabel.text = NSLocalizedString(@"About & legal",@"main menu item");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.imageView.image = [self getIcon:kIconAbout];
                    break;
                case kTableAboutSupport:
                    cell.textLabel.text = NSLocalizedString(@"Help, Tips & support",@"main menu item");
                    cell.imageView.image = [self getIcon:kIconXml];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableAboutFacebook:
                    cell.textLabel.text = NSLocalizedString(@"PDX Bus Fan Page",@"main menu item");
                    cell.imageView.image = [self getIcon:kIconFacebook];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kTableAboutRate:
                    cell.textLabel.text = NSLocalizedString(@"Rate PDX Bus in the App Store",@"main menu item");
                    cell.textLabel.adjustsFontSizeToFitWidth = YES;
                    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
                    cell.imageView.image = [self getIcon:kIconAward];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            cell.textLabel.font = self.basicFont;
            [self updateAccessibility:cell];
            return cell;
        }
        case kTableSectionAlarms:
        {
            UITableViewCell *cell = nil;
            
            if (indexPath.row < self.alarmKeys.count)
            {
                AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
                
                if (task!=nil)
                {
                    NSString *cellId = [task cellReuseIdentifier:kAlarmCellId width:self.screenInfo.screenWidth];
                    cell = [tableView dequeueReusableCellWithIdentifier:cellId];
                    if (cell == nil)
                    {
                        cell = [AlarmCell tableviewCellWithReuseIdentifier:cellId];
                    }
                    
                    [task populateCell:(AlarmCell*)cell];
                    
                    cell.imageView.image = [self getIcon:task.icon];
                    
                }
            }
            
            
            
            if (cell  == nil)
            {
                cell = [self tableView:tableView cellWithReuseIdentifier:kAboutId];
                
                cell.textLabel.text = nil;
                
                cell.textLabel.text = NSLocalizedString(@"Alarm completed", @"button text");
                cell.imageView.image = nil;
                cell.accessoryType  = UITableViewCellAccessoryNone;
            }
            
            cell.textLabel.font = self.basicFont;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.editingAccessoryType = cell.accessoryType;
            [self updateAccessibility:cell];
            return cell;
        }    
        case kTableSectionPlanner:
        {
            switch( indexPath.row )
            {
                case kTableTripRowPlanner:
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconTripPlanner]
                                      text:NSLocalizedString(@"Trip planner", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
                case kTableTripRowCache:
                    return [self plainCell:tableView
                                     image:[self getIcon:kIconHistory]
                                      text:NSLocalizedString(@"Recent trips", @"main menu item")
                                 accessory:UITableViewCellAccessoryDisclosureIndicator];
            }
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

-(NSString*)propertyListToHex:(NSDictionary *)item
{
    NSError *error = nil;
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:item format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    
    LOG_NSERROR(error);
    
    if (data != nil)
    {
        NSMutableString *hex = [NSMutableString string];
        
        for (int i=0; i<data.length; i++)
        {
            [hex appendFormat:@"%02X", ((unsigned char*)data.bytes)[i]];
        }
        
        return hex;
    }
    
    return nil;
}

- (bool)validBookmark:(NSDictionary *)item
{
    NSString *location = item[kUserFavesLocation];
    NSMutableDictionary* tripItem = item[kUserFavesTrip];
    TripUserRequest *req = [TripUserRequest fromDictionary:tripItem];
    
    return !((tripItem==nil && item!=nil && ((location==nil) || (location.length == 0)))
             || (tripItem !=nil
                 && req !=nil
                 && req.fromPoint.locationDesc==nil
                 && req.fromPoint.useCurrentLocation == false)
             || (tripItem !=nil
                 && req !=nil
                 && req.toPoint.locationDesc==nil
                 && req.toPoint.useCurrentLocation == false));
}


- (void)openFave:(int)index allowEdit:(bool)allowEdit
{
    NSMutableDictionary *item = nil;
    NSString *location = nil;
    TripUserRequest *req = nil;
    NSMutableDictionary *tripItem = nil;
    
    NSInteger rowType = [self rowType:[NSIndexPath indexPathForRow:index inSection:_faveSection]];
    
    if (rowType == kTableFaveBookmark)
    {
        @synchronized (_userData)
        {
            item = (NSMutableDictionary *)(_userData.faves[index]);
            location = item[kUserFavesLocation];
            tripItem = item[kUserFavesTrip];
            req = [TripUserRequest fromDictionary:tripItem];
        }
    }
    
    DEBUG_LOGB(self.table.editing);
    
    bool validItem = [self validBookmark:item];
    
    if (    allowEdit
        &&  (self.table.editing
             || _userData.faves.count==0
             || !validItem))
    {
    
        switch (rowType)
        {
            case kTableFaveBookmark:
            {
                EditBookMarkView *edit = [EditBookMarkView viewController];
                edit.invalidItem = !validItem;
                [edit editBookMark:item item:index];
                [self.navigationController pushViewController:edit animated:YES];
                break;
            }
            case kTableFaveAddStop:
            {
                EditBookMarkView *edit = [EditBookMarkView viewController];
                [edit addBookMark];
                [self.navigationController pushViewController:edit animated:YES];
                break;
            }
            case kTableFaveAddTrip:
            {
                EditBookMarkView *edit = [EditBookMarkView viewController];
                [edit addTripBookMark];
                [self.navigationController pushViewController:edit animated:YES];
                break;
            }
            case kTableFaveAddTakeMeHome:
            {
                EditBookMarkView *edit = [EditBookMarkView viewController];
                [edit addTakeMeHomeBookMark];
                [self.navigationController pushViewController:edit animated:YES];
                break;
            }
            default:
                break;
        }
    }
    else if (location !=nil)
    {
        [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                                    loc:location
                                                                  title:item[kUserFavesChosenName]];
    }
    else
    {
        TripPlannerDateView *tripDate = [TripPlannerDateView viewController];
        
        [tripDate initializeFromBookmark:req];
        @synchronized (_userData)
        {
            [tripDate.tripQuery addStopsFromUserFaves:_userData.faves];
        }
        
        // Push the detail view controller
        [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
    }
}

- (void)openSearchItem:(NSDictionary *)item
{
    NSString *uniqueId = item[CSSearchableItemActivityIdentifier];
    
    NSScanner *scanner = [NSScanner scannerWithString:uniqueId];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSString *prefix = nil;
    
    if ([scanner scanUpToCharactersFromSet:colon intoString:&prefix])
    {
        int arg = -1;
        
        if (!scanner.atEnd)
        {
            scanner.scanLocation++;
        }
        
        if ([scanner scanInt:&arg])
        {
            if ([prefix isEqualToString:kSearchItemStation])
            {
                HOTSPOT *hotSpots = [RailMapView hotspots];
                [RailMapView initHotspotData];
                
                RailStation *station = [RailStation fromHotSpot:hotSpots+arg index:arg];
                RailStationTableView *railView = [RailStationTableView viewController];
                railView.station = station;
                railView.locationsDb = [StopLocations getDatabase];
                [self.navigationController popToRootViewControllerAnimated:NO];
                
                [railView maybeFetchRouteShapesAsync:self.backgroundTask];
                // [self.navigationController pushViewController:railView animated:YES];
            } else if ([prefix isEqualToString:kSearchItemBookmark])
            {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self openFave:arg allowEdit:NO];
            }
            else if ([prefix isEqualToString:kSearchItemRoute])
            {
                [self.navigationController popToRootViewControllerAnimated:NO];
                [[DirectionView viewController] fetchDirectionsAsync:self.backgroundTask route:[NSString stringWithFormat:@"%d", arg]];
            }
        }

    }
}

- (void)openUserActivityBookmark:(NSDictionary *)item
{
    NSString *location = item[kUserFavesLocation];
    NSMutableDictionary *tripItem = item[kUserFavesTrip];;
    NSString *block = item[kUserFavesBlock];
    
    if (location !=nil && block!=nil)
    {
        [[DepartureDetailView viewController] fetchDepartureAsync:self.backgroundTask location:location block:block backgroundRefresh:NO];
    }
    else if (location !=nil)
    {
        [[DepartureTimesView viewController] fetchTimesForLocationAsync:self.backgroundTask
                                                               loc:location
                                                             title:item[kUserFavesChosenName]];
    }
    else
    {
        TripUserRequest *req = [TripUserRequest fromDictionary:tripItem];
        
        [req clearGpsNames];
        
        TripPlannerDateView *tripDate = [TripPlannerDateView viewController];
        
        [tripDate initializeFromBookmark:req];
        @synchronized (_userData)
        {
            [tripDate.tripQuery addStopsFromUserFaves:_userData.faves];
        }
        
        // Push the detail view controller
        [tripDate nextScreen:self.navigationController taskContainer:self.backgroundTask];
    }
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationItem.rightBarButtonItem == self.goButton)
    {
        self.navigationItem.rightBarButtonItem = self.helpButton;
        [self.editWindow resignFirstResponder];
    }
    
    switch([self sectionType:indexPath.section])
    {
        case kTableSectionStopId:
        case kTableSectionVehicleId:
        {
            NSInteger rowType = [self rowType:indexPath];
            switch (rowType)
            {
                case kTableFindRowId:
                {
                    
                    UITextView *textView = (UITextView*)(self.editCell).view;
                    
                    NSString *editText = [textView.text justNumbers];
                    
                    if (editText.length == 0)
                    {
                        return;
                    }
                    
                    
                    if (_keyboardUp)
                    {
                        [self.editWindow resignFirstResponder];
                    }
                    else
                    {
                        // UITextView *textView = (UITextView*)[self.editCell view];
                        [self postEditingAction:textView];
                    }
                    break;
                }
                case kTableFindRowBrowse:
                {
                    [[RouteView viewController] fetchRoutesAsync:self.backgroundTask backgroundRefresh:NO];
                    break;
                }
                case kTableFindRowLocate:
                {
                    [self.navigationController pushViewController:[FindByLocationView viewController] animated:YES];
                    break;
                }
                case kTableFindRowVehicle:
                {
                    [self.navigationController pushViewController:[VehicleLocatingTableView viewController] animated:YES];
                    break;
                }
                case kTableFindRowVehicleId:
                {
                    [self.navigationController pushViewController:[VehicleIdsView viewController] animated:YES];
                    
                    break;
                }
                case kTableFindRowRailMap:
                {
                    [self.navigationController pushViewController:[RailMapView viewController] animated:YES];
                    break;
                }
                case kTableFindRowRailStops:
                {
                    [self.navigationController pushViewController:[AllRailStationView viewController] animated:YES];
                    break;
                    
                }
                case kTableFindRowHistory:
                {
                    [self.navigationController pushViewController:[DepartureHistoryView viewController] animated:YES];
                    break;
                }
                case kTableFindRowQR:
                {
                    if (![self QRCodeScanner])
                    {
                        [self clearSelection];
                    }
                }
            }
            
            
            break;
        }
        case kTableSectionFaves:
        {
            [self openFave:(int)indexPath.row allowEdit:YES];
            break;
        }
        case kTableSectionAlarms:
        {
            if (indexPath.row < self.alarmKeys.count)
            {
                AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
                
                if (task !=nil)
                {
                    [task showToUser:self.backgroundTask];
                }
            }
            
            break;
            
        }
        case kTableSectionTriMet:
        {
            NSInteger rowType = [self rowType:indexPath];
            
            switch (rowType)
            {
                case kTableStreetcarTweet:
                {
                    [self tweetAt:@"PDXStreetcar"];
                    break;
                }
                case kTableTriMetTweet:
                {
                    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
                    [self triMetTweetFrom:cell.imageView];
                    break;
                }
                    
                case kTableTriMetTicketApp:
                {
                    [self ticketAppFrom:[self.table cellForRowAtIndexPath:indexPath].contentView button:nil];
                    break;
                }
                    
                case kTableTriMetCall:
                {
                    [self callTriMet];
                    break;
                }
                 
                case kTableTriMetCustomerService:
                {
                    [WebViewController displayPage:@"https://trimet.org/contact/customerservice.htm"
                                              full:nil
                                         navigator:self.navigationController
                                    itemToDeselect:self
                                          whenDone:self.callbackWhenDone];
                    break;
                }
                    
                case kTableTriMetLink:
                {
                    [WebViewController displayPage:@"https://trimet.org"
                                              full:nil
                                         navigator:self.navigationController
                                    itemToDeselect:self
                                          whenDone:self.callbackWhenDone];
                    break;
                }
                case kTableTriMetDetours:
                {
                    [[DetoursView viewController] fetchDetoursAsync:self.backgroundTask];
                    break;
                }
                case kTableTriMetFacebook:
                {
                    [self facebookTriMet];
                    break;
                }
            }
        }
            break;
            
        case kTableSectionAbout:
        {
            
            NSInteger rowType = [self rowType:indexPath];
            
            switch (rowType)
            {
                case kTableAboutSettings:
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    break;
                }
                case kTableAboutRowAbout:
                {
                    [self.navigationController pushViewController:[AboutView viewController] animated:YES];
                    break;
                }
                case kTableAboutSupport:
                {
                    [self.navigationController pushViewController:[SupportView viewController] animated:YES];
                    break;
                }
                case kTableAboutRate:
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                @"https://itunes.apple.com/us/app/pdx-bus-max-streetcar-and-wes/id289814055?action=write-review"]];
                    // @"itms-apps://www.itunes.com/apps/pdx-bus-max-streetcar-and-wes/id289814055?mt=8"]];
                    [self.table deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                case kTableAboutFacebook:
                    
                {
                    [self facebook];
                    break;
                }
            }
            break;
        }
        case kTableSectionPlanner:
            if (indexPath.row == kTableTripRowPlanner)
            {
                [self tripPlanner:YES];
            }
            else
            {
                [self.navigationController pushViewController:[TripPlannerCacheView viewController] animated:YES];
            }
    }
}



 // Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    DEBUG_LOG(@"delete r %ld  s %ld\n", (long)indexPath.row, (long)indexPath.section);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        switch ([self sectionType:indexPath.section])
        {
            case kTableSectionFaves:
                @synchronized(_userData)
                {
                    [_userData.faves removeObjectAtIndex:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [_userData cacheAppData];
                    [WatchAppContext updateWatch:self.session];
                    [self setEditBookmarksButtonTitle];
                }
                break;
            case kTableSectionAlarms:
                [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
                NSMutableArray *newKeys = [NSMutableArray arrayWithArray:self.alarmKeys];
                [newKeys removeObjectAtIndex:indexPath.row];
                self.alarmKeys = newKeys;
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                
                if (self.alarmKeys.count == 0)
                {
                    [self reloadData];
                }
                break;
        }

    }    
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}


// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:indexPath.section])
    {
        case kTableSectionFaves:
            switch ([self rowType:indexPath])
            {
                case kTableFaveBookmark:
                    return UITableViewCellEditingStyleDelete;
                case kTableFaveAddStop:
                case kTableFaveAddTrip:
                case kTableFaveAddTakeMeHome:
                    return UITableViewCellEditingStyleInsert;
                case kTableFaveButtons:
                    return UITableViewCellEditingStyleNone;
            }
            return UITableViewCellEditingStyleNone;
        case kTableSectionAlarms:
            return UITableViewCellEditingStyleDelete;
            
    }
    return UITableViewCellEditingStyleNone;
}



 // Override if you support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    
    switch([self sectionType:indexPath.section])
    {
        case kTableSectionStopId:
            return NO;
        case kTableSectionFaves:
            switch ([self rowType:indexPath])
            {
                case kTableFaveButtons:
                    return NO;
                default:
                    return YES;
            }
            
        case kTableSectionAlarms:
            return YES;
        case kTableSectionAbout:
            return NO;
        default:
            return NO;
    }    
    return NO;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // printf("********HERE\n");
    NSInteger srcSection = [self sectionType:sourceIndexPath.section];
    
    int sectionMax=1;
    
    switch (srcSection)
    {
        case kTableSectionFaves:
            sectionMax = (int)_userData.faves.count;
            break;
            
    }
    
    if (proposedDestinationIndexPath.section < sourceIndexPath.section)
    {
        return [NSIndexPath 
                indexPathForRow:0
                inSection:sourceIndexPath.section];
    }
    if (proposedDestinationIndexPath.section > sourceIndexPath.section)
    {
        return [NSIndexPath 
                indexPathForRow:sectionMax-1
                inSection:sourceIndexPath.section];
    }
    if (proposedDestinationIndexPath.row >= sectionMax)
    {
        return [NSIndexPath 
                indexPathForRow:sectionMax-1
                inSection:sourceIndexPath.section];
    }
    return proposedDestinationIndexPath;
    
}

 
/*
// Have an accessory view for the second section only
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return (sectionMap[indexPath.section] == kTableSectionFaves && indexPath.row < [self.userFaves count] && self.editing) 
                ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone ;
}
*/

// Override if you support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
//    [self dumpPath:@"moveRowAtIndexPath from" path:fromIndexPath];
//    [self dumpPath:@"moveRowAtIndexPath to  " path:toIndexPath];
    
    switch ([self sectionType:fromIndexPath.section])
    {
        case kTableSectionFaves:
        {
            if ([self sectionType:toIndexPath.section] == kTableSectionFaves)
            {
                @synchronized (_userData)
                {
                    NSMutableDictionary *move = _userData.faves[fromIndexPath.row];
                
                    if (fromIndexPath.row < toIndexPath.row)
                    {
                        [_userData.faves insertObject:move atIndex:toIndexPath.row+1];
                        [_userData.faves removeObjectAtIndex:fromIndexPath.row];
                    }
                    else
                    {
                        [_userData.faves removeObjectAtIndex:fromIndexPath.row];
                        [_userData.faves insertObject:move atIndex:toIndexPath.row];
                    }
                    [_userData cacheAppData];
                    [WatchAppContext updateWatch:self.session];
                }
            }

            break;
        }
    }
//    [tableView reloadData];
}




 // Override if you support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    switch ([self sectionType:indexPath.section]) {
        case kTableSectionFaves:
        {
            NSInteger rowType = [self rowType:indexPath];
            if (rowType == kTableFaveBookmark)
            {
                return YES;
            }
            return NO;
        }
        default:
            break;
    }
    return NO;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    switch([self sectionType:indexPath.section])
    {
        case kTableSectionAlarms:
        {
            if (self.navigationItem.rightBarButtonItem == self.goButton)
            {
                self.navigationItem.rightBarButtonItem = self.helpButton;
                [self.editWindow resignFirstResponder];
            }
    
            if (indexPath.row < self.alarmKeys.count)
            {
#ifdef DEBUG_ALARMS    
                AlarmTask *task = [_taskList taskForKey:self.alarmKeys[indexPath.row]];
                LocationServicesDebugView *debugView = [[LocationServicesDebugView alloc] init];
                debugView.data = task;
                [self.navigationController pushViewController:debugView animated:YES];
#else
                [_taskList cancelTaskForKey:self.alarmKeys[indexPath.row]];
#endif
            }

            break;
            
        }
        case kTableSectionStopId:
        {
            
            UITextView *textView = (UITextView*)(self.editCell).view;
            
            NSString *editText = [textView.text justNumbers];
            
            if (editText.length == 0)
            {
                return;
            }
            
            
            if (_keyboardUp)
            {
                [self.editWindow resignFirstResponder];
            }
            else
            {
                // UITextView *textView = (UITextView*)[self.editCell view];
                [self postEditingAction:textView];
            }
            break;
        }
    }
}

#pragma mark Mail Composer callbacks

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Alarm tasks callbacks
- (void)taskUpdate:(id)task
{
    AlarmTask *realTask = (AlarmTask *)task;
    
    int alarmSection = -1;
    int i=0;
    
    // Find the alarm section
    for (i=0; i<[self sections]; i++)
    {
        if ([self sectionType:i] == kTableSectionAlarms)
        {
            alarmSection = i;
            break;
        }
    }
    
    if (alarmSection !=-1)
    {
        i=0;
        for (NSString *key in self.alarmKeys)
        {
            if ([key isEqualToString:[realTask key]])
            {
                NSIndexPath *cellIndex = [NSIndexPath indexPathForRow:i
                                                            inSection:alarmSection];
                
                
                UITableViewCell *cell = [self.table cellForRowAtIndexPath:cellIndex];
                
                if (!cell.showingDeleteConfirmation && !cell.editing)
                {
                    [self.table reloadRowsAtIndexPaths:@[cellIndex]
                                      withRowAnimation:UITableViewRowAnimationNone];
                }
                
            }
            i++;
        }
    }
}

- (void)taskStarted:(id)task
{
    
}

- (void)taskDone:(id)task
{
    if (!self.table.editing)
    {
        [self reloadData];
    }
}



- (void)didEnterBackground
{
    [self.progressView removeFromSuperview];
    self.progressView= nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.backgroundTask)
    {
        [self.backgroundTask taskCancel];
        [self.backgroundTask.progressModal removeFromSuperview];
        self.backgroundTask.progressModal= nil;
        
    };

    
}

//Watch Kit delegate


/** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
- (void)sessionDidBecomeInactive:(WCSession *)session
{
    
}

/** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
- (void)sessionDidDeactivate:(WCSession *)session
{
    
}

/** Called when any of the Watch state properties change. */
- (void)sessionWatchStateDidChange:(WCSession *)session
{
    [WatchAppContext updateWatch:self.session];
}

/** Called on the sending side after the user info transfer has successfully completed or failed with an error. Will be called on next launch if the sender was not running when the user info finished. */
- (void)session:(WCSession * __nonnull)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(nullable NSError *)error
{
    
}

/** Called on the delegate of the receiver. Will be called on startup if the user info finished transferring when the receiver was not running. */
- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo
{
    if (userInfo !=nil)
    {
        NSDictionary *recent = userInfo[@"recent"];
        
        if (recent)
        {
            NSString *locId = recent[kUserFavesLocation];
            NSString *desc  = recent[kUserFavesOriginalName];
            
            if (locId && desc)
            {
                [[SafeUserData sharedInstance] addToRecentsWithLocation:locId description:desc];
            }
            
        }
    }
}

@end


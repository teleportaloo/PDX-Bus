//
//  SupportViewController.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "SupportViewController.h"
#import "AboutViewController.h"
#import "BackgroundDownloader.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "BoxedIcon.h"
#import "DebugLogging.h"
#import "Icons.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "NearestVehiclesMapViewController.h"
#import "PDXBus-Swift.h"
#import "PDXBusAppDelegate+Methods.h"
#import "QueryCacheManager.h"
#import "RootViewController.h"
#import "TableViewControllerWithToolbar.h"
#import "TaskDispatch.h"
#import "TaskState.h"
#import "TextViewLinkCell.h"
#import "TriMetInfo+UI.h"
#import "TriMetXML.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UITableViewCell+Icons.h"
#import "WebViewController.h"
#import "WhatsNewViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

#define kBytesToKB(B) ((double)(B) / 1024)
#define kBytesToMB(B) (((double)(B)) / (1024 * 1024))
#define kBytesBigSize(B)                                                                           \
    ((kBytesToKB(B) > 512) ? [NSString stringWithFormat:@"%.2f MB", kBytesToMB(B)]                 \
                           : [NSString stringWithFormat:@"%.2f KB", kBytesToKB(B)])
#define kBytesSize(B)                                                                              \
    (((B) <= 1024) ? [NSString stringWithFormat:@"%i bytes", (int)(B)] : kBytesBigSize(B))

enum {
    kSectionSupport,
    kSectionTips,
    kSectionLinks,
    kSectionTriMet,
    kSectionTriMetCall,
    kSectionTriMetSupport,
    kSectionStreetcarSupport,
    kSectionTriMetBluesky,
    kSectionRowNetwork,
    kSectioniCloud,
    kRowWriteToiCloud,
    kRowReadFromiCloud,
    kRowDeleteiCloud,
    kSectionRowCache,
    kSectionRowShapeCache,
    kSectionRowHighlights,
    kSectionRowWatch,
    kSectionRowWatchInfo,
    kSectionRowShortcuts,
    kRowShortcutDocumentation,
    kSectionRowLocations,
    kSectionPrivacy,
    kSectionSupportRowSupport,
    kSectionSupportRowNew,
    kSectionSupportRowTip,
    kSectionSupportHowToRide,
    kSectionLinkBlog,
    kSectionLinkBluesky,
    kSectionLinkInstagram,
    kSectionLinkFacebook,
    kSectionLinkGitHub,
    kSectionPrivacyRowLocation,
    kSectionPrivacyRowCamera,
    kSectionRowTip
};

@interface SupportViewController () {
    NSString *_supportText;
    NSArray<NSString *> *_tipText;

    bool _cameraGoesToSettings;
    bool _locationGoesToSettings;
}

@property (nonatomic, strong) CLLocationManager *locMan;
@property (nonatomic, copy) NSString *locationText;
@property (nonatomic, copy) NSString *cameraText;

@end

@implementation SupportViewController

#pragma mark Helper functions

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Help and Support", @"page title");

        [self makeText];

        [self createLocationText];
        [self createCameraText];

        _locMan = [[CLLocationManager alloc] init];

        [_locMan requestAlwaysAuthorization];

        _locMan.delegate = self;

        [self clearSectionMaps];

        [self addSectionType:kSectionSupport];
        [self addRowType:kSectionSupportRowSupport];
        [self addRowType:kSectionSupportRowNew];
        [self addRowType:kSectionSupportRowTip];

        [self addSectionType:kSectionTriMet];
        [self addRowType:kSectionSupportHowToRide];

        if ([self canCallTriMet]) {
            [self addRowType:kSectionTriMetCall];
        }

        [self addRowType:kSectionTriMetSupport];
        [self addRowType:kSectionTriMetBluesky];
        [self addRowType:kSectionStreetcarSupport];

        [self addSectionType:kSectionTips];
        [self addRowType:kSectionRowTip count:_tipText.count];

        [self addSectionType:kSectionLinks];
        [self addRowType:kSectionLinkBlog];

        [self addRowType:kSectionLinkBluesky];
        [self addRowType:kSectionLinkInstagram];
        [self addRowType:kSectionLinkFacebook];
        [self addRowType:kSectionLinkGitHub];

        [self addSectionType:kSectionRowNetwork];
        [self addRowType:kSectionRowNetwork];

        [self addSectionType:kSectionRowCache];
        [self addRowType:kSectionRowCache];

        if (Settings.kmlRoutes) {
            [self addRowType:kSectionRowShapeCache];
        }

#if !TARGET_OS_MACCATALYST
        [self addSectionType:kSectionRowShortcuts];
        [self addRowType:kSectionRowShortcuts];
        [self addRowType:kRowShortcutDocumentation];
#endif // !TARGET_OS_MACCATALYST

        if (Settings.iCloudToken != nil) {
            [self addSectionType:kSectioniCloud];
            [self addRowType:kRowWriteToiCloud];
            [self addRowType:kRowReadFromiCloud];
            [self addRowType:kRowDeleteiCloud];
        }

        [self addSectionType:kSectionRowHighlights];
        [self addRowType:kSectionRowHighlights];

        [self addSectionType:kSectionRowWatch];
        [self addRowType:kSectionRowWatch];
        [self addRowType:kSectionRowWatchInfo];

        [self addSectionType:kSectionRowLocations];
        [self addRowType:kSectionRowLocations];

        [self addSectionType:kSectionPrivacy];

        [self addRowType:kSectionPrivacyRowLocation];
        [self addRowType:kSectionPrivacyRowCamera];
    }

    return self;
}

- (void)dealloc {
    DEBUG_FUNC();
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)reloadData {
    [super reloadData];
    [self makeText];
}

#pragma mark Table view methods

- (void)createCameraText {
    _cameraGoesToSettings = NO;

    AVAuthorizationStatus authStatus =
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    switch (authStatus) {
    default:
    case AVAuthorizationStatusAuthorized:
        self.cameraText = @"Camera access is authorized. Touch here to check settings.";
        _cameraGoesToSettings = YES;
        break;

    case AVAuthorizationStatusNotDetermined:
        self.cameraText = @"Camera access has not been set up by the user. "
                          @"Touch here to set this up.";
        break;

    case AVAuthorizationStatusDenied:
        self.cameraText = @"Camera access has been denied by the user. Touch here to go to "
                          @"the settings app re-enable Camera access.";
        _cameraGoesToSettings = YES;
        break;

    case AVAuthorizationStatusRestricted:
        self.cameraText = @"Camea access has been restricted. Check the "
                          @"restrictions section in the Setttings app under "
                          @"'General->Restrictions' to change this.";
        break;
    }
}

- (void)createLocationText {
    _locationGoesToSettings = NO;
    CLLocationManager *locMan = [[CLLocationManager alloc] init];
    switch (locMan.authorizationStatus) {
        // User has not yet made a choice with regards to this application
    default:
    case kCLAuthorizationStatusNotDetermined:
        self.locationText = @"Location Services: Authorization has not been "
                            @"set by the user. Touch here to set this up.";
        break;

        // This application is not authorized to use location services.  Due
        // to active restrictions on location services, the user cannot change
        // this status, and may not have personally denied authorization
    case kCLAuthorizationStatusRestricted:
        self.locationText = @"Location Services: Authorization has been restricted. Check the "
                            @"restrictions section in the Setttings app under "
                            @"'General->Restrictions' to change this.";
        break;

        // User has explicitly denied authorization for this application, or
        // location services are disabled in Settings.
    case kCLAuthorizationStatusDenied:
        _locationGoesToSettings = YES;
        self.locationText = @"Location Services: Authorization has been denied. Touch here to "
                            @"go to the settings app to re-enable location services.";
        break;

        // User has granted authorization to use their location at any time,
        // including monitoring for regions, visits, or significant location
        // changes.
    case kCLAuthorizationStatusAuthorizedAlways:
        self.locationText = @"Location Services: Authorization has been granted for use in the "
                            @"background for the alarms. Touch here to check settings.";
        _locationGoesToSettings = YES;
        break;

        // User has granted authorization to use their location only when your
        // app is visible to them (it will be made visible to them if you
        // continue to receive location updates while in the background).
        // Authorization to use launch APIs has not been granted.
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        self.locationText = @"Location Services: Authorization has been granted for use only "
                            @"when PDX Bus is being used, which means the proximity alarms "
                            @"will not work in iOS 8. Touch here to change this to allow "
                            @"alarms to work - choose 'Always' for location.";
        _locationGoesToSettings = YES;
        break;
    }
}

- (void)makeText {
    _supportText = [NSString
        stringWithFormat:NSLocalizedString(
                             @"#bPDX Bus#b uses real-time tracking information from #bTriMet#b "
                             @"to display bus, MAX, WES and streetcar times for the Portland, "
                             @"Oregon, metro area.\n\n"
                             @"Every #bTriMet#b bus stop and rail station has its own unique "
                             @"#iStop ID#i number, up to five digits. Enter the #iStop ID#i to "
                             @"get the departures for that stop.\n\n"
                             @"#bPDX Bus#b offers several ways to discover #iStop IDs#i:#>\n"
                             @"·\tBrowse a list of routes and stops;\n"
                             @"·\tUse the #bGPS#b to locate nearby stops;\n"
                             @"·\tSearch though the rail stations;\n"
                             @"·\tUse the maps of the rail systems;\n"
                             @"·\tor scan a #bQR code#b (found at some stops).#<\n\n"
                             @"Once you have found your stops - #ibookmark#i them to use them "
                             @"again later. You can set a bookmark to be for your commute, and "
                             @"it will automatically be dispayed in the morning or evening or "
                             @"when you choose the #)%@ #( toolbar icon.\n\n"
                             @"The #iTrip Planner#i feature uses #ischeduled times#i to arrange "
                             @"a journey with several transfers, always check the #bcurrent "
                             @"departures#b.\n\n"
                             @"See below for other tips and links, touch here to start using "
                             @"#bPDX Bus#b."
                             @"\n\nThe departure data is provided by #bTriMet#b and #bPortland "
                             @"Streetcar#b and is the same as the transit tracker data. "
                             @"#b#RPlease contact TriMet for issues about late buses or other "
                             @"transit issues as the app developer cannot help.#b#D"
                             @"\n\nFor app support or feature requests please leave a comment "
                             @"on the blog; alternatively use Bluesky #)%@"
                             @" #(, Facebook #)%@"
                             @" #( or Github #)%@"
                             @" #(. The app developer is not able to "
                             @"respond to app store reviews, "
                             @"so please do not use these for support or feature requests. ",
                             @"Main help description"),
                         kIconCommute.markup,
                         kIconBluesky.markup,
                         kIconFacebook.markup,
                         kIconGitHub.markup];

    _tipText = [[NSArray alloc]
        initWithObjects:
            NSLocalizedString(@"There are #bLOTS#b of settings for #bPDX Bus#b - take a look "
                              @"at the settings on the home screen to change colors, move "
                              @"the #ibookmarks#i to the top of the screen or change other "
                              @"options.",
                              @"info text"),
            NSLocalizedString(@"There is an #bApple Watch#b app. Not all features are "
                              @"available "
                              @"on the watch - no trip planner or trip planner bookmarks.",
                              @"info text"),
            NSLocalizedString(@"Use the top-left #bEdit#b button on the home screen to "
                              @"re-order or modify the #ibookmarks#i.  #iBookmarks#i can be "
                              @"re-ordered, they can also include multiple stops and can be "
                              @"made to show themselves automatically in the morning or "
                              @"evening.",
                              @"info text"),
            NSLocalizedString(@"When the time is shown in #Rred#D the vehicle "
                              @"will depart in 5 minutes or less.",
                              @"info text"),
            NSLocalizedString(@"When the time is shown in #Ublue#D the vehicle "
                              @"will depart in more than 5 minutes.",
                              @"info text"),
            NSLocalizedString(@"When the time is shown in #Agray#D no location infomation is "
                              @"available - the scheduled time is shown.",
                              @"info text"),
            NSLocalizedString(@"When the time is shown in #Mmagenta#D the vehicle is late.",
                              @"info text"),
            NSLocalizedString(@"When the time is shown in #Oorange#D and crossed out the "
                              @"vehicle was canceled.  The original scheduled time is shown "
                              @"for reference.",
                              @"info text"),
            NSLocalizedString(@"#bStop IDs:#b Every #bTriMet#b bus stop and rail station has "
                              @"its own unique #iStop ID#i number, up to five digits. Enter "
                              @"the #iStop ID#i to get the departures for that stop.",
                              @"info text"),
            NSLocalizedString(@"#bVehicle IDs:#b Every #bTriMet#b bus or train has an ID "
                              @"posted inside (except for the Streetcar). This is the "
                              @"#bVehicle ID#b. The #bVehicle ID#b is shown on the departure "
                              @"details.  This can help to tell if a MAX car has a low-foor.",
                              @"info text"),
            NSLocalizedString(
                @"#b" kBlockNameC " IDs:#b This is an ID given to a specific timetabled "
                 "movement, internally this is known as a #iblock#i.  You can "
                 "tag a #b" kBlockNameC " ID#b with a color. "
                @"#b" kBlockNameC " ID#b color tags can be set to highlight a bus or train so "
                 "that you can follow its progress through several stops. "
                @"For example, if you tag a departure at one stop, you can use "
                @"the color tag to see when it will arrive at your "
                @"destination. "
                @"Also, the tags will remain persistant on each day of the "
                @"week, so the same bus or train will have the same color the "
                @"next day.",
                @"info text"),
            NSLocalizedString(@"Sometimes the scheduled time is also shown in #Agray#D when "
                              @"the vehicle is not running to schedule.",
                              @"info text"),
            NSLocalizedString(@"Shake the device to #brefresh#b the departure times.",
                              @"info text"),
            NSLocalizedString(@"Backup your bookmarks by #iemailing#i them to yourself.",
                              @"info text"),
            NSLocalizedString(@"Keep an eye on the #btoolbar#b at the bottom - there are "
                              @"maps, options, and other features to explore.",
                              @"info text"),
            NSLocalizedString(@"At night, #bTriMet#b recommends holding up a cell phone or "
                              @"flashing light so the driver can see you.",
                              @"info text"),
            NSLocalizedString(@"Many issues can be solved by deleting the app and "
                              @"reinstalling - be sure to #iemail the bookmarks to "
                              @"yourself#i first so you can restore them.",
                              @"info text"),
            // ATTR(@"Bad escape#"),
            // ATTR(@"## started ## pound"),
            nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_hideButton) {
        UIBarButtonItem *info =
            [UIBarButtonItem textButton:NSLocalizedString(@"About", @"button text")
                                 target:self
                                 action:@selector(infoAction:)];

        self.navigationItem.rightBarButtonItem = info;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)infoAction:(id)sender {
    AboutViewController *infoView = [AboutViewController viewController];

    infoView.hideButton = YES;

    // Push the detail view controller
    [self.navigationController pushViewController:infoView animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionSupport:
        return NSLocalizedString(@"PDX Bus - App Support", @"section header");

    case kSectionTips:
        return NSLocalizedString(@"Tips", @"section header");

    case kSectionLinks:
        return NSLocalizedString(@"App Support Links (not TriMet!)", @"section header");

    case kSectionRowNetwork:
        return NSLocalizedString(@"Network & Server Connectivity", @"section header");

    case kSectionPrivacy:
        return NSLocalizedString(@"Privacy", @"section header");

    case kSectionRowCache:
        return NSLocalizedString(@"Route and Stop Data Cache", @"section header");

    case kSectionRowHighlights:
        return NSLocalizedString(@"Vehicle highlights", @"section header");

    case kSectionRowWatch:
        return NSLocalizedString(@"Apple Watch", @"section header");

    case kSectionRowShortcuts:
        return NSLocalizedString(@"Siri Shortcuts", @"section header");

    case kSectioniCloud:
        return NSLocalizedString(@"iCloud debugging", @"section header");

    case kSectionRowLocations:

        if (Settings.kmlRoutes) {
            return NSLocalizedString(@"Vehicles & routes", @"section header");
        }

        return NSLocalizedString(@"Vehicle locations", @"section header");

    case kSectionTriMet:
        return NSLocalizedString(@"Please contact TriMet for service issues, "
                                 @"the PDX Bus developer cannot help.",
                                 @"section header");
    }
    return nil;
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    [self createLocationText];
    [self reloadData];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS SupportViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowNetwork

MARKUP_CELL_SELECT(kSectionRowNetwork,
                   auto,

                   NSLocalizedString(@"Check Network Connection", @"main menu item"),
                   kIconNetwork,
                   UITableViewCellAccessoryDisclosureIndicator) {
    [self networkTips:nil networkError:nil];
    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowCache

CELL_CONFIG_METHOD(kSectionRowCache) {
    NSUInteger size = kBytesToKB([TriMetXML cacheSizeInBytes]);

    return [self
             multiLine:[self tableView:tableView cellWithReuseIdentifier:@"cache"]
                  text:size > 0
                           ? ([NSString
                                 stringWithFormat:NSLocalizedString(@"#b#RDelete Cached Routes and "
                                                                    @"Stops#b\n#ACache size %@",
                                                                    @"main menu item"),
                                                  kBytesSize([TriMetXML cacheSizeInBytes])])
                           : NSLocalizedString(@"#b#RDelete Cached Routes and Stops",
                                               @"main menu item")
                  icon:kIconDelete
         accessoryType:UITableViewCellAccessoryNone
        selectionStyle:UITableViewCellSelectionStyleBlue];
}

CELL_SELECT_METHOD(kSectionRowCache) {
    [TriMetXML deleteCacheFile];
    [KMLRoutes deleteCacheFile];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:UITableViewRowAnimationNone];

    [UIAlertController
        simpleOkWithTitle:NSLocalizedString(@"Data Cache", @"alert title")
                  message:NSLocalizedString(@"Cached Routes and Stops have been deleted",
                                            @"information text")
           viewController:self
               completion:nil];
    [self reloadData];
}

STATIC_VTABLE_VCS_H(kSectionRowCache, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kRowShortcutDocumentation

LINK_CELL(kRowShortcutDocumentation,
          kIconSource,
          NSLocalizedString(@"Shortcut Documentation", @"main menu item"),
          @"PDXBus Shortcut Documentation");

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionSupportHowToRide

LINK_CELL(kSectionSupportHowToRide,
          kIconTriMetLink,
          NSLocalizedString(@"How to ride", @"main menu item"),
          @"TriMet How To Ride");

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionTriMetSupport

LINK_CELL(kSectionTriMetSupport,
          kIconTriMetLink,
          NSLocalizedString(@"TriMet Customer Service", @"main menu item"),
          @"TriMet Customer Service");

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionStreetcarSupport

LINK_CELL(kSectionStreetcarSupport,
          kIconStreetcar,
          NSLocalizedString(@"Contact Portland Streetcar", @"main menu item"),
          @"Contact Portland Streetcar");

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLinkGitHub

LINK_CELL(kSectionLinkGitHub,
          kIconGitHub,
          NSLocalizedString(@"PDX Bus on GitHub", @"main menu item"),
          @"PDX Bus on GitHub");

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLinkBlog

LINK_CELL(kSectionLinkBlog,
          kIconAppIconAction,
          NSLocalizedString(@"PDX Bus website & support", @"main menu item"),
          @"PDXBus Website");

//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionTriMetBluesky

LINK_CELL_SELECT(kSectionTriMetBluesky,
                 kIconBluesky,
                 NSLocalizedString(@"@trimet.org on Bluesky", @"main menu item")) {
    [self triMetBluesky];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLinkBluesky

LINK_CELL_SELECT(kSectionLinkBluesky,
                 kIconBluesky,
                 NSLocalizedString(@"@pdxbus.bsky.social on Bluesky", @"main menu item")) {
    [self blueskyAt:@"pdxbus.bsky.social"];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLinkInstagram

LINK_CELL_SELECT(kSectionLinkInstagram,
                 kIconInstagram,
                 NSLocalizedString(@"@pdxbus on Instagram", @"main menu item")) {
    [self instagramAt:@"pdxbus"];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLinkFacebook

LINK_CELL_SELECT(kSectionLinkFacebook,
                 kIconFacebook,
                 NSLocalizedString(@"PDX Bus Facebook page", @"main menu item")) {
    [self facebookPDXBus];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowShortcuts

MARKUP_CELL_SELECT(kSectionRowShortcuts,
                   auto,
                   NSLocalizedString(@"#b#RDelete all Siri Shortcuts", @"main menu item"),
                   kIconDelete,
                   UITableViewCellAccessoryNone) {
    [NSUserActivity deleteAllSavedUserActivitiesWithCompletionHandler:^{
      [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"Siri Shortcuts", @"alert title")
                      message:NSLocalizedString(@"All shortcuts deleted", @"information text")
               viewController:self
                   completion:nil];
      }];
    }];

    [self clearSelection];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowShapeCache

CELL_CONFIG_METHOD(kSectionRowShapeCache) {
    KMLRoutes *kml = [KMLRoutes xml];

    NSString *downloadProgress = @"";
    NSString *downloadNumber = kml.downloadProgress;

    if (downloadNumber) {
        downloadProgress = @"\n#UDownloading (touch for progress)#D";
    }

    NSString *cacheDate = @"";

    NSDate *date = kml.cacheDate;

    NSString *text = nil;

    if (date) {
        cacheDate = [NSString
            stringWithFormat:@"\nDownloaded: %@",
                             [NSDateFormatter localizedStringFromDate:date
                                                            dateStyle:NSDateFormatterShortStyle
                                                            timeStyle:NSDateFormatterShortStyle]];
    }

    if (kml.cacheAgeInDays == kNoCache) {
        text =
            ([NSString stringWithFormat:NSLocalizedString(@"#bFetch route paths#b\n#ANone cached%@",
                                                          @"main menu item"),
                                        downloadProgress]);
    } else if (Settings.kmlManual) {
        text = ([NSString stringWithFormat:NSLocalizedString(@"#bFetch route paths#b\n#ACache is "
                                                             @"%ld days old\nCache size %@%@%@",
                                                             @"main menu item"),
                                           (long)kml.cacheAgeInDays,
                                           kBytesSize(kml.sizeInBytes),
                                           cacheDate,
                                           downloadProgress]);
    } else {
        text = ([NSString
            stringWithFormat:NSLocalizedString(@"#bFetch route paths#b\n#ACache is %d days "
                                               @"old\n%ld days until reload\nCache %@%@%@",
                                               @"main menu item"),
                             (int)kml.cacheAgeInDays,
                             (long)kml.daysToAutoload,
                             kBytesSize(kml.sizeInBytes),
                             cacheDate,
                             downloadProgress]);
    }

    return [self multiLine:[self tableView:tableView cellWithReuseIdentifier:@"kml"]
                      text:text
                      icon:kIconDownload
             accessoryType:UITableViewCellAccessoryNone
            selectionStyle:UITableViewCellSelectionStyleBlue];
}

CELL_SELECT_METHOD(kSectionRowShapeCache) {
    KMLRoutes *kml = [KMLRoutes xml];

    NSString *downloadNumber = kml.downloadProgress;
    if (downloadNumber == nil) {
        NSString *title = nil;
        if (kml.cacheAgeInDays == kNoCache) {
            title = NSLocalizedString(@"Download route paths?", @"Alert title");
        } else {
            title = NSLocalizedString(@"Route paths have finished downloading. Download again?",
                                      @"Alert title");
        }

        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:title
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction
                             actionWithTitle:kAlertViewOK
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action) {
                                       [self.backgroundTask taskRunAsync:^(TaskState *taskState) {
                                         self.backgroundRefresh = YES;
                                         [taskState startAtomicTask:@"Getting paths"];

                                         kml.oneTimeDelegate = taskState;

                                         [kml fetchNowForced:YES];

                                         [taskState atomicTaskItemDone];

                                         return (UIViewController *)nil;
                                       }];
                                     }]];

        [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
                                                  [self reloadData];
                                                }]];

        [self displayPopover:alert
                  completion:^{
                    [self clearSelection];
                  }];
    } else {
        NSString *downloadProgress = @"";
        downloadProgress = [NSString
            stringWithFormat:NSLocalizedString(@"Route paths are downloading.\nProgress: %@",
                                               @"update"),
                             downloadNumber];

        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:downloadProgress
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", @"button")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                  [self reloadData];
                                                }]];

        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel the download", @"button")
                                       style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {
                                       [kml cancelBackgroundFetch];
                                       [self reloadData];
                                     }]];

        [self displayPopover:alert
                  completion:^{
                    [self clearSelection];
                  }];
    }
}

STATIC_VTABLE_VCS_H(kSectionRowShapeCache, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowHighlights

MARKUP_CELL_SELECT(kSectionRowHighlights,
                   auto,
                   NSLocalizedString(@"Show trip color tags", @"main menu item"),
                   [BoxedImageIcon withImage:[BlockColorDb imageWithColor:[UIColor redColor]]],
                   UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([BlockColorViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionTriMetCall

MARKUP_CELL_SELECT(kSectionTriMetCall,
                   auto,
                   (NSLocalizedString(@"Call TriMet on 503-238-RIDE", @"main menu item")),
                   kIconPhone,
                   UITableViewCellAccessoryNone) {
    [self callTriMet];
    [self clearSelection];
}
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowWatch

CELL_CONFIG_METHOD(kSectionRowWatch) {
    RootViewController *root = RootViewController.currentRootViewController;

    NSString *text = nil;
    if (root.session) {
#define BOOL2STR(X) ((X) ? @"#b#UYes#D#b" : @"#b#RNo#D#b")
        text = [NSString
            stringWithFormat:NSLocalizedString(@"#DWatch paired:%@\nApp installed:%@\nComplication "
                                               @"installed:%@\nSequence:#b##%ld",
                                               @"watch info"),
                             BOOL2STR(root.session.paired),
                             BOOL2STR(root.session.isWatchAppInstalled),
                             BOOL2STR(root.session.isComplicationEnabled),
                             (long)UserState.sharedInstance.watchSequence];
    } else {
        text = NSLocalizedString(@"#DNo watch support.", @"error message");
    }

    return [self multiLine:[self tableView:tableView cellWithReuseIdentifier:@"watch"]
                      text:text
                      icon:kIconAppIconAction
             accessoryType:UITableViewCellAccessoryNone
            selectionStyle:(root.session && root.session.isWatchAppInstalled)
                               ? UITableViewCellSelectionStyleBlue
                               : UITableViewCellSelectionStyleNone];
}

CELL_SELECT_METHOD(kSectionRowWatch) {
    RootViewController *root = RootViewController.currentRootViewController;

    if (root.session && root.session.isWatchAppInstalled) {
        [self updateWatch];
        [UIAlertController
            simpleOkWithTitle:NSLocalizedString(@"Apple Watch", @"alert title")
                      message:NSLocalizedString(@"Sent data to watch.", @"information text")
               viewController:self
                   completion:nil];
        [self reloadData];
        [self clearSelection];
    }
}

STATIC_VTABLE_VCS_H(kSectionRowWatch, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowWatchInfo

PARA_CELL(kSectionRowWatchInfo,
          NSLocalizedString(@"The #bApple Watch#b app does #Rnot#D support the Trip "
                            @"Planner, nor Trip Planner bookmarks. Bookmark changes may "
                            @"not be reflected on the watch immediately. Check that the "
                            @"#iSequence number#i on the watch (at the end of the "
                            @"bookmarks) matches the sequence number above. Tap on the "
                            @"sequence number above to force a resend.",
                            @"alert title"),
          nil);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionRowTip

TEXT_CELL_SELECT(kSectionRowTip,
                 ((indexPath.row < _tipText.count) ? _tipText[indexPath.row] : @""),
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleNone){};

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionSupportRowNew

MARKUP_CELL_SELECT(kSectionSupportRowNew,
                   auto,
                   NSLocalizedString(@"What's new?", @"main menu item"),
                   kIconAppIconAction,
                   UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([WhatsNewViewController viewController]);
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionSupportRowTip

CELL_TIP_JAR(kSectionSupportRowTip, auto);

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionSupportRowSupport

TEXT_CELL_SELECT(kSectionSupportRowSupport,
                 _supportText,
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleNone) {
    CELL_POP();
};

//--------------------------------------------------------------------------------------------------

#pragma mark kRowWriteToiCloud

MULTI_CELL_SELECT(kRowWriteToiCloud,
                  auto,
                  NSLocalizedString(@"#bReplace#b iCloud bookmarks with local bookmarks",
                                    @"main menu item"),
                  kIconDelete,
                  UITableViewCellAccessoryNone,
                  UITableViewCellSelectionStyleBlue) {

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Force Overwrite to iCloud", @"Alert title")
                         message:NSLocalizedString(@"This will write your local "
                                                   @"bookmarks to the cloud.",
                                                   @"Alert text")
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                              NSUbiquitousKeyValueStore *store =
                                                  [NSUbiquitousKeyValueStore defaultStore];

                                              NSDictionary *cloud =
                                                  [store dictionaryRepresentation];

                                              for (NSString *key in cloud) {
                                                  [store removeObjectForKey:key];
                                              }

                                              DEBUG_LOG_description(cloud);

                                              [self->_userState writeToCloud];
                                              [self userStateChanged];
                                              [self clearSelection];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                              [self clearSelection];
                                            }]];

    [self displayPopover:alert
              completion:^{
                [self clearSelection];
              }];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kRowReadFromiCloud

MULTI_CELL_SELECT(kRowReadFromiCloud,
                  auto,
                  NSLocalizedString(@"#bReplace#b local bookmarks with iCloud bookmarks",
                                    @"main menu item"),
                  kIconDelete,
                  UITableViewCellAccessoryNone,
                  UITableViewCellSelectionStyleBlue) {

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Force Read from iCloud", @"Alert title")
                         message:NSLocalizedString(@"This will overwrite "
                                                   @"your local bookmarks.",
                                                   @"Alert text")
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                              [self->_userState mergeWithCloud:nil];
                                              [self userStateChanged];
                                              [self clearSelection];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                              [self clearSelection];
                                            }]];

    [self displayPopover:alert
              completion:^{
                [self clearSelection];
              }];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kRowDeleteiCloud

MULTI_CELL_SELECT(kRowDeleteiCloud,
                  auto,
                  NSLocalizedString(@"#b#RDelete all in iCloud", @"main menu item"),
                  kIconDelete,
                  UITableViewCellAccessoryNone,
                  UITableViewCellSelectionStyleBlue) {

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Delete iCloud bookmarks", @"Alert title")
                         message:NSLocalizedString(@"This will delete all iCloud items.",
                                                   @"Alert text")
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                              [self->_userState clearCloud];

                                              // When debugging, we may want to exit
                                              // here. exit(0);

                                              [self clearSelection];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                              [self clearSelection];
                                            }]];

    [self displayPopover:alert
              completion:^{
                [self clearSelection];
              }];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionRowLocations

MARKUP_CELL_SELECT(kSectionRowLocations,
                   auto,
                   (Settings.kmlRoutes
                        ? NSLocalizedString(@"Show all vehicles & routes", @"main menu item")
                        : NSLocalizedString(@"Show vehicle locations", @"main menu item")),
                   kIconMap,
                   UITableViewCellAccessoryDisclosureIndicator) {
    NearestVehiclesMapViewController *mapView = [NearestVehiclesMapViewController viewController];

    mapView.alwaysFetch = YES;
    mapView.allRoutes = YES;
    mapView.staticOverlays = YES;
    [mapView fetchNearestVehiclesAsync:self.backgroundTask];
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionPrivacyRowLocation

PARA_CELL_SELECT(kSectionPrivacyRowLocation,
                 auto,
                 self.locationText,
                 nil,
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleBlue) {
    if (_locationGoesToSettings) {
        [[UIApplication sharedApplication]
            compatOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        self.locMan = [[CLLocationManager alloc] init];

        [self.locMan requestAlwaysAuthorization];

        self.locMan.delegate = self;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark kSectionPrivacyRowCamera

PARA_CELL_SELECT(kSectionPrivacyRowCamera,
                 auto,
                 self.cameraText,
                 nil,
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleBlue) {
    if (_cameraGoesToSettings) {
        [[UIApplication sharedApplication]
            compatOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                   MAIN_TASK(^{
                                     if (granted) {
                                         DEBUG_LOG(@"Granted access to %@", AVMediaTypeVideo);
                                     } else {
                                         DEBUG_LOG(@"Not granted access to %@", AVMediaTypeVideo);
                                     }

                                     [self createCameraText];
                                     [self reloadData];
                                   });
                                 }];
    }
}

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionRowNetwork),
    CELL_MAP(kSectionRowCache),
    CELL_MAP(kRowShortcutDocumentation),
    CELL_MAP(kSectionTriMetSupport),
    CELL_MAP(kSectionStreetcarSupport),
    CELL_MAP(kSectionLinkGitHub),
    CELL_MAP(kSectionLinkBlog),
    CELL_MAP(kSectionSupportHowToRide),
    CELL_MAP(kSectionLinkBluesky),
    CELL_MAP(kSectionTriMetBluesky),
    CELL_MAP(kSectionLinkInstagram),
    CELL_MAP(kSectionLinkFacebook),
    CELL_MAP(kSectionRowShortcuts),
    CELL_MAP(kSectionRowShapeCache),
    CELL_MAP(kSectionRowHighlights),
    CELL_MAP(kSectionTriMetCall),
    CELL_MAP(kSectionRowWatch),
    CELL_MAP(kSectionRowWatchInfo),
    CELL_MAP(kSectionRowTip),
    CELL_MAP(kSectionSupportRowNew),
    CELL_MAP(kSectionSupportRowTip),
    CELL_MAP(kSectionSupportRowSupport),
    CELL_MAP(kRowWriteToiCloud),
    CELL_MAP(kRowReadFromiCloud),
    CELL_MAP(kRowDeleteiCloud),
    CELL_MAP(kSectionRowLocations),
    CELL_MAP(kSectionPrivacyRowLocation),
    CELL_MAP(kSectionPrivacyRowCamera),
};

//--------------------------------------------------------------------------------------------------

@end

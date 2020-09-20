//
//  SupportView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SupportView.h"
#import "WebViewController.h"
#import "TriMetXML.h"
#import "WhatsNewView.h"
#import "AboutView.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "DebugLogging.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import "NearestVehiclesMap.h"
#import "NSString+Helper.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"
#import "QueryCacheManager.h"
#import "TableViewWithToolbar.h"
#import "TaskState.h"
#import "RootViewController.h"
#import "PDXBusAppDelegate+Methods.h"
#import "Icons.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "BackgroundDownloader.h"


#define kBytesToKB(B) ((B) / 1024)
#define kBytesToMB(B) (((double)(B)) / (1024 * 1024))

enum {
    kSectionSupport,
    kSectionTips,
    kSectionLinks,
    kSectionTriMet,
    kSectionTriMetCall,
    kSectionTriMetSupport,
    kSectionTriMetTweet,
    kSectionRowNetwork,
    kSectioniCloud,
    kRowWriteToiCloud,
    kRowReadFromiCloud,
    kRowDeleteiCloud,
    kSectionRowCache,
    kSectionRowShapeCache,
    kSectionRowHighlights,
    kSectionRowWatch,
    kSectionRowShortcuts,
    kRowShortcutDocumentation,
    kSectionRowLocations,
    kSectionPrivacy,
    kSectionSupportRowSupport,
    kSectionSupportRowNew,
    kSectionSupportHowToRide,
    kSectionLinkBlog,
    kSectionLinkTwitter,
    kSectionLinkFacebook,
    kSectionLinkGitHub,
    kSectionPrivacyRowLocation,
    kSectionPrivacyRowCamera,
    kSectionRowTip = 200                // leave a gap after this
};

@interface SupportView () {
    NSAttributedString *_supportText;
    NSArray *_tipText;
    
    bool _cameraGoesToSettings;
    bool _locationGoesToSettings;
}

@property (nonatomic, strong) CLLocationManager *locMan;
@property (nonatomic, copy)   NSString *locationText;
@property (nonatomic, copy)   NSString *cameraText;

@end

@implementation SupportView


#pragma mark Helper functions

- (void)dealloc
{
    DEBUG_FUNC();
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods

- (void)initCameraText {
    _cameraGoesToSettings = NO;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authStatus) {
        default:
        case AVAuthorizationStatusAuthorized:
            self.cameraText = @"Camera access is authorized. Touch here to check settings.";
            _cameraGoesToSettings = YES;
            break;
            
        case AVAuthorizationStatusNotDetermined:
            self.cameraText = @"Camera access has not been set up by the user. Touch here to set this up.";
            break;
            
        case AVAuthorizationStatusDenied:
            self.cameraText = @"Camera access has been denied by the user. Touch here to go to the settings app re-enable Camera access.";
            _cameraGoesToSettings = YES;
            break;
            
        case AVAuthorizationStatusRestricted:
            self.cameraText = @"Camea access has been restricted. Check the restrictions section in the Setttings app under 'General->Restrictions' to change this.";
            break;
    }
}

- (void)initLocationText {
    _locationGoesToSettings = NO;
    switch ([CLLocationManager authorizationStatus]) {
            // User has not yet made a choice with regards to this application
        default:
        case kCLAuthorizationStatusNotDetermined:
            self.locationText = @"Location Services: Authorization has not been set by the user. Touch here to set this up.";
            break;
            
            // This application is not authorized to use location services.  Due
            // to active restrictions on location services, the user cannot change
            // this status, and may not have personally denied authorization
        case kCLAuthorizationStatusRestricted:
            self.locationText = @"Location Services: Authorization has been restricted. Check the restrictions section in the Setttings app under 'General->Restrictions' to change this.";
            break;
            
            // User has explicitly denied authorization for this application, or
            // location services are disabled in Settings.
        case kCLAuthorizationStatusDenied:
            _locationGoesToSettings = YES;
            self.locationText = @"Location Services: Authorization has been denied. Touch here to go to the settings app to re-enable location services.";
            break;
            
            // User has granted authorization to use their location at any time,
            // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways:
            self.locationText = @"Location Services: Authorization has been granted for use in the background for the alarms. Touch here to check settings.";
            _locationGoesToSettings = YES;
            break;
            
            // User has granted authorization to use their location only when your app
            // is visible to them (it will be made visible to them if you continue to
            // receive location updates while in the background).  Authorization to use
            // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.locationText = @"Location Services: Authorization has been granted for use only when PDX Bus is being used, which means the proximity alarms will not work in iOS 8. Touch here to change this to allow alarms to work - choose 'Always' for location.";
            _locationGoesToSettings = YES;
            break;
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Help and Support", @"page title");
        
#define ATTR(X, Y) [NSLocalizedString(X, Y) formatAttributedStringWithFont:self.paragraphFont]
        
        _supportText = ATTR(
                            @"#bPDX Bus#b uses real-time tracking information from #bTriMet#b to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
                            "Every #bTriMet#b bus stop and rail station has its own unique #iStop ID#i number, up to five digits. Enter the #iStop ID#i to get the departures for that stop.\n\n"
                            "#bPDX Bus#b offers several ways to discover #iStop IDs#i:\n"
                            "- Browse a list of routes and stops;\n"
                            "- Use the #bGPS#b to locate nearby stops;\n"
                            "- Search though the rail stations;\n"
                            "- Use the maps of the rail systems;\n"
                            "- or scan a #bQR code#b (found at some stops).\n\n"
                            "Once you have found your stops - #ibookmark#i them to use them again later.\n\n"
                            "The #iTrip Planner#i feature uses #ischeduled times#i to arrange a journey with several transfers, always check the #bcurrent departures#b.\n\n"
                            "See below for other tips and links, touch here to start using #bPDX Bus#b."
                            "\n\nThe departure data is provided by #bTriMet#b and #bPortland Streetcar#b and is the same as the transit tracker data. "
                            "#b#RPlease contact TriMet for issues about late buses or other transit issues as the app developer cannot help.#b#D"
                            "\n\nFor app support or feature requests please leave a comment on the blog; alternatively use twitter, Facebook or Github. The app developer is not able to respond to app store reviews, "
                            "so please do not use these for support or feature requests. ", @"Main help description");
        
        
        _tipText = [[NSArray alloc] initWithObjects:
                    ATTR(@"There are #bLOTS#b of settings for #bPDX Bus#b - take a look at the settings on the home screen to change colors, move the #ibookmarks#i to the top of the screen or change other options.", @"info text"),
                    ATTR(@"Use the top-left #bEdit#b button on the home screen to re-order or modify the #ibookmarks#i.  #iBookmarks#i can be re-ordered, they can also include multiple stops and can be made to show themselves automatically in the morning or evening.", @"info text"),
                    ATTR(@"When the time is shown in #Rred#D the vehicle will depart in 5 minutes or less.", @"info text"),
                    ATTR(@"When the time is shown in #Ublue#D the vehicle will depart in more than 5 minutes.", @"info text"),
                    ATTR(@"When the time is shown in #Agray#D no location infomation is available - the scheduled time is shown.", @"info text"),
                    ATTR(@"When the time is shown in #Mmagenta#D the vehicle is late.", @"info text"),
                    ATTR(@"When the time is shown in #Oorange#D and crossed out the vehicle was canceled.  The original scheduled time is shown for reference.", @"info text"),
                    ATTR(@"#bStop IDs:#b Every #bTriMet#b bus stop and rail station has its own unique #iStop ID#i number, up to five digits. Enter the #iStop ID#i to get the departures for that stop.", @"info text"),
                    ATTR(@"#bVehicle IDs:#b Every #bTriMet#b bus or train has an ID posted inside (except for the Streetcar). This is the #bVehicle ID#b. The #bVehicle ID#b is shown on the departure details.  This can help to tell if a MAX car has a low-foor.",  @"info text"),
                    ATTR(@"#b" kBlockNameC " IDs:#b This is an ID given to a specific timetabled movement, internally this is known as a #iblock#i.  You can tag a #b" kBlockNameC " ID#b with a color. "
                         @"#b" kBlockNameC " ID#b color tags can be set to highlight a bus or train so that you can follow its progress through several stops. "
                         @"For example, if you tag a departure at one stop, you can use the color tag to see when it will arrive at your destination. "
                         @"Also, the tags will remain persistant on each day of the week, so the same bus or train will have the same color the next day.", @"info text"),
                    ATTR(@"Sometimes the scheduled time is also shown in #Agray#D when the vehicle is not running to schedule.", @"info text"),
                    ATTR(@"Shake the device to #brefresh#b the departure times.", @"info text"),
                    ATTR(@"Backup your bookmarks by #iemailing#i them to yourself.", @"info text"),
                    ATTR(@"Keep an eye on the #btoolbar#b at the bottom - there are maps, options, and other features to explore.", @"info text"),
                    ATTR(@"At night, #bTriMet#b recommends holding up a cell phone or flashing light so the driver can see you.", @"info text"),
                    ATTR(@"Many issues can be solved by deleting the app and reinstalling - be sure to #iemail the bookmarks to yourself#i first so you can restore them.", @"info text"),
                    // ATTR(@"Bad escape#"),
                    // ATTR(@"## started ## pound"),
                    nil];
        
        [self initLocationText];
        [self initCameraText];
        
        self.locMan = [[CLLocationManager alloc] init];
        
        [self.locMan requestAlwaysAuthorization];
        
        self.locMan.delegate = self;
        
        
        [self clearSectionMaps];
        
        
        [self addSectionType:kSectionSupport];
        [self addRowType:kSectionSupportRowSupport];
        [self addRowType:kSectionSupportRowNew];
        
        [self addSectionType:kSectionTriMet];
        [self addRowType:kSectionSupportHowToRide];
        
        if ([self canCallTriMet]) {
            [self addRowType:kSectionTriMetCall];
        }
        
        [self addRowType:kSectionTriMetSupport];
        [self addRowType:kSectionTriMetTweet];
        
        [self addSectionType:kSectionTips];
        
        for (int i = 0; i < _tipText.count; i++) {
            [self addRowType:kSectionRowTip + i];
        }
        
        [self addSectionType:kSectionLinks];
        [self addRowType:kSectionLinkBlog];
        [self addRowType:kSectionLinkTwitter];
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
        if (@available(iOS 12.0, *)) {
            [self addSectionType:kSectionRowShortcuts];
            [self addRowType:kSectionRowShortcuts];
            [self addRowType:kRowShortcutDocumentation];
        }
#endif
        
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
        
        [self addSectionType:kSectionRowLocations];
        [self addRowType:kSectionRowLocations];
        
        [self addSectionType:kSectionPrivacy];
        
        [self addRowType:kSectionPrivacyRowLocation];
        [self addRowType:kSectionPrivacyRowCamera];
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_hideButton) {
        UIBarButtonItem *info = [[UIBarButtonItem alloc]
                                 initWithTitle:NSLocalizedString(@"About", @"button text")
                                 style:UIBarButtonItemStylePlain
                                 target:self action:@selector(infoAction:)];
        
        
        self.navigationItem.rightBarButtonItem = info;
    }
}

- (void)infoAction:(id)sender {
    AboutView *infoView = [AboutView viewController];
    
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
            return NSLocalizedString(@"Please contact TriMet for service issues, the PDX Bus developer cannot help.", @"section header");
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView linkCell:(NSString *)text image:(UIImage *)image {
    UITableViewCell *cell = [self tableViewCell:tableView];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor modeAwareBlue];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.text = text;
    cell.imageView.image = image;
    cell.accessibilityLabel = [NSString stringWithFormat:@"Link to %@", cell.textLabel.text.phonetic];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [self rowType:indexPath];
    
    switch (row) {
        case kSectionRowNetwork: {
            UITableViewCell *cell = [self tableViewCell:tableView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Check Network Connection", @"main menu item");
            cell.imageView.image = [Icons getIcon:kIconNetwork];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kSectionRowCache: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            NSUInteger size = kBytesToKB([TriMetXML cacheSizeInBytes]);
            
            if (size > 0) {
                cell.textLabel.attributedText = FormatTextBasic(([NSString stringWithFormat:NSLocalizedString(@"#b#RDelete Cached Routes and Stops#b\n#ACache size %ld KB", @"main menu item"), (long)kBytesToKB([TriMetXML cacheSizeInBytes])]));
            } else {
                cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#b#RDelete Cached Routes and Stops", @"main menu item"));
            }
            
            cell.imageView.image = [Icons getIcon:kIconDelete];
            return cell;
            
            break;
        }
            
        case kSectionRowShapeCache: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            KMLRoutes *kml = [KMLRoutes xml];
            
            NSString *downloadProgress = @"";
            NSString *downloadNumber = kml.downloadProgress;
            
            if (downloadNumber)
            {
                downloadProgress =  @"\n#UDownloading (touch for progress)#D";
            }
            
            NSString *cacheDate = @"";
            
            NSDate *date = kml.cacheDate;
            
            if (date)
            {
                cacheDate = [NSString stringWithFormat:
                                        @"\nDownloaded: %@",
                                        [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
               
            }
            
            if (kml.cacheAgeInDays == kNoCache) {
                cell.textLabel.attributedText = FormatTextBasic(([NSString stringWithFormat:NSLocalizedString(@"#bFetch route shapes#b\n#ANone cached%@", @"main menu item"),
                                                                  downloadProgress]));
            } else if (Settings.kmlManual) {
                cell.textLabel.attributedText = FormatTextBasic(([NSString stringWithFormat:NSLocalizedString(@"#bFetch route shapes#b\n#ACache is %ld days old\nCache size %.1f MB%@%@", @"main menu item"),
                                                                  (long)kml.cacheAgeInDays,
                                                                  kBytesToMB(kml.sizeInBytes),
                                                                  cacheDate, downloadProgress]));
            } else {
                cell.textLabel.attributedText = FormatTextBasic(([NSString stringWithFormat:NSLocalizedString(@"#bFetch route shapes#b\n#ACache is %d days old\n%ld days until reload\nCache size %.1f MB%@%@", @"main menu item"),
                                                                  (int)kml.cacheAgeInDays,
                                                                  (long)kml.daysToAutoload,
                                                                  kBytesToMB(kml.sizeInBytes),
                                                                  cacheDate,downloadProgress]));
            }
            cell.imageView.image = [Icons getIcon:kIconRedo];
            return cell;
            
            break;
        }
            
        case kSectionRowHighlights: {
            UITableViewCell *cell = [self tableViewCell:tableView];
            cell.textLabel.text = NSLocalizedString(@"Show trip color tags", @"main menu item");
            cell.imageView.image = [BlockColorDb imageWithColor:[UIColor redColor]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kSectionRowWatch: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView ];        //  [UIFont fontWithName:@"Ariel" size:14];
            cell.imageView.image = [Icons getIcon:kIconAppIconAction];
            
            
            RootViewController *root = PDXBusAppDelegate.sharedInstance.rootViewController;
            
            if (root.session) {
#define BOOL2STR(X) ((X) ? @"#b#UYes#D#b" : @"#b#RNo#D#b")
                NSString *str = [NSString stringWithFormat:
                                 NSLocalizedString(@"#DWatch paired:%@\nApp installed:%@\nComplication installed:%@", @"watch info"),
                                 BOOL2STR(root.session.paired),
                                 BOOL2STR(root.session.isWatchAppInstalled),
                                 BOOL2STR(root.session.isComplicationEnabled)
                                 ];
                cell.textLabel.attributedText = FormatTextBasic(str);
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#DNo watch support.", @"error message"));
            }
            return cell;
            
            break;
        }
            
        case kSectionRowShortcuts: {
            UITableViewCell *cell = [self tableViewCell:tableView];
            cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#b#RDelete all Siri Shortcuts", @"main menu item"));
            cell.imageView.image = [Icons getIcon:kIconDelete];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kRowShortcutDocumentation: {
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"Shortcut Documentation", @"main menu item")
                             image:[Icons getIcon:kIconSrc]];
            break;
        }
            
        case kRowWriteToiCloud: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#bReplace#b iCloud bookmarks with local bookmarks", @"main menu item"));
            cell.imageView.image = [Icons getIcon:kIconDelete];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kRowReadFromiCloud: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#bReplace#b local bookmarks with iCloud bookmarks", @"main menu item"));
            cell.imageView.image = [Icons getIcon:kIconDelete];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kRowDeleteiCloud: {
            UITableViewCell *cell = [self tableViewCell:tableView];
            cell.textLabel.attributedText = FormatTextBasic(NSLocalizedString(@"#b#RDelete all in iCloud", @"main menu item"));
            cell.imageView.image = [Icons getIcon:kIconDelete];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kSectionRowLocations: {
            UITableViewCell *cell = [self tableViewCell:tableView];
            
            if (Settings.kmlRoutes) {
                cell.textLabel.text = NSLocalizedString(@"Show all vehicles & routes", @"main menu item");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Show vehicle locations", @"main menu item");
            }
            
            cell.imageView.image = [Icons getModeAwareIcon:kIconMap7];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            return cell;
            
            break;
        }
            
        case kSectionSupportRowSupport: {
                UITableViewCell *cell = [self tableViewMultiLineParaCell:tableView];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.attributedText = _supportText;
                DEBUG_LOG(@"width:  %f\n", cell.textLabel.bounds.size.width);
                
                [self updateAccessibility:cell];
                // cell.backgroundView = [self clearView];
                return cell;
            }
            
        case kSectionSupportRowNew: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"What's new?", @"main menu item");
            
            [self updateAccessibility:cell];
            cell.imageView.image = [Icons getIcon:kIconAppIconAction];
            return cell;
            
            break;
        }
            
        case kSectionTriMetCall: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"Call TriMet on 503-238-RIDE", @"main menu item");
            [self updateAccessibility:cell];
            cell.imageView.image = [Icons getIcon:kIconPhone];
            return cell;
            
            break;
        }
            
            
        case kSectionSupportHowToRide:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"How to ride", @"main menu item")
                             image:[Icons getIcon:kIconTriMetLink]];
            
            break;
            
        case kSectionTriMetSupport:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"TriMet Customer Service", @"main menu item")
                             image:[Icons getIcon:kIconTriMetLink]];
            
        case kSectionTriMetTweet: {
            UITableViewCell *cell = [self tableViewMultiLineBasicCell:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"@TriMet on Twitter", @"main menu item");
            [self updateAccessibility:cell];
            cell.imageView.image = [Icons getIcon:kIconTwitter];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
            
        case kSectionLinkBlog:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"PDX Bus blog & support", @"main menu item")
                             image:[Icons getIcon:kIconBlog]];
            
        case kSectionLinkTwitter:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"@pdxbus on Twitter", @"main menu item")
                             image:[Icons getIcon:kIconTwitter]];
            
        case kSectionLinkGitHub:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"pdxbus on GitHub", @"main menu item")
                             image:[Icons getIcon:kIconSrc]];
            
        case kSectionLinkFacebook:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"PDX Bus Facebook page", @"main menu item")
                             image:[Icons getIcon:kIconFacebook]];
            
        case kSectionPrivacyRowLocation: {
            UITableViewCell *cell = [self tableViewMultiLineParaCell:tableView];
            cell.textLabel.text = self.locationText;
            [self updateAccessibility:cell];
            return cell;
        }
            
        case kSectionPrivacyRowCamera: {
            UITableViewCell *cell = [self tableViewMultiLineParaCell:tableView];
            cell.textLabel.text = self.cameraText;
            [self updateAccessibility:cell];
            return cell;
        }
            
        default: {
            if (row >= kSectionRowTip && (row - kSectionRowTip) < _tipText.count) {
                NSUInteger tipNumber = row - kSectionRowTip;
                UITableViewCell *cell = [self tableViewMultiLineParaCell:tableView];
                cell.textLabel.attributedText = _tipText[tipNumber];
                [self updateAccessibility:cell];
                return cell;
                
                break;
            }
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    
    if (cell.textLabel != nil) {
        DEBUG_LOGR(cell.frame);
        DEBUG_LOGR(cell.textLabel.frame);
    }
    
    switch ([self rowType:indexPath]) {
        case kSectionLinkBlog: {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
            
        case kSectionLinkGitHub: {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"https:/github.com/teleportaloo/PDX-Bus" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
            
        case kSectionTriMetSupport: {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"https://trimet.org/contact/customerservice.htm" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
            
        case kSectionTriMetTweet: {
            UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
            [self triMetTweetFrom:cell.imageView];
            break;
        }
            
        case kSectionLinkTwitter:
            [self tweetAt:@"pdxbus"];
            break;
            
        case kSectionLinkFacebook:
            [self facebook];
            break;
            
        case kSectionTriMetCall:
            [self callTriMet];
            [self clearSelection];
            break;
            
        case kSectionRowNetwork:
            [self networkTips:nil networkError:nil];
            [self clearSelection];
            break;
            
        case kSectionRowCache: {
            [TriMetXML deleteCacheFile];
            [KMLRoutes deleteCacheFile];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
              
            UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Data Cache", @"alert title")
                                                                    message:NSLocalizedString(@"Cached Routes and Stops have been deleted", @"information text")];
            [self presentViewController:alert animated:YES completion:nil];
            [self reloadData];
            break;
        }
            
        case kSectionRowShapeCache: {
            KMLRoutes *kml = [KMLRoutes xml];
            
            NSString *downloadNumber = kml.downloadProgress;
            if (downloadNumber == nil) {
                NSString *title = nil;
                if (kml.cacheAgeInDays == kNoCache)
                {
                    title = NSLocalizedString(@"Download route shapes in background?", @"Alert title");
                }
                else
                {
                    title = NSLocalizedString(@"Route shapes have finished downloading. Download again in background?", @"Alert title");
                }
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [kml fetchInBackground:YES];
                    [self reloadData];
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self reloadData];
                }]];
                
                [self displayActionSheet:alert];
            } else {
                NSString *downloadProgress = @"";
                downloadProgress = [NSString stringWithFormat:
                                        NSLocalizedString(@"Route shapes are downloading.\nProgress: %@", @"update"),
                                        downloadNumber];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:downloadProgress
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", @"button") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self reloadData];
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel the download", @"button") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [kml cancelBackgroundFetch];
                    [self reloadData];
                }]];
                
                [self displayActionSheet:alert];
            }
            
            break;
        }
            
            
        case kSectionRowHighlights: {
            BlockColorViewController *blockTable = [BlockColorViewController viewController];
            [self.navigationController pushViewController:blockTable animated:YES];
            break;
        }
            
        case kSectionRowWatch: {
            RootViewController *root = PDXBusAppDelegate.sharedInstance.rootViewController;
            
            if (root.session) {
                [self updateWatch];
                UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Apple Watch", @"alert title")
                                                                        message:NSLocalizedString(@"Sent data to watch.", @"information text")];
                [self presentViewController:alert animated:YES completion:nil];
                
                [self clearSelection];
            }
        
            break;
        }
            
        case kSectionRowShortcuts: {
            if (@available(iOS 12, *)) {
                [NSUserActivity deleteAllSavedUserActivitiesWithCompletionHandler:^{
                    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                        [self.table deselectRowAtIndexPath:indexPath animated:YES];
                        UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Siri Shortcuts", @"alert title")
                                                                                message:NSLocalizedString(@"All shortcuts deleted", @"information text")];
                        [self presentViewController:alert animated:YES completion:nil];
                    }];
                }];
            }
            
            [self clearSelection];
            break;
        }
            
        case kRowShortcutDocumentation:
            [WebViewController displayPage:@"https://github.com/teleportaloo/PDX-Bus/blob/master/Shortcuts.markdown#introduction"
                                      full:nil
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
            
        case kSectionSupportHowToRide:
            [WebViewController displayPage:@"https://trimet.org/howtoride/index.htm"
                                      full:nil
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
            
        case kRowWriteToiCloud: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Force Overwrite to iCloud", @"Alert title")
                                                                           message:NSLocalizedString(@"This will write your local bookmarks to the cloud.", @"Alert text")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
                
                NSDictionary *cloud = [store dictionaryRepresentation];
                
                for (NSString *key in cloud) {
                    [store removeObjectForKey:key];
                }
                
                DEBUG_LOGO(cloud);
                
                [self->_userState writeToiCloud];
                [self favesChanged];
                [self clearSelection];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self clearSelection];
            }]];
            
            [self displayActionSheet:alert];
            break;
        }
            
        case kRowReadFromiCloud: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Force Read from iCloud", @"Alert title")
                                                                           message:NSLocalizedString(@"This will overwrite your local bookmarks.", @"Alert text")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self->_userState mergeWithCloud:nil];
                [self favesChanged];
                [self clearSelection];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self clearSelection];
            }]];
            
            [self displayActionSheet:alert];
            break;
        }
            
        case kRowDeleteiCloud: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete iCloud bookmarks", @"Alert title")
                                                                           message:NSLocalizedString(@"This will delete all iCloud items.", @"Alert text")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self->_userState clearCloud];
                
                // When debugging, we may want to exit here.
                // exit(0);
                
                [self clearSelection];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self clearSelection];
            }]];
            
            [self displayActionSheet:alert];
            
            break;
        }
            
        case kSectionRowLocations: {
            NearestVehiclesMap *mapView = [NearestVehiclesMap viewController];
            mapView.alwaysFetch = YES;
            mapView.allRoutes = YES;
            [mapView fetchNearestVehiclesAsync:self.backgroundTask];
            break;
        }
            
        case kSectionSupportRowSupport:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
       
            
        case kSectionSupportRowNew: {
            [self.navigationController pushViewController:[WhatsNewView viewController] animated:YES];
            break;
        }
            
        case kSectionPrivacyRowLocation: {
            if (_locationGoesToSettings) {
                [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            } else {
                self.locMan = [[CLLocationManager alloc] init];
                
                [self.locMan requestAlwaysAuthorization];
                
                self.locMan.delegate = self;
            }
            
            break;
        }
            
        case kSectionPrivacyRowCamera: {
            if (_cameraGoesToSettings) {
                [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            } else {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        DEBUG_LOG(@"Granted access to %@", AVMediaTypeVideo);
                    } else {
                        DEBUG_LOG(@"Not granted access to %@", AVMediaTypeVideo);
                    }
                    
                    [self initCameraText];
                    [self reloadData];
                }
                 ];
            }
            
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self initLocationText];
    [self reloadData];
}

@end

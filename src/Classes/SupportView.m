//
//  SupportView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SupportView.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"
#import "AboutView.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "DebugLogging.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import "NearestVehiclesMap.h"
#import "StringHelper.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"

enum
{
    kSectionSupport,
    kSectionTips,
    kSectionLinks,
    kSectionTriMet,
    kSectionTriMetCall,
    kSectionTriMetSupport,
    kSectionTriMetTweet,
    kSectionRowNetwork,
    kSectionRowCache,
    kSectionRowHighlights,
    kSectionRowShortcuts,
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


@implementation SupportView


#pragma mark Helper functions

- (UITableViewStyle) style
{
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (bool)canOpenSettings
{
    return([UIDevice currentDevice].systemVersion.floatValue >= 8.0);
}

- (void)initCameraText
{
    _cameraGoesToSettings = NO;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authStatus)
    {
        default:
        case AVAuthorizationStatusAuthorized:
            if ([self canOpenSettings])
            {
                self.cameraText = @"Camera access is authorized. Touch here to check settings.";
                _cameraGoesToSettings = YES;
            }
            else
            {
                self.cameraText = @"Camera access is authorized.";
            }
            break;
        case AVAuthorizationStatusNotDetermined:
            self.cameraText = @"Camera access has not been set up by the user. Touch here to set this up.";
            break;
        case AVAuthorizationStatusDenied:
            if ([self canOpenSettings])
            {
                self.cameraText = @"Camera access has been denied by the user. Touch here to go to the settings app re-enable Camera access.";
                _cameraGoesToSettings = YES;
            }
            else
            {
                self.cameraText = @"Camera access has been denied by the user. Go to the settings app and select PDX Bus to re-enable Camera access.";
            }
            break;
        case AVAuthorizationStatusRestricted:
            self.cameraText = @"Camea access has been restricted. Check the restrictions section in the Setttings app under 'General->Restrictions' to change this.";
            break;
    }
    
}

- (void)initLocationText
{
    _locationGoesToSettings = NO;
    switch ([CLLocationManager authorizationStatus])
    {
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
            if (self.canOpenSettings)
            {
                _locationGoesToSettings = YES;
                self.locationText = @"Location Services: Authorization has been denied. Touch here to go to the settings app to re-enable location services.";
            }
            else
            {
                self.locationText = @"Location Services: Authorization has been denied. Go to the settings app and select PDX Bus to re-enable location services.";
            }
            break;
            
            // User has granted authorization to use their location at any time,
            // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.canOpenSettings)
            {
                self.locationText = @"Location Services: Authorization has been granted for use in the background for the alarms. Touch here to check settings.";
                _locationGoesToSettings = YES;

            }
            else
            {
                self.locationText = @"Location Services: Authorization has been granted for use in the background for the alarms.";

            }
            break;
            
            // User has granted authorization to use their location only when your app
            // is visible to them (it will be made visible to them if you continue to
            // receive location updates while in the background).  Authorization to use
            // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.canOpenSettings)
            {
                self.locationText = @"Location Services: Authorization has been granted for use only when PDX Bus is being used, which means the proximity alarms will not work in iOS 8. Touch here to change this to allow alarms to work - choose 'Always' for location.";
                _locationGoesToSettings = YES;
            }
            else
            {
                self.locationText = @"Location Services: Authorization has been granted for use only when PDX Bus is being used, which means the proximity alarms will not work in iOS 8. To change this to allow alarms to work go to the Settings app and select PDX Bus  - choose 'Always' for location.";
            }
            break;
    }
}

- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Help and Support",@"page title");
        
#define ATTR(X,Y) [NSLocalizedString(X, Y) formatAttributedStringWithFont:self.paragraphFont]
        
        supportText = ATTR(
                           @"#bPDX Bus#b uses real-time tracking information from #bTriMet#b to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
                           "Every #bTriMet#b bus stop and rail station has its own unique #iStop ID#i number, up to five digits. Enter the #iStop ID#i to get the arrivals for that stop.\n\n"
                           "#bPDX Bus#b offers several ways to discover #iStop IDs#i:\n"
                           "- Browse a list of routes and stops;\n"
                           "- Use the #bGPS#b to locate nearby stops;\n"
                           "- Search though the rail stations;\n"
                           "- Use the maps of the rail systems;\n"
                           "- or scan a #bQR code#b (found at some stops).\n\n"
                           "Once you have found your stops - #ibookmark#i them to use them again later.\n\n"
                           "The #iTrip Planner#i feature uses #ischeduled times#i to arrange a journey with several transfers, always check the #bcurrent arrivals#b.\n\n"
                           "See below for other tips and links, touch here to start using #bPDX Bus#b."
                           "\n\nThe arrival data is provided by #bTriMet#b and #bPortland Streetcar#b and is the same as the transit tracker data. "
                           "#b#RPlease contact TriMet for issues about late buses or other transit issues as the app developer cannot help.#b#0"
                           "\n\nFor app support or feature requests please leave a comment on the blog; alternatively use twitter, Facebook or Github. The app developer is not able to respond to app store reviews, "
                           "so please do not use these for support or feature requests. ", @"Main help description");
        
        
        tipText = [[NSArray alloc] initWithObjects:
                   ATTR(@"There are #bLOTS#b of settings for #bPDX Bus#b - take a look at the settings on the home screen to change colors, move the #ibookmarks#i to the top of the screen or change other options.", @"info text"),
                   ATTR(@"Use the top-left #bEdit#b button on the home screen to re-order or modify the #ibookmarks#i.  #iBookmarks#i can be re-ordered, they can also include multiple stops and can be made to show themselves automatically in the morning or evening.", @"info text"),
                   ATTR(@"When the time is shown in #Rred#0 the vehicle will depart in 5 minutes or less.", @"info text"),
                   ATTR(@"When the time is shown in #Bblue#0 the vehicle will depart in more than 5 minutes.", @"info text"),
                   ATTR(@"When the time is shown in #Agray#0 no location infomation is available - the scheduled time is shown.", @"info text"),
                   ATTR(@"When the time is shown in #Mmagenta#0 the vehicle is late.", @"info text"),
                   ATTR(@"When the time is shown in #Oorange#0 and crossed out the vehicle was canceled.  The original scheduled time is shown for reference.", @"info text"),
                   ATTR(@"#bStop IDs:#b Every #bTriMet#b bus stop and rail station has its own unique #iStop ID#i number, up to five digits. Enter the #iStop ID#i to get the arrivals for that stop.", @"info text"),
                   ATTR(@"#bVehicle IDs:#b Every #bTriMet#b bus or train has an ID posted inside (except for the Streetcar). This is the #bVehicle ID#b. The #bVehicle ID#b is shown on the arrival details.  This can help to tell if a MAX car has a low-foor.",  @"info text"),
                   ATTR(@"#b" kBlockNameC " IDs:#b This is an ID given to a specific timetabled movement, internally this is known as a #iblock#i.  You can tag a #b" kBlockNameC " ID#b with a color. "
                        @"#b" kBlockNameC " ID#b color tags can be set to highlight a bus or train so that you can follow its progress through several stops. "
                        @"For example, if you tag an arrival at one stop, you can use the color tag to see when it will arrive at your destination. "
                        @"Also, the tags will remain persistant on each day of the week, so the same bus or train will have the same color the next day.", @"info text"),
                   ATTR(@"Sometimes the scheduled time is also shown in #Agray#0 when the vehicle is not running to schedule.", @"info text"),
                   ATTR(@"Shake the device to #brefresh#b the arrival times.", @"info text"),
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
        
        if ([self canCallTriMet])
        {
            [self addRowType:kSectionTriMetCall];
        }
        [self addRowType:kSectionTriMetSupport];
        [self addRowType:kSectionTriMetTweet];
        
        [self addSectionType:kSectionTips];
        
        for (int i=0; i<tipText.count; i++)
        {
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
        [self addSectionType:kSectionRowHighlights];
        [self addRowType:kSectionRowHighlights];

        if (@available(iOS 12.0, *))
        {
            [self addSectionType:kSectionRowShortcuts];
            [self addRowType:kSectionRowShortcuts];
        }
        
        
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
    
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"About", @"button text")
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(infoAction:)];
        
        
        self.navigationItem.rightBarButtonItem = info;
    }
}

- (void)infoAction:(id)sender
{
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
        case kSectionRowShortcuts:
            return NSLocalizedString(@"Siri Shortcuts", @"section header");
        case kSectionRowLocations:
            if ([UserPrefs sharedInstance].kmlRoutes)
            {
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

- (UITableViewCell *)tableView:(UITableView *)tableView linkCell:(NSString *)text image:(UIImage*)image
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionLinks)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
    cell.textLabel.textColor = [UIColor blueColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.text = text;
    cell.imageView.image = image;
    cell.accessibilityLabel = [NSString stringWithFormat:@"Link to %@", cell.textLabel.text.phonetic];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [self rowType:indexPath];
    
    switch (row) {
        case kSectionRowNetwork:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionNetwork)];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.textLabel.text = NSLocalizedString(@"Check Network Connection", @"main menu item");
            cell.imageView.image = [self getIcon:kIconNetwork];
            return cell;
            break;
        }
        case kSectionRowCache:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionCache)];
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.textLabel.text = NSLocalizedString(@"Delete Cached Routes and Stops", @"main menu item");
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.imageView.image = [self getIcon:kIconDelete];
            return cell;
            break;
        }
        case kSectionRowHighlights:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionHighlights)];
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.textLabel.text = NSLocalizedString(@"Show trip color tags", @"main menu item");
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.imageView.image = [BlockColorDb imageWithColor:[UIColor redColor]];
            return cell;
            break;
        }
        case kSectionRowShortcuts:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionHighlights)];
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.textLabel.text = NSLocalizedString(@"Delete all Siri Shortcuts", @"main menu item");
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.imageView.image = [self getIcon:kIconDelete];
            return cell;
            break;
        }
        case kSectionRowLocations:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionLocations)];
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            if ([UserPrefs sharedInstance].kmlRoutes)
            {
                cell.textLabel.text = NSLocalizedString(@"Show all vehicles & routes", @"main menu item");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Show vehicle locations", @"main menu item");
            }
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.imageView.image = [self getIcon:kIconMap7];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
            break;
        }
        case kSectionSupportRowSupport:
        {
            {
                UITableViewCell *cell =[self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionSupportRowSupport)];
            
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.attributedText =  supportText;
                DEBUG_LOG(@"width:  %f\n", cell.textLabel.bounds.size.width);
                
                [self updateAccessibility:cell];
                // cell.backgroundView = [self clearView];
                return cell;
            }
        case kSectionSupportRowNew:
            {
                UITableViewCell *cell  = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionSupportRowNew)];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.text = NSLocalizedString(@"What's new?", @"main menu item");
                [self updateAccessibility:cell];
                cell.imageView.image = [self getIcon:kIconAppIconAction];
                return cell;
            }
            
            break;
        }
        case kSectionTriMetCall:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionTriMetCall)];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"Call TriMet on 503-238-RIDE", @"main menu item");
            [self updateAccessibility:cell];
            cell.imageView.image =  [self getIcon:kIconPhone];
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
            break;
        }
            
            
        case kSectionSupportHowToRide:
            return [self tableView:tableView
                         linkCell:NSLocalizedString(@"How to ride", @"main menu item")
                            image:[self getIcon:kIconTriMetLink]];
            break;
        case kSectionTriMetSupport:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"TriMet Customer Service", @"main menu item")
                             image:[self getIcon:kIconTriMetLink]];
            
        case kSectionTriMetTweet:
        {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionTriMetTweet)];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"@TriMet on Twitter", @"main menu item");
            [self updateAccessibility:cell];
            cell.imageView.image = [self getIcon:kIconTwitter];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        case kSectionLinkBlog:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"PDX Bus blog & support", @"main menu item")
                             image:[self getIcon:kIconBlog]];
        case kSectionLinkTwitter:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"@pdxbus on Twitter", @"main menu item")
                             image:[self getIcon:kIconTwitter]];
        case kSectionLinkGitHub:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"pdxbus on GitHub", @"main menu item")
                             image:[self getIcon:kIconSrc]];
        case kSectionLinkFacebook:
            return [self tableView:tableView
                          linkCell:NSLocalizedString(@"PDX Bus Facebook page", @"main menu item")
                             image:[self getIcon:kIconFacebook]];
            
        case kSectionPrivacyRowLocation:
        {
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionPrivacy) font:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.locationText;
            [self updateAccessibility:cell];
            return cell;
        }
            
        case kSectionPrivacyRowCamera:
        {
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionPrivacy) font:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.cameraText;
            [self updateAccessibility:cell];
            return cell;
        }
            
            
        default:
        {
            if (row >= kSectionRowTip && (row - kSectionRowTip) < tipText.count)
            {
                NSUInteger tipNumber = row - kSectionRowTip;
                UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionTips)];
                cell.textLabel.attributedText = tipText[tipNumber];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [self updateAccessibility:cell];
                return cell;
                break;
            }
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [self.table cellForRowAtIndexPath:indexPath];
    
    if (cell.textLabel != nil)
    {
        DEBUG_LOGR(cell.frame);
        DEBUG_LOGR(cell.textLabel.frame);
        
    }
    switch ([self rowType:indexPath])
    {
        case kSectionLinkBlog:
        {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
        case kSectionLinkGitHub:
        {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"https:/github.com/teleportaloo/PDX-Bus" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
        
        case kSectionTriMetSupport:
        {
            WebViewController *webPage = [WebViewController viewController];
            [webPage setURLmobile:@"https://trimet.org/contact/customerservice.htm" full:nil];
            [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
            break;
        }
        case kSectionTriMetTweet:
        {
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
        case kSectionRowCache:
        {
            [TriMetXML deleteCacheFile];
            [KMLRoutes deleteCacheFile];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Data Cache", @"alert title")
                                                               message:NSLocalizedString(@"Cached Routes and Stops have been deleted", @"information text")
                                                              delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                     otherButtonTitles:nil ];
            [alert show];
            
            break;
        }
        case kSectionRowHighlights:
        {
            BlockColorViewController *blockTable = [BlockColorViewController viewController];
            [self.navigationController pushViewController:blockTable animated:YES];
            break;
        }
            
        case kSectionRowShortcuts:
        {
            if (@available(iOS 12, *))
            {
                [NSUserActivity deleteAllSavedUserActivitiesWithCompletionHandler:^{
                    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                        [self.table deselectRowAtIndexPath:indexPath animated:YES];
                        UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Siri Shortcuts", @"alert title")
                                                                           message:NSLocalizedString(@"All shortcuts deleted", @"information text")
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                                 otherButtonTitles:nil ];
                        [alert show];
                    }];
                }];
            }
            break;
        }
        case kSectionRowLocations:
        {
            NearestVehiclesMap *mapView = [NearestVehiclesMap viewController];
            mapView.alwaysFetch = YES;
            mapView.allRoutes = YES;
            [mapView fetchNearestVehiclesAsync:self.backgroundTask];
            break;
        }
            
        case kSectionSupportRowSupport:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case kSectionSupportHowToRide:
            [WebViewController displayPage:@"https://trimet.org/howtoride/index.htm"
                                      full:nil
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:self.callbackWhenDone];
            break;
        case kSectionSupportRowNew:
        {
            [self.navigationController pushViewController:[WhatsNewView viewController] animated:YES];
            break;
        }
        case kSectionPrivacyRowLocation:
        {
            
            if (_locationGoesToSettings)
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
            else
            {
                self.locMan = [[CLLocationManager alloc] init];
                
                [self.locMan requestAlwaysAuthorization];
                
                self.locMan.delegate = self;
            }
            break;
        }
        case kSectionPrivacyRowCamera:
        {
            
            if (_cameraGoesToSettings)
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
            else
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if(granted){
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


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self initLocationText];
    [self reloadData];
}




@end


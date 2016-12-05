//
//  SupportView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SupportView.h"
#include "CellLabel.h"
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

#define kSectionSupport			0
#define kSectionTips			1
#define kSectionLinks			2
#define kSectionNetwork			3
#define kSectionCache           4
#define kSectionHighlights      5
#define kSectionLocations       6
#define kSectionPrivacy         7

#define kSections               8

#define kLinkRows				3
			

#define kSectionSupportRowSupport 0
#define kSectionSupportRowNew	 1
#define kSectionSupportHowToRide 2
#define kSectionSupportRows		 3

#define kSectionLinkRows        4
#define kSectionLinkBlog        0
#define kSectionLinkTwitter     1
#define kSectionLinkFacebook    2
#define kSectionLinkGitHub      3

#define kSectionPrivacyRows     2
#define kSectionPrivacyRowLocation 0
#define kSectionPrivacyRowCamera   1



@implementation SupportView

@synthesize hideButton = _hideButton;
@synthesize locMan     = _locMan;
@synthesize locationText = _locationText;
@synthesize cameraText = _cameraText;

- (void)dealloc {
	[supportText release];
    [tipText release];
    self.locMan = nil;
    self.locationText = nil;
    self.cameraText = nil;
	[super dealloc];
}

#pragma mark Helper functions

- (UITableViewStyle) getStyle
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
        
#define ATTR(X) [X formatAttributedStringWithFont:self.paragraphFont]
        
        supportText = ATTR(
                       NSLocalizedString(
                          @"#bPDX Bus#b uses real-time tracking information from #bTriMet#b to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
                          "Every #bTriMet#b bus stop and rail station has its own unique #iStop ID#i number, up to five digits. Enter the #iStop ID#i to get the arrivals for that stop.\n\n"
                          "#bPDX Bus#b offers several ways to discover #iStop IDs#i:\n"
                          "- Browse a list of routes and stops;\n"
                          "- Use the #bGPS#b to locate nearby stops;\n"
                          "- Search though the rail stations;\n"
                          "- Use the maps of the rail systems;\n"
                          "- or scan a #bQR code#b (found at some stops).\n\n"
                          "One you have found your stops - #ibookmark#i them to use them again later.\n\n"
                          "The #iTrip Planner#i feature uses #ischeduled times#i to arrange a journey with several transfers, always check the #bcurrent arrivals#b.\n\n"
                          "See below for other tips and links, touch here to start using #bPDX Bus#b."
                          "\n\nThe arrival data is provided by #bTriMet#b and #bPortland Streetcar#b and is the same as the transit tracker data. "
                          "#b#RPlease contact TriMet for issues about late buses or other transit issues as the app developer cannot help.#b#0"
                          "\n\nFor app support or feature requests please leave a comment on the blog; alternatively use twitter, Facebook or Github. The app developer is not able to respond to app store reviews, "
                          "so please do not use these for support or feature requests. ", @"Main help description")).retain;
                       
        
        tipText = [[NSArray alloc] initWithObjects:
                   ATTR(NSLocalizedString(@"There are #bLOTS#b of settings for #bPDX Bus#b - take a look at the settings on the home screen to change colors, move the #ibookmarks#i to the top of the screen or change other options.", @"info text")),
                   ATTR(NSLocalizedString(@"Use the top-left #bEdit#b button on the home screen to re-order or modify the #ibookmarks#i.  #iBookmarks#i can be re-ordered, they can also include multiple stops and can be made to show themselves automatically in the morning or evening.", @"info text")),
                   ATTR(NSLocalizedString(@"When the time is shown in #Rred#0 the vehicle will depart in 5 minutes or less.", @"info text")),
                   ATTR(NSLocalizedString(@"When the time is shown in #Bblue#0 the vehicle will depart in more than 5 minutes.", @"info text")),
                   ATTR(NSLocalizedString(@"When the time is shown in #Agray#0 no location infomation is available - the scheduled time is shown.", @"info text")),
                   ATTR(NSLocalizedString(@"When the time is shown in #Oorange#0 and crossed out the vehicle was canceled.  The original scheduled time is shown for reference.", @"info text")),
                   ATTR(NSLocalizedString(@"Sometimes the scheduled time is also shown in #Agray#0 when the vehicle is not running to schedule.", @"info text")),
                   ATTR(NSLocalizedString(@"Shake the device to #brefresh#b the arrival times.", @"info text")),
                   ATTR(NSLocalizedString(@"Backup your bookmarks by #iemailing#i them to yourself.", @"info text")),
                   ATTR(NSLocalizedString(@"Keep an eye on the #btoolbar#b at the bottom - there are maps, options, and other features to explore.", @"info text")),
                   ATTR(NSLocalizedString(@"At night, #bTriMet#b recommends holding up a cell phone or flashing light so the driver can see you.", @"info text")),
                   ATTR(NSLocalizedString(@"Many issues can be solved by deleting the app and reinstalling - be sure to #iemail the bookmarks to yourself#i first so you can restore them.", @"info text")),
                   // ATTR(@"Bad escape#"),
                   // ATTR(@"## started ## pound"),
                   nil];
    
        [self initLocationText];
        [self initCameraText];
        
        self.locMan = [[[CLLocationManager alloc] init] autorelease];
        
        [self.locMan requestAlwaysAuthorization];
            
        self.locMan.delegate = self;
	}
	return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"About", @"button text")
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
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
	switch (section) {
		case kSectionSupport:
            return NSLocalizedString(@"PDX Bus - App Support", @"section header");
        case kSectionTips:
			return NSLocalizedString(@"Tips", @"section header");
		case kSectionLinks:
			return NSLocalizedString(@"App Support Links (not TriMet!)", @"section header");
        case kSectionNetwork:
			return NSLocalizedString(@"Network & Server Connectivity", @"section header");
        case kSectionPrivacy:
            return NSLocalizedString(@"Privacy", @"section header");
		case kSectionCache:
			return NSLocalizedString(@"Route and Stop Data Cache", @"section header");
        case kSectionHighlights:
			return NSLocalizedString(@"Vehicle highlights", @"section header");
        case kSectionLocations:
            return NSLocalizedString(@"Vehicle locations", @"section header");

	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionSupport:
			return kSectionSupportRows;
		case kSectionLinks:
			return kSectionLinkRows;
        case kSectionNetwork:
		case kSectionCache:
        case kSectionHighlights:
        case kSectionLocations:
            return 1;
        case kSectionPrivacy:
            return kSectionPrivacyRows;
        case kSectionTips:
			return tipText.count;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case kSectionNetwork:
        {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionNetwork)];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionNetwork)] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.text = NSLocalizedString(@"Check Network Connection", @"main menu item");
				cell.imageView.image = [self getActionIcon:kIconNetwork];
				
			}
			return cell;
			break;
		}
		case kSectionCache:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionCache)];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionCache)] autorelease];
				cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.text = NSLocalizedString(@"Delete Cached Routes and Stops", @"main menu item");
				cell.textLabel.textAlignment = NSTextAlignmentLeft;
				cell.imageView.image = [self getActionIcon:kIconDelete];
			}
			return cell;
			break;
		}
            
        case kSectionHighlights:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionHighlights)];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionHighlights)] autorelease];
				cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.text = NSLocalizedString(@"Show vehicle color tags", @"main menu item");
				cell.textLabel.textAlignment = NSTextAlignmentLeft;
				cell.imageView.image = [BlockColorDb imageWithColor:[UIColor redColor]];
			}
			return cell;
			break;
		}
            
        case kSectionLocations:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionLocations)];
            if (cell == nil) {
                
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionLocations)] autorelease];
                cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.text = NSLocalizedString(@"Show vehicle locations", @"main menu item");
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.imageView.image = [self getActionIcon:kIconMap];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return cell;
            break;
        }
			
		case kSectionSupport:
		{
			if (indexPath.row == kSectionSupportRowSupport)
			{
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionSupportRowSupport)];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionSupportRowSupport)] autorelease];
					cell.view = [self create_UITextView:nil font:self.paragraphFont];
				}
				
				cell.view.font =  self.paragraphFont;
				cell.view.attributedText =  supportText;
                [cell.view setAdjustsFontSizeToFitWidth:NO];
				DEBUG_LOG(@"width:  %f\n", cell.view.bounds.size.width);
    
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
				[self updateAccessibility:cell indexPath:indexPath text:supportText.string alwaysSaySection:YES];
				// cell.backgroundView = [self clearView];
				return cell;
			}
			else {
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionSupportRowNew)];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionSupportRowNew)] autorelease];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					/*
					 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					
					cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
                
                switch (indexPath.row)
                {
                    case kSectionSupportHowToRide:
                        cell.textLabel.text = NSLocalizedString(@"How to ride", @"main menu item");
                        cell.imageView.image = [self getActionIcon:kIconTriMetLink];
                        break;
                    case kSectionSupportRowNew:
                        cell.textLabel.text = NSLocalizedString(@"What's new?", @"main menu item");
                        cell.imageView.image = [self getActionIcon:kIconAppIconAction];
                        break;
                }
				return cell;
			}

			break;
		}
		case kSectionLinks:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionLinks)];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionLinks)] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			
			switch (indexPath.row)
			{
			case kSectionLinkBlog:
                cell.textLabel.text = NSLocalizedString(@"PDX Bus blog & support", @"main menu item");
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
            case kSectionLinkTwitter:
                cell.textLabel.text = NSLocalizedString(@"@pdxbus on Twitter", @"main menu item");
                cell.imageView.image = [self getActionIcon:kIconTwitter];
                break;
            case kSectionLinkGitHub:
                cell.textLabel.text = NSLocalizedString(@"pdxbus on GitHub", @"main menu item");
                cell.imageView.image = [self getActionIcon:kIconSrc];
                break;
            case kSectionLinkFacebook:
                cell.textLabel.text = NSLocalizedString(@"PDX Bus Facebook page", @"main menu item");
                cell.imageView.image = [self getActionIcon:kIconFacebook];
                break;
            }
			cell.accessibilityLabel = [NSString stringWithFormat:@"Link to %@", cell.textLabel.text];
			return cell;
			break;
		}
        case kSectionTips:
		{
			CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionTips)];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionTips)] autorelease];
				cell.view = [self create_UITextView:nil font:self.paragraphFont];
			}
			
			cell.view.font =  self.paragraphFont;
			cell.view.attributedText = tipText[indexPath.row];
            [cell.view setAdjustsFontSizeToFitWidth:NO];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
            NSAttributedString *tip = tipText[indexPath.row];
			[self updateAccessibility:cell indexPath:indexPath text:tip.string alwaysSaySection:YES];
			return cell;
			break;
		}
        case kSectionPrivacy:
        {
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionPrivacy)];
            if (cell == nil) {
                cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kSectionPrivacy)] autorelease];
                cell.view = [self create_UITextView:nil font:self.paragraphFont];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.view.font =  self.paragraphFont;
            
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                cell.view.text = self.locationText;
                [self updateAccessibility:cell indexPath:indexPath text:self.locationText alwaysSaySection:YES];
            }
            else
            {
                cell.view.text = self.cameraText;
                [self updateAccessibility:cell indexPath:indexPath text:self.cameraText alwaysSaySection:YES];
            }
            return cell;
            break;
        }
		default:
			break;
	}
	
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case kSectionSupport:
			if (indexPath.row == kSectionSupportRowSupport)
			{
                return [self getAtrributedTextHeight:supportText] + 20;;
			}
			break;
        case kSectionTips:
        {
            NSAttributedString *tip = tipText[indexPath.row];
			return [self getAtrributedTextHeight:tip] + 20;
        }
        case kSectionPrivacy:
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                return [self getTextHeight:self.locationText font:self.paragraphFont];
            }
            else
            {
                return [self getTextHeight:self.cameraText font:self.paragraphFont];
            }
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [self.table cellForRowAtIndexPath:indexPath];
    
    if (cell.textLabel != nil)
    {
        DEBUG_LOGR(cell.frame);
        DEBUG_LOGR(cell.textLabel.frame);
        
    }
	switch (indexPath.section)
	{
		case kSectionLinks:
		{
            WebViewController *webPage = [WebViewController viewController];
		
			switch (indexPath.row)
			{
				case kSectionLinkBlog:
					[webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil];
                    [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
					break;
                case kSectionLinkGitHub:
					[webPage setURLmobile:@"https:/github.com/teleportaloo/PDX-Bus" full:nil];
                    [webPage displayPage:self.navigationController animated:YES itemToDeselect:self];
					break;
                case kSectionLinkTwitter:
                    self.tweetAt   = @"pdxbus";
                    self.initTweet = @"@pdxbus";
                    [self tweet];
                    break;
                case kSectionLinkFacebook:
                    [self facebook];
                    break;
            }
				
			break;
		}
		case kSectionNetwork:
			[self networkTips:nil networkError:nil];
            [self clearSelection];
			break;
		case kSectionCache:
		{
			[TriMetXML deleteCacheFile];
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
            UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Data Cache", @"alert title")
															   message:NSLocalizedString(@"Cached Routes and Stops have been deleted", @"information text")
															  delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
													 otherButtonTitles:nil ] autorelease];
			[alert show];
			
			break;
		}
        case kSectionHighlights:
		{
            BlockColorViewController *blockTable = [BlockColorViewController viewController];
            [self.navigationController pushViewController:blockTable animated:YES];
            break;
		}
        case kSectionLocations:
        {
            NearestVehiclesMap *mapView = [NearestVehiclesMap viewController];
            mapView.alwaysFetch = YES;
            [mapView fetchNearestVehiclesAsync:self.backgroundTask];
            break;
        }
		case kSectionSupport:
            switch (indexPath.row)
            {
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
            }
			break;
        case kSectionPrivacy:
        {
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                if (_locationGoesToSettings)
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
                else
                {
                    self.locMan = [[[CLLocationManager alloc] init] autorelease];
            
                    [self.locMan requestAlwaysAuthorization];
                
                    self.locMan.delegate = self;
                }
            }
            else
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


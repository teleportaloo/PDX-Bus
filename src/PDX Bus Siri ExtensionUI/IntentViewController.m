//
//  IntentViewController.m
//  PDXBus Siri ExtensionUI
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifdef PDXBUS_EXTENSION
#define LARGE_SCREEN NO
#else
#define LARGE_SCREEN                ([UIApplication sharedApplication].delegate.window.bounds.size.width >= kLargeScreenWidth)
#endif
#define SMALL_SCREEN                !(LARGE_SCREEN)

#import "IntentViewController.h"
#import "ArrivalsIntent.h"
#import "DebugLogging.h"
#import "XMLLocateStops.h"
#import "XMLDepartures+iOSUI.h"
#import "XMLMultipleDepartures.h"
#import "DepartureCell.h"
#import "DepartureData+iOSUI.h"
#import "UIColor+DarkMode.h"

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

@interface IntentViewController ()

@end

@implementation IntentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    DEBUG_FUNC();
}



#define ZeroSize CGSizeMake(0, 0)

#pragma mark - INUIHostedViewControlling

// Prepare your view controller for the interaction to handle.
- (void)configureViewForParameters:(NSSet <INParameter *> *)parameters ofInteraction:(INInteraction *)interaction interactiveBehavior:(INUIInteractiveBehavior)interactiveBehavior context:(INUIHostedViewContext)context completion:(void (^)(BOOL success, NSSet <INParameter *> *configuredParameters, CGSize desiredSize))completion  API_AVAILABLE(ios(11.0)){
    // Do configuration here, including preparing views and calculating a desired size for presentation.
    DEBUG_FUNC();
    
    
    NSUserActivity *activity = nil;
    
    if (@available(iOS 12.0, *)) {
        if ([interaction.intent isKindOfClass:[ArrivalsIntent class]])
        {
            ArrivalsIntentResponse *response = (ArrivalsIntentResponse *)interaction.intentResponse;
            activity = response.userActivity;
        }
    } else {
        // Fallback on earlier versions
    }
    
    if (parameters == nil || activity == nil)
    {
        completion(NO,parameters,ZeroSize);
        return;
    }
        
    NSData *xml = activity.userInfo[@"xml"];
    
    if (xml!=nil)
    {
        // There will be only 1 batch here
        XMLMultipleDepartures *multiple = [XMLMultipleDepartures xml];
        
        multiple.locs = activity.userInfo[@"locs"];
        [multiple reparse:xml.mutableCopy];
    
        self.departures = [NSMutableArray array];
        
        for (XMLDepartures *deps in multiple)
        {
            [self.departures addObject:deps];
        }
        completion(YES,parameters,self.desiredSize);
    }
    else
    {
        completion(NO,parameters,ZeroSize);
    }
}

- (CGSize)desiredSize {
    DEBUG_FUNC();
    
    CGSize sz = [self extensionContext].hostedViewMaximumAllowedSize;
    CGFloat h = 0;
    
    for(XMLDepartures *xml in self.departures)
    {
        h+=self.tableView.sectionHeaderHeight;
        h+= DEPARTURE_CELL_HEIGHT * xml.count;
    }
    
    if (h>0)
    {
        h+=DEPARTURE_CELL_HEIGHT;
    }
    sz.height = h;
    return sz;
}


// - (NSUInteger)table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.departures.count;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DEBUG_FUNC();
    return self.departures[section].count+1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView disclaimerCell:(NSString *)resuseIdentifier
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:resuseIdentifier];
        cell.detailTextLabel.text = kTriMetDisclaimerText;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.numberOfLines = 1;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    XMLDepartures *xml = self.departures[indexPath.section];
    
    if (indexPath.row < xml.count)
    {
        Departure *departure = xml[indexPath.row];
        DepartureCell *dcell = [DepartureCell tableView:tableView cellWithReuseIdentifier:@"departure"];
    
        [xml depPopulateCell:departure cell:dcell decorate:NO wide:NO];
        cell = dcell;
    }
    else
    {
        cell = [self tableView:tableView disclaimerCell:@"static"];
        cell.textLabel.text =[NSString stringWithFormat:NSLocalizedString(@"%@ Updated: %@", @"text followed by time data was fetched"),
                              xml.depStaticText,
                              [NSDateFormatter localizedStringFromDate:xml.depQueryTime
                                                             dateStyle:NSDateFormatterNoStyle
                                                             timeStyle:NSDateFormatterMediumStyle]];
        cell.textLabel.textColor = [UIColor grayColor];
    }
        
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    XMLDepartures *xml = self.departures[section];
    return xml.depGetSectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DEPARTURE_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.minimumScaleFactor = 0.84;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
}



@end

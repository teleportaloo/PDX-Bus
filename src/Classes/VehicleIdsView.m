//
//  VehicleIdsView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleIdsView.h"
#import "TriMetInfo.h"
#import "DepartureTimesView.h"
#import "NSString+Helper.h"

#define kSearchSections         1
#define kSectionSearchHistory   0

#define kSectionAdd             0
#define kSectionHistory         1

#define kPlainId @"plain"

@implementation VehicleIdsView


- (NSMutableArray *)loadItems
{
    return _userData.vehicleIds;
}

- (NSString *)noItems
{
    return NSLocalizedString(@"These recently viewed vehicle IDs can be re-used to get current departures.", @"section title");
}


- (NSInteger)historySection:(UITableView*)tableView
{
    if (tableView == self.table)
    {
        return kSectionHistory;
    }
    return kSectionSearchHistory;
}

- (bool)tableView:(UITableView*)tableView isHistorySection:(NSInteger)section
{
    if (tableView == self.table)
    {
        return [self sectionType:section] == kSectionHistory;
    }
    return [super tableView:tableView isHistorySection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.table)
    {
        return self.sections;
    }
    return kSearchSections;
}


- (instancetype)init
{
    if ((self = [super init]))
    {
        [self clearSectionMaps];
        [self addSectionType:kSectionAdd];
        [self addRowType:kSectionAdd];
        [self addSectionType:kSectionHistory];
    }
    
    return self;
}


-(NSString*)stringToFilter:(NSObject*)i
{
    NSNumber *n = (NSNumber*)i;
    NSDictionary *item = self.localRecents[n.integerValue];
    return [TriMetInfo vehicleString:item[kVehicleId]].removeFormatting;
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Vehicle Ids", @"screen title");
}


#pragma mark  Table View methods


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self tableView:tableView isHistorySection:section])
    {
        return [self filteredData:tableView].count;
    }
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self tableView:tableView isHistorySection:indexPath.section])
    {
        UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionHistory)];
    
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
        // Set up the cell
        NSDictionary *item =[self tableView:tableView filteredDict:indexPath.row];
        NSString *vehicleId = item[kVehicleId];
        cell.textLabel.attributedText = [[TriMetInfo vehicleString:vehicleId] formatAttributedStringWithFont:self.paragraphFont];
        [self updateAccessibility:cell];
        return cell;
    }
    else
    {
        UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:kPlainId];
        
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        cell.textLabel.text =  NSLocalizedString(@"Touch here to enter new vehicle ID", @"button text");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    // [self chosenEndpoint:[self.locList objectAtIndex:indexPath.row] ];
    if ([self tableView:tableView isHistorySection:indexPath.section])
    {
        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
        NSDictionary *item =[self tableView:tableView filteredDict:indexPath.row];
        NSString *vehicleId = item[kVehicleId];
        [departureViewController fetchTimesForVehicleAsync:self.backgroundTask vehicleId:vehicleId];
        
        [_userData addToVehicleIds:vehicleId];
        [self reloadData];
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Vehicle ID", @"Alert title")
                                                                       message:NSLocalizedString(@"Show next departures for a vehicle (not streetcar).", @"Alert text")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Button text") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            NSString *text = [alert.textFields.firstObject.text justNumbers];
            
            if (text && text.length > 0)
            {
                DepartureTimesView *departureView = [DepartureTimesView viewController];
                [departureView fetchTimesForVehicleAsync:self.backgroundTask vehicleId:text];
                
                [self->_userData addToVehicleIds:text];
                [self reloadData];
            }
            else
            {
                [self clearSelection];
            }
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Button text") style:UIAlertActionStyleCancel handler:^(UIAlertAction* action){
            [self clearSelection];
        }]];
        
        alert.popoverPresentationController.sourceView  = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 10, 10);
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

@end

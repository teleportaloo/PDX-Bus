//
//  VehicleIdsViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleIdsViewController.h"
#import "DepartureTimesViewController.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "NearestVehiclesMapViewController.h"
#import "TextViewLinkCell.h"
#import "TriMetInfo.h"
#import "UIAlertController+SimpleMessages.h"
#import "UserParams.h"
#import "ViewControllerBase+LinkCell.h"

#define kSearchSections 1
#define kSectionSearchHistory 0

enum { kSectionRowAdd = 0, kSectionHistory, kRowRowSpecial };

#define kPlainId @"plain"

@interface VehicleIdsViewController ()

@end

@implementation VehicleIdsViewController

- (void)showMap:(id)unused {
    NearestVehiclesMapViewController *mapView =
        [NearestVehiclesMapViewController viewController];

    mapView.staticOverlays = YES;
    mapView.alwaysFetch = YES;
    mapView.allRoutes = YES;
    [mapView fetchNearestVehiclesAsync:self.backgroundTask];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems
        addObject:[UIToolbar mapButtonWithTarget:self
                                          action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (NSMutableArray *)loadItems {
    return _userState.vehicleIds;
}

- (NSString *)noItems {
    return NSLocalizedString(@"These recently viewed vehicle IDs can be "
                             @"re-used to get current departures.",
                             @"section title");
}

- (NSInteger)historySection:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kSectionHistory;
    }

    return kSectionSearchHistory;
}

- (bool)tableView:(UITableView *)tableView isHistorySection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self sectionType:section] == kSectionHistory;
    }

    return [super tableView:tableView isHistorySection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return self.sections;
    }

    return kSearchSections;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self clearSectionMaps];
        [self addSectionType:kSectionRowAdd];
        [self addRowType:kSectionRowAdd];
        [self addRowType:kRowRowSpecial];
        [self addSectionType:kSectionHistory];
    }

    return self;
}

- (NSString *)stringToFilter:(NSObject *)i {
    NSNumber *n = (NSNumber *)i;
    UserParams *item = self.localRecents[n.integerValue].userParams;

    return [TriMetInfo markedUpVehicleString:item.valVehicleId].removeMarkUp;
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[TextViewLinkCell nib]
         forCellReuseIdentifier:MakeCellId(kSectionHistory)];

    self.title = NSLocalizedString(@"Vehicle Ids", @"screen title");
}

#pragma mark Table View methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    if ([self tableView:tableView isHistorySection:section]) {
        return [self filteredData:tableView].count;
    }

    return [self rowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self tableView:tableView isHistorySection:indexPath.section]) {
        TextViewLinkCell *cell = (TextViewLinkCell *)[self.tableView
            dequeueReusableCellWithIdentifier:MakeCellId(kSectionHistory)];

        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        // Set up the cell
        UserParams *item =
            [self tableView:tableView filteredDict:indexPath.row].userParams;
        NSString *vehicleId = item.valVehicleId;
        cell.textView.attributedText =
            [TriMetInfo markedUpVehicleString:vehicleId]
                .smallAttributedStringFromMarkUp;
        cell.urlCallback = self.urlActionCalback;
        [self updateAccessibility:cell];
        return cell;
    } else {
        switch ([self rowType:indexPath]) {
        default:
        case kSectionRowAdd: {
            UITableViewCell *cell = [self tableView:tableView
                   multiLineCellWithReuseIdentifier:kPlainId];

            cell.editingAccessoryType = UITableViewCellAccessoryNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;

            cell.textLabel.text = NSLocalizedString(
                @"Touch here to enter new vehicle ID", @"button text");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        }
        case kRowRowSpecial: {
            UITableViewCell *cell = [self tableView:tableView
                   multiLineCellWithReuseIdentifier:kPlainId];
            cell.editingAccessoryType = UITableViewCellAccessoryNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text =
                NSLocalizedString(@"Show Celebration vehicles", @"button text");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        }
        }
    }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController
    // alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];

    // [self chosenEndpoint:[self.locList objectAtIndex:indexPath.row] ];
    if ([self tableView:tableView isHistorySection:indexPath.section]) {
        DepartureTimesViewController *departureViewController =
            [DepartureTimesViewController viewController];
        UserParams *item =
            [self tableView:tableView filteredDict:indexPath.row].userParams;
        NSString *vehicleId = item.valVehicleId;
        [departureViewController fetchTimesForVehicleAsync:self.backgroundTask
                                                 vehicleId:vehicleId];

        [_userState addToVehicleIds:vehicleId];
        [self reloadData];
    } else {
        switch ([self rowType:indexPath]) {
        default:
        case kSectionRowAdd: {
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:NSLocalizedString(@"Enter Vehicle ID",
                                                           @"Alert title")
                                 message:NSLocalizedString(
                                             @"Show next departures for a "
                                             @"vehicle (not streetcar).",
                                             @"Alert text")
                          preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(
                       UITextField *_Nonnull textField) {
              [textField setKeyboardType:UIKeyboardTypeNumberPad];
            }];

            [alert
                addAction:
                    [UIAlertAction
                        actionWithTitle:kAlertViewOK
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                  NSString *text = [alert.textFields.firstObject
                                                        .text justNumbers];

                                  if (text && text.length > 0) {
                                      DepartureTimesViewController
                                          *departureView =
                                              [DepartureTimesViewController
                                                  viewController];
                                      [departureView
                                          fetchTimesForVehicleAsync:
                                              self.backgroundTask
                                                          vehicleId:text];

                                      [self->_userState addToVehicleIds:text];
                                      [self reloadData];
                                  } else {
                                      [self clearSelection];
                                  }
                                }]];

            [alert addAction:[UIAlertAction
                                 actionWithTitle:kAlertViewCancel
                                           style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction *action) {
                                           [self clearSelection];
                                         }]];

            alert.popoverPresentationController.sourceView = self.view;
            alert.popoverPresentationController.sourceRect =
                CGRectMake(self.view.frame.size.width / 2,
                           self.view.frame.size.height / 2, 10, 10);

            [self.navigationController presentViewController:alert
                                                    animated:YES
                                                  completion:nil];
            break;
        }

        case kRowRowSpecial: {

            TriMetInfo_VehicleSpecialConstPtr specials =
                TriMetInfo_getVehicleSpecial();

            for (TriMetInfo_VehicleSpecialConstPtr special = specials;
                 special->markedUpSpecialInfo != nil; special++) {

                TriMetInfo_VehicleConstPtr vehicle =
                    [TriMetInfo vehicleInfo:special->vehicleId];

                if (vehicle->locatable) {
                    [self->_userState
                        addToVehicleIds:[NSString stringWithFormat:@"%ld",
                                                                   special->
                                                                   vehicleId]];
                }
            }

            [self reloadData];
            break;
        }
        }
    }
}

@end

//
//  TripPlannerBookmarkView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/3/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerBookmarkView.h"
#import "XMLDepartures.h"
#import "StopNameCacheManager.h"
#import "NSString+Helper.h"
#import "TaskState.h"

@interface TripPlannerBookmarkView ()

@property (nonatomic, strong) NSMutableArray *locList;


@end

@implementation TripPlannerBookmarkView

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Data fetchers



- (void)fetchNamesForStopIdsAsync:(id<TaskController>)taskController stopIds:(NSString *)stopIds {
    [taskController taskRunAsync:^(TaskState *taskState) {
        self.locList = [NSMutableArray array];
        
        NSArray<NSString*> *stopIdArray  = stopIds.arrayFromCommaSeparatedString;
        
        [taskState taskStartWithTotal:stopIdArray.count title:NSLocalizedString(@"getting stop names", @"progress message")];
        
        StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];
        
        NSDictionary *names = [stopNameCache getStopNames:stopIdArray fetchAndCache:YES updated:nil completion:^(int item) {
            [taskController taskItemsDone:item + 1];
        }];
        
        for (NSString *stopId in stopIdArray) {
            NSArray *stopName = names[stopId];
            
            if (stopName) {
                [self.locList addObject:stopName];
            }
        }
        
        return (UIViewController *)self;
    }];
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.title == nil) {
        self.title = NSLocalizedString(@"Bookmarked stops", @"page title");
    }
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.from) {
        return NSLocalizedString(@"Choose a starting stop:", @"section header");
    }
    
    return NSLocalizedString(@"Choose a destination stop:", @"section header");
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.locList.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"tripbookmark"];
    
    NSArray *stopInfo = self.locList[indexPath.row];
    
    // cell.textLabel.text = dep.locDesc;
    cell.textLabel.text = [StopNameCacheManager getLongName:stopInfo];
    
    cell.textLabel.adjustsFontSizeToFitWidth = true;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.font = self.basicFont;
    
    if (cell.textLabel.text != nil) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
    
    NSArray *stopInfo = self.locList[indexPath.row];
    
    /*    if ([self.callback getController] != nil)
     {
     [self.navigationController popToViewController:[self.callback getController] animated:YES];
     } */
    
    if ([self.stopIdCallback respondsToSelector:@selector(selectedStop:desc:)]) {
        // cell.textLabel.text = dep.locDesc;
        [self.stopIdCallback selectedStop:[StopNameCacheManager getStopId:stopInfo] desc:[StopNameCacheManager getLongName:stopInfo]];
    } else {
        [self.stopIdCallback selectedStop:[StopNameCacheManager getStopId:stopInfo]];
    }
}

@end

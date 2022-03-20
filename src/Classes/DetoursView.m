//
//  DetoursView.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetoursView.h"
#import "Detour.h"
#import "DirectionView.h"
#import "DebugLogging.h"
#import "Detour+iOSUI.h"
#import "NSString+Helper.h"
#import "TriMetInfo.h"
#import "WebViewController.h"
#import "NSString+Helper.h"
#import "MapViewWithDetourStops.h"
#import "XMLDetoursAndMessages.h"
#import "TaskState.h"
#import "DetourTableViewCell.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "SystemWideAlertsIntent.h"

#define kGettingDetours NSLocalizedString(@"getting detours", @"progress message")

@interface DetoursView () {
    NSInteger _disclaimerSection;
}

@property (nonatomic, strong) XMLDetoursAndMessages *detours;
@property (nonatomic, strong) NSMutableArray<DetoursForRoute *> *sortedDetours;
@property (nonatomic, strong) NSArray *routes;

@end

@implementation DetoursView

- (bool)tableView:(UITableView *)tableView disclaimerSection:(NSInteger)section {
    if (section == _disclaimerSection && tableView == self.table) {
        return YES;
    }
    
    return NO;
}

- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index {
    DetoursForRoute *result = [DetoursForRoute new];
    DetoursForRoute *item = (DetoursForRoute *)i;
    
    if ([item.route.desc hasCaseInsensitiveSubstring:searchText]) {
        return i;
    }
    
    result.route = item.route;
    
    for (Detour *d in item.detours) {
        if ([[d markedUpDescription:nil].removeMarkUp hasCaseInsensitiveSubstring:searchText]
            || [d.markedUpHeader.removeMarkUp hasCaseInsensitiveSubstring:searchText]) {
            [result.detours addObject:d];
        }
    }
    
    if (result.detours.count == 0) {
        result = nil;
    }
    
    return result;
}

- (void)initSearchArray {
    self.searchableItems = self.sortedDetours;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.enableSearch = YES;
        self.refreshFlags = kRefreshButton | kRefreshShake;
    }
    
    return self;
}

#pragma mark Data fetchers

- (void)sort:(NSArray *)routes {
    // Sort the detours
    self.sortedDetours = [NSMutableArray array];
    
    bool found = NO;
    
    NSMutableSet *detoursNoLongerFound = Settings.hiddenSystemWideDetours.mutableCopy;
    
    for (Detour *d in self.detours) {
        if (d.systemWide) {
            [detoursNoLongerFound removeObject:d.detourId];
        }
        
        for (Route *r in d.routes) {
            found = NO;
            
            for (DetoursForRoute *detoursForRoute in self.sortedDetours) {
                if ([r.route isEqualToString:detoursForRoute.route.route]) {
                    [detoursForRoute.detours addObject:d];
                    found = YES;
                    break;
                }
            }
            
            if (!found) {
                DetoursForRoute *detours = [DetoursForRoute new];
                detours.route = r;
                [detours.detours addObject:d];
                [self.sortedDetours addObject:detours];
            }
        }
    }
    
    if (routes) {
        [Settings removeOldSystemWideDetours:detoursNoLongerFound];
    }
    
    // Remove any not in our route list
    if (routes) {
        NSSet<NSString *> *routeSet = [NSSet setWithArray:routes];
        
        NSInteger i;
        
        for (i = 0; i < self.sortedDetours.count;) {
            DetoursForRoute *d = self.sortedDetours[i];
            
            if (![routeSet containsObject:d.route.route] && !d.route.systemWide) {
                [self.sortedDetours removeObjectAtIndex:i];
            } else {
                i++;
            }
        }
    }
    
    [self.sortedDetours sortUsingComparator:^NSComparisonResult (DetoursForRoute *d1, DetoursForRoute *d2)
     {
        return [d1.route compare:d2.route];
    }];
    
    [self.sortedDetours enumerateObjectsUsingBlock:^(DetoursForRoute * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.detours sortUsingSelector:@selector(compare:)];
    }];
    
    [self initSearchArray];
}

- (void)fetchDetours:(NSArray *)routes taskController:(id<TaskController>)taskController backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
        self.backgroundRefresh = backgroundRefresh;
        
        self.detours = [XMLDetoursAndMessages xmlWithRoutes:routes];
        
        [taskState startAtomicTask:kGettingDetours];
        self.routes = routes;
        self.detours.oneTimeDelegate = taskState;
        [self.detours fetchDetoursAndMessages];
        
        [self sort:routes];
        self->_disclaimerSection = self.sortedDetours.count;
        
        [self updateRefreshDate:nil];
        return (UIViewController *)self;
    }];
}

- (void)fetchDetoursAsync:(id<TaskController>)taskController {
    [self fetchDetours:nil taskController:taskController backgroundRefresh:NO];
}

- (void)fetchDetoursAsync:(id<TaskController>)taskController routes:(NSArray *)routes backgroundRefresh:(bool)backgroundRefresh {
    [self fetchDetours:routes taskController:taskController backgroundRefresh:backgroundRefresh];
}

- (void)fetchDetoursAsync:(id<TaskController>)taskController route:(NSString *)route {
    [taskController taskRunAsync:^(TaskState *taskState) {
        [taskState startAtomicTask:kGettingDetours];
        self.detours = [XMLDetoursAndMessages xmlWithRoutes:@[route]];
        self.detours.oneTimeDelegate = taskState;
        [self.detours fetchDetoursAndMessages];
        [self sort:@[route]];
        self->_disclaimerSection = self.sortedDetours.count;
        return (UIViewController *)self;
    }];
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView disclaimerSection:section]) {
        return nil;
    }
    
    DetoursForRoute *detours = [self filteredData:tableView][section];
    
    if (detours.detours.count > 0 && detours.detours.firstObject.systemWide && [Settings.hiddenSystemWideDetours containsObject:detours.detours.firstObject.detourId]) {
        return nil;
    }
    
    return detours.route.desc;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.table) {
        return self.sortedDetours.count + 1;
    }
    
    return [self filteredData:tableView].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self tableView:tableView disclaimerSection:section]) {
        return 1;
    }
    
    return [self filteredData:tableView][section].detours.count;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self tableView:tableView disclaimerSection:indexPath.section]) {
        return kDisclaimerCellHeight;
    }
    
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self tableView:tableView disclaimerSection:indexPath.section]) {
        UITableViewCell *cell = nil;
        
        cell = [self disclaimerCell:tableView];
        
        if (self.detours.items == nil) {
            [self noNetworkDisclaimerCell:cell];
        } else if (self.detours.count == 0) {
            [self addTextToDisclaimerCell:cell text:NSLocalizedString(@"No current detours", @"empty list message")];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [self updateDisclaimerAccessibility:cell];
        return cell;
    } else {
        Detour *detour = [self filteredData:tableView][indexPath.section].detours[indexPath.row];
        
        
        DetourTableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:detour.reuseIdentifer];
        DetoursForRoute *detours = [self filteredData:tableView][indexPath.section];
        
        [cell populateCell:detours.detours[indexPath.row] route:detours.route.route];

         __weak __typeof__(self) weakSelf = self;
        
        cell.buttonCallback = ^(DetourTableViewCell *cell, NSInteger tag) {
            [weakSelf detourAction:cell.detour buttonType:tag indexPath:indexPath reloadSection:NO];
        };
        
        cell.urlCallback = self.detourActionCalback;
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self tableView:tableView disclaimerSection:indexPath.section]) {
        DetoursForRoute *detours = [self filteredData:tableView][indexPath.section];
        Detour *detour = detours.detours[indexPath.row];
        [self detourToggle:detour indexPath:indexPath reloadSection:YES];
    } else if (self.detours.items == nil) {
        [self networkTips:self.detours.htmlError networkError:self.detours.networkErrorMsg];
        [self clearSelection];
    }
}

#pragma mark View methods

- (void)loadView {
    [super loadView];
    self.title = NSLocalizedString(@"Alerts & Detours", @"screen title");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.table registerNib:[DetourTableViewCell nib] forCellReuseIdentifier:kSystemDetourResuseIdentifier];
    [self.table registerNib:[DetourTableViewCell nib] forCellReuseIdentifier:kDetourResuseIdentifier];
    
    [self safeScrollToTop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)buttonAction:(UIBarButtonItem *)sender  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Siri"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add TriMet system-wide alerts to Siri", @"menu")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        SystemWideAlertsIntent *intent = [[SystemWideAlertsIntent alloc] init];
        
        intent.suggestedInvocationPhrase = NSLocalizedString(@"TriMet system-wide alerts", @"menu");
        
        INShortcut *shortCut = [[INShortcut alloc] initWithIntent:intent];
        
        INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.delegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];
        
    }]];
        
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
    
    alert.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)mapAction:(id)unused {
    [[MapViewWithDetourStops viewController] fetchLocationsMaybeAsync:self.backgroundTask detours:self.detours.items nav:self.navigationController];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    if (self.detours.gotData && self.detours.items.count > 0) {
        [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(mapAction:)]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
#if !TARGET_OS_MACCATALYST
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                           target:self
                                                                           action:@selector(buttonAction:)]];
    [toolbarItems addObject:[UIToolbar flexSpace]];
#endif
    
    [self updateToolbarItemsWithXml:toolbarItems];
}

- (void)appendXmlData:(NSMutableData *)buffer {
    [self.detours appendQueryAndData:buffer];
}

- (void)refreshAction:(id)unused {
    if (!self.backgroundRefresh) {
        [self fetchDetoursAsync:self.backgroundTask routes:self.routes backgroundRefresh:YES];
    }
}

@end

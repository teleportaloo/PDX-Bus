//
//  BlockColorViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/26/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorViewController.h"
#import "TriMetInfo.h"
#import "NSString+Helper.h"

#define kSectionData   0
#define kSectionNoData 1
#define kSections      2

@interface BlockColorViewController () {
    NSArray *_keys;
    BlockColorDb *_db;
    NSString *_changingColor;
    NSString *_helpText;
}

- (void)colorPickerControllerDidFinish:(InfColorPickerController *)controller;

@end

@implementation BlockColorViewController

- (void)initKeys {
    _keys = [_db.keys sortedArrayUsingComparator:^NSComparisonResult (NSString *obj1, NSString *obj2) {
        NSDate *d1 = [self->_db timeForBlock:obj1];
        NSDate *d2 = [self->_db timeForBlock:obj2];
        return [d1 compare:d2];
    }];
}

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@kBlockNameC " Color Tags", @"screen text");
        _db = [BlockColorDb sharedInstance];
        
        [self initKeys];
        
        
        self.table.allowsSelectionDuringEditing = YES;
        _helpText = NSLocalizedString(@kBlockNameC " color tags can be set to highlight a bus or train so that you can follow its progress through several stops. "
                                      @"For example, if you tag a departure at one stop, you can use the color tag to see when it will arrive at your destination. "
                                      @"Also, the tags will remain persistant on each day of the week, so the same bus or train will have the same color the next day.\n\n"
                                      @"To set a tag, click 'Tag this " kBlockName " with a color' from the departure details.", @"Tagging help screen");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deleteAll:(id)sender {
    [_db clearAll];
    
    [self initKeys];
    [self reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case kSectionData:
            return _keys.count;
            
        case kSectionNoData:
            return (_keys.count > 0 ? 0 : 1);
    }
    return 0;
}

- (UILabel *)create_UITextView:(UIFont *)font {
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
    
    UILabel *textView = [[UILabel alloc] initWithFrame:frame];
    
    textView.textColor = [UIColor modeAwareText];
    textView.font = font;
    textView.backgroundColor = [UIColor modeAwareCellBackground];
    textView.lineBreakMode = NSLineBreakByWordWrapping;
    textView.adjustsFontSizeToFitWidth = YES;
    textView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    textView.numberOfLines = 0;
    
    return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionData) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionData)];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MakeCellId(kSectionData)];
        }
        
        // Configure the cell...
        NSString *key = _keys[indexPath.row];
        UIColor *col = [_db colorForBlock:key];
        
        cell.imageView.image = [BlockColorDb imageWithColor:col];
        cell.textLabel.text = [_db descForBlock:key];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        cell.detailTextLabel.text = [NSString stringWithFormat:@kBlockNameC " ID %@ - %@", key,
                                     [NSDateFormatter localizedStringFromDate:[_db timeForBlock:key] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        
        return cell;
    } else {
        UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"HelpCell" font:self.paragraphFont];
        cell.textLabel.text = _helpText;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessibilityLabel = _helpText.phonetic;
        return cell;
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionData) {
        _changingColor = _keys[indexPath.row];
        
        InfColorPickerController *picker = [ InfColorPickerController colorPickerViewController ];
        
        picker.delegate = self;
        
        picker.sourceColor = [_db colorForBlock:_changingColor];
        
        
        [ picker presentModallyOverViewController:self ];
    }
}

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionData) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSString *block = _keys[indexPath.row];
            
            [_db addColor:nil forBlock:block description:nil];
            
            [self initKeys];
            
            [tableView beginUpdates];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
            
            if (_keys.count == 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:kSectionNoData];
                [tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:YES];
            }
            
            [tableView endUpdates];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionNoData) {
        return UITableViewAutomaticDimension;
    }
    
    return tableView.rowHeight;
}

- (void)colorPickerControllerDidFinish:(InfColorPickerController *)controller {
    NSString *desc = [_db descForBlock:_changingColor];
    
    [_db   addColor:controller.resultColor
           forBlock:_changingColor
        description:desc];
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    _changingColor = nil;
    
    [self reloadData];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    // match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
    // UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
    
    
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete All", @"button text")
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(deleteAll:)];
    
    
    delete.style = UIBarButtonItemStylePlain;
    delete.accessibilityLabel = NSLocalizedString(@"Delete all", @"accessibility text");
    
    [toolbarItems addObject:delete];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

@end

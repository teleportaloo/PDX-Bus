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


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "BlockColorViewController.h"
#import "NSString+Core.h"
#import "PDXBus-Swift.h"
#import "TriMetInfo+UI.h"

enum SECTION_ROW { kSectionData, kSectionNoData };

@interface BlockColorViewController () {
    NSArray *_keys;
    BlockColorDb *_db;
    NSString *_helpText;
}

@end

@implementation BlockColorViewController

- (void)initKeys {
    _keys =
        [_db.keys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
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

        self.tableView.allowsSelectionDuringEditing = YES;
        _helpText = NSLocalizedString(
            @kBlockNameC " color tags can be set to highlight a bus or train so that you "
                         "can follow its progress through several stops. "
                        @"For example, if you tag a departure at one stop, you can use the "
                        @"color tag to see when it will arrive at your destination. "
                        @"Also, the tags will remain persistant on each day of the week, so "
                        @"the same bus or train will have the same color the next day.\n\n"
                        @"To set a tag, click 'Tag this " kBlockName
                         " with a color' from the departure details.",
            @"Tagging help screen");

        [self createSections];
    }

    return self;
}

- (void)createSections {
    [self clearSectionMaps];

    if (_keys.count > 0) {
        [self addSectionType:kSectionData];
        [self addRowType:kSectionData count:_keys.count];
    } else {
        [self addSectionTypeWithRow:kSectionNoData];
    }
}

- (void)deleteAll:(id)sender {
    [_db clearAll];

    [self initKeys];
    [self createSections];
    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelectionDuringEditing = YES;
}

#pragma mark - Table view delegate

// Override if you support editing the list
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kSectionData) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSString *block = _keys[indexPath.row];

            [_db addColor:nil forBlock:block description:nil];

            [self initKeys];

            [tableView beginUpdates];

            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [self removeRowAtIndexPath:indexPath];

            if (_keys.count == 0) {
                [self createSections];
                NSIndexPath *ip =
                    [NSIndexPath indexPathForRow:0
                                       inSection:[self firstSectionOfType:kSectionNoData]];
                [tableView insertRowsAtIndexPaths:@[ ip ]
                                 withRowAnimation:UITableViewRowAnimationAutomatic];
            }

            [tableView endUpdates];
        }
    }
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    UIBarButtonItem *del =
        [UIBarButtonItem textButton:NSLocalizedString(@"Delete All", @"button text")
                             target:self
                             action:@selector(deleteAll:)];

    del.style = UIBarButtonItemStylePlain;
    del.accessibilityLabel = NSLocalizedString(@"Delete all", @"accessibility text");

    [toolbarItems addObject:del];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS BlockColorViewController

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionData

CELL_CONFIG_METHOD(kSectionData) {

    // One of the few cases where we have to make the cell from scatch as we want the subtitle
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionData)];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:MakeCellId(kSectionData)];
    }

    // Configure the cell...
    NSString *key = _keys[indexPath.row];
    UIColor *col = [_db colorForBlock:key];

    cell.imageView.image = [BlockColorDb imageWithColor:col];
    cell.textLabel.text = [_db descForBlock:key];
    cell.textLabel.adjustsFontSizeToFitWidth = NO;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.detailTextLabel.text = [NSString
        stringWithFormat:@kBlockNameC " ID %@ - %@",
                         key,
                         [NSDateFormatter localizedStringFromDate:[_db timeForBlock:key]
                                                        dateStyle:NSDateFormatterMediumStyle
                                                        timeStyle:NSDateFormatterShortStyle]];
    return cell;
}

CELL_SELECT_METHOD(kSectionData) {
    if ([self rowType:indexPath] == kSectionData) {
        NSString *changingColor = _keys[indexPath.row];

        __weak __typeof(self) weakSelf = self;

        UIViewController *pickerVC = [SimpleColorPickerCoordinator
            createWithInitialColor:[_db colorForBlock:changingColor]
                             title:@"Pick tag color"
                          onPicked:^(UIColor *selectedColor) {
                            __strong __typeof(self) strongSelf = weakSelf;
                            if (!strongSelf)
                                return;
                            if (selectedColor) {
                                NSString *desc = [strongSelf->_db descForBlock:changingColor];

                                [strongSelf->_db addColor:selectedColor
                                                 forBlock:changingColor
                                              description:desc];
                            }
                            [strongSelf reloadData];
                          }];

        [self presentViewController:pickerVC animated:YES completion:nil];
    }
}

CELL_STATIC_VTABLE(kSectionData){
    SET_CELL_CONFIG_SEL(kSectionData),
    SET_CELL_SELECT_SEL(kSectionData),
    SET_CELL_EDITING_STYLE_SEL(delete),
    SET_CELL_CAN_EDIT_SEL(yes),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionNoData

PARA_CELL(kSectionNoData, _helpText, nil);

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kSectionData),
    CELL_MAP(kSectionNoData),
};

@end

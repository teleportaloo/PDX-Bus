//
//  AddNewStopToBookMark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "AddNewStopToBookMark.h"
#import "CellTextField.h"
#import "NSString+Helper.h"
#import "Icons.h"
#import "UIColor+DarkMode.h"

enum {
    kRowEnter,
    kRowDone
};

#define kDoneId       @"DoneCell"
#define kUIEditHeight 50.0
#define kUIRowHeight  40.0

@interface AddNewStopToBookMark ()

@property (nonatomic, strong) UITextField *editWindow;

@end

@implementation AddNewStopToBookMark

#pragma mark Helper functions

- (instancetype)init {
    if ((self = [super init])) {
        [self clearSectionMaps];
        [self addSectionType:kRowEnter];
        [self addRowType:kRowEnter];
        [self addRowType:kRowDone];
    }
    
    return self;
}

- (UITextField *)createTextField_Rounded {
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, [CellTextField editHeight]);
    UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];
    
    returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor modeAwareText];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = NSLocalizedString(@"<enter stop ID>", @"default stop id text");
    returnTextField.backgroundColor = [UIColor modeAwareGrayBackground];
    returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;            // no auto correction support
    
    returnTextField.keyboardType = UIKeyboardTypeNumberPad;
    returnTextField.returnKeyType = UIReturnKeyDone;
    
    returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;          // has a clear 'x' button to the right
    self.editWindow = returnTextField;
    
    return returnTextField;
}

#pragma mark TableViewWithToolbar functions

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark View functions

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                     target:self
                                     action:@selector(cancelAction:)];
    
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editWindow becomeFirstResponder];
    [super viewWillAppear:animated];
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Enter stop ID:", @"stop id section header");
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [CellTextField cellHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SimpleEdit";
    
    switch ([self rowType:indexPath]) {
        case kRowEnter: {
            CellTextField *sourceCell = (CellTextField *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (sourceCell == nil) {
                sourceCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                ((CellTextField *)sourceCell).view = [self createTextField_Rounded];
                ((CellTextField *)sourceCell).delegate = self;
                self.editWindow = sourceCell.view;
                [self.editWindow becomeFirstResponder];
                sourceCell.cellLeftOffset = 50.0;
                sourceCell.imageView.image = [Icons getIcon:kIconEnterStopID];
                return sourceCell;
            }
            
            break;
        }
            
        case kRowDone: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kDoneId];
            
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            // Set up the cell
            cell.textLabel.text = NSLocalizedString(@"Add this stop ID", @"action button");
            cell.imageView.image = [Icons getIcon:kIconAdd];
            // [self maybeAddSectionToAccessibility:cell indexPath:indexPath];
            cell.textLabel.font = self.basicFont;
            return cell;
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITextView *textView = (UITextView *)self.editWindow;
    NSString *editText = [textView.text justNumbers];
    
    NSInteger rowType = [self rowType:indexPath];
    
    if (rowType == kRowDone && editText.length != 0) {
        [self.editWindow resignFirstResponder];
    } else {
        NSIndexPath *ip = self.table.indexPathForSelectedRow;
        
        if (ip != nil) {
            [self.table deselectRowAtIndexPath:ip animated:YES];
        }
    }
}

#pragma mark Editing functions

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell {
    // add our custom add button as the nav bar's custom right view
    return YES;
}

// Invoked after editing ends.


- (void)cellDidEndEditing:(EditableTableViewCell *)cell {
    UITextView *textView = (UITextView *)((CellTextField *)cell).view;
    NSString *editText = [textView.text justNumbers];
    
    if (editText.length != 0 && self.navigationItem.rightBarButtonItem != nil) {
        if (self.stopIdStringCallback.returnStopIdStringController != nil) {
            [self.navigationController popToViewController:self.stopIdStringCallback.returnStopIdStringController animated:YES];
        }
        
        [self.stopIdStringCallback returnStopIdString:editText desc:nil];
    }
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)cancelAction:(id)sender {
    self.navigationItem.rightBarButtonItem = nil;
    [self.editWindow resignFirstResponder];
    [self.navigationController popToViewController:self.stopIdStringCallback.returnStopIdStringController animated:YES];
}

@end

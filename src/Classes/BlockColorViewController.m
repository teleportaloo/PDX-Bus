//
//  BlockColorViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/26/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorViewController.h"
#import "CellLabel.h"

@interface BlockColorViewController ()

@end

#define kSectionData        0
#define kSectionNoData      1
#define kSections           2

@implementation BlockColorViewController


- (instancetype)init
{
	if ((self = [super init]))
	{
		self.title = NSLocalizedString(@"Vehicle Color Tags", @"screen text");
        _db = [[BlockColorDb singleton] retain];
        _keys = [[_db keys] retain];
        self.table.allowsSelectionDuringEditing = YES;
        _helpText = NSLocalizedString(@"Vehicle color tags can be set to highlight a bus or train so that you can follow its progress through several stops. "
                                                      @"For example, if you tag an arrival at one stop, you can use the color tag to see when it will arrive at your destination. "
                                                      @"Also, the tags will remain persistant on each day of the week, so the same bus or train will have the same color the next day.\n\n"
                                                      @"To set a tag, click 'Tag this vehicle with a color' from the arrival details.", @"Tagging help screen");

	}
	return self;
}

- (void)dealloc
{
    [_db release];
    [_keys release];
    [_changingColor release];
    [_helpText release];
    
    [super dealloc];
}



- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deleteAll:(id)sender
{
    [_db clearAll];
    [_keys release];
    _keys = [_db keys];
    [self reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return kSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section)
    {
        case kSectionData:
            return _keys.count;
        case kSectionNoData:
            return (_keys.count> 0 ? 0 : 1);
    }
    return 0;
}

-(UILabel *)create_UITextView:(UIFont *)font
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	
	UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = font;
    textView.backgroundColor = [UIColor whiteColor];
	textView.lineBreakMode =   NSLineBreakByWordWrapping;
	textView.adjustsFontSizeToFitWidth = YES;
	textView.numberOfLines = 0;
    
	return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionData)
    {

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionData)];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MakeCellId(kSectionData)] autorelease];
        }
        
        // Configure the cell...
        NSString *key = _keys[indexPath.row];
        UIColor *col  = [_db colorForBlock:key];
        
        cell.imageView.image = [BlockColorDb imageWithColor:col];
        cell.textLabel.text  =  [_db descForBlock:key];
    
        cell.detailTextLabel.text = [NSString stringWithFormat:@"ID %@ - %@", key,
                                     [NSDateFormatter localizedStringFromDate:[_db timeForBlock:key] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        
        
        return cell;
    }
    else
    {
		NSString *MyIdentifier = [NSString stringWithFormat:@"CellLabel%f", [self getTextHeight:_helpText font:self.paragraphFont]];
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
			cell.view = [self create_UITextView:self.paragraphFont];
		}
		
		cell.view.text = _helpText;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		cell.accessibilityLabel = _helpText;
        
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionData)
    {
        _changingColor = [_keys[indexPath.row] retain];
        
        InfColorPickerController* picker = [ InfColorPickerController colorPickerViewController ];
        
        picker.delegate = self;
        
        picker.sourceColor = [_db colorForBlock:_changingColor];
        
        
        [ picker presentModallyOverViewController: self ];
    }
    
}


// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == kSectionData)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            
            NSString *block = _keys[indexPath.row];
            
            [_db addColor:nil forBlock:block description:nil];
            [_keys release];
            _keys = [[_db keys] retain];
            
            [tableView beginUpdates];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
            
            if (_keys.count == 0)
            {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:kSectionNoData] ;
                [tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:YES];
            }
            
            [tableView endUpdates];
            
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionNoData)
    {
        return [self getTextHeight:_helpText font:self.paragraphFont];
    }
    return tableView.rowHeight;

}


- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller
{
    NSString *desc = [_db descForBlock:_changingColor];
    
    [_db addColor:controller.resultColor
         forBlock:_changingColor
      description:desc];
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    [_changingColor release];
    _changingColor = nil;

    [self reloadData];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
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
    
    [delete release];

}

@end

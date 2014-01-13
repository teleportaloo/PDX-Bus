//
//  BlockColorViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/26/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "BlockColorViewController.h"
#import "CellLabel.h"

@interface BlockColorViewController ()

@end

@implementation BlockColorViewController


- (id)init
{
	if ((self = [super init]))
	{
		self.title = @"Vehicle Color Tags";
        _db = [[BlockColorDb getSingleton] retain];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return  (_keys.count> 0 ? _keys.count : 1);
}

-(UILabel *)create_UITextView:(UIFont *)font
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	
	UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = font;
    textView.backgroundColor = [UIColor whiteColor];
	textView.lineBreakMode =   UILineBreakModeWordWrap;
	textView.adjustsFontSizeToFitWidth = YES;
	textView.numberOfLines = 0;
    
	return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_keys.count > 0)
    {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // Configure the cell...
        NSString *key = [_keys objectAtIndex:indexPath.row];
        UIColor *col = [_db colorForBlock:key];
        
        cell.imageView.image = [BlockColorDb imageWithColor:col];
        cell.textLabel.text  =  [_db descForBlock:key];
        
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"ID %@ - %@", key,
                                     [dateFormatter stringFromDate:[_db timeForBlock:key]]];
        
        
        return cell;
    }
    else
    {
		NSString *MyIdentifier = [NSString stringWithFormat:@"CellLabel%f", [self getTextHeight:_helpText font:[self getParagraphFont]]];
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
			cell.view = [self create_UITextView:[self getParagraphFont]];
		}
		
		cell.view.text = _helpText;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		[cell setAccessibilityLabel:_helpText];
        
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
    if (_keys.count > 0)
    {
        _changingColor = [[_keys objectAtIndex:indexPath.row] retain];
        
        InfColorPickerController* picker = [ InfColorPickerController colorPickerViewController ];
        
        picker.delegate = self;
        
        picker.sourceColor = [_db colorForBlock:_changingColor];
        
        
        [ picker presentModallyOverViewController: self ];
    }
    
}


// Override if you support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSString *block = [_keys objectAtIndex:indexPath.row];
               
        [_db addColor:nil forBlock:block description:nil];
        [_keys release];
        _keys = [[_db keys] retain];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];

    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_keys.count == 0)
    {
        return [self getTextHeight:_helpText font:[self getParagraphFont]];
    }
    return tableView.rowHeight;

}


- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller
{
    NSString *desc = [_db descForBlock:_changingColor];
    
    [_db addColor:controller.resultColor
         forBlock:_changingColor
      description:desc];
    [controller dismissModalViewControllerAnimated:YES];
    
    [_changingColor release];
    _changingColor = nil;

    [self reloadData];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
	// UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(deleteAll:)];
	
	
	delete.style = UIBarButtonItemStylePlain;
	delete.accessibilityLabel = @"Delete all";
	
    [toolbarItems addObject:delete];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    
    [delete release];

}

@end

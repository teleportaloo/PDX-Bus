//
//  RssView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "RssView.h"
#import "CellLabel.h"
#import "WebViewController.h"
#import "debug.h"

#define kGettingRss @"getting RSS feed"

@implementation RssView

@synthesize rssData = _rssData;
@synthesize rssUrl	= _rssUrl;

- (void)dealloc {
	self.rssData = nil;
	self.rssUrl = nil;
	[super dealloc];
}

#pragma mark Data fetchers

- (void)fetchRss:(id) arg
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self.backgroundTask.callbackWhenFetching BackgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching BackgroundStart:1 title:kGettingRss];
	
	NSError *parseError = nil;
    self.rssData = [[[RssXML alloc] init] autorelease];
	[self.rssData startParsing:self.rssUrl parseError:&parseError];
	
	[self.backgroundTask.callbackWhenFetching BackgroundCompleted:self];
	[pool release];
}


- (void) fetchRssInBackground:(id<BackgroundTaskProgress>) callback url:(NSString*)rssUrl
{
	self.rssUrl = rssUrl;
	self.backgroundTask.callbackWhenFetching = callback;
	
	[NSThread detachNewThreadSelector:@selector(fetchRss:) toTarget:self withObject:nil];
}

#pragma mark View methods

-(void)loadView
{
	[super loadView];
	self.title = self.rssData.title;
}

- (void)viewDidLoad {
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark UI helpers

- (UILabel *)create_UITextView
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	
	UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = [self getParagraphFont];
	//    textView.delegate = self;
	//	textView.editable = NO;
    textView.backgroundColor = [UIColor whiteColor];
	textView.lineBreakMode =   UILineBreakModeWordWrap;
	textView.adjustsFontSizeToFitWidth = YES;
	textView.numberOfLines = 0;
	
	return textView;
}

#pragma mark Tableview methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([self.rssData safeItemCount] > 0)
	{
		return [self.rssData safeItemCount];
	}
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.rssData safeItemCount] > 0)
	{
		RssLink *link = [self.rssData itemAtIndex:indexPath.row];
		
		return [link getTimeHeight:self.screenWidth] + 3 * VGAP +[self getTextHeight:link.title font:[self getParagraphFont]];
	}
	
	return [self getTextHeight:[self.rssData fullErrorMsg] font:[self getParagraphFont]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.row < [self.rssData safeItemCount])
	{
		RssLink *link = [self.rssData itemAtIndex:indexPath.row];
	
		NSString *MyIdentifier = [link cellReuseIdentifier:[NSString stringWithFormat:@"RssLabel%f", [self getTextHeight:link.title 
																													font:[self getParagraphFont]]] 
													 width:self.screenWidth];
		
		UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [link tableviewCellWithReuseIdentifier:MyIdentifier width:[self screenWidth] font:[self getParagraphFont]];
			
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		[link populateCell:cell];
		
		[cell setAccessibilityLabel:[link title]];
		
		return cell;
	}
	else {
		NSString *MyIdentifier = [NSString stringWithFormat:@"RssLabel"];
		
		CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
		if (cell == nil) {
			cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
			cell.view = [self create_UITextView];
		}
		
		((UILabel*)cell.view).text = [self.rssData fullErrorMsg];
		
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		
		if ([self.rssData gotData])
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		return cell;
	}
	return nil;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.row < [self.rssData safeItemCount])
	{
		RssLink *link = [self.rssData itemAtIndex:indexPath.row];
		WebViewController *web = [[WebViewController alloc] init];

		[web setRssItem:link title:self.rssData.title];
		web.rssLinks = self.rssData.itemArray;
		web.rssLinkItem = indexPath.row;
	
		[[self navigationController] pushViewController:web animated:YES];
		[web release];
	}
	else if (![self.rssData gotData])
	{
		[self networkTips:nil networkError:self.rssData.errorMsg];
	}
}



@end

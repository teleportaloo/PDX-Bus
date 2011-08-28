//
//  TripPlannerResultsView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
//

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

#import <UIKit/UIKit.h>
#import "XMLTrips.h"
#import "TableViewWithToolbar.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface TripPlannerResultsView : TableViewWithToolbar <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate,
											UIAlertViewDelegate> {
	XMLTrips *_tripQuery;
	int itinerarySectionOffset;
	int _bookmarkItem;
	int _smsRows;
	int _calRows;
	int _recentTripItem;
	TripItinerary *_calendarItinerary;
}

@property (nonatomic, retain) XMLTrips *tripQuery;
@property (nonatomic, retain) TripItinerary *calendarItinerary;

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath;
- (int)rowType:(NSIndexPath*)indexPath;
- (int)legRows:(TripItinerary *)it;
- (int)sectionType:(int)section;
- (TripItinerary *)getSafeItinerary:(int)section;
- (NSString*)getFromText;
- (NSString*)getToText;
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result;
- (id)initWithHistoryItem:(int)item;
- (void)setItemFromHistory:(int)item;

@end

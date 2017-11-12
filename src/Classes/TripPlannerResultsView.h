//
//  TripPlannerResultsView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "XMLTrips.h"
#import "TableViewWithToolbar.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>


@interface TripPlannerResultsView : TableViewWithToolbar <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,
											UIAlertViewDelegate> {
	XMLTrips *      _tripQuery;
	int             _itinerarySectionOffset;
	int             _smsRows;
	int             _calRows;
	int             _recentTripItem;
    int             _alarmItem;
	TripItinerary * _calendarItinerary;
    NSUserActivity *_userActivity;
    TripItemCell *_prototypeTripCell;
}

@property (nonatomic, retain) XMLTrips *tripQuery;
@property (nonatomic, retain) TripItinerary *calendarItinerary;
@property (nonatomic, retain) NSUserActivity *userActivity;
@property (nonatomic, retain) TripItemCell *prototypeTripCell;

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath;
- (NSInteger)rowType:(NSIndexPath*)indexPath;
- (NSInteger)legRows:(TripItinerary *)it;
- (NSInteger)sectionType:(NSInteger)section;
- (TripItinerary *)getSafeItinerary:(NSInteger)section;
@property (nonatomic, getter=getFromText, readonly, copy) NSString *fromText;
@property (nonatomic, getter=getToText, readonly, copy) NSString *toText;
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result;
- (instancetype)initWithHistoryItem:(int)item;
- (void)setItemFromHistory:(int)item;
- (void)setItemFromArchive:(NSDictionary *)archive;


@end

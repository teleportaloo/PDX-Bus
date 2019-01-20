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
#import "InfColorPickerController.h"
#import <EventKitUI/EventKitUI.h>
#import <IntentsUI/IntentsUI.h>


@interface TripPlannerResultsView : TableViewWithToolbar <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,
                                                            InfColorPickerControllerDelegate, EKEventViewDelegate,INUIAddVoiceShortcutViewControllerDelegate>
{
    int             _itinerarySectionOffset;
    bool            _sms;
    bool            _cal;
    int             _recentTripItem;
}

@property (nonatomic, strong) XMLTrips *tripQuery;
@property (nonatomic, strong) NSUserActivity *userActivity;
@property (nonatomic, strong) TripItemCell *prototypeTripCell;
@property (nonatomic, strong) EKEvent *event;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, readonly, copy) NSString *fromText;
@property (nonatomic, readonly, copy) NSString *toText;

- (NSString *)getTextForLeg:(NSIndexPath *)indexPath;
- (NSInteger)legRows:(TripItinerary *)it;
- (TripItinerary *)getSafeItinerary:(NSInteger)section;
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result;
- (instancetype)initWithHistoryItem:(int)item;
- (void)setItemFromHistory:(int)item;
- (void)setItemFromArchive:(NSDictionary *)archive;

@end

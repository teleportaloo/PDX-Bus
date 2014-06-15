//
//  DetoursView.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "XMLDetour.h"


@interface DetoursView : TableViewWithToolbar {
	XMLDetour *_detourData; 
	NSInteger disclaimerSection;
}
- (void)fetchDetoursInBackground:(id<BackgroundTaskProgress>) callback;
- (void)fetchDetoursInBackground:(id<BackgroundTaskProgress>) callback route:(NSString *)route;
- (void)fetchDetoursInBackground:(id<BackgroundTaskProgress>) callback routes:(NSArray *)routes;

@property (nonatomic, retain) XMLDetour *detourData;

@end

//
//  ProgressModal.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

@protocol ProgressDelegate <NSObject>

- (void)progressDelegateCancel;

@end

@interface ProgressModalView : UIView

@property(nonatomic, weak) id<ProgressDelegate> progressDelegate;
@property(nonatomic) NSInteger totalItems;

- (void)itemsDone:(NSInteger)itemsDone;
- (void)subItemsDone:(NSInteger)subItemsDone totalSubs:(NSInteger)totalSubs;
- (void)totalItems:(NSInteger)total;
- (void)addSubtext:(NSString *)subtext;
- (void)addHelpText:(NSString *)helpText;

- (ProgressModalView *)initWithParent:(UIView *)back
                                items:(NSInteger)items
                                title:(NSString *)title
                             delegate:(id<ProgressDelegate>)delegate
                          orientation:(UIInterfaceOrientation)orientation;

@end

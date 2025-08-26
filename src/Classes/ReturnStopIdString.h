/*
 *  ReturnStopIdString.h
 *  PDX Bus
 *
 *  Created by Andrew Wallace on 1/25/09.
 */



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@protocol ReturnStopIdString <NSObject>

@property(nonatomic, readonly, strong)
    UIViewController *returnStopIdStringController;
@property(nonatomic, readonly, copy) NSString *returnStopIdStringActionText;

- (void)returnStopIdString:(NSString *)stopId desc:(NSString *)desc;

@end

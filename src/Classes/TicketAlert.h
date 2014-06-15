//
//  TicketAlert.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/24/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ViewControllerBase.h"

@interface TicketAlert : NSObject<UIActionSheetDelegate>
{
    ViewControllerBase *_parent;
    UIActionSheet      *_sheet;
    
}

@property (nonatomic, retain) ViewControllerBase *parent;
@property (nonatomic, retain) UIActionSheet      *sheet;

- (id)initWithParent:(ViewControllerBase *)newParent;

@end

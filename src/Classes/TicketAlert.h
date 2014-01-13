//
//  TicketAlert.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/24/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

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

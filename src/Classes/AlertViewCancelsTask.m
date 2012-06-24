//
//  AlertViewCancelsTask.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
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

#import "AlertViewCancelsTask.h"

@implementation AlertViewCancelsTask

@synthesize backgroundTask = _backgroundTask;
@synthesize caller         = _caller;

- (void)dealloc
{
    self.backgroundTask = nil;
    self.caller         = nil;
    
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.backgroundTask.callbackWhenFetching BackgroundCompleted:self.caller];
    [self release];
}


@end

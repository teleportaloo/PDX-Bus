//
//  XMLYahooPlaceNames.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/29/10.
//  Copyright 2010. All rights reserved.
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

#import "XMLYahooPlaceNames.h"


@implementation XMLYahooPlaceNames

- (id)init {
	if ((self = [super init]))
	{
		self.elements = [[[NSArray alloc] initWithObjects:@"line1", @"line2", @"line3", nil] autorelease];
		self.dividers = [[[NSArray alloc] initWithObjects:@" ", @" ", @" ", @"", nil] autorelease];
		self.takeFirst = true;
	}
	return self;
}

- (NSString*)fullAddressForLocation:(CLLocation *)loc
{
	return [NSString stringWithFormat:@"http://where.yahooapis.com/geocode?q=%f,%f&gflags=R&appid=%@", 
			loc.coordinate.latitude, 
			loc.coordinate.longitude,
			kYahooAppId];
}

- (NSString *)getServiceName
{
	return @"Yahoo Place Finder";
}

@end

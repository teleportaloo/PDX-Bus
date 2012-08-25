//
//  XMLYahooPlaceNames.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/29/10.
//  Copyright 2010. All rights reserved.
//

/* */

#import <Foundation/Foundation.h>
#import "XMLReverseGeoCode.h"

// To use Reverse Geo Coding from Yahoo you need an APP ID from
// http://developer.yahoo.com/geo/placefinder/
// The app will default to a use GeoNames.org without this ID.
//

#define kYahooAppId @""


@interface XMLYahooPlaceNames : XMLReverseGeoCode {

}

@end

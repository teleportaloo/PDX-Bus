//
//  FormatDistance.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/31/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

#define kMetresInAKm (1000.0)
#define kMetresInAMile (1609.344)
#define kFeetInAMile (5280.0)
#define kFeetInAMetre (kFeetInAMile / kMetresInAMile)
#define MetresForMiles(X) (kMetresInAMile * (X))
#define MilesForKm(X) ((X) / (kMetresInAMile / kMetresInAKm))

@interface FormatDistance : NSObject

+ (NSString *)formatMetres:(double)meters;
+ (NSString *)formatMiles:(double)miles;
+ (NSString *)formatFeet:(double)feet;
@end

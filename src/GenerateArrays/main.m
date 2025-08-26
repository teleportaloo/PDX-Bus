//
//  main.m
//  GenerateArrays
//
//  Created by Andy Wallace on 3/9/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

#import "GenerateArrays.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        GenerateArrays *generator = [GenerateArrays new];

        [generator generateStaticStationData];

        [generator generateHotSpotTiles];

        [generator generateCopySh];
    }
    return 0;
}

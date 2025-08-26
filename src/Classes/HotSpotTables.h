//
//  HotSpotTables.h
//  PDX Bus
//
//  Created by Andy Wallace on 8/5/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define HS_MAP 0
#include "../Tables/MaxHotSpotTable.c"
#undef HS_MAP

#define HS_MAP 1
#include "../Tables/StreetcarHotSpotTable.c"
#undef HS_MAP

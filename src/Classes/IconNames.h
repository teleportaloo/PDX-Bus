//
//  IconNames.h
//  PDX Bus
//
//  Created by Andy Wallace on 9/2/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#define ICON(X, S) extern NSString *const X##Name;
#define SF_ICON(X, S) extern NSString *const X##Name;
#define SF_ICON_ALT(X, S, A) SF_ICON(X, S);
#define SF_ICON_TINT(X, S, C) extern NSString *const X##Name;
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_TINT(X, S, C);

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT

//
//  IconsNames.m
//  PDX Bus
//
//  Created by Andy Wallace on 9/2/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#include "Icons.h"
#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define EXTERN_DEF extern
#else
#define EXTERN_DEF /* nothing */
#endif             // __cplusplus

#define ICON(X, S) NSString *const X##Name = S;
#define SF_ICON(X, S) NSString *const X##Name = S;
#define SF_ICON_ALT(X, S, A) NSString *const X##Name = S;
#define SF_ICON_TINT(X, S, A) SF_ICON(X, S)
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_ALT(X, S, A)

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT

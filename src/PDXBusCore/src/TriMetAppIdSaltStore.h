//
//  AppIdSaltStore.h
//  PDX Bus
//
//  Created by Andy Wallace on 10/6/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#include <stdint.h>

#define APP_ID_SIZE (25)

const uint8_t *TriMetAppIdSalt(void);

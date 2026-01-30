//
//  AppIdSalt.c
//  PDX Bus
//
//  Created by Andy Wallace on 10/6/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#import "TriMetAppIdSaltStore.h"
#import "../../Tables/TriMetAppIdSalt.h"

// This is deliberately in a separate compilation unit than the App ID itself so they are
// not adjacent in the binary.

static const uint8_t salt[APP_ID_SIZE] = {
    APP_ID_SALT_1,  APP_ID_SALT_2,  APP_ID_SALT_3,  APP_ID_SALT_4,  APP_ID_SALT_5,
    APP_ID_SALT_6,  APP_ID_SALT_7,  APP_ID_SALT_8,  APP_ID_SALT_9,  APP_ID_SALT_10,
    APP_ID_SALT_11, APP_ID_SALT_12, APP_ID_SALT_13, APP_ID_SALT_14, APP_ID_SALT_15,
    APP_ID_SALT_16, APP_ID_SALT_17, APP_ID_SALT_18, APP_ID_SALT_19, APP_ID_SALT_20,
    APP_ID_SALT_21, APP_ID_SALT_22, APP_ID_SALT_23, APP_ID_SALT_24, APP_ID_SALT_25};

const uint8_t *TriMetAppIdSalt(void) { return salt; }

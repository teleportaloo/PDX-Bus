//
//  DebugLogging.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/13/20.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DebugLogging.h"
#import "TaskDispatch.h"

DEBUG_LOG_LEVELS((^{
  DEBUG_LOG_LEVEL_0(LogSettings);
  DEBUG_LOG_LEVEL_0(LogNet);
  DEBUG_LOG_LEVEL_0(LogXML);
  DEBUG_LOG_LEVEL_0(LogParsing);
  DEBUG_LOG_LEVEL_1(LogTask);
  DEBUG_LOG_LEVEL_1(LogUI);
  DEBUG_LOG_LEVEL_0(LogData);
  DEBUG_LOG_LEVEL_1(LogTests);
  DEBUG_LOG_LEVEL_1(LogTestFiles);
  DEBUG_LOG_LEVEL_1(LogIntents);
  DEBUG_LOG_LEVEL_1(LogAlarms);
  DEBUG_LOG_LEVEL_0(LogWeb);
  DEBUG_LOG_LEVEL_1(LogTipJar);
  DEBUG_LOG_LEVEL_0(LogMarkup);
}));

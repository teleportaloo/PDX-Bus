//
//  ComplicationController.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 11/17/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "ComplicationController.h"
#import "DebugLogging.h"
#import <ClockKit/ClockKit.h>

@implementation ComplicationController

- (void)getCurrentTimelineEntryForComplication:(nonnull CLKComplication *)complication withHandler:(nonnull void (^)(CLKComplicationTimelineEntry *_Nullable))handler {
    [self getLocalizableSampleTemplateForComplication:complication withHandler:^(CLKComplicationTemplate *_Nullable complicationTemplate) {
        CLKComplicationTimelineEntry *entry = [[CLKComplicationTimelineEntry alloc] init];
        
        entry.complicationTemplate = complicationTemplate;
        entry.date = [NSDate date];
        handler(entry);
    }];
}

- (void)getSupportedTimeTravelDirectionsForComplication:(nonnull CLKComplication *)complication withHandler:(nonnull void (^)(CLKComplicationTimeTravelDirections))handler {
    handler(CLKComplicationTimeTravelDirectionNone);
}

+ (UIImage *)image:(NSString *)named {
    UIImage *image = [UIImage imageNamed:named];
    
    if (image == nil) {
        ERROR_LOG(@"Failed to load image %@", named);
        return [UIImage imageNamed:@"84x84.png"];
    } else {
        DEBUG_LOG(@"Loaded image %@", named);
    }
    
    return image;
}

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void (^)(CLKComplicationTemplate *__nullable complicationTemplate))handler API_AVAILABLE(watchos(3.0)) {
    CLKComplicationTemplate *template;
    
    DEBUG_HERE();
    DEBUG_LOGD(complication.family);
    
    switch (complication.family) {
        case CLKComplicationFamilyModularSmall: {
            UIImage *image = [ComplicationController image:@"Complication/Modular"];
            CLKComplicationTemplateModularSmallSimpleImage *temp = [[CLKComplicationTemplateModularSmallSimpleImage alloc] init];
            temp.imageProvider = [CLKImageProvider imageProviderWithOnePieceImage:image];
            template = temp;
            break;
        }
            
        case CLKComplicationFamilyCircularSmall: {
            UIImage *image = [ComplicationController image:@"Complication/Circular"];
            CLKComplicationTemplateCircularSmallSimpleImage *temp = [[CLKComplicationTemplateCircularSmallSimpleImage alloc] init];
            temp.imageProvider = [CLKImageProvider imageProviderWithOnePieceImage:image];
            template = temp;
            break;
        }
            
        case CLKComplicationFamilyModularLarge:
            break;
            
        case CLKComplicationFamilyUtilitarianSmallFlat: {
            CLKComplicationTemplateUtilitarianSmallFlat *temp = [[CLKComplicationTemplateUtilitarianSmallFlat alloc] init];
            temp.textProvider = [CLKSimpleTextProvider textProviderWithText:@"PDX BUS"];
            template = temp;
            break;
        }
            
        case CLKComplicationFamilyUtilitarianSmall: {
            UIImage *image = [ComplicationController image:@"Complication/Utilitarian"];
            CLKComplicationTemplateUtilitarianSmallSquare *temp = [[CLKComplicationTemplateUtilitarianSmallSquare alloc] init];
            temp.imageProvider = [CLKImageProvider imageProviderWithOnePieceImage:image];
            template = temp;
            break;
        }
            
        case CLKComplicationFamilyUtilitarianLarge:
        case CLKComplicationFamilyExtraLarge:
            break;
            
        case CLKComplicationFamilyGraphicCorner: {
            if (@available(watchOS 5.0, *)) {
                UIImage *image = [ComplicationController image:@"Complication/Graphic Corner"];
                CLKComplicationTemplateGraphicCornerCircularImage *temp = [[CLKComplicationTemplateGraphicCornerCircularImage alloc] init];
                temp.imageProvider = [CLKFullColorImageProvider providerWithFullColorImage:image];
                template = temp;
            }
            
            break;
        }
            
        case CLKComplicationFamilyGraphicBezel:
            break;
            
        case CLKComplicationFamilyGraphicCircular: {
            if (@available(watchOS 5.0, *)) {
                UIImage *image = [ComplicationController image:@"Complication/Graphic Circular"];
                CLKComplicationTemplateGraphicCircularImage *temp = [[CLKComplicationTemplateGraphicCircularImage alloc] init];
                temp.imageProvider = [CLKFullColorImageProvider providerWithFullColorImage:image];
                template = temp;
            }
            
            break;
        }
            
        case CLKComplicationFamilyGraphicRectangular:
            break;
            
        default:
            break;
    }
    
    handler(template);
}



@end

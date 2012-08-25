//
//  CatchHtmlRedirect.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/17/12.
//  Copyright (c) 2012 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoppableFetcher.h"

@interface ProcessQRCodeString : StoppableFetcher
{
    NSString *_stopId;
}    

@property (nonatomic, retain) NSString *stopId;

- (NSString *)extractStopId:(NSString *)originalURL;


@end




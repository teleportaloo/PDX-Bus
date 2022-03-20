//
//  SimpleStop.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/6/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//

#import "SimpleAnnotation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleStop : SimpleAnnotation

@property (nonatomic, copy) NSString *stopId;

@end

NS_ASSUME_NONNULL_END

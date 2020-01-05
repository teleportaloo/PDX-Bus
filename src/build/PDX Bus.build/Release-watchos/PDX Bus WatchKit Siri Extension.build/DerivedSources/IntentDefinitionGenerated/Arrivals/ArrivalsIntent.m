//
// ArrivalsIntent.m
//
// This file was automatically generated and should not be edited.
//

#import "ArrivalsIntent.h"

#if __has_include(<Intents/Intents.h>) && (!TARGET_OS_OSX || TARGET_OS_IOSMAC) && !TARGET_OS_TV

@implementation ArrivalsIntent

@dynamic stops, locationName;

@end

@interface ArrivalsIntentResponse ()

@property (readwrite, NS_NONATOMIC_IOSONLY) ArrivalsIntentResponseCode code;

@end

@implementation ArrivalsIntentResponse

@synthesize code = _code;

@dynamic arrivals, alerts, stopName, numberOfRoutes;

- (instancetype)initWithCode:(ArrivalsIntentResponseCode)code userActivity:(nullable NSUserActivity *)userActivity {
    self = [super init];
    if (self) {
        _code = code;
        self.userActivity = userActivity;
    }
    return self;
}

+ (instancetype)successIntentResponseWithStopName:(NSString *)stopName arrivals:(NSString *)arrivals {
    ArrivalsIntentResponse *intentResponse = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeSuccess userActivity:nil];
    intentResponse.stopName = stopName;
    intentResponse.arrivals = arrivals;
    return intentResponse;
}

+ (instancetype)noArrivalsIntentResponseWithStopName:(NSString *)stopName {
    ArrivalsIntentResponse *intentResponse = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeNoArrivals userActivity:nil];
    intentResponse.stopName = stopName;
    return intentResponse;
}

+ (instancetype)bigSuccessIntentResponseWithNumberOfRoutes:(NSString *)numberOfRoutes stopName:(NSString *)stopName arrivals:(NSString *)arrivals {
    ArrivalsIntentResponse *intentResponse = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeBigSuccess userActivity:nil];
    intentResponse.numberOfRoutes = numberOfRoutes;
    intentResponse.stopName = stopName;
    intentResponse.arrivals = arrivals;
    return intentResponse;
}

+ (instancetype)watchSuccessIntentResponseWithStopName:(NSString *)stopName {
    ArrivalsIntentResponse *intentResponse = [[ArrivalsIntentResponse alloc] initWithCode:ArrivalsIntentResponseCodeWatchSuccess userActivity:nil];
    intentResponse.stopName = stopName;
    return intentResponse;
}

@end

#endif

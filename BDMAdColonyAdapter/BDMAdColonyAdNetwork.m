//
//  BDMAdColonyAdapter.m
//  BDMAdColonyAdapter
//
//  Created by Stas Kochkin on 19/07/2019.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import StackFoundation;

#import "BDMAdColonyAdNetwork.h"
#import "BDMAdColonyAppOptions.h"
#import "BDMAdColonyFullscreenAdapter.h"

NSString *const BDMAdColonyAppIDKey     = @"app_id";
NSString *const BDMAdColonyZoneIDKey    = @"zone_id";
NSString *const BDMAdColonyDataKey      = @"data";
NSString *const BDMAdColonyAdmKey       = @"adm";

@interface BDMAdColonyAdNetwork ()

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic,   copy) NSString *appId;

@end

@implementation BDMAdColonyAdNetwork

- (NSString *)name {
    return @"adcolony";
}

- (NSString *)sdkVersion {
    return AdColony.getSDKVersion;
}

- (void)initializeWithParameters:(BDMStringToStringMap *)parameters
                           units:(NSArray<BDMAdUnit *> *)units
                      completion:(BDMInitializeBiddingNetworkBlock)completion
{
    if (self.initialized) {
        STK_RUN_BLOCK(completion, NO, nil);
        return;
    }
    
    
    NSString *appId = ANY(parameters).from(BDMAdColonyAppIDKey).string;
    NSArray <NSString *> *zones = ANY(units)
    .flatMap(^id(BDMAdUnit *unit){ return ANY(unit.params).from(BDMAdColonyZoneIDKey).string; })
    .arrayOfString;
    
    if (!appId || !zones.count) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"AdColony app id or zones not valid!"];
        STK_RUN_BLOCK(completion, YES, error);
        return;
    }
    
    self.appId = appId;
    self.initialized = YES;
    
    [AdColony configureWithAppID:appId
                         zoneIDs:zones
                         options:BDMAdColonyAppOptions.new
                      completion:^(NSArray<AdColonyZone *> *zones) {
        STK_RUN_BLOCK(completion, YES, nil);
    }];
}

- (void)collectHeaderBiddingParameters:(BDMAdUnit *)unit
                            completion:(BDMCollectBiddingParamtersBlock)completion
{
    NSString *zoneId = ANY(unit.params).from(BDMAdColonyZoneIDKey).string;
    NSString *signals = AdColony.collectSignals;
    // Check that we have zone id
    if (!zoneId || !signals) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"AdColony zone_id wasn't found"];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    NSDictionary *clientParams = @{ BDMAdColonyAppIDKey   : self.appId,
                                    BDMAdColonyZoneIDKey  : zoneId,
                                    BDMAdColonyDataKey    : signals
    };
    STK_RUN_BLOCK(completion, clientParams, nil);
}

- (id<BDMFullscreenAdapter>)videoAdapterForSdk:(BDMSdk *)sdk {
    return [BDMAdColonyFullscreenAdapter new];
}

@end

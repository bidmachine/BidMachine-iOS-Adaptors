//
//  BDMMyTargetAdNetwork.m
//  BDMMyTargetAdapter
//
//  Created by Stas Kochkin on 17/07/2019.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import MyTargetSDK;
@import StackFoundation;

#import "BDMMyTargetAdNetwork.h"
#import "BDMMyTargetBannerAdapter.h"
#import "BDMMyTargetFullscreenAdapter.h"
#import "BDMMyTargetNativeAdServiceAdapter.h"


NSString *const BDMMyTargetSlotIDKey    = @"slot_id";
NSString *const BDMMyTargetBidIDKey     = @"bid_id";
NSString *const BDMMyTargetBidTokenKey  = @"bidder_token";


@implementation BDMMyTargetAdNetwork

- (NSString *)name {
    return @"my_target";
}

- (NSString *)sdkVersion {
    return MTRGVersion.currentVersion;
}

- (void)initializeWithParameters:(BDMStringToStringMap *)parameters
                           units:(NSArray<BDMAdUnit *> *)units
                      completion:(BDMInitializeBiddingNetworkBlock)completion
{
    [self syncMetadata];
    STK_RUN_BLOCK(completion, NO, nil);
}

- (void)collectHeaderBiddingParameters:(BDMAdUnit *)unit
                            completion:(BDMCollectBiddingParamtersBlock)completion
{
    [self syncMetadata];
    NSString *slotId = ANY(unit.params).from(BDMMyTargetSlotIDKey).string;
    NSString *bidToken = MTRGManager.getBidderToken;
    NSDictionary *clientParams;
    NSError *error;
    if (slotId.length && bidToken) {
        clientParams = @{ BDMMyTargetSlotIDKey    : slotId,
                          BDMMyTargetBidTokenKey  : bidToken };
    } else {
        error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                               description:@"MyTarget ad unit not contains valid slot id"];
    }
    STK_RUN_BLOCK(completion, clientParams, error);
}

- (id<BDMFullscreenAdapter>)interstitialAdAdapterForSdk:(BDMSdk *)sdk {
    return [BDMMyTargetFullscreenAdapter new];
}

- (id<BDMFullscreenAdapter>)videoAdapterForSdk:(BDMSdk *)sdk {
    return [BDMMyTargetFullscreenAdapter new];
}

- (id<BDMBannerAdapter>)bannerAdapterForSdk:(BDMSdk *)sdk {
    return [BDMMyTargetBannerAdapter new];
}

- (id<BDMNativeAdServiceAdapter>)nativeAdAdapterForSdk:(BDMSdk *)sdk {
    return [BDMMyTargetNativeAdServiceAdapter new];
}

#pragma mark - Private

- (void)syncMetadata {
    MTRGPrivacy.userAgeRestricted = BDMSdk.sharedSdk.restrictions.coppa;
    
    if (BDMSdk.sharedSdk.restrictions.subjectToGDPR) {
        [MTRGPrivacy setUserConsent:BDMSdk.sharedSdk.restrictions.hasConsent];
    }
    
    if (BDMSdk.sharedSdk.restrictions.subjectToCCPA) {
        [MTRGPrivacy setCcpaUserConsent:BDMSdk.sharedSdk.restrictions.hasCCPAConsent];
    }
}

@end

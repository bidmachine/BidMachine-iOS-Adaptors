//
//  BDMSmaatoAdNetwork.m
//  BDMSmaatoAdapter
//
//  Created by Ilia Lozhkin on 10/24/19.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import SmaatoSDKCore;
@import SmaatoSDKUnifiedBidding;
@import StackFoundation;

#import "BDMSmaatoAdNetwork.h"
#import "BDMSmaatoBannerAdapter.h"
#import "BDMSmaatoFullscreenAdapter.h"


NSString *const BDMSmaatoIDKey          = @"publisher_id";
NSString *const BDMSmaatoPriceKey       = @"bid_price";
NSString *const BDMSmaatoSpaceIDKey     = @"ad_space_id";

typedef void (^BDMSmaatoCompletionBlock)(SMAUbBid *bid, NSError *error);

@interface BDMSmaatoAdNetwork()

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic,   copy) NSString *publisherId;

@end

@implementation BDMSmaatoAdNetwork

- (NSString *)name {
    return @"smaato";
}

- (NSString *)sdkVersion {
    return SmaatoSDK.sdkVersion;
}

- (void)initializeWithParameters:(BDMStringToStringMap *)parameters
                           units:(NSArray<BDMAdUnit *> *)units
                      completion:(BDMInitializeBiddingNetworkBlock)completion
{
    [self syncMetadata];
    
    if (self.initialized) {
        STK_RUN_BLOCK(completion, NO, nil);
        return;
    }
    
    NSString *publisherId = ANY(parameters).from(BDMSmaatoIDKey).string;
    if (publisherId) {
        SMAConfiguration *configuration = [[SMAConfiguration alloc] initWithPublisherId:publisherId];
        configuration.logLevel = BDMSdkLoggingEnabled ? kSMALogLevelVerbose : kSMALogLevelError;
        [SmaatoSDK initSDKWithConfig:configuration];
        self.initialized = YES;
        self.publisherId = publisherId;
        STK_RUN_BLOCK(completion, YES, nil);
    } else {
        NSError * error = [NSError bdm_errorWithCode:BDMErrorCodeInternal description:@"Smaato app id is not valid string"];
        STK_RUN_BLOCK(completion, NO, error);
    }
}

- (void)collectHeaderBiddingParameters:(BDMAdUnit *)unit
                            completion:(BDMCollectBiddingParamtersBlock)completion
{
    NSString *adSpaceId = ANY(unit.params).from(BDMSmaatoSpaceIDKey).string;
    if (!adSpaceId) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"Smaato adapter was not receive valid bidding data"];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    
    __weak typeof(self) weakself = self;
    BDMSmaatoCompletionBlock smaatoCompletion = ^(SMAUbBid *bid, NSError *error) {
        NSMutableDictionary *bidding = [NSMutableDictionary dictionaryWithCapacity:3];
        bidding[BDMSmaatoSpaceIDKey] = adSpaceId;
        bidding[BDMSmaatoIDKey] = weakself.publisherId;
        
        if (bid) {
            bidding[BDMSmaatoPriceKey] = @(bid.bidPrice).stringValue;
        } else {
            error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                   description:@"Smaato can't prebid adapter"];
        }
        
        STK_RUN_BLOCK(completion, bidding, error);
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself prebidSmaatoAdapter:unit.format
                            adSpaceId:adSpaceId
                           completion:[smaatoCompletion copy]];
    });
}

- (id<BDMBannerAdapter>)bannerAdapterForSdk:(BDMSdk *)sdk {
    return BDMSmaatoBannerAdapter.new;
}

- (id<BDMFullscreenAdapter>)interstitialAdAdapterForSdk:(BDMSdk *)sdk {
    return BDMSmaatoFullscreenAdapter.new;
}

- (id<BDMFullscreenAdapter>)videoAdapterForSdk:(BDMSdk *)sdk {
    return BDMSmaatoFullscreenAdapter.new;
}

- (void)prebidSmaatoAdapter:(BDMAdUnitFormat)adUnitFormat
                  adSpaceId:(NSString *)adSpaceId
                 completion:(BDMSmaatoCompletionBlock)completion {
    if (adUnitFormat >= 0 && adUnitFormat < 4) {
        SMAUbBannerSize size = kSMAUbBannerSizeXXLarge_320x50;
        switch (adUnitFormat) {
            case BDMAdUnitFormatBanner728x90: size = kSMAUbBannerSizeLeaderboard_728x90;
            case BDMAdUnitFormatBanner300x250: size = kSMAUbBannerSizeMediumRectangle_300x250;
            default: break;
        }
        [SmaatoSDK prebidBannerForAdSpaceId:adSpaceId bannerSize:size completion:completion];
    } else if (adUnitFormat >= 4 && adUnitFormat < 7) {
        [SmaatoSDK prebidInterstitialForAdSpaceId:adSpaceId completion:completion];
    } else if (adUnitFormat >= 7 && adUnitFormat < 10) {
        [SmaatoSDK prebidRewardedInterstitialForAdSpaceId:adSpaceId completion:completion];
    } else {
        NSError * error = [NSError bdm_errorWithCode:BDMErrorCodeInternal description:@"Smaato invalid ad unit format"];
        STK_RUN_BLOCK(completion, nil, error);
    }
}

#pragma mark - Private

- (void)syncMetadata {
    if (BDMSdk.sharedSdk.restrictions.allowUserInformation) {
        BDMTargeting *targeting = BDMSdk.sharedSdk.configuration.targeting;
        SmaatoSDK.userAge = targeting.userAge;
        SmaatoSDK.userRegion = targeting.country;
        SmaatoSDK.userZipCode = targeting.zip;
        SmaatoSDK.requireCoppaCompliantAds = YES;

        if (targeting.deviceLocation) {
            SmaatoSDK.userLocation = [[SMALocation alloc] initWithLatitude:targeting.deviceLocation.coordinate.latitude
                                                                 longitude:targeting.deviceLocation.coordinate.longitude
                                                        horizontalAccuracy:targeting.deviceLocation.horizontalAccuracy
                                                                 timestamp:targeting.deviceLocation.timestamp];
            
        }
        
        if ([targeting.gender isEqualToString:kBDMUserGenderMale]) {
            SmaatoSDK.userGender = kSMAGenderMale;
        } else if ([targeting.gender isEqualToString:kBDMUserGenderFemale]) {
            SmaatoSDK.userGender = kSMAGenderFemale;
        }
    }
}

@end

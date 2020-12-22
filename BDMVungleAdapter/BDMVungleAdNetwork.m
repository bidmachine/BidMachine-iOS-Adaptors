//
//  BDMVungleAdapter.m
//  BDMVungleAdapter
//
//  Created by Stas Kochkin on 19/07/2019.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import StackFoundation;

#import "BDMVungleAdNetwork.h"
#import "BDMVungleFullscreenAdapter.h"


NSString *const BDMVungleTokenKey               = @"token";
NSString *const BDMVungleAppIDKey               = @"app_id";
NSString *const BDMVunglePlacementIDKey         = @"placement_id";

@interface BDMVungleAdNetwork () <VungleSDKDelegate, VungleSDKHeaderBidding>

@property (nonatomic, copy, nullable) NSString *appId;
@property (nonatomic, copy, nullable) BDMInitializeBiddingNetworkBlock initialisationCompletion;
@property (nonatomic, copy,  nonnull) NSHashTable <BDMVungleFullscreenAdapter *> *delegates;
@property (nonatomic, copy,  nonnull) NSMapTable <NSString *, BDMCollectBiddingParamtersBlock> *completionByPlacement;

@end


@implementation BDMVungleAdNetwork

- (NSString *)name {
    return @"vungle";
}

- (NSString *)sdkVersion {
    return VungleSDKVersion;
}

- (NSMapTable<NSString *,BDMCollectBiddingParamtersBlock> *)completionByPlacement {
    if (!_completionByPlacement) {
        _completionByPlacement = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _completionByPlacement;
}

- (NSHashTable<BDMVungleFullscreenAdapter *> *)delegates {
    if (!_delegates) {
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return _delegates;
}

- (void)initializeWithParameters:(BDMStringToStringMap *)parameters
                           units:(NSArray<BDMAdUnit *> *)units
                      completion:(BDMInitializeBiddingNetworkBlock)completion
{
    [self syncMetadata];
    if ([VungleSDK.sharedSDK isInitialized]) {
        STK_RUN_BLOCK(completion, NO, nil);
        return;
    }
    
    NSError *error = nil;
    NSString *appId = ANY(parameters).from(BDMVungleAppIDKey).string;
    
    if (appId) {
        self.appId = appId;
        VungleSDK.sharedSDK.delegate = self;
        VungleSDK.sharedSDK.headerBiddingDelegate = self;
        self.initialisationCompletion = completion;
        [VungleSDK.sharedSDK startWithAppId:appId error:&error];
    } else {
        error = [NSError bdm_errorWithCode:BDMErrorCodeInternal description:@"Vungle app id is not valid string"];
    }
    
    if (error) {
        self.initialisationCompletion = nil;
        BDMLog(@"Vungle initialisation failed with error: %@", error);
        STK_RUN_BLOCK(completion, YES, error);
    }
}

- (void)collectHeaderBiddingParameters:(BDMAdUnit *)unit
                            completion:(BDMCollectBiddingParamtersBlock)completion
{
    NSString *placement = ANY(unit.params).from(BDMVunglePlacementIDKey).string;
    
    if (!placement) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeInternal description:@"Vungle placement id is not valid string"];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    
    NSString *token = [VungleSDK.sharedSDK bidTokenForPlacement:placement];
    if (token) {
        NSDictionary *bidding = @{ BDMVunglePlacementIDKey  : placement,
                                   BDMVungleTokenKey        : token };
        STK_RUN_BLOCK(completion, bidding, nil);
        return;
    }
    
    if ([VungleSDK.sharedSDK isAdCachedForPlacementID:placement]) {
        NSString *description = [NSString stringWithFormat:@"Vungle bid token is not available for placement %@", placement];
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeInternal
                                        description:description];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    
    NSError *error = nil;
    [VungleSDK.sharedSDK loadPlacementWithID:placement error: &error];
    if (error) {
        error = [error bdm_wrappedWithCode:BDMErrorCodeUnknown];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    [self.completionByPlacement setObject:completion forKey:placement];
}

- (id<BDMFullscreenAdapter>)videoAdapterForSdk:(BDMSdk *)sdk {
    BDMVungleFullscreenAdapter *adapter = [BDMVungleFullscreenAdapter new];
    [self.delegates addObject:adapter];
    return adapter;
}

#pragma mark - VungleSDKDelegate

- (void)vungleSDKDidInitialize {
    STK_RUN_BLOCK(self.initialisationCompletion, YES, nil);
    self.initialisationCompletion = nil;
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    error ? BDMLog(@"Vungle initialisation failed with error: %@", error) : nil;
    STK_RUN_BLOCK(self.initialisationCompletion, YES, error);
    self.initialisationCompletion = nil;
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(NSString *)placementID
                            error:(NSError *)error {
    if (error) {
        NSError *wrapper = [error bdm_wrappedWithCode:BDMErrorCodeHeaderBiddingNetwork];
        STK_RUN_BLOCK([self.completionByPlacement objectForKey:placementID], nil, wrapper);
        [self.completionByPlacement removeObjectForKey:placementID];
    }
    
    for (BDMVungleFullscreenAdapter *adapter in self.delegates.allObjects.reverseObjectEnumerator) {
        [adapter vungleAdPlayabilityUpdate:isAdPlayable
                               placementID:placementID
                                     error:error];
    }
}

- (void)vungleWillShowAdForPlacementID:(NSString *)placementID {
    for (BDMVungleFullscreenAdapter *adapter in self.delegates.allObjects.reverseObjectEnumerator) {
        [adapter vungleWillShowAdForPlacementID: placementID];
    }
}

- (void)vungleWillCloseAdForPlacementID:(NSString *)placementID {
    for (BDMVungleFullscreenAdapter *adapter in self.delegates.allObjects.reverseObjectEnumerator) {
        [adapter vungleWillCloseAdForPlacementID:placementID];
    }
}

- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID {
    for (BDMVungleFullscreenAdapter *adapter in self.delegates.allObjects.reverseObjectEnumerator) {
        [adapter vungleTrackClickForPlacementID:placementID];
    }
}

- (void)vungleRewardUserForPlacementID:(nullable NSString *)placementID {
    for (BDMVungleFullscreenAdapter *adapter in self.delegates.allObjects.reverseObjectEnumerator) {
        [adapter vungleRewardUserForPlacementID:placementID];
    }
}

#pragma mark - VungleSDKHeaderBidding

- (void)placementPrepared:(NSString *)placement
             withBidToken:(NSString *)bidToken {
    
    if ([VungleSDK.sharedSDK isAdCachedForPlacementID:placement] && !bidToken) {
        NSString *description = [NSString stringWithFormat:@"Vungle bid token is not available for placement %@", placement];
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeInternal
                                        description:description];
        STK_RUN_BLOCK([self.completionByPlacement objectForKey:placement], nil, error);
        [self.completionByPlacement removeObjectForKey:placement];
        return;
    }
    
    NSMutableDictionary *bidding = [NSMutableDictionary dictionaryWithCapacity:2];
    bidding[BDMVunglePlacementIDKey] = placement;
    bidding[BDMVungleTokenKey] = bidToken;
    STK_RUN_BLOCK([self.completionByPlacement objectForKey:placement], bidding, nil);
    [self.completionByPlacement removeObjectForKey:placement];
}

#pragma mark - Private

- (void)syncMetadata {
    // GDPR compliance
    if (BDMSdk.sharedSdk.restrictions.subjectToGDPR) {
        VungleConsentStatus status = BDMSdk.sharedSdk.restrictions.hasConsent ? VungleConsentAccepted : VungleConsentDenied;
        [VungleSDK.sharedSDK updateConsentStatus:status consentMessageVersion:@""];
    }
    
    if (BDMSdk.sharedSdk.restrictions.subjectToCCPA) {
        VungleCCPAStatus status = BDMSdk.sharedSdk.restrictions.hasCCPAConsent ? VungleCCPAAccepted : VungleCCPADenied;
        [VungleSDK.sharedSDK updateCCPAStatus:status];
    }
    
    [VungleSDK.sharedSDK setLoggingEnabled:BDMSdkLoggingEnabled];
}

@end

//
//  BDMCriteoAdNetwork.m
//
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import StackFoundation;

#import "BDMCriteoAdNetwork.h"
#import "BDMCriteoBannerAdapter.h"
#import "BDMCriteoInterstitialAdapter.h"


NSString *const BDMCriteoIDKey                      = @"publisher_id";
NSString *const BDMCriteoPriceKey                   = @"price";
NSString *const BDMCriteoAdUnitIDKey                = @"ad_unit_id";
NSString *const BDMCriteoOrienationKey              = @"orientation";

@interface BDMCriteoAdNetwork ()

@property (nonatomic, assign) BOOL hasBeenInitialized;
@property (nonatomic, strong) NSMapTable *bidStorage;

@end


@implementation BDMCriteoAdNetwork

- (NSString *)name {
    return @"criteo";
}

- (NSString *)sdkVersion {
    return @"3.4.1";
}

- (NSMapTable *)bidStorage {
    if (!_bidStorage) {
        _bidStorage = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _bidStorage;
}

- (void)initializeWithParameters:(BDMStringToStringMap *)parameters
                           units:(NSArray<BDMAdUnit *> *)units
                      completion:(BDMInitializeBiddingNetworkBlock)completion
{
    [self syncMetadata];
    if (self.hasBeenInitialized) {
        STK_RUN_BLOCK(completion, NO, nil);
        return;
    }
    
    NSString *publisherId = ANY(parameters).from(BDMCriteoIDKey).string;
    
    NSArray *bannerAdUnitsArray = ANY(units)
    .flatMap(^id(BDMAdUnit *unit){
        if ((unit.format >= 0) && (unit.format <= 3)) {
            return ANY(unit.params).from(BDMCriteoAdUnitIDKey).string;
        }
        return nil;
    })
    .arrayOfString;
    
    NSArray *interstitialAdUnitsArray = ANY(units)
    .flatMap(^id(BDMAdUnit *unit){
        if ((unit.format >= 4) && (unit.format <= 6)) {
            return ANY(unit.params).from(BDMCriteoAdUnitIDKey).string;
        }
        return nil;
    })
    .arrayOfString;
    if (!NSString.stk_isValid(publisherId)) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"Criteo adapter was not receive valid publisher id"];
        STK_RUN_BLOCK(completion, NO, error);
        return;
    }
    
    NSArray <CRBannerAdUnit *> *bannerAdUnits = ANY(bannerAdUnitsArray).flatMap(^CRBannerAdUnit *(NSString *value){
        return [self bannerAdUnit:value size:CGSizeZero];
    }).array;
    NSArray <CRInterstitialAdUnit *> *interstitialAdUnits = ANY(interstitialAdUnitsArray).flatMap(^CRInterstitialAdUnit *(NSString *value){
        return [self interstitialAdUnit:value];
    }).array;
    
    NSArray *adUnits = [NSArray stk_concat:bannerAdUnits, interstitialAdUnits, nil];
    
    self.hasBeenInitialized = YES;
    [Criteo.sharedCriteo registerCriteoPublisherId:publisherId
                                       withAdUnits:adUnits];
    STK_RUN_BLOCK(completion, YES, nil);
}

- (void)collectHeaderBiddingParameters:(BDMAdUnit *)unit
                            completion:(BDMCollectBiddingParamtersBlock)completion
{
    NSString *adUnitId = ANY(unit.params).from(BDMCriteoAdUnitIDKey).string;
    NSString *orientation = ANY(unit.params).from(BDMCriteoOrienationKey).string;
    
    if (!NSString.stk_isValid(adUnitId) || ![self isValidOrientation:orientation]) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"Criteo adapter was not receive valid bidding data"];
        STK_RUN_BLOCK(completion, nil, error);
        return;
    }
    [self syncMetadata];
    
    __weak typeof(self) weakSelf = self;
    CRAdUnit *adUnit = [self adUnitByFormat:unit.format adUnitId:adUnitId];
    [[Criteo sharedCriteo] loadBidForAdUnit:adUnit responseHandler:^(CRBid * _Nullable bid) {
        if (!bid) {
            NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                            description:@"Criteo adapter bid response not ready"];
            STK_RUN_BLOCK(completion, nil, error);
        } else {
            NSMutableDictionary *bidding = [[NSMutableDictionary alloc] initWithCapacity:2];
            bidding[BDMCriteoPriceKey] = @(bid.price).stringValue;
            bidding[BDMCriteoAdUnitIDKey] = adUnitId;
            
            [weakSelf.bidStorage setObject:bid forKey:adUnitId];
            STK_RUN_BLOCK(completion, bidding, nil);
        }
    }];
}

- (id<BDMBannerAdapter>)bannerAdapterForSdk:(BDMSdk *)sdk {
    return [[BDMCriteoBannerAdapter alloc] initWithProvider:self];;
}

- (id<BDMFullscreenAdapter>)interstitialAdAdapterForSdk:(BDMSdk *)sdk {
    return [[BDMCriteoInterstitialAdapter alloc] initWithProvider:self];
}

- (CRBid *)bidForAdUnitId:(NSString *)adUnitId {
    CRBid *bid = [self.bidStorage objectForKey:adUnitId];
    [self.bidStorage removeObjectForKey:adUnitId];
    return bid;
}

- (void)syncMetadata {
    if (BDMSdk.sharedSdk.restrictions.subjectToCCPA) {
        [Criteo.sharedCriteo setUsPrivacyOptOut:YES];
    }
}

#pragma mark - Private

- (CRBannerAdUnit *)bannerAdUnit:(NSString *)adUnitId size:(CGSize)size {
    return [[CRBannerAdUnit alloc] initWithAdUnitId:adUnitId size:size];
}

- (CRInterstitialAdUnit *)interstitialAdUnit:(NSString *)adUnitId {
    return [[CRInterstitialAdUnit alloc] initWithAdUnitId:adUnitId];
}

- (CRAdUnit *)adUnitByFormat:(BDMAdUnitFormat)format adUnitId:(NSString *)adUnitId {
    switch (format) {
        case BDMAdUnitFormatInLineBanner: return [self bannerAdUnit:adUnitId size:CGSizeFromBDMSize(BDMBannerAdSize320x50)]; break;
        case BDMAdUnitFormatBanner320x50: return [self bannerAdUnit:adUnitId size:CGSizeFromBDMSize(BDMBannerAdSize320x50)]; break;
        case BDMAdUnitFormatBanner728x90: return [self bannerAdUnit:adUnitId size:CGSizeFromBDMSize(BDMBannerAdSize728x90)]; break;
        case BDMAdUnitFormatBanner300x250: return [self bannerAdUnit:adUnitId size:CGSizeFromBDMSize(BDMBannerAdSize300x250)]; break;
        case BDMAdUnitFormatInterstitialStatic: return [self interstitialAdUnit:adUnitId]; break;
        case BDMAdUnitFormatInterstitialVideo: return [self interstitialAdUnit:adUnitId]; break;
        case BDMAdUnitFormatInterstitialUnknown: return [self interstitialAdUnit:adUnitId]; break;
            
        default: return nil; break;
    }
}

- (BOOL)isValidOrientation:(NSString *)orientation {
    if (!orientation ||
        (UIInterfaceOrientationIsPortrait(STKInterface.orientation) && [orientation isEqualToString:@"portrait"]) ||
        (UIInterfaceOrientationIsLandscape(STKInterface.orientation) && [orientation isEqualToString:@"landscape"])) {
        return YES;
    }
    
    return NO;
}

@end

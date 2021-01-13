//
//  BDMAdColonyFullscreenAdapter.m
//  BDMAdColonyAdapter
//
//  Created by Stas Kochkin on 19/07/2019.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import AdColony;
@import StackFoundation;

#import "BDMAdColonyFullscreenAdapter.h"


@interface BDMAdColonyFullscreenAdapter ()<AdColonyInterstitialDelegate>

@property (nonatomic, strong) AdColonyInterstitial *interstitial;

@end

@implementation BDMAdColonyFullscreenAdapter

- (UIView *)adView {
    return nil;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo {
    NSString *zone = ANY(contentInfo).from(BDMAdColonyZoneIDKey).string;
    NSString *adm = ANY(contentInfo).from(BDMAdColonyAdmKey).string;
    if (!zone || !adm) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeNoContent description:@"AdColony zone id wasn't found or adm was nil"];
        [self.loadingDelegate adapter:self failedToPrepareContentWithError:error];
        return;
    }
    AdColonyAdOptions *options = [AdColonyAdOptions new];
    [options setOption:@"adm" withStringValue:adm];
    
    [AdColony requestInterstitialInZone:zone options:options andDelegate:self];
}

- (void)present {
    UIViewController *rootViewController = [self.displayDelegate rootViewControllerForAdapter:self];
    if (self.interstitial.expired || !self.interstitial) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeWasExpired description:@"AdColony interstitial was expired"];
        [self.displayDelegate adapter:self failedToPresentAdWithError:error];
        return;
    }
    [self.interstitial showWithPresentingViewController:rootViewController];
}

#pragma mark - AdColonyInterstitialDelegate

- (void)adColonyInterstitialDidLoad:(AdColonyInterstitial * _Nonnull)interstitial {
    self.interstitial = interstitial;
    [self.loadingDelegate adapterPreparedContent:self];
}

- (void)adColonyInterstitialDidFailToLoad:(AdColonyAdRequestError * _Nonnull)error {
    [self.loadingDelegate adapter:self failedToPrepareContentWithError:error];
}

- (void)adColonyInterstitialWillOpen:(AdColonyInterstitial * _Nonnull)interstitial {
    [self.displayDelegate adapterWillPresent:self];
}

- (void)adColonyInterstitialDidClose:(AdColonyInterstitial * _Nonnull)interstitial {
    if (self.rewarded) {
        [self.displayDelegate adapterFinishRewardAction:self];
    }
    [self.displayDelegate adapterDidDismiss:self];
}

- (void)adColonyInterstitialExpired:(AdColonyInterstitial * _Nonnull)interstitial {
    self.interstitial = nil;
    NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeWasExpired description:@"Interstitial was expired"];
    [self.loadingDelegate adapter:self failedToPrepareContentWithError:error];
}

- (void)adColonyInterstitialDidReceiveClick:(AdColonyInterstitial * _Nonnull)interstitial {
    [self.displayDelegate adapterRegisterUserInteraction:self];
}

@end

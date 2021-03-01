//
//  BDMMRAIDInterstitialAdapter.m
//
//  Copyright © 2018 Appodeal. All rights reserved.
//

@import StackUIKit;
@import StackMRAIDKit;
@import StackFoundation;

#import "BDMMRAIDConfiguration.h"
#import "BDMMRAIDInterstitialAdapter.h"


@interface BDMMRAIDInterstitialAdapter () <STKMRAIDAdDelegate, STKMRAIDServiceDelegate, STKMRAIDInterstitialPresenterDelegate>

@property (nonatomic, strong) STKMRAIDAd *ad;
@property (nonatomic, strong) STKMRAIDInterstitialPresenter *presenter;

@property (nonatomic, assign) NSTimeInterval skipOffset;

@end

@implementation BDMMRAIDInterstitialAdapter

- (UIView *)adView {
    return self.ad.webView;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo {
    NSArray *mraidFeatures      = @[kMRAIDSupportsInlineVideo, kMRAIDSupportsLogging, kMRAIDPreloadURL, kMRAIDMeasure];

    self.adContent              = ANY(contentInfo).from(kBDMCreativeAdm).string;
    self.ad                     = [STKMRAIDAd new];
    self.ad.delegate            = self;
    self.ad.service.delegate    = self;
    self.presenter              = [[STKMRAIDInterstitialPresenter alloc] initWithConfiguration:[BDMMRAIDConfiguration configuraton:contentInfo]];
    self.presenter.delegate     = self;
    
    [self.ad.service.configuration registerServices:mraidFeatures];
    self.ad.service.configuration.partnerName = kBDMOMPartnerName;
    self.ad.service.configuration.partnerVersion = kBDMVersion;
    [self.ad loadHTML:self.adContent];
}

- (void)present {
    [self.presenter presentAd:self.ad];
}

#pragma mark - STKMRAIDAdDelegate

- (void)didLoadAd:(STKMRAIDAd *)ad {
    [self.loadingDelegate adapterPreparedContent:self];
}

- (void)didFailToLoadAd:(STKMRAIDAd *)ad withError:(NSError *)error {
    [self.loadingDelegate adapter:self failedToPrepareContentWithError:error];
}

- (BOOL)ad:(STKMRAIDAd *)ad shouldProcessNavigationWithURL:(NSURL *)URL {
    return YES;
}

#pragma mark - STKMRAIDInterstitialPresenterDelegate

- (void)presenterDidAppear:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterWillPresent:self];
}

- (void)presenterDidDisappear:(id<STKMRAIDPresenter>)presenter {
    if (self.rewarded) {
        [self.displayDelegate adapterFinishRewardAction:self];
    }
    [self.displayDelegate adapterDidDismiss:self];
}

- (void)presenterFailToPresent:(id<STKMRAIDPresenter>)presenter withError:(NSError *)error {
    NSError *wrappedError = [error bdm_wrappedWithCode:BDMErrorCodeBadContent];
    [self.displayDelegate adapter:self failedToPresentAdWithError:wrappedError];
}

- (UIViewController *)presenterRootViewController {
    return [self.displayDelegate rootViewControllerForAdapter:self] ?: UIViewController.stk_topPresentedViewController;
}

- (void)presenterWillLeaveApplication:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterRegisterUserInteraction:self];
}

- (void)presenterWillPresentProductScreen:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterRegisterUserInteraction:self];
}

#pragma mark - STKMRAIDServiceDelegate

- (void)mraidServiceDidReceiveLogMessage:(NSString *)message {
    BDMLog(@"%@", message);
}

@end
